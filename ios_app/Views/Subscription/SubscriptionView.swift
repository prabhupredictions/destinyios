import SwiftUI
import StoreKit

/// Subscription screen matching target mockup design
/// Features displayed from backend with marketing_text
struct SubscriptionView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @StateObject private var quotaManager = QuotaManager.shared
    @State private var isPurchasing = false
    @State private var purchasingPlanId: String?
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var plans: [PlanInfo] = []
    @State private var isLoading = true
    @State private var isRefreshing = false  // For manual refresh button
    @State private var isRestoring = false   // For Restore Purchases button
    @State private var showDestinyMatchingInfo = false
    
    // Trigger build bump: 2026-02-10-10-20
    
    private var isPlusTrialEligible: Bool {
        subscriptionManager.isPlusTrialEligible
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if isLoading {
                        ProgressView("Loading plans...")
                            .padding(.vertical, 40)
                    } else if plans.isEmpty {
                        Text("no_plans_available".localized)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                            .padding(.vertical, 40)
                    } else {
                        // Subheader
                        Text("upgrade_to_keep_going".localized)
                            .font(AppTheme.Fonts.body(size: 16))
                            .foregroundColor(AppTheme.Colors.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 16)
                            .padding(.top, 4)

                        // INV-3 Gap 4: transition banner when Apple says active
                        // but our DB has not yet caught up. Reassures user during
                        // the reconcile window (offer code redemption etc.).
                        activatingBanner

                        // INV-1: cross-account conflict banner — shown when the
                        // local Apple ID's subscription is already linked to a
                        // different Destiny email. Tells user the right action
                        // upfront so they don't tap the plan button repeatedly.
                        crossAccountConflictBanner

                        // Plan cards with feature lists
                        planCardsSection
                        
                        // Collapsible "What is Destiny Matching™?"
                        destinyMatchingSection
                        
                        // Apple ID info
                        appleAccountNote
                        
                        // Restore purchases
                        restoreButton
                        
                        // Footer disclaimers
                        footerDisclaimers
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 40)
            }
            .refreshable {
                // INV-J4: pull-to-refresh — force a full reconcile and
                // force=true backend sync. Safety net for users who
                // redeemed an offer code or where webhook delivery lagged.
                await refreshStatus()
            }
            .background(AppTheme.Colors.mainBackground.ignoresSafeArea())
            .navigationTitle("choose_plan_title".localized)
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        Task { await refreshStatus() }
                    } label: {
                        if isRefreshing {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.Colors.gold))
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "arrow.clockwise")
                                .foregroundColor(AppTheme.Colors.gold)
                        }
                    }
                    .disabled(isRefreshing)
                    .accessibilityLabel("a11y_refresh_subscription".localized)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("done_action".localized) { dismiss() }
                        .foregroundColor(AppTheme.Colors.gold)
                }
                #endif
            }
            .alert("Error", isPresented: $showError) {
                Button("ok_action".localized, role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .task {
                await loadPlans()
                // Refresh StoreKit products each time screen opens (picks up approved products)
                if subscriptionManager.products.isEmpty {
                    await subscriptionManager.loadProducts()
                }
                // If StoreKit has entitlements but backend says free (isPremium=false),
                // reconcile immediately so the conflict is detected and the activating
                // spinner resolves to either "active" or the conflict banner — never stuck.
                if subscriptionManager.hasActiveSubscription && !quotaManager.isPremium {
                    await subscriptionManager.reconcileEntitlementsWithBackend()
                }
            }
            .accessibilityIdentifier("subscription_screen")
        }
    }
    
    // MARK: - Load Plans from Backend
    private func loadPlans() async {
        // Step 1: Immediately show cached plans (no spinner, no flicker)
        let cachedPlans = quotaManager.paidPlans
            .sorted { lhs, rhs in
                if lhs.planId == "plus" { return true }
                if rhs.planId == "plus" { return false }
                return (lhs.priceMonthly ?? 0) < (rhs.priceMonthly ?? 0)
            }
        
        if !cachedPlans.isEmpty {
            plans = cachedPlans
            isLoading = false
            print("⚡ [SubscriptionView] Showing \(cachedPlans.count) cached plans instantly")
        }
        
        // Step 2: Background refresh from server (updates silently)
        do {
            var fetchedPlans = try await quotaManager.fetchPlans()
            fetchedPlans = fetchedPlans.filter { !$0.isFree && $0.planId != "free_guest" && $0.planId != "free_registered" }
            fetchedPlans.sort { lhs, rhs in
                if lhs.planId == "plus" { return true }
                if rhs.planId == "plus" { return false }
                return (lhs.priceMonthly ?? 0) < (rhs.priceMonthly ?? 0)
            }
            await MainActor.run {
                plans = fetchedPlans
                isLoading = false
            }
        } catch {
            print("Failed to refresh plans: \(error)")
            // If we have cached plans, just keep showing those (no error state)
            if plans.isEmpty {
                await MainActor.run { isLoading = false }
            }
        }
    }
    
    // MARK: - Refresh Status
    /// Manually refresh subscription status from StoreKit AND backend.
    /// Called by the toolbar refresh button AND pull-to-refresh (INV-J4).
    private func refreshStatus() async {
        isRefreshing = true

        // Sync with App Store to get latest entitlements
        try? await AppStore.sync()

        // INV-J4: full reconcile so any out-of-band redemptions
        // (offer codes redeemed BEFORE app install) are pushed to the
        // backend, then force a backend sync to clear cached state.
        await subscriptionManager.reconcileEntitlementsWithBackend()

        // Update purchased products and check for pending upgrades
        await subscriptionManager.updatePurchasedProducts()

        // Force backend re-fetch (bypass any local 60s cache)
        if let email = UserDefaults.standard.string(forKey: "userEmail"), !email.isEmpty {
            try? await quotaManager.syncStatus(email: email, force: true)
        }

        // Small delay to ensure UI updates
        try? await Task.sleep(nanoseconds: 300_000_000)

        isRefreshing = false
        print("🔄 [SubscriptionView] Manual refresh completed (force=true)")
    }

    // MARK: - Activating Banner (INV-3 Gap 4)
    /// Shown when Apple says the user has an active subscription but our
    /// DB hasn't caught up yet — typical during the reconcile window
    /// after an offer code redemption. Empty view otherwise.
    @ViewBuilder
    private var activatingBanner: some View {
        // Show "Activating..." ONLY when:
        //   - StoreKit reports an active sub (we have a valid entitlement)
        //   - Backend hasn't yet caught up (isPremium=false)
        //   - AND there's no detected cross-account conflict — otherwise the
        //     banner deadlocks forever because the backend will keep
        //     correctly rejecting (different email already owns this Apple
        //     ID's sub). In that case the conflict alert is the right UX,
        //     not a perpetual "activating" spinner.
        if subscriptionManager.hasActiveSubscription &&
           !quotaManager.isPremium &&
           subscriptionManager.subscriptionConflict == nil &&
           !subscriptionManager.conflictDetectedThisSession {
            HStack(spacing: 10) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.Colors.gold))
                    .scaleEffect(0.8)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Activating your subscription…")
                        .font(AppTheme.Fonts.title(size: 14))
                        .foregroundColor(AppTheme.Colors.gold)
                    Text("This usually takes a few seconds. If it persists, sign out and back in.")
                        .font(AppTheme.Fonts.body(size: 12))
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
                Spacer()
            }
            .padding(12)
            .background(AppTheme.Colors.cardBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(AppTheme.Colors.gold.opacity(0.4), lineWidth: 1)
            )
            .cornerRadius(10)
            .padding(.horizontal, 16)
        }
    }

    // MARK: - Cross-Account Conflict Banner (INV-1)
    /// Shown on the paywall when the local Apple ID's subscription is
    /// already claimed by a different Destiny email per backend. Directs
    /// the user to the right next action upfront so they don't tap the
    /// plan button repeatedly and trip Apple's "you're already subscribed"
    /// alert each time.
    @ViewBuilder
    private var crossAccountConflictBanner: some View {
        // BUG-2 fix: use conflictDetectedThisSession (persists until sign-out),
        // NOT subscriptionConflict (cleared to nil by .alert(item:) on dismiss).
        // Using subscriptionConflict caused the banner to vanish after the user
        // tapped OK on the popup, then reappear on the next foreground reconcile.
        if subscriptionManager.conflictDetectedThisSession {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(AppTheme.Fonts.title(size: 16))
                    .foregroundColor(.orange)
                    .padding(.top, 1)
                VStack(alignment: .leading, spacing: 4) {
                    Text("conflict_banner_title".localized)
                        .font(AppTheme.Fonts.title(size: 14))
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    Text("conflict_banner_body".localized)
                        .font(AppTheme.Fonts.body(size: 12))
                        .foregroundColor(AppTheme.Colors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
            }
            .padding(12)
            .background(Color.orange.opacity(0.10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.orange.opacity(0.55), lineWidth: 1)
            )
            .cornerRadius(10)
            .padding(.horizontal, 16)
            .accessibilityIdentifier("subscription_conflict_banner")
        }
    }

    // MARK: - Plan Cards Section
    private var planCardsSection: some View {
        VStack(spacing: 16) {
            // Find core plan for reference
            let corePlan = plans.first { $0.planId == "core" }
            // Get user's current plan for dynamic button text.
            // INV-3 Gap 3: prefer Apple's view (purchasedProductIDs) when DB is stale.
            // During the window between Apple-side activation (offer code redeem) and
            // backend reconcile completing, quotaManager.currentPlanId may say
            // "free_registered" while Apple says Plus active. Without this fallback,
            // the trial button would render because isCurrentPlan would be false.
            let dbPlan = quotaManager.currentPlanId ?? "free_guest"
            let applePlan = subscriptionManager.activePlanId
            // When the user's paid subscription has lapsed (expired/canceled/
            // revoked/refunded), they have NO current plan from a billing
            // perspective. plan_id still records their history (so Profile
            // can show "Plus (expired)") but the SubscriptionView should
            // show NO "Current" badge — every paid plan should look
            // available for renewal/upgrade. Treat as "no current plan"
            // by returning an empty string (no plan card matches).
            // W3: align with QuotaManager._isInTerminalPaidStatus — `canceled`
            // users still hold entitlement until expires_at, so we don't
            // treat them as expired here. `billing_retry` IS terminal.
            let isPaidPlanExpired = !dbPlan.starts(with: "free")
                && quotaManager.subscriptionStatus.map { ["expired", "billing_retry", "revoked", "refunded"].contains($0) } ?? false
            let userCurrentPlanId: String = {
                if isPaidPlanExpired {
                    // No current plan — user is between subscriptions.
                    return ""
                }
                // If a cross-account conflict was detected, the Apple-side
                // plan does NOT belong to this email. Trust the DB only —
                // otherwise we'd show "Plus" as current plan to a user who
                // is permanently locked out of that Apple sub by INV-1.
                // Also check conflictDetectedThisSession — subscriptionConflict
                // is cleared to nil by SwiftUI's .alert(item:) on dismiss.
                if subscriptionManager.subscriptionConflict != nil ||
                    subscriptionManager.conflictDetectedThisSession {
                    return dbPlan
                }
                if dbPlan.starts(with: "free") || dbPlan == "free_guest" || dbPlan == "free_registered" {
                    return applePlan ?? dbPlan
                }
                return dbPlan
            }()

            ForEach(plans) { plan in
                PlanCardWithFeatures(
                    plan: plan,
                    product: subscriptionManager.monthlyProduct(for: plan.planId),
                    isPurchasing: isPurchasing && purchasingPlanId == plan.planId,
                    isPlus: plan.planId == "plus",
                    // INV-3 (gates pinned in SubscriptionManager.shouldShowTrialButton):
                    // (a) plan must be Plus
                    // (b) Apple says intro-eligible
                    // (c) user has NO active subscription anywhere — closes the
                    //     offer-code-redeemed bug since Apple's intro flag is
                    //     unaware of offer redemptions.
                    // (d) no cross-account conflict — even in the brief window
                    //     before reconcile finishes, never offer trial when
                    //     backend has rejected the claim.
                    isTrialEligible: SubscriptionManager.shouldShowTrialButton(
                        planId: plan.planId,
                        isPlusTrialEligible: isPlusTrialEligible,
                        hasActiveSubscription: subscriptionManager.hasActiveSubscription,
                        hasConflict: subscriptionManager.subscriptionConflict != nil ||
                        subscriptionManager.conflictDetectedThisSession,
                        hasEverSubscribed: QuotaManager.shared.hasEverSubscribed
                    ),
                    corePlan: corePlan,
                    userCurrentPlanId: userCurrentPlanId,
                    pendingUpgradePlanId: subscriptionManager.pendingUpgradePlanId,
                    pendingUpgradeDate: subscriptionManager.pendingUpgradeEffectiveDate
                ) {
                    Task {
                        await purchaseSubscription(planId: plan.planId)
                    }
                }
                .accessibilityIdentifier("subscription_plan_card")
            }
        }
    }
    
    // MARK: - Destiny Matching Info Section
    private var destinyMatchingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showDestinyMatchingInfo.toggle()
                }
            } label: {
                HStack {
                    Image(systemName: showDestinyMatchingInfo ? "chevron.up" : "chevron.down")
                        .font(AppTheme.Fonts.title(size: 14))
                    Text("what_is_destiny_matching".localized)
                        .font(AppTheme.Fonts.title(size: 18))
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(AppTheme.Fonts.body(size: 14))
                }
                .foregroundColor(AppTheme.Colors.textSecondary)
            }
            
            if showDestinyMatchingInfo {
                VStack(alignment: .leading, spacing: 12) {
                    Text("destiny_matching_desc_1".localized)
                        .font(AppTheme.Fonts.body(size: 15).weight(.bold))
                        .foregroundColor(AppTheme.Colors.textSecondary)
                    
                    Text("destiny_matching_desc_2".localized)
                        .font(AppTheme.Fonts.body(size: 14))
                        .foregroundColor(AppTheme.Colors.textSecondary)
                    
                    Text("destiny_matching_desc_3".localized)
                        .font(AppTheme.Fonts.body(size: 14))
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
                .padding()
                .background(AppTheme.Colors.cardBackground)
                .cornerRadius(12)
            }
        }
        .padding(.top, 8)
    }
    
    // MARK: - Restore Button
    /// Apple HIG: a Restore Purchases tap MUST give explicit feedback —
    /// either the paywall dismisses (sub restored) or the user is told
    /// nothing was restorable. Silent no-op is rejection-prone and
    /// confuses users who genuinely paid before.
    private var restoreButton: some View {
        Button(action: {
            Task {
                isRestoring = true
                let restored = await subscriptionManager.restorePurchases()
                isRestoring = false

                if restored {
                    // At least one entitlement is live — dismiss to let the
                    // surrounding UI (badge, unlocked features) reflect it.
                    dismiss()
                } else if let mgrMsg = subscriptionManager.errorMessage,
                          !mgrMsg.isEmpty {
                    // AppStore.sync threw — surface the underlying error.
                    errorMessage = mgrMsg
                    showError = true
                } else {
                    // Apple synced cleanly but found no active entitlements
                    // for this Apple ID. Required HIG feedback.
                    errorMessage = "no_purchases_to_restore".localized
                    showError = true
                }
            }
        }) {
            HStack(spacing: 8) {
                if isRestoring {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.Colors.gold))
                        .scaleEffect(0.8)
                }
                Text("restore_purchases".localized)
                    .font(AppTheme.Fonts.body(size: 15))
                    .foregroundColor(AppTheme.Colors.gold)
            }
        }
        .disabled(isRestoring)
        .padding(.top, 8)
    }
    
    // MARK: - Footer Disclaimers
    private var footerDisclaimers: some View {
        VStack(spacing: 8) {
            Text("subscription_auto_renew".localized)
                .font(AppTheme.Fonts.caption(size: 12))
                .foregroundColor(AppTheme.Colors.textTertiary)
                .multilineTextAlignment(.center)

            Text("fair_use_notice".localized)
                .font(AppTheme.Fonts.caption(size: 11))
                .italic()
                .foregroundColor(AppTheme.Colors.textTertiary)

            // Apple Guideline 3.1.2(a) requires functional Terms + Privacy
            // links on every auto-renewing subscription paywall. Link to the
            // same URLs surfaced from the Profile screen.
            HStack(spacing: 16) {
                Link("terms_of_service".localized,
                     destination: URL(string: "https://www.destinyaiastrology.com/terms-of-service/")!)
                    .font(AppTheme.Fonts.caption(size: 12))
                    .foregroundColor(AppTheme.Colors.gold)
                Text("·")
                    .foregroundColor(AppTheme.Colors.textTertiary)
                Link("privacy_policy".localized,
                     destination: URL(string: "https://www.destinyaiastrology.com/privacy-policy/")!)
                    .font(AppTheme.Fonts.caption(size: 12))
                    .foregroundColor(AppTheme.Colors.gold)
            }
            .padding(.top, 4)
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
    }
    
    // MARK: - Apple Account Note
    private var appleAccountNote: some View {
        HStack(spacing: 6) {
            Image(systemName: "apple.logo")
                .font(.system(size: 12))
            Text("apple_subscription_notice".localized)
                .font(AppTheme.Fonts.caption(size: 11))
        }
        .foregroundColor(AppTheme.Colors.textTertiary)
        .padding(.horizontal, 16)
        .padding(.top, 4)
    }
    
    // MARK: - Purchase Action
    private func purchaseSubscription(planId: String) async {
        guard let product = subscriptionManager.monthlyProduct(for: planId) else {
            errorMessage = "product_not_available_error".localized
            showError = true
            return
        }
        
        isPurchasing = true
        purchasingPlanId = planId
        
        do {
            let success = try await subscriptionManager.purchase(product)
            isPurchasing = false
            purchasingPlanId = nil

            if success {
                // Standard StoreKit pattern: Apple already showed its own
                // "Subscription Confirmed" sheet. We just dismiss the
                // paywall — purchasedProductIDs / quotaManager.currentPlanId
                // update naturally and the surrounding UI reflects the new
                // plan (badge, unlocked features) without needing a custom
                // celebration popup.
                dismiss()
            } else if let mgrMsg = subscriptionManager.errorMessage, !mgrMsg.isEmpty {
                // purchase() returned false because either:
                //  - backend verification is still pending (we have a payment
                //    but no DB row yet), or
                //  - Apple is awaiting parental / SCA approval (.pending).
                // Surface the manager's message so the user knows what's up
                // and doesn't think nothing happened.
                errorMessage = mgrMsg
                showError = true
            }
        } catch {
            isPurchasing = false
            purchasingPlanId = nil
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}

// MARK: - Plan Card with Full Feature List
struct PlanCardWithFeatures: View {
    let plan: PlanInfo
    let product: Product?
    let isPurchasing: Bool
    let isPlus: Bool
    let isTrialEligible: Bool
    let corePlan: PlanInfo?
    let userCurrentPlanId: String
    let pendingUpgradePlanId: String?
    let pendingUpgradeDate: Date?
    let onPurchase: () -> Void
    
    /// Features to display - DYNAMIC based on marketing_text from database
    /// Only shows features that have marketing_text (differentiators from free plan)
    private var displayFeatures: [PlanEntitlement] {
        guard let entitlements = plan.entitlements else { 
            print("[SubscriptionView] No entitlements for plan: \(plan.planId)")
            return [] 
        }
        
        print("[SubscriptionView] Plan \(plan.planId) has \(entitlements.count) entitlements")
        
        if isPlus {
            // For Plus: show only plus-exclusive features with marketing_text
            // Features that are either not in Core OR have different text (like "unlimited")
            let coreFeatureTexts = Dictionary(uniqueKeysWithValues: 
                (corePlan?.entitlements ?? []).compactMap { e -> (String, String)? in
                    guard let text = e.marketingText else { return nil }
                    return (e.featureId, text)
                }
            )
            
            let plusOnly = entitlements.filter { ent in
                // Must have marketing_text to display
                guard let text = ent.marketingText, !text.isEmpty else { return false }
                // Show if: not in core, OR has different marketing_text than core
                if let coreText = coreFeatureTexts[ent.featureId] {
                    return text != coreText  // Different text (e.g., "unlimited" vs "up to 3")
                }
                return true  // Feature not in Core at all
            }
            print("[SubscriptionView] Plus exclusive features: \(plusOnly.map { $0.featureId })")
            return plusOnly
        } else {
            // For Core: show ONLY features with marketing_text (paid differentiators)
            let filtered = entitlements.filter { ent in
                ent.marketingText != nil && !ent.marketingText!.isEmpty
            }
            print("[SubscriptionView] Core features: \(filtered.map { $0.featureId })")
            return filtered
        }
    }
    
    /// Check if this plan is the user's current plan
    private var isCurrentPlan: Bool {
        plan.planId == userCurrentPlanId
    }
    
    /// Check if user has a pending upgrade TO this plan
    private var isPendingUpgrade: Bool {
        pendingUpgradePlanId == plan.planId
    }
    
    /// Format pending upgrade date
    private var pendingUpgradeDateText: String? {
        guard let date = pendingUpgradeDate else { return nil }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header: Plan Name + Price + Current Plan Badge
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(plan.displayName)
                            .font(AppTheme.Fonts.title(size: 24))
                            .foregroundColor(AppTheme.Colors.gold)
                        
                        // Current Plan badge
                        if isCurrentPlan {
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(AppTheme.Fonts.caption(size: 10))
                                Text("current_plan".localized)
                                    .font(AppTheme.Fonts.caption(size: 10).weight(.heavy))
                            }
                            .foregroundColor(AppTheme.Colors.mainBackground)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(AppTheme.Colors.gold)
                            )
                        }
                        
                        // Pending upgrade badge (when user scheduled upgrade to this plan)
                        if isPendingUpgrade && !isCurrentPlan {
                            HStack(spacing: 4) {
                                Image(systemName: "clock.fill")
                                    .font(AppTheme.Fonts.caption(size: 10))
                                Text("scheduled_plan".localized)
                                    .font(AppTheme.Fonts.caption(size: 10).weight(.heavy))
                            }
                            .foregroundColor(AppTheme.Colors.mainBackground)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(Color.orange)
                            )
                        }
                    }
                    
                    if let desc = plan.description {
                        Text(desc)
                            .font(AppTheme.Fonts.body(size: 14))
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                }
                
                Spacer()
                
                // Price
                VStack(alignment: .trailing, spacing: 2) {
                    if let product = product {
                        Text(product.displayPrice)
                            .font(AppTheme.Fonts.title(size: 20))
                            .foregroundColor(AppTheme.Colors.textPrimary)
                    } else {
                        Text(localizedFallbackPrice(plan.priceMonthly ?? 0))
                            .font(AppTheme.Fonts.title(size: 20))
                            .foregroundColor(AppTheme.Colors.textPrimary)
                    }
                    Text("per_month".localized)
                        .font(AppTheme.Fonts.body(size: 14))
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
            }
            
            // For Plus: "Everything in Core, plus:" header
            if isPlus {
                Text("everything_in_core_plus".localized)
                    .font(AppTheme.Fonts.caption(size: 12).weight(.medium))
                    .foregroundColor(AppTheme.Colors.gold)
                    .padding(.top, 4)
            }
            
            // Feature List with checkmarks and descriptions
            VStack(alignment: .leading, spacing: 14) {
                ForEach(displayFeatures) { feature in
                    FeatureItemRow(feature: feature)
                }
            }
            .padding(.top, 4)
            
            // CTA Button
            Button(action: onPurchase) {
                Group {
                    if isTrialEligible && !isCurrentPlan && !isPendingUpgrade && !isPurchasing {
                        VStack(spacing: 3) {
                            Text("Start 7-Day Free Trial")
                                .font(AppTheme.Fonts.title(size: 16))
                            Text("then \(priceDisplay) · cancel anytime")
                                .font(AppTheme.Fonts.body(size: 11))
                                .opacity(0.85)
                        }
                    } else {
                        HStack {
                            if isPurchasing {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.Colors.mainBackground))
                            }
                            if isCurrentPlan {
                                Image(systemName: "checkmark")
                                    .font(AppTheme.Fonts.title(size: 14))
                            }
                            Text(isPurchasing ? "processing".localized : buttonText)
                                .font(AppTheme.Fonts.title(size: 16))
                        }
                    }
                }
                .foregroundColor(isCurrentPlan ? AppTheme.Colors.textSecondary : AppTheme.Colors.mainBackground)
                .frame(maxWidth: .infinity)
                .frame(height: (isTrialEligible && !isCurrentPlan && !isPendingUpgrade && !isPurchasing) ? 58 : 50)
                .background(isCurrentPlan ? AppTheme.Colors.cardBackground : AppTheme.Colors.gold)
                .cornerRadius(25)
                .overlay(
                    RoundedRectangle(cornerRadius: 25)
                        .stroke(isCurrentPlan ? AppTheme.Colors.gold.opacity(0.5) : Color.clear, lineWidth: 1)
                )
            }
            .disabled(isPurchasing || isCurrentPlan || isPendingUpgrade)
            .padding(.top, 8)
            
            // Show pending upgrade effective date below button
            if isPendingUpgrade, let dateText = pendingUpgradeDateText {
                Text(String(format: "subscription_starts_format".localized, dateText))
                    .font(AppTheme.Fonts.caption(size: 12))
                    .foregroundColor(Color.orange)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppTheme.Colors.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isCurrentPlan ? AppTheme.Colors.gold : AppTheme.Colors.gold.opacity(0.3), lineWidth: isCurrentPlan ? 2 : 1)
        )
    }
    
    private var priceDisplay: String {
        if let product = product {
            return "\(product.displayPrice) / month"
        }
        return "\(localizedFallbackPrice(plan.priceMonthly ?? 0)) / month"
    }

    private func localizedFallbackPrice(_ usdAmount: Double) -> String {
        let isIndia = Locale.current.region?.identifier == "IN"
        if isIndia {
            // Core ($4.99) → ₹249, Plus ($7.99) → ₹599
            let inrAmount = usdAmount <= 5.0 ? 249 : 599
            return "₹\(inrAmount)"
        }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "en_US")
        return formatter.string(from: NSNumber(value: usdAmount)) ?? "$\(String(format: "%.2f", usdAmount))"
    }
    
    /// Dynamic button text based on user's current plan
    private var buttonText: String {
        // Pending upgrade takes priority
        if isPendingUpgrade {
            return "upgrade_scheduled_label".localized
        }
        if isCurrentPlan {
            return "current_plan_label".localized
        }
        if isPlus {
            // Plus card: "Choose Plus" for free users, "Upgrade to Plus" for Core users
            return userCurrentPlanId == "core" ? "upgrade_to_plus_label".localized : "choose_plus_label".localized
        } else {
            // Core card: "Choose Core" for all users
            return "choose_core_label".localized
        }
    }
}

// MARK: - Feature Item Row (Checkmark + Title + Description)
struct FeatureItemRow: View {
    let feature: PlanEntitlement
    
    /// Check if feature is "coming soon" (based on display_name_override from backend)
    private var isComingSoon: Bool {
        feature.displayName.lowercased().contains("coming soon")
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Gold checkmark
            Image(systemName: "checkmark")
                .font(AppTheme.Fonts.title(size: 14))
                .foregroundColor(AppTheme.Colors.gold)
                .frame(width: 16, height: 16)
                .padding(.top, 2)
            
            VStack(alignment: .leading, spacing: 2) {
                // Feature title (bold) with optional "(coming soon)"
                HStack(spacing: 4) {
                    Text(feature.displayName)
                        .font(AppTheme.Fonts.title(size: 15))
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    
                    if isComingSoon {
                        Text("coming_soon".localized)
                            .font(AppTheme.Fonts.caption(size: 10))
                            .foregroundColor(AppTheme.Colors.textTertiary)
                    }
                }
                
                // Description below (from marketing_text)
                if let description = feature.marketingText, !description.isEmpty {
                    Text(description)
                        .font(AppTheme.Fonts.body(size: 13))
                        .foregroundColor(AppTheme.Colors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
}

// MARK: - Preview
#Preview {
    SubscriptionView()
}
