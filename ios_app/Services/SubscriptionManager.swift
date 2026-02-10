import Foundation
import StoreKit
import Combine

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
    }
    
    // MARK: - Product Loading
    
    /// Load available products from App Store
    func loadProducts() async {
        isLoading = true
        errorMessage = nil
        
        do {
            products = try await Product.products(for: productIDs)
            products.sort { $0.price < $1.price }
            isLoading = false
        } catch {
            errorMessage = "Failed to load products: \(error.localizedDescription)"
            isLoading = false
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
    
    /// Purchase a subscription product
    func purchase(_ product: Product) async throws -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            let result = try await product.purchase()
            
            switch result {
            case .success(let verification):
                // Extract JWS from VerificationResult BEFORE extracting Transaction
                let jws = verification.jwsRepresentation
                let transaction = try checkVerified(verification)
                await verifyWithBackend(jws: jws, transaction: transaction)
                await transaction.finish()
                await updatePurchasedProducts()
                
                // Delayed re-check for pending upgrades (StoreKit status may not update immediately)
                Task {
                    try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 second delay
                    await self.checkPendingUpgrade()
                    print("🔄 [purchase] Delayed pending upgrade check completed")
                }
                
                isLoading = false
                return true
                
            case .userCancelled:
                isLoading = false
                return false
                
            case .pending:
                isLoading = false
                errorMessage = "Purchase is pending approval"
                return false
                
            @unknown default:
                isLoading = false
                return false
            }
        } catch {
            isLoading = false
            errorMessage = "Purchase failed: \(error.localizedDescription)"
            throw error
        }
    }
    
    // MARK: - Restore Purchases
    
    /// Restore previous purchases
    func restorePurchases() async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await AppStore.sync()
            await updatePurchasedProducts()
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = "Restore failed: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Entitlement Check
    
    /// Check if user has any active subscription
    var hasActiveSubscription: Bool {
        !purchasedProductIDs.isEmpty
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
                    await self?.verifyWithBackend(jws: jws, transaction: transaction)
                    await transaction.finish()
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
    
    func updatePurchasedProducts() async {
        var purchased: Set<String> = []
        
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                if transaction.revocationDate == nil {
                    purchased.insert(transaction.productID)
                }
            } catch {
                print("Entitlement verification failed: \(error)")
            }
        }
        
        purchasedProductIDs = purchased
        UserDefaults.standard.set(!purchased.isEmpty, forKey: "isPremium")
        
        // Check for pending upgrades
        await checkPendingUpgrade()
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
    
    // MARK: - Backend Verification
    
    private func verifyWithBackend(jws: String, transaction: Transaction) async {
        guard let email = getCurrentUserEmail() else {
            print("No user email for backend verification")
            return
        }
        
        do {
            // JWS is extracted from VerificationResult.jwsRepresentation
            // It contains the actual JWS signed payload for server verification
            
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
            
            let (_, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 200 {
                    print("✅ Backend verification successful for \(email)")
                    // Sync quota status after successful verification
                    try? await QuotaManager.shared.syncStatus(email: email)
                } else {
                    print("❌ Backend verification failed: HTTP \(httpResponse.statusCode)")
                }
            }
        } catch {
            print("Backend verification error: \(error)")
        }
    }
    
    private func getCurrentUserEmail() -> String? {
        if let profile = DataManager.shared.getCurrentUserProfile() {
            return profile.email
        }
        return UserDefaults.standard.string(forKey: "userEmail")
    }
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
