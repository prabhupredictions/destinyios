import Foundation
import StoreKit
import Combine
import CryptoKit  // W4: SHA1 for UUIDv5(appAccountToken) derivation

/// Surfaced to the UI when the backend rejects a /verify call because the
/// Apple-side subscription is already linked to a different email account
/// in our DB. The user needs to sign in with the original email or contact
/// support — they cannot resolve this in-app without action.
struct SubscriptionConflict: Identifiable {
    let id = UUID()
    let productID: String
}

/// StoreKit 2 Subscription Manager
/// Handles product loading, purchasing, and transaction verification
@MainActor
class SubscriptionManager: ObservableObject {
    static let shared = SubscriptionManager()
    
    // MARK: - Published Properties
    @Published private(set) var products: [Product] = []
    @Published private(set) var purchasedProductIDs: Set<String> = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    
    // Pending upgrade tracking (when user upgrades Core→Plus, effective next billing)
    @Published private(set) var pendingUpgradeProductId: String?
    @Published private(set) var pendingUpgradeEffectiveDate: Date?

    // Free trial eligibility — false if user has ever subscribed to Core or Plus
    @Published private(set) var isPlusTrialEligible: Bool = false

    /// True while a direct in-app purchase via SubscriptionView is in flight.
    /// QuotaManager checks this to suppress the external-plan-change alert
    /// (because SubscriptionView shows its own success modal in that flow).
    var directPurchaseInProgress: Bool = false

    /// Set when /verify rejects a transaction because the Apple subscription
    /// is already linked to a different email account in our backend. Surfaced
    /// to the UI as a clear alert so the user knows to sign in with the
    /// original email instead of being confused by "you're already subscribed"
    /// from Apple paired with a free-tier app experience.
    @Published var subscriptionConflict: SubscriptionConflict?
    /// Set to true when a cross-account conflict is detected this session.
    /// Unlike subscriptionConflict, this is NOT cleared by SwiftUI's .alert(item:)
    /// binding — it persists until sign-out so the activating spinner cannot
    /// re-appear after the conflict alert is dismissed.
    @Published private(set) var conflictDetectedThisSession: Bool = false

    // MARK: - UserDefaults keys

    /// iOS-7: cached `hasActiveSubscription` flag persisted across cold starts.
    /// Trial-button gating reads this synchronously at launch (before reconcile
    /// completes) to avoid mis-rendering the trial CTA for a user who is in
    /// fact already subscribed. Cleared on sign-out via resetForAccountSwitch.
    static let hasActiveSubscriptionCacheKey = "subscription_has_active_cached"

    // MARK: - Product IDs (Configure in App Store Connect)

    /// Core plan
    static let coreMonthlyProductID = "com.daa.core.monthly"
    static let coreYearlyProductID = "com.daa.core.yearly"
    
    /// Plus plan
    static let plusMonthlyProductID = "com.daa.plus.monthly"
    static let plusYearlyProductID = "com.daa.plus.yearly"
    
    private let productIDs: Set<String> = [
        coreMonthlyProductID, coreYearlyProductID,
        plusMonthlyProductID, plusYearlyProductID
    ]
    
    // MARK: - Transaction Listener
    private var transactionListener: Task<Void, Never>?

    // Dedup: tracks original transaction IDs currently in-flight to /verify.
    // Prevents concurrent calls from listenForTransactions + reconcile both
    // hitting the backend for the same transaction and firing two conflict popups.
    private var verifyInFlight: Set<String> = []

    // MARK: - Foreground sync timer (INV-2 Gap A)
    /// Runs while the app is in foreground and triggers QuotaManager.syncStatus
    /// every minute. Respects QuotaManager's 5-min cooldown internally, so the
    /// actual network call happens at most every 5 min — but cancellations or
    /// expirations that the backend received via webhook reflect in the UI
    /// without requiring the user to background+foreground the app.
    private var foregroundSyncTimer: Task<Void, Never>?
    private static let foregroundSyncTickInterval: TimeInterval = 60

    // MARK: - Init
    private init() {
        transactionListener = listenForTransactions()

        Task {
            await loadProducts()
            await updatePurchasedProducts()
        }
    }
    
    deinit {
        transactionListener?.cancel()
        foregroundSyncTimer?.cancel()
    }

    // MARK: - Foreground sync timer control (INV-2 Gap A)

    /// Start the periodic sync. Called from scenePhase=.active in ios_appApp.
    /// Idempotent — safe to call multiple times.
    func startForegroundSyncTimer() {
        foregroundSyncTimer?.cancel()
        foregroundSyncTimer = Task { [weak self] in
            let interval = Self.foregroundSyncTickInterval
            while !Task.isCancelled {
                let nanoseconds = UInt64(interval * 1_000_000_000)
                try? await Task.sleep(nanoseconds: nanoseconds)
                guard let self = self, !Task.isCancelled else { return }

                let email = DataManager.shared.getCurrentUserProfile()?.email
                    ?? UserDefaults.standard.string(forKey: "userEmail")
                guard let email = email else { continue }

                // force=false respects the 5-min cooldown — actual network
                // calls happen at most every 5 min while foreground.
                try? await QuotaManager.shared.syncStatus(email: email, force: false)
            }
        }
    }

    /// Stop the periodic sync. Called from scenePhase=.background.
    func stopForegroundSyncTimer() {
        foregroundSyncTimer?.cancel()
        foregroundSyncTimer = nil
    }
    
    // MARK: - Product Loading
    
    /// Load available products from App Store.
    ///
    /// INV-3 Gap 6: retry up to 3 times with exponential backoff. Without
    /// products, isPlusTrialEligible defaults to false and the user can't
    /// see trial pricing. A transient network blip should not lock them out.
    func loadProducts() async {
        isLoading = true
        errorMessage = nil

        var attempt = 0
        let maxAttempts = 3
        while attempt < maxAttempts {
            attempt += 1
            do {
                products = try await Product.products(for: productIDs)
                products.sort { $0.price < $1.price }
                await updateTrialEligibility()
                isLoading = false
                return
            } catch {
                if attempt >= maxAttempts {
                    errorMessage = "Failed to load products: \(error.localizedDescription)"
                    isLoading = false
                    return
                }
                // Exponential backoff: 1s, 2s
                let delaySeconds = UInt64(attempt) * 1_000_000_000
                try? await Task.sleep(nanoseconds: delaySeconds)
            }
        }
    }
    
    /// Get products for a specific plan
    func productsForPlan(_ planId: String) -> [Product] {
        let prefix = "com.daa.\(planId)."
        return products.filter { $0.id.hasPrefix(prefix) }
    }
    
    /// Get monthly product for a plan
    func monthlyProduct(for planId: String) -> Product? {
        products.first { $0.id == "com.daa.\(planId).monthly" }
    }
    
    /// Get yearly product for a plan
    func yearlyProduct(for planId: String) -> Product? {
        products.first { $0.id == "com.daa.\(planId).yearly" }
    }
    
    // MARK: - Purchase

    /// Direct-to-Plus purchase helper.
    ///
    /// Exists for Paywall v2 paths where the UI skips the SubscriptionView
    /// picker and commits the user straight to the monthly Plus plan. Resolves
    /// the monthly Plus product via `monthlyProduct(for:)` and delegates to the
    /// existing `purchase(_:)` method, which already handles JWS verification,
    /// `transaction.finish()`, `syncStatus(force:true)`, and error states.
    /// Returns `true` only when the underlying purchase fully activates;
    /// returns `false` (and logs) when the product is missing or the purchase
    /// fails / is cancelled / is pending.
    public func purchasePlusDirect() async -> Bool {
        guard let product = monthlyProduct(for: "plus") else {
            print("⚠️ [purchasePlusDirect] No monthly Plus product available — cannot purchase")
            errorMessage = "Plus subscription is unavailable right now. Please try again."
            return false
        }
        do {
            return try await purchase(product)
        } catch {
            print("⚠️ [purchasePlusDirect] purchase failed: \(error)")
            return false
        }
    }

    /// Purchase a subscription product
    func purchase(_ product: Product) async throws -> Bool {
        isLoading = true
        errorMessage = nil
        directPurchaseInProgress = true
        defer { directPurchaseInProgress = false }

        do {
            // W4b: bind a server-minted random UUID as `appAccountToken`.
            // iOS fetches the UUID from /subscription/app-account-token at
            // login + caches in Keychain. Apple includes it in the signed
            // transaction; backend rejects /verify if the JWS-embedded
            // token doesn't match the user's stored UUID — REAL cross-
            // account replay defense (the W4a UUIDv5(email) was forgeable
            // and only logged for support correlation).
            let result: Product.PurchaseResult
            if let appAccountToken = await fetchOrCacheAppAccountToken() {
                result = try await product.purchase(options: [
                    .appAccountToken(appAccountToken),
                ])
            } else {
                result = try await product.purchase()
            }
            
            switch result {
            case .success(let verification):
                // Extract JWS from VerificationResult BEFORE extracting Transaction
                let jws = verification.jwsRepresentation
                let transaction = try checkVerified(verification)
                let backendOK = await verifyWithBackend(jws: jws, transaction: transaction)
                if backendOK {
                    await transaction.finish()
                } else {
                    // Don't finish — StoreKit will re-deliver on next launch via Transaction.updates
                    print("⚠️ [Purchase] Backend verification failed — leaving transaction unfinished. Will retry on next launch.")
                    errorMessage = "We've received your payment. Activating your subscription — please reopen the app shortly."
                }
                await updatePurchasedProducts()

                // Delayed re-check for pending upgrades (StoreKit status may not update immediately)
                Task {
                    try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 second delay
                    await self.checkPendingUpgrade()
                    print("🔄 [purchase] Delayed pending upgrade check completed")
                }

                isLoading = false

                // Log transaction details for debugging
                print("✅ [Purchase] Completed: \(product.id), env: \(transaction.environment)")
                if let expires = transaction.expirationDate {
                    print("   Expires: \(expires)")
                }

                // Return backendOK — caller treats `true` as "fully activated".
                // If backend verify failed, errorMessage is already set above
                // so the caller can surface it without flashing a misleading
                // success state.
                return backendOK
                
            case .userCancelled:
                isLoading = false
                return false
                
            case .pending:
                isLoading = false
                // INV-A8: surface a clearer message — .pending means Apple is
                // waiting on parental approval (Ask to Buy) or SCA bank
                // confirmation. The transaction will arrive later via
                // Transaction.updates, so the user shouldn't tap purchase
                // again. Be explicit so they don't think the flow failed.
                errorMessage = "Your purchase is awaiting approval (e.g. Ask to Buy or bank confirmation). It will activate automatically once approved — no need to retry."
                return false
                
            @unknown default:
                isLoading = false
                return false
            }
        } catch {
            isLoading = false

            // INV-3 Gap 5: detect Apple's "you're already subscribed" error.
            // StoreKit raises StoreKitError.userCancelled when the user dismisses
            // Apple's confirmation alert, but the underlying SKError can be
            // .paymentNotAllowed or product-already-owned states. We recover by
            // re-running reconcile so backend gets the existing entitlement.
            let nsErr = error as NSError
            let lowerDesc = nsErr.localizedDescription.lowercased()
            let alreadySubscribed = lowerDesc.contains("already")
                && (lowerDesc.contains("subscrib") || lowerDesc.contains("purchas"))
            if alreadySubscribed {
                print("ℹ️ [Purchase] Apple says user is already subscribed — running reconcile")
                errorMessage = "You're already subscribed. Activating in the app now…"
                Task { await self.reconcileEntitlementsWithBackend() }
                return false
            }

            errorMessage = "Purchase failed: \(error.localizedDescription)"
            throw error
        }
    }

    // MARK: - Restore Purchases
    
    /// Restore previous purchases — standard StoreKit 2 pattern. Forces a
    /// fresh receipt sync from Apple AND pushes every active entitlement to
    /// the backend so a user with a paid sub that the DB never recorded
    /// (e.g. offer code redeemed pre-install, missed webhook) is fully
    /// activated by tapping Restore. Returns `true` if at least one active
    /// entitlement was found, `false` if there was nothing to restore. The
    /// caller is responsible for showing UI feedback in either case
    /// (Apple HIG requires explicit feedback on Restore).
    @discardableResult
    func restorePurchases() async -> Bool {
        isLoading = true
        errorMessage = nil

        do {
            try await AppStore.sync()
            await reconcileEntitlementsWithBackend()
            await updatePurchasedProducts()
            isLoading = false
            return !purchasedProductIDs.isEmpty
        } catch {
            isLoading = false
            errorMessage = "Restore failed: \(error.localizedDescription)"
            return false
        }
    }
    
    // MARK: - Entitlement Check
    
    /// Check if user has any active subscription
    var hasActiveSubscription: Bool {
        !purchasedProductIDs.isEmpty
    }

    /// iOS-7: synchronous reader for the persisted `hasActiveSubscription`
    /// state. Use this during cold-start trial gating BEFORE reconcile
    /// completes so the trial CTA does not flash on for a user who already
    /// owns a paid entitlement on their last known good state.
    /// Returns false if no value is cached (fail-closed for trial visibility).
    nonisolated static func cachedHasActiveSubscription() -> Bool {
        UserDefaults.standard.bool(forKey: hasActiveSubscriptionCacheKey)
    }

    /// INV-3 gate: should the "Start 7-Day Free Trial" button be visible
    /// for the given plan? Pure function so it can be unit-tested without
    /// instantiating SubscriptionManager.
    ///
    /// Returns true ONLY when ALL conditions hold:
    ///   1. The plan is Plus (we only offer trial on Plus today)
    ///   2. Apple says the user is eligible for the intro offer
    ///   3. User has NO active subscription (Apple-side truth via
    ///      Transaction.currentEntitlements). This is the critical
    ///      check that closes the offer-code-redeemed bug — Apple's
    ///      intro eligibility flag is true even after offer redemption,
    ///      so we must additionally verify there is no live entitlement.
    ///   4. NO cross-account conflict has been detected. Belt-and-
    ///      suspenders: even in the brief race window between sign-in
    ///      and reconcile finishing, if backend has rejected this
    ///      email's claim on the local Apple ID's sub, never offer the
    ///      trial — it cannot succeed.
    ///   5. Backend says the user has NEVER subscribed before. This is
    ///      authoritative truth from /subscription/status — survives
    ///      across devices and sandbox sim transaction-cache wipes.
    ///      Apple's `isEligibleForIntroOffer` resets to true if the
    ///      sandbox tester deletes their StoreKit transactions; backend
    ///      `has_ever_subscribed` does not. Defaults to false (trust
    ///      Apple) when the param is omitted so existing callers and
    ///      tests are unchanged.
    nonisolated static func shouldShowTrialButton(
        planId: String,
        isPlusTrialEligible: Bool,
        hasActiveSubscription: Bool,
        hasConflict: Bool = false,
        hasEverSubscribed: Bool = false
    ) -> Bool {
        guard planId == "plus" else { return false }
        guard isPlusTrialEligible else { return false }
        guard !hasActiveSubscription else { return false }
        guard !hasConflict else { return false }
        guard !hasEverSubscribed else { return false }
        return true
    }

    /// Get the active plan ID from purchased products
    var activePlanId: String? {
        for productId in purchasedProductIDs {
            if productId.contains(".core.") { return "core" }
            if productId.contains(".plus.") { return "plus" }
        }
        return nil
    }
    
    // MARK: - Transaction Listener
    
    private func listenForTransactions() -> Task<Void, Never> {
        Task.detached { [weak self] in
            for await result in Transaction.updates {
                do {
                    // Extract JWS from VerificationResult BEFORE extracting Transaction
                    let jws = result.jwsRepresentation
                    let transaction = try Self.checkVerifiedStatic(result)
                    
                    // Skip expired transactions to prevent stale sandbox renewals
                    // from overwriting the user's plan
                    if let expiresDate = transaction.expirationDate,
                       expiresDate < Date() {
                        print("⏭️ [TransactionListener] Skipping expired transaction: \(transaction.productID), expired: \(expiresDate)")
                        await transaction.finish()
                        continue
                    }
                    
                    print("📥 [TransactionListener] Processing transaction: \(transaction.productID), env: \(transaction.environment)")
                    let backendOK = await self?.verifyWithBackend(jws: jws, transaction: transaction) ?? false
                    if backendOK {
                        await transaction.finish()
                    } else {
                        // Don't finish — StoreKit will re-deliver on next launch
                        print("⚠️ [TransactionListener] Backend failed — leaving unfinished for retry: \(transaction.productID)")
                    }
                    await self?.updatePurchasedProducts()
                } catch {
                    print("Transaction verification failed: \(error)")
                }
            }
        }
    }
    
    // MARK: - Verification
    
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        try Self.checkVerifiedStatic(result)
    }
    
    private nonisolated static func checkVerifiedStatic<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw SubscriptionError.verificationFailed
        case .verified(let safe):
            return safe
        }
    }
    
    /// Call on logout/account switch to prevent a previous user's StoreKit
    /// entitlements from bleeding into the newly logged-in account.
    func resetForAccountSwitch() {
        purchasedProductIDs = []
        pendingUpgradeProductId = nil
        pendingUpgradeEffectiveDate = nil
        isPlusTrialEligible = false
        conflictDetectedThisSession = false
        subscriptionConflict = nil
        UserDefaults.standard.set(false, forKey: "isPremium")
        // INV-J5: clear ALL subscription cache keys so a different
        // user signing in on the same device cannot see stale data.
        UserDefaults.standard.removeObject(forKey: "currentPlanId")
        UserDefaults.standard.removeObject(forKey: "subscriptionStatus")
        UserDefaults.standard.removeObject(forKey: "subscriptionExpiresAt")
        UserDefaults.standard.removeObject(forKey: "autoRenewStatus")
        UserDefaults.standard.removeObject(forKey: "currentPlanDisplayName")
        // iOS-7: clear cached hasActiveSubscription so a different user signing
        // in on the same device cannot inherit the previous user's trial-gating
        // state at cold start.
        UserDefaults.standard.removeObject(forKey: Self.hasActiveSubscriptionCacheKey)
    }

    func updatePurchasedProducts() async {
        var purchased: Set<String> = []

        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                // INV-J7: skip transactions that have been superseded by an
                // upgrade. Without this, a Core+Plus user during the brief
                // overlap window appears to own BOTH tiers, which can flip
                // pendingUpgrade UI off prematurely and confuse plan display.
                if transaction.isUpgraded {
                    continue
                }
                if transaction.revocationDate == nil {
                    purchased.insert(transaction.productID)
                }
            } catch {
                print("Entitlement verification failed: \(error)")
            }
        }

        purchasedProductIDs = purchased
        UserDefaults.standard.set(!purchased.isEmpty, forKey: "isPremium")
        // iOS-7: persist hasActiveSubscription so cold-start trial gating
        // can use the last known good state until reconcile lands.
        UserDefaults.standard.set(!purchased.isEmpty, forKey: Self.hasActiveSubscriptionCacheKey)

        // INV-3 Gap 2: refresh trial eligibility whenever entitlements change.
        // Apple's isEligibleForIntroOffer is computed lazily and the value
        // observed at app launch may be stale after a reconcile/redemption.
        await updateTrialEligibility()

        // Check for pending upgrades
        await checkPendingUpgrade()
    }

    /// Reconcile every active StoreKit entitlement with the backend.
    /// Critical for offer-code redemptions that happened BEFORE the app was
    /// installed (e.g. user taps redeem link, downloads app, signs in).
    /// In that flow Transaction.updates does NOT fire, so /verify is never
    /// called and the backend has no record of the paid subscription —
    /// user gets stuck on free plan and (when waitlist is on) lands in
    /// waitlist despite having paid.
    ///
    /// Call this after sign-in/sign-up succeeds and on every foreground.
    /// Idempotent — backend dedups by originalTransactionId.
    ///
    /// INV-9 G2: re-entry guard. Sign-in path and scenePhase=.active can
    /// fire reconcile concurrently. Without the guard, both iterations
    /// hit the backend in parallel for the same entitlements — wasteful.
    /// Backend correctness is preserved by the DB unique index, but we
    /// can avoid the redundant network calls entirely.
    private var isReconciling: Bool = false
    private var lastReconcileTime: Date = .distantPast

    func reconcileEntitlementsWithBackend() async {
        if isReconciling {
            print("🔄 [Reconcile] Already running; skipping concurrent invocation")
            return
        }
        // Debounce: multiple call sites (app foreground + sign-in + view appear)
        // can all dispatch Task{} nearly simultaneously, reading isReconciling=false
        // before any one sets it true. A 5s cooldown absorbs all same-login bursts.
        guard Date().timeIntervalSince(lastReconcileTime) > 5 else {
            print("🔄 [Reconcile] Debounced; last ran \(String(format: "%.1f", Date().timeIntervalSince(lastReconcileTime)))s ago")
            return
        }
        isReconciling = true
        lastReconcileTime = Date()
        defer { isReconciling = false }

        for await result in Transaction.currentEntitlements {
            do {
                let jws = result.jwsRepresentation
                let transaction = try checkVerified(result)
                if transaction.revocationDate != nil { continue }
                // INV-J7: skip superseded transactions during reconcile too
                // so we don't push the older tier to the backend after an
                // upgrade has already been recorded.
                if transaction.isUpgraded { continue }
                print("🔄 [Reconcile] Verifying entitlement with backend: \(transaction.productID)")
                let ok = await verifyWithBackend(jws: jws, transaction: transaction)
                if ok {
                    await transaction.finish()
                }
            } catch {
                print("⚠️ [Reconcile] Entitlement verification failed: \(error)")
            }
        }
        await updatePurchasedProducts()
    }
    
    /// Check for pending subscription upgrades (e.g., Core→Plus scheduled for next billing)
    /// Uses StoreKit 2's Product.SubscriptionInfo to detect autoRenewPreference changes
    func checkPendingUpgrade() async {
        print("🔍 [checkPendingUpgrade] Starting check...")
        
        // Reset pending state
        pendingUpgradeProductId = nil
        pendingUpgradeEffectiveDate = nil
        
        // Get current subscription status for each product
        for product in products {
            guard let subscription = product.subscription else { 
                print("🔍 [checkPendingUpgrade] Product \(product.id) has no subscription")
                continue 
            }
            
            print("🔍 [checkPendingUpgrade] Checking product: \(product.id)")
            
            // Get subscription status
            guard let statuses = try? await subscription.status else { 
                print("🔍 [checkPendingUpgrade] No status for \(product.id)")
                continue 
            }
            
            print("🔍 [checkPendingUpgrade] Found \(statuses.count) status(es) for \(product.id)")
            
            for (index, status) in statuses.enumerated() {
                print("🔍 [checkPendingUpgrade] Status[\(index)] state: \(status.state)")
                
                // Only check verified statuses
                guard case .verified(let renewalInfo) = status.renewalInfo,
                      case .verified(let transaction) = status.transaction else { 
                    print("🔍 [checkPendingUpgrade] Status[\(index)] verification failed")
                    continue 
                }
                
                print("🔍 [checkPendingUpgrade] Current productID: \(transaction.productID)")
                print("🔍 [checkPendingUpgrade] autoRenewPreference: \(renewalInfo.autoRenewPreference ?? "nil")")
                print("🔍 [checkPendingUpgrade] willAutoRenew: \(renewalInfo.willAutoRenew)")
                
                // Check if auto-renew product differs from current product
                if let autoRenewProductId = renewalInfo.autoRenewPreference,
                   autoRenewProductId != transaction.productID {
                    // User has scheduled a change - this is a pending upgrade/downgrade
                    self.pendingUpgradeProductId = autoRenewProductId
                    
                    // Effective date is the current subscription's expiration
                    self.pendingUpgradeEffectiveDate = transaction.expirationDate
                    
                    print("📅 Pending upgrade detected: \(transaction.productID) → \(autoRenewProductId)")
                    print("   Effective: \(transaction.expirationDate?.description ?? "unknown")")
                    return
                }
            }
        }
        print("🔍 [checkPendingUpgrade] No pending upgrade found")
    }
    
    /// Get pending upgrade plan ID (extracted from product ID)
    var pendingUpgradePlanId: String? {
        guard let productId = pendingUpgradeProductId else { return nil }
        if productId.contains(".core.") { return "core" }
        if productId.contains(".plus.") { return "plus" }
        return nil
    }
    
    // MARK: - Trial Eligibility

    func updateTrialEligibility() async {
        guard let plusProduct = products.first(where: { $0.id.hasPrefix("com.daa.plus.") }),
              let subscription = plusProduct.subscription else {
            isPlusTrialEligible = false
            return
        }
        isPlusTrialEligible = await subscription.isEligibleForIntroOffer
    }

    // MARK: - Backend Verification

    /// Verify the transaction with our backend.
    /// Returns true if the backend confirmed (HTTP 200), false otherwise.
    /// Sandbox transactions on a production API build return false — they are
    /// neither verified nor finished, so StoreKit will redeliver them later
    /// on a build whose environment actually matches (iOS-4).
    /// Caller must only call transaction.finish() when this returns true,
    /// so StoreKit will re-deliver the unfinished transaction on retry.
    @discardableResult
    private func verifyWithBackend(jws: String, transaction: Transaction) async -> Bool {
        guard let email = getCurrentUserEmail() else {
            print("⚠️ [Backend] No user email — keeping transaction unfinished for retry on next sign-in")
            return false
        }

        // Dedup: if another code path (listenForTransactions vs reconcile) is already
        // calling /verify for this exact transaction, skip. Both paths run on @MainActor
        // so this set access is safe. Without this guard, two concurrent calls for
        // transaction "0" (Simulator always uses "0") each get a conflict response from
        // the DB unique index and fire two separate conflict popups.
        let txnKey = "\(transaction.originalID)-\(email)"
        guard !verifyInFlight.contains(txnKey) else {
            print("🔄 [Backend] /verify already in-flight for \(txnKey) — skipping duplicate call")
            return false
        }
        verifyInFlight.insert(txnKey)
        defer { verifyInFlight.remove(txnKey) }

        // iOS-4 fix: Sandbox transactions on a production-API build must NOT be
        // finished locally. Returning false here ensures the caller (purchase /
        // listenForTransactions / reconcile) does NOT call transaction.finish(),
        // so StoreKit will redeliver the transaction on a future launch when the
        // user is on the matching environment (or on the sandbox/test build).
        // The backend also rejects these (test cases I1-I4 / INV-10) — this is
        // a defense-in-depth guard. We never set isPremium locally for these:
        // isPremium flips only via updatePurchasedProducts, which is driven by
        // Transaction.currentEntitlements on the production environment.
        if transaction.subscriptionEnvironment == .sandbox &&
            APIConfig.baseURL.contains("astroapi-prod") {
            print("⚠️ [Backend] Sandbox transaction on production API — NOT finishing, NOT granting premium. StoreKit will redeliver on env match. (product=\(transaction.productID))")
            return false
        }

        do {
            let url = URL(string: APIConfig.baseURL + "/subscription/verify")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("Bearer \(APIConfig.apiKey)", forHTTPHeaderField: "Authorization")

            let body: [String: Any] = [
                "signed_transaction": jws,
                "user_email": email,
                "platform": "apple",
                "environment": transaction.subscriptionEnvironment.rawValue
            ]
            request.httpBody = try JSONSerialization.data(withJSONObject: body)

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ [Backend] No HTTP response — keeping transaction unfinished for retry")
                return false
            }

            if httpResponse.statusCode != 200 {
                print("❌ Backend verification failed: HTTP \(httpResponse.statusCode) — keeping transaction unfinished for retry")
                return false
            }

            // Backend returns 200 with success:false for application-level rejections
            // (cross-account conflict, invalid bundle, etc.). Parse the body so we
            // can surface specific errors to the UI rather than treating all 200s
            // as success.
            struct VerifyResponseBody: Decodable {
                let success: Bool
                let error: String?
            }
            let parsedResponse = (try? JSONDecoder().decode(VerifyResponseBody.self, from: data))

            if let parsedResponse, !parsedResponse.success {
                let errorCode = parsedResponse.error ?? "unknown"
                print("❌ Backend verification rejected: \(errorCode)")
                if errorCode == "transaction_belongs_to_different_user" {
                    // BUG-1 fix: only create a new SubscriptionConflict if we haven't
                    // already shown the alert this session. SwiftUI's .alert(item:)
                    // fires whenever subscriptionConflict transitions nil→non-nil with
                    // a new UUID — re-assigning on every foreground reconcile caused the
                    // popup to fire repeatedly. conflictDetectedThisSession is only
                    // cleared on sign-out, so this gates to exactly one popup per session.
                    if !self.conflictDetectedThisSession {
                        self.subscriptionConflict = SubscriptionConflict(productID: transaction.productID)
                        self.conflictDetectedThisSession = true
                    }
                }
                // Finish to avoid retry loop — this transaction will never succeed
                // for the current user (different email already owns it, or invalid bundle, etc.)
                return true
            }

            print("✅ Backend verification successful for \(email)")
            // Sync quota status after successful verification (force bypass cooldown)
            try? await QuotaManager.shared.syncStatus(email: email, force: true)
            return true
        } catch {
            print("❌ Backend verification error: \(error) — keeping transaction unfinished for retry")
            return false
        }
    }
    
    private func getCurrentUserEmail() -> String? {
        if let profile = DataManager.shared.getCurrentUserProfile() {
            return profile.email
        }
        return UserDefaults.standard.string(forKey: "userEmail")
    }

    // W4b-fix #7: in-flight dedup so two simultaneous purchase taps
    // don't race the server's mint. Same pattern as verifyInFlight.
    private var appAccountTokenFetchInFlight: Task<UUID?, Never>?

    /// W4b: Fetch the server-minted random UUID this user must use as
    /// `appAccountToken` on Apple purchases. The backend stores it in
    /// `user_subscriptions.apple_app_account_token`, mints lazily on
    /// first GET, and enforces match on /verify. Cached in Keychain
    /// (per-email key) so we only hit the network once.
    ///
    /// SECURITY MODEL: this UUID is treated as a secret on the iOS
    /// side. Stored in Keychain (encrypted, device-bound), NEVER
    /// UserDefaults.
    ///
    /// W4b-fix #5: on ANY fetch failure, return nil. Caller MUST then
    /// call product.purchase() WITHOUT the appAccountToken option so
    /// the JWS goes through the backend's backward-compat path. The
    /// previous behavior (fall back to deriveAppAccountToken's UUIDv5
    /// of email) BAKED a bad UUID into Apple's signed JWS, which the
    /// strict backend then rejected forever — user charged, no
    /// recovery in code. Sending no token is strictly safer than
    /// sending the wrong one.
    private func fetchOrCacheAppAccountToken() async -> UUID? {
        guard let email = getCurrentUserEmail()?.lowercased(),
              !email.isEmpty else { return nil }

        let keychainKey = "appAccountToken::\(email)"
        if let cached = KeychainService.shared.loadString(forKey: keychainKey),
           let uuid = UUID(uuidString: cached) {
            return uuid
        }

        // W4b-fix #7: dedup concurrent fetches.
        if let existing = appAccountTokenFetchInFlight {
            return await existing.value
        }
        let task = Task<UUID?, Never> { [weak self] in
            guard let self = self else { return nil }
            defer { self.appAccountTokenFetchInFlight = nil }
            return await self.performAppAccountTokenFetch(
                email: email, keychainKey: keychainKey
            )
        }
        appAccountTokenFetchInFlight = task
        return await task.value
    }

    private func performAppAccountTokenFetch(email: String, keychainKey: String) async -> UUID? {
        // Re-check Keychain inside the task — another caller may have
        // populated it between our cache miss and task scheduling.
        if let cached = KeychainService.shared.loadString(forKey: keychainKey),
           let uuid = UUID(uuidString: cached) {
            return uuid
        }

        guard var components = URLComponents(string: APIConfig.baseURL + "/subscription/app-account-token") else {
            return nil  // W4b-fix #5: fail safe (no token) rather than poison JWS
        }
        components.queryItems = [URLQueryItem(name: "email", value: email)]
        guard let url = components.url else { return nil }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(APIConfig.apiKey)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 8

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                print("⚠️ [appAccountToken] fetch returned non-200 — purchase will proceed without token (backward-compat path)")
                return nil
            }
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let tokenStr = json["app_account_token"] as? String,
                  let uuid = UUID(uuidString: tokenStr) else {
                print("⚠️ [appAccountToken] fetch returned malformed body — purchase will proceed without token")
                return nil
            }
            // Cache in Keychain
            try? KeychainService.shared.saveString(tokenStr, forKey: keychainKey)
            return uuid
        } catch {
            print("⚠️ [appAccountToken] fetch failed: \(error) — purchase will proceed without token")
            return nil
        }
    }

    /// W4a (kept for golden-test parity ONLY): UUIDv5 derivation from
    /// email. FORGEABLE — DO NOT USE in any production code path. The
    /// backend test suite pins this helper's output to detect drift; iOS
    /// no longer calls it (W4b-fix #5 removed the fallback that did).
    private func deriveAppAccountToken() -> UUID? {
        guard let email = getCurrentUserEmail()?.lowercased(),
              !email.isEmpty else { return nil }
        // RFC 4122 §4.3 — namespace UUIDs. Use URL namespace.
        let urlNamespace = UUID(uuidString: "6BA7B811-9DAD-11D1-80B4-00C04FD430C8")!
        let nsBytes = withUnsafeBytes(of: urlNamespace.uuid) { Array($0) }
        let emailBytes = Array(email.utf8)
        var data = Data()
        data.append(contentsOf: nsBytes)
        data.append(contentsOf: emailBytes)
        let digest = Insecure.SHA1.hash(data: data)
        var bytes = Array(digest.prefix(16))
        // Set version (5) and variant (RFC 4122) per RFC 4122 §4.3
        bytes[6] = (bytes[6] & 0x0F) | 0x50
        bytes[8] = (bytes[8] & 0x3F) | 0x80
        let tuple = (
            bytes[0],  bytes[1],  bytes[2],  bytes[3],
            bytes[4],  bytes[5],  bytes[6],  bytes[7],
            bytes[8],  bytes[9],  bytes[10], bytes[11],
            bytes[12], bytes[13], bytes[14], bytes[15]
        )
        return UUID(uuid: tuple)
    }

    // MARK: - Test helpers (DEBUG only)
    // Used by SubscriptionConflictUXTests to inject conflict state without
    // needing a live StoreKit session. Stripped from release builds.
    #if DEBUG
    /// Simulates verifyWithBackend receiving transaction_belongs_to_different_user.
    /// Applies the same guard logic as the production path so tests exercise the fix.
    func simulateConflictDetected(productID: String) {
        if !conflictDetectedThisSession {
            subscriptionConflict = SubscriptionConflict(productID: productID)
            conflictDetectedThisSession = true
        }
    }

    /// Simulates SwiftUI's .alert(item:) clearing the binding on dismiss.
    func simulateAlertDismissed() {
        subscriptionConflict = nil
    }
    #endif
}

// MARK: - Errors

enum SubscriptionError: Error, LocalizedError {
    case verificationFailed
    case purchaseFailed
    case productNotFound
    
    var errorDescription: String? {
        switch self {
        case .verificationFailed: return "Transaction verification failed"
        case .purchaseFailed: return "Purchase could not be completed"
        case .productNotFound: return "Product not found"
        }
    }
}

// MARK: - Transaction Extension

extension Transaction {
    // Note: jwsRepresentation is a native property of Transaction in StoreKit 2
    // Do NOT override it - it provides the actual JWS signed payload
    
    var subscriptionEnvironment: SubscriptionEnvironmentType {
        // Use environment property from Transaction
        // Map to sandbox for any non-production environment
        if case .production = self.environment {
            return .production
        } else {
            return .sandbox
        }
    }
}

enum SubscriptionEnvironmentType: String {
    case sandbox = "Sandbox"
    case production = "Production"
}
