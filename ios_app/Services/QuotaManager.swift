import Foundation
import Combine
import SwiftData

// MARK: - Errors

/// Thrown when an archived guest tries to use the app again with same birth data
/// The user should be prompted to sign in to their registered account instead
struct ArchivedGuestError: Error, LocalizedError {
    let upgradedToEmail: String?
    let provider: String?  // "apple" or "google" - the provider used when upgrading
    
    var errorDescription: String? {
        if let email = upgradedToEmail {
            return "This account was upgraded to \(email). Please sign in."
        }
        return "You already have a registered account. Please sign in."
    }
}

/// Thrown when a guest's birth data matches an existing registered user
/// The user should be prompted to sign in with their registered account instead
struct RegisteredUserConflictError: Error, LocalizedError {
    let maskedEmail: String?
    let provider: String?  // 'apple', 'google', or 'email'
    
    var errorDescription: String? {
        // Show friendly message based on provider - don't confuse users with relay emails
        switch provider {
        case "apple":
            return "An account already exists with your birth data. Please sign in with Apple to continue."
        case "google":
            if let email = maskedEmail {
                return "An account already exists with your birth data. Please sign in with Google (\(email))."
            }
            return "An account already exists with your birth data. Please sign in with Google."
        default:
            if let email = maskedEmail {
                return "An account already exists with your birth data. Please sign in with \(email)."
            }
            return "An account already exists with your birth data. Please sign in."
        }
    }
}

/// Thrown when trying to save birth data that already belongs to another registered user
/// Used during guest upgrade when their birth data matches another registered user
struct BirthDataTakenError: Error, LocalizedError {
    let existingEmail: String?
    let provider: String?  // 'apple', 'google', or 'email'
    
    var errorDescription: String? {
        // Show friendly message based on provider - don't confuse users with relay emails
        switch provider {
        case "apple":
            return "Your birth data is already linked to your Apple account. Please sign in with Apple to continue."
        case "google":
            if let email = existingEmail {
                return "Your birth data is already linked to \(email). Please sign in with Google."
            }
            return "Your birth data is already linked to your Google account. Please sign in with Google."
        default:
            if let email = existingEmail {
                return "Your birth data is already linked to \(email). Please sign in with that account to continue."
            }
            return "Your birth data is already linked to a registered account. Please sign in to continue."
        }
    }
}

// MARK: - Feature & Plan Models

/// Feature IDs matching backend
enum FeatureID: String, Codable, Sendable {
    case aiQuestions = "ai_questions"  // Shared pool for chat + follow-ups
    case compatibility = "compatibility"
    case history = "history"
    case profiles = "multiple_profile_match"
    case switchProfile = "switch_profile"
    case maintainProfile = "maintain_profile"  // Save/create profiles (Core: 5, Plus: Unlimited)
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
    @Published private(set) var subscriptionStatus: String?
    @Published private(set) var subscriptionExpiresAtString: String?
    
    /// Current plan ID (convenience accessor for dynamic button text)
    var currentPlanId: String? {
        currentPlan?.planId ?? UserDefaults.standard.string(forKey: "currentPlanId")
    }
    
    private let dataManager: DataManager
    
    init(dataManager: DataManager? = nil) {
        self.dataManager = dataManager ?? DataManager.shared
    }
    
    // MARK: - Feature Access
    
    /// Check if user can access a feature N times
    /// - Parameters:
    ///   - feature: The feature to check
    ///   - email: User email
    ///   - count: Number of usages to check (for multi-partner, pass partners.count)
    func canAccessFeature(_ feature: FeatureID, email: String, count: Int = 1) async throws -> FeatureAccessResponse {
        var components = URLComponents(string: APIConfig.baseURL + "/subscription/can-access")!
        components.queryItems = [
            URLQueryItem(name: "email", value: email),
            URLQueryItem(name: "feature", value: feature.rawValue),
            URLQueryItem(name: "count", value: String(count))
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
    /// Throws ArchivedGuestError if guest account was already upgraded to registered
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
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        // Handle 409 Conflict - either archived guest or birth data matches registered user
        if httpResponse.statusCode == 409 {
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let detail = json["detail"] as? [String: Any],
               let error = detail["error"] as? String {
                
                // Case 1: Archived guest - account was upgraded to registered
                if error == "archived_guest" {
                    let upgradedTo = detail["upgraded_to_email"] as? String
                    let provider = detail["provider"] as? String
                    print("[QuotaManager] 🔔 Archived guest detected! Upgraded to: \(upgradedTo ?? "unknown") (provider: \(provider ?? "unknown"))")
                    throw ArchivedGuestError(upgradedToEmail: upgradedTo, provider: provider)
                }
                
                // Case 2: Guest birth data matches existing registered user
                if error == "registered_user_conflict" {
                    let maskedEmail = detail["masked_email"] as? String
                    let provider = detail["provider"] as? String
                    print("[QuotaManager] 🔔 Guest conflict! Birth data belongs to: \(maskedEmail ?? "unknown") (provider: \(provider ?? "unknown"))")
                    throw RegisteredUserConflictError(maskedEmail: maskedEmail, provider: provider)
                }
            }
            // Unknown 409 error - throw generic
            throw URLError(.badServerResponse)
        }
        
        guard httpResponse.statusCode == 200 else {
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
        subscriptionStatus = status.subscriptionStatus
        subscriptionExpiresAtString = status.subscriptionExpiresAt
        
        UserDefaults.standard.set(status.isPremium, forKey: "isPremium")
        UserDefaults.standard.set(status.planId, forKey: "currentPlanId")
        UserDefaults.standard.set(status.subscriptionStatus, forKey: "subscriptionStatus")
        UserDefaults.standard.set(status.subscriptionExpiresAt, forKey: "subscriptionExpiresAt")
        
        if let profile = dataManager.getCurrentUserProfile() {
            profile.totalQuestionsAsked = status.totalQuestionsAsked
            try? dataManager.context.save()
        }
    }
    
    // MARK: - Convenience
    
    /// Display name for current plan (shows "Free Plan" for free tiers)
    var planDisplayName: String {
        if let plan = currentPlan {
            if plan.isFree {
                return "Free Plan"
            }
            return plan.displayName
        }
        return "Free Plan"
    }
    
    /// Check if user can upgrade
    var canUpgrade: Bool {
        currentPlan?.isFree ?? true
    }
    
    /// Simple sync check for UI - uses cached features list
    /// For authoritative check, use `canAsk(feature:email:)` async method
    var canAsk: Bool {
        availableFeatures.contains(FeatureID.aiQuestions.rawValue)
    }
    
    /// Check if current user is a guest (based on cached plan)
    var isGuest: Bool {
        currentPlan?.planId == "free_guest"
    }
    
    /// Check if user is on Plus plan (for Plus-exclusive features like multi-partner matching)
    var isPlus: Bool {
        currentPlan?.planId == "plus"
    }
    
    /// Check if user has access to a specific feature based on plan entitlements (cached)
    func hasFeature(_ feature: FeatureID) -> Bool {
        availableFeatures.contains(feature.rawValue)
    }
    
    // MARK: - Subscription Display Helpers
    
    /// Parse subscription expiry date from ISO8601 string
    /// Parse subscription expiry date from ISO8601 string
    var subscriptionExpiresAt: Date? {
        guard let expiryString = subscriptionExpiresAtString else { return nil }
        
        // 1. Try ISO8601DateFormatter (expects 'Z' or timezone)
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = isoFormatter.date(from: expiryString) {
            return date
        }
        
        isoFormatter.formatOptions = [.withInternetDateTime]
        if let date = isoFormatter.date(from: expiryString) {
            return date
        }
        
        // 2. Fallback to DateFormatter for naive strings (Python's isoformat() without tz)
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        
        // Try with fractional seconds
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS"
        if let date = formatter.date(from: expiryString) {
            return date
        }
        
        // Try without fractional seconds
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        return formatter.date(from: expiryString)
    }
    
    /// User-friendly expiry text: "Expires Feb 28, 2026" or "Renews Feb 28, 2026"
    var subscriptionExpiryDisplayText: String? {
        guard let expiryDate = subscriptionExpiresAt else { return nil }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        
        // For active subscriptions, say "Renews" since auto-renewal is on by default
        // For cancelled/expired, say "Expires"
        let prefix = (subscriptionStatus == "active") ? "Renews" : "Expires"
        return "\(prefix) \(formatter.string(from: expiryDate))"
    }
    
    /// Subscription status display: "Active", "Expired", "Grace Period"
    var subscriptionStatusDisplayText: String {
        switch subscriptionStatus {
        case "active": return "Active"
        case "expired": return "Expired"
        case "grace_period": return "Grace Period"
        case "cancelled": return "Cancelled"
        default: return ""
        }
    }
    
    // MARK: - Profile Management
    
    /// Check if user can add a new profile based on maintain_profile entitlement
    /// Returns: (canAdd, limit, showUpgrade)
    /// - canAdd: true if user can add another profile
    /// - limit: the maximum allowed (-1 = unlimited)
    /// - showUpgrade: true if user should see upgrade prompt
    func canAddProfile(email: String, currentCount: Int) async -> (canAdd: Bool, limit: Int, showUpgrade: Bool) {
        do {
            let response = try await canAccessFeature(.maintainProfile, email: email)
            if !response.canAccess {
                // User doesn't have maintain_profile feature - show upgrade
                return (false, 0, true)
            }
            
            // Check limits from response
            if let limits = response.limits, let overall = limits["overall"] {
                let limit = overall.limit
                if limit == -1 {
                    // Unlimited
                    return (true, -1, false)
                }
                // Check if current count is below limit
                let canAdd = currentCount < limit
                return (canAdd, limit, !canAdd)
            }
            
            // Default: allow if feature is accessible but no limit info
            return (true, -1, false)
        } catch {
            print("❌ canAddProfile error: \(error)")
            // Fail open - allow on network error
            return (true, -1, false)
        }
    }
}
