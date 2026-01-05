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
    
    // MARK: - Product IDs (Configure in App Store Connect)
    
    /// Core plan
    static let coreMonthlyProductID = "com.daa.core.monthly"
    static let coreYearlyProductID = "com.daa.core.yearly"
    
    /// Advanced plan
    static let advancedMonthlyProductID = "com.daa.advanced.monthly"
    static let advancedYearlyProductID = "com.daa.advanced.yearly"
    
    /// Premium plan
    static let premiumMonthlyProductID = "com.daa.premium.monthly"
    static let premiumYearlyProductID = "com.daa.premium.yearly"
    
    private let productIDs: Set<String> = [
        coreMonthlyProductID, coreYearlyProductID,
        advancedMonthlyProductID, advancedYearlyProductID,
        premiumMonthlyProductID, premiumYearlyProductID
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
                let transaction = try checkVerified(verification)
                await verifyWithBackend(transaction: transaction)
                await transaction.finish()
                await updatePurchasedProducts()
                
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
            if productId.contains(".advanced.") { return "advanced" }
            if productId.contains(".premium.") { return "premium" }
        }
        return nil
    }
    
    // MARK: - Transaction Listener
    
    private func listenForTransactions() -> Task<Void, Never> {
        Task.detached { [weak self] in
            for await result in Transaction.updates {
                do {
                    let transaction = try Self.checkVerifiedStatic(result)
                    await self?.verifyWithBackend(transaction: transaction)
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
    }
    
    // MARK: - Backend Verification
    
    private func verifyWithBackend(transaction: Transaction) async {
        guard let email = getCurrentUserEmail() else {
            print("No user email for backend verification")
            return
        }
        
        do {
            guard let jwsRepresentation = transaction.jwsRepresentation else {
                print("No JWS representation available")
                return
            }
            
            let url = URL(string: APIConfig.baseURL + "/subscription/verify")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("Bearer \(APIConfig.apiKey)", forHTTPHeaderField: "Authorization")
            
            let body: [String: Any] = [
                "signed_transaction": jwsRepresentation,
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
    var jwsRepresentation: String? {
        return String(self.originalID)
    }
    
    var subscriptionEnvironment: SubscriptionEnvironmentType {
        #if DEBUG
        return .sandbox
        #else
        return .production
        #endif
    }
}

enum SubscriptionEnvironmentType: String {
    case sandbox = "Sandbox"
    case production = "Production"
}
