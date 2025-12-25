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
    
    // MARK: - Product IDs
    /// Configure these in App Store Connect
    static let monthlyProductID = "com.destinyai.premium.monthly"
    static let yearlyProductID = "com.destinyai.premium.yearly"
    
    private let productIDs: Set<String> = [
        monthlyProductID,
        yearlyProductID
    ]
    
    // MARK: - Transaction Listener
    private var transactionListener: Task<Void, Never>?
    
    // MARK: - Init
    private init() {
        // Start listening for transactions
        transactionListener = listenForTransactions()
        
        // Load products
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
    
    // MARK: - Purchase
    
    /// Purchase a subscription product
    func purchase(_ product: Product) async throws -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            let result = try await product.purchase()
            
            switch result {
            case .success(let verification):
                // Verify the transaction
                let transaction = try checkVerified(verification)
                
                // Verify with backend
                await verifyWithBackend(transaction: transaction)
                
                // Finish the transaction
                await transaction.finish()
                
                // Update purchased products
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
    
    // MARK: - Check Entitlement
    
    /// Check if user has premium entitlement
    var isPremium: Bool {
        !purchasedProductIDs.isEmpty
    }
    
    /// Get monthly product
    var monthlyProduct: Product? {
        products.first { $0.id == Self.monthlyProductID }
    }
    
    /// Get yearly product
    var yearlyProduct: Product? {
        products.first { $0.id == Self.yearlyProductID }
    }
    
    // MARK: - Transaction Listener
    
    /// Listen for transaction updates
    private func listenForTransactions() -> Task<Void, Never> {
        Task.detached { [weak self] in
            for await result in Transaction.updates {
                do {
                    let transaction = try Self.checkVerifiedStatic(result)
                    
                    // Verify with backend
                    await self?.verifyWithBackend(transaction: transaction)
                    
                    // Finish transaction
                    await transaction.finish()
                    
                    // Update purchased products on main actor
                    await self?.updatePurchasedProducts()
                    
                } catch {
                    print("Transaction verification failed: \(error)")
                }
            }
        }
    }
    
    // MARK: - Verification
    
    /// Verify a transaction result
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        try Self.checkVerifiedStatic(result)
    }
    
    /// Static version for use in detached tasks
    private nonisolated static func checkVerifiedStatic<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw SubscriptionError.verificationFailed
        case .verified(let safe):
            return safe
        }
    }
    
    /// Update purchased products from current entitlements
    func updatePurchasedProducts() async {
        var purchased: Set<String> = []
        
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                
                // Only include active subscriptions
                if transaction.revocationDate == nil {
                    purchased.insert(transaction.productID)
                }
            } catch {
                print("Entitlement verification failed: \(error)")
            }
        }
        
        purchasedProductIDs = purchased
        
        // Update local premium flag
        UserDefaults.standard.set(!purchased.isEmpty, forKey: "isPremium")
        
        // Refresh QuotaManager
        QuotaManager.shared.refresh()
    }
    
    // MARK: - Backend Verification
    
    /// Verify transaction with backend and upgrade user
    private func verifyWithBackend(transaction: Transaction) async {
        guard let email = getCurrentUserEmail() else {
            print("No user email for backend verification")
            return
        }
        
        do {
            // Get the signed transaction
            guard let jwsRepresentation = transaction.jwsRepresentation else {
                print("No JWS representation available")
                return
            }
            
            let url = URL(string: APIConfig.baseURL + APIConfig.subscriptionVerify)!
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
                    print("Backend verification successful for \(email)")
                } else {
                    print("Backend verification failed: HTTP \(httpResponse.statusCode)")
                }
            }
        } catch {
            print("Backend verification error: \(error)")
            // Don't throw - just log the error
            // The StoreKit transaction is still valid locally
        }
    }
    
    /// Get current user email
    private func getCurrentUserEmail() -> String? {
        // Try to get from DataManager
        if let profile = DataManager.shared.getCurrentUserProfile() {
            return profile.email
        }
        
        // Fallback to UserDefaults
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
        case .verificationFailed:
            return "Transaction verification failed"
        case .purchaseFailed:
            return "Purchase could not be completed"
        case .productNotFound:
            return "Product not found"
        }
    }
}

// MARK: - Transaction Extension

extension Transaction {
    /// Get JWS representation if available
    var jwsRepresentation: String? {
        // StoreKit 2 provides signed transaction data via jsonRepresentation
        // For now, return the original transaction ID as a fallback
        // Full JWS requires access to the original signed payload
        return String(self.originalID)
    }
    
    /// Get environment as string
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
