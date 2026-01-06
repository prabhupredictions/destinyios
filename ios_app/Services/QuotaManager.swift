import Foundation
import Combine
import SwiftData

// MARK: - Feature & Plan Models

/// Feature IDs matching backend
enum FeatureID: String, Codable, Sendable {
    case aiQuestions = "ai_questions"  // Shared pool for chat + follow-ups
    case compatibility = "compatibility"
    case history = "history"
    case profiles = "multiple_profiles"
    case alerts = "alerts"
    case earlyAccess = "early_access"
}

/// Feature entitlement info from server
struct PlanEntitlement: Codable, Sendable, Identifiable {
    let featureId: String
    let displayName: String
    let description: String?  // Feature description from backend
    let marketingText: String?  // Custom rich marketing copy for this plan
    let dailyLimit: Int   // -1 = unlimited
    let overallLimit: Int  // -1 = unlimited
    
    var id: String { featureId }
    var isUnlimited: Bool { dailyLimit == -1 && overallLimit == -1 }
    
    /// Display text for this entitlement (user-facing)
    /// Prefer marketingText if available, otherwise generate from displayName
    var displayText: String {
        // Use custom marketing text if available
        if let text = marketingText, !text.isEmpty {
            return text
        }
        // For unlimited features (both daily and overall = -1)
        if overallLimit == -1 {
            return "Unlimited \(displayName.lowercased())"
        }
        // For limited features, just show the feature name (don't expose internal limits)
        return displayName
    }
    
    enum CodingKeys: String, CodingKey {
        case featureId = "feature_id"
        case displayName = "display_name"
        case description
        case marketingText = "marketing_text"
        case dailyLimit = "daily_limit"
        case overallLimit = "overall_limit"
    }
}

/// Subscription plan info from server
struct PlanInfo: Codable, Sendable, Identifiable {
    let planId: String
    let displayName: String
    let description: String?
    let isFree: Bool
    let priceMonthly: Double?
    let priceYearly: Double?
    let currency: String?
    let appleProductIdMonthly: String?
    let appleProductIdYearly: String?
    let entitlements: [PlanEntitlement]?
    
    var id: String { planId }
    var isPaid: Bool { !isFree }
    
    /// Helper to get display features for paywall UI
    var displayFeatures: [String] {
        guard let ents = entitlements else { return [] }
        return ents.map { $0.displayText }
    }
    
    enum CodingKeys: String, CodingKey {
        case planId = "plan_id"
        case displayName = "display_name"
        case description
        case isFree = "is_free"
        case priceMonthly = "price_monthly"
        case priceYearly = "price_yearly"
        case currency
        case appleProductIdMonthly = "apple_product_id_monthly"
        case appleProductIdYearly = "apple_product_id_yearly"
        case entitlements
    }
}

/// Limit info for a feature
struct LimitInfo: Codable, Sendable {
    let used: Int
    let limit: Int
    let remaining: Int
    
    var isUnlimited: Bool { limit == -1 }
    var hasRemaining: Bool { isUnlimited || remaining > 0 }
    
    var displayText: String {
        if isUnlimited { return "Unlimited" }
        return "\(remaining) remaining"
    }
}

/// Feature access response from /can-access
struct FeatureAccessResponse: Codable, Sendable {
    let canAccess: Bool
    let feature: String?
    let planId: String?
    let reason: String?
    let requiresQuota: Bool?
    let limits: [String: LimitInfo]?
    let resetAt: String?
    let upgradeCta: UpgradeCTA?
    
    enum CodingKeys: String, CodingKey {
        case canAccess = "can_access"
        case feature
        case planId = "plan_id"
        case reason
        case requiresQuota = "requires_quota"
        case limits
        case resetAt = "reset_at"
        case upgradeCta = "upgrade_cta"
    }
    
    /// User-friendly denial reason
    var denialMessage: String {
        switch reason {
        case "daily_limit_reached": return "Daily limit reached. Resets at midnight."
        case "overall_limit_reached": return "You've used all your questions."
        case "feature_not_available": return upgradeCta?.message ?? "Upgrade to access this feature."
        default: return "Unable to access this feature."
        }
    }
}

struct UpgradeCTA: Codable, Sendable {
    let message: String
    let suggestedPlan: String
    
    enum CodingKeys: String, CodingKey {
        case message
        case suggestedPlan = "suggested_plan"
    }
}

/// Usage response from /use
struct UseFeatureResponse: Codable, Sendable {
    let success: Bool
    let feature: String?
    let usage: UsageInfo?
    let error: String?
}

struct UsageInfo: Codable, Sendable {
    let daily: LimitInfo
    let overall: LimitInfo
}

/// Per-feature usage statistics from backend
struct FeatureUsageInfo: Codable, Sendable {
    let daily: Int
    let overall: Int
    let lastUsed: String?
    
    enum CodingKeys: String, CodingKey {
        case daily
        case overall
        case lastUsed = "last_used"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        daily = try container.decodeIfPresent(Int.self, forKey: .daily) ?? 0
        overall = try container.decodeIfPresent(Int.self, forKey: .overall) ?? 0
        lastUsed = try container.decodeIfPresent(String.self, forKey: .lastUsed)
    }
}

/// Status response from /status
struct SubscriptionStatus: Codable, Sendable {
    let userEmail: String
    let planId: String?
    let plan: PlanInfo?
    let isGeneratedEmail: Bool
    let featureUsage: [String: FeatureUsageInfo]  // Per-feature usage (chat, compatibility, etc.)
    let isPremium: Bool
    let features: [String]
    let subscriptionStatus: String?
    let subscriptionExpiresAt: String?
    
    enum CodingKeys: String, CodingKey {
        case userEmail = "user_email"
        case planId = "plan_id"
        case plan
        case isGeneratedEmail = "is_generated_email"
        case featureUsage = "feature_usage"
        case isPremium = "is_premium"
        case features
        case subscriptionStatus = "subscription_status"
        case subscriptionExpiresAt = "subscription_expires_at"
    }
    
    /// Helper to get total questions across all features (for backward compat)
    var totalQuestionsAsked: Int {
        featureUsage.values.reduce(0) { $0 + $1.overall }
    }
}

// MARK: - QuotaManager

/// Manages user quota and subscription status
@MainActor
class QuotaManager: ObservableObject {
    static let shared = QuotaManager()
    
    // MARK: - Published State
    @Published private(set) var currentPlan: PlanInfo?
    @Published private(set) var isPremium: Bool = false
    @Published private(set) var availableFeatures: [String] = []
    @Published private(set) var totalQuestionsAsked: Int = 0
    @Published private(set) var availablePlans: [PlanInfo] = []
    
    /// Current plan ID (convenience accessor for dynamic button text)
    var currentPlanId: String? {
        currentPlan?.planId ?? UserDefaults.standard.string(forKey: "currentPlanId")
    }
    
    private let dataManager: DataManager
    
    init(dataManager: DataManager = DataManager.shared) {
        self.dataManager = dataManager
    }
    
    // MARK: - Feature Access
    
    /// Check if user can access a feature
    func canAccessFeature(_ feature: FeatureID, email: String) async throws -> FeatureAccessResponse {
        var components = URLComponents(string: APIConfig.baseURL + "/subscription/can-access")!
        components.queryItems = [
            URLQueryItem(name: "email", value: email),
            URLQueryItem(name: "feature", value: feature.rawValue)
        ]
        
        var request = URLRequest(url: components.url!)
        request.httpMethod = "GET"
        request.setValue("Bearer \(APIConfig.apiKey)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        return try JSONDecoder().decode(FeatureAccessResponse.self, from: data)
    }
    
    /// Simple bool check for feature access
    func canAsk(feature: FeatureID = .aiQuestions, email: String) async -> Bool {
        do {
            let response = try await canAccessFeature(feature, email: email)
            return response.canAccess
        } catch {
            print("❌ canAsk error: \(error)")
            return false
        }
    }
    
    // MARK: - Record Usage
    
    /// Record feature usage after successful action
    func recordFeatureUsage(_ feature: FeatureID, email: String) async throws -> UseFeatureResponse {
        let url = URL(string: APIConfig.baseURL + "/subscription/use")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(APIConfig.apiKey)", forHTTPHeaderField: "Authorization")
        
        let body: [String: String] = [
            "email": email,
            "feature_id": feature.rawValue
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        let result = try JSONDecoder().decode(UseFeatureResponse.self, from: data)
        
        if result.success {
            totalQuestionsAsked += 1
            if let profile = dataManager.getCurrentUserProfile() {
                profile.totalQuestionsAsked += 1
                try? dataManager.context.save()
            }
        }
        
        return result
    }
    
    // MARK: - Plans
    
    /// Fetch available subscription plans for paywall
    func fetchPlans() async throws -> [PlanInfo] {
        let url = URL(string: APIConfig.baseURL + "/subscription/plans")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(APIConfig.apiKey)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        let plans = try JSONDecoder().decode([PlanInfo].self, from: data)
        availablePlans = plans
        return plans
    }
    
    /// Get paid plans only (for paywall)
    var paidPlans: [PlanInfo] {
        availablePlans.filter { $0.isPaid }
    }
    
    // MARK: - Registration & Sync
    
    /// Register user with backend (call on birth data save or login)
    func registerUser(email: String, isGeneratedEmail: Bool) async throws {
        let url = URL(string: APIConfig.baseURL + "/subscription/register")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(APIConfig.apiKey)", forHTTPHeaderField: "Authorization")
        
        let body: [String: Any] = [
            "email": email,
            "is_generated_email": isGeneratedEmail
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        let status = try JSONDecoder().decode(SubscriptionStatus.self, from: data)
        updateFromStatus(status)
    }
    
    /// Sync status from server
    func syncStatus(email: String) async throws {
        var components = URLComponents(string: APIConfig.baseURL + "/subscription/status")!
        components.queryItems = [URLQueryItem(name: "email", value: email)]
        
        var request = URLRequest(url: components.url!)
        request.httpMethod = "GET"
        request.setValue("Bearer \(APIConfig.apiKey)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        let status = try JSONDecoder().decode(SubscriptionStatus.self, from: data)
        updateFromStatus(status)
    }
    
    /// Update local state from server status
    private func updateFromStatus(_ status: SubscriptionStatus) {
        currentPlan = status.plan
        isPremium = status.isPremium
        availableFeatures = status.features
        totalQuestionsAsked = status.totalQuestionsAsked
        
        UserDefaults.standard.set(status.isPremium, forKey: "isPremium")
        UserDefaults.standard.set(status.planId, forKey: "currentPlanId")
        
        if let profile = dataManager.getCurrentUserProfile() {
            profile.totalQuestionsAsked = status.totalQuestionsAsked
            try? dataManager.context.save()
        }
    }
    
    // MARK: - Convenience
    
    /// Display name for current plan
    var planDisplayName: String {
        currentPlan?.displayName ?? "Free"
    }
    
    /// Check if user can upgrade
    var canUpgrade: Bool {
        currentPlan?.isFree ?? true
    }
    
    /// Simple sync check for UI - uses cached features list
    /// For authoritative check, use `canAsk(feature:email:)` async method
    var canAsk: Bool {
        isPremium || availableFeatures.contains(FeatureID.aiQuestions.rawValue)
    }
    
    /// Check if current user is a guest (based on cached plan)
    var isGuest: Bool {
        currentPlan?.planId == "free_guest"
    }
}
