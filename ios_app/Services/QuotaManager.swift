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
            return String(format: "account_upgraded_to_email".localized, email)
        }
        return "already_have_account".localized
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
            return "conflict_apple".localized
        case "google":
            if let email = maskedEmail {
                return String(format: "conflict_google_email".localized, email)
            }
            return "conflict_google".localized
        default:
            if let email = maskedEmail {
                return String(format: "conflict_email".localized, email)
            }
            return "conflict_generic".localized
        }
    }
}

/// Thrown when a soft-deleted account tries to sign in or register
/// The user must be informed that the account is permanently deactivated
struct AccountDeletedError: Error, LocalizedError {
    let message: String
    
    var errorDescription: String? {
        return message
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
            return "birth_data_linked_apple".localized
        case "google":
            if let email = existingEmail {
                return String(format: "birth_data_linked_google_email".localized, email)
            }
            return "birth_data_linked_google".localized
        default:
            return String(format: "birth_data_linked_email".localized, existingEmail ?? "a_registered_account".localized)
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
    /// Server-set when an active Plus subscriber hits a feature's overall
    /// lifetime cap. iOS uses this to render "Usage Restricted" / Contact
    /// Support flow instead of an upgrade paywall (Plus has no higher tier
    /// to upgrade to). Optional — older API responses won't carry it; iOS
    /// falls back to the heuristic isFairUseViolation in that case.
    let isFairUseViolation: Bool?

    enum CodingKeys: String, CodingKey {
        case canAccess = "can_access"
        case feature
        case planId = "plan_id"
        case reason
        case requiresQuota = "requires_quota"
        case limits
        case resetAt = "reset_at"
        case upgradeCta = "upgrade_cta"
        case isFairUseViolation = "is_fair_use_violation"
    }
    
    /// User-friendly denial reason
    var denialMessage: String {
        switch reason {
        case "daily_limit_reached": return "daily_limit_reached".localized
        case "overall_limit_reached": return "overall_limit_reached".localized
        case "feature_not_available": return upgradeCta?.message ?? "feature_not_available".localized
        default: return "unable_access_feature".localized
        }
    }
}

struct UpgradeCTA: Codable, Sendable {
    /// Server-curated upgrade message. Optional because backend deliberately
    /// returns null for overall-limit rejections so iOS falls back to its
    /// 13-locale `quota_fallback_*` strings rather than surfacing a verbatim
    /// "0 remaining" line. A non-Optional decoder threw DecodingError on
    /// null, fell through to the catch-all in ChatViewModel.sendMessage,
    /// and the gate failed-open — letting the cosmic-progress UI render
    /// before /predict 403'd. NEVER make this required again without
    /// auditing every catch block that calls canAccessFeature.
    let message: String?
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
    let featureUsage: [String: FeatureUsageInfo]
    let isPremium: Bool
    let features: [String]
    let subscriptionStatus: String?
    let subscriptionExpiresAt: String?
    let hasEverSubscribed: Bool
    let autoRenewStatus: Bool?

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
        case hasEverSubscribed = "has_ever_subscribed"
        case autoRenewStatus = "auto_renew_status"
    }
    
    /// Helper to get total questions across all features (for backward compat)
    var totalQuestionsAsked: Int {
        featureUsage.values.reduce(0) { $0 + $1.overall }
    }
}

// MARK: - QuotaManager

/// One-time alert payload shown when an external transaction (offer code
/// redemption, family share activation, App Store-side restore) changes the
/// user's subscription. Direct in-app purchases bypass this and show the
/// SubscriptionView success modal instead.
struct ExternalPlanChange: Identifiable {
    let id = UUID()
    let previousPlanId: String?
    let newPlanId: String
    let newPlanDisplayName: String
    let expiresAt: String?
    let willAutoRenew: Bool?
}

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
    @Published private(set) var hasEverSubscribed: Bool = false
    @Published private(set) var autoRenewStatus: Bool? = nil

    /// Set when a subscription change is detected via Transaction.updates
    /// (e.g. offer code redemption, plan switch). Consumed by AppRootView
    /// to show a one-time alert. Direct in-app purchases set this nil
    /// because SubscriptionView shows its own success modal.
    @Published var externalPlanChangeAlert: ExternalPlanChange?

    /// Tracks last non-nil plan_id seen during sync, used to detect changes.
    private var previousObservedPlanId: String?
    
    /// Current plan ID (convenience accessor for dynamic button text)
    var currentPlanId: String? {
        currentPlan?.planId ?? UserDefaults.standard.string(forKey: "currentPlanId")
    }
    
    private static let cachedPlansKey = "cachedAvailablePlans"
    private static let cachedFeaturesKey = "cachedAvailableFeatures"
    private let dataManager: DataManager

    /// Last time syncStatus was called (for TTL-based short-circuit)
    private var lastSyncTime: Date?
    /// Minimum interval between syncStatus calls (5 minutes)
    private let syncCooldown: TimeInterval = 300

    init(dataManager: DataManager? = nil) {
        self.dataManager = dataManager ?? DataManager.shared
        // Restore cached state immediately so icons show correct color before first network sync
        loadCachedPlans()
        loadCachedSubscriptionState()
    }

    // MARK: - Guest Detection (single source of truth)

    /// Single source of truth for detecting guest emails.
    ///
    /// Recognizes the actual guest email formats produced by this app:
    /// - `EmailGenerator` output: `YYYYMMDD_HHMM_CityPrefix_LatInt_LngInt@daa.com`
    /// - Legacy generated suffix: `@gen.com`
    /// - Anonymous-id prefix used by AppleAuthService / mock auth: `guest_<uuid>`
    ///
    /// Replaces the previous `email.contains("guest") || email.contains("@gen.com")`
    /// substring heuristic, which misclassified real users with addresses like
    /// `bguest@example.com` as guests (iOS-12).
    ///
    /// Empty strings are NOT guests (callers should treat empty separately).
    nonisolated static func isGuestEmail(_ email: String) -> Bool {
        guard !email.isEmpty else { return false }
        return email.hasSuffix("@daa.com")
            || email.hasSuffix("@gen.com")
            || email.hasPrefix("guest_")
    }

    /// Load plans from UserDefaults cache (synchronous, called on init)
    private func loadCachedPlans() {
        guard let data = UserDefaults.standard.data(forKey: Self.cachedPlansKey) else { return }
        if let cached = try? JSONDecoder().decode([PlanInfo].self, from: data) {
            availablePlans = cached
            print("📦 [QuotaManager] Loaded \(cached.count) cached plans")
        }
    }

    /// Restore subscription state from UserDefaults so UI shows correct badges on cold start
    private func loadCachedSubscriptionState() {
        isPremium = UserDefaults.standard.bool(forKey: "isPremium")
        subscriptionStatus = UserDefaults.standard.string(forKey: "subscriptionStatus")
        subscriptionExpiresAtString = UserDefaults.standard.string(forKey: "subscriptionExpiresAt")
        if UserDefaults.standard.object(forKey: "autoRenewStatus") != nil {
            autoRenewStatus = UserDefaults.standard.bool(forKey: "autoRenewStatus")
        }
        if let data = UserDefaults.standard.data(forKey: Self.cachedFeaturesKey),
           let features = try? JSONDecoder().decode([String].self, from: data) {
            availableFeatures = features
        }
        print("📦 [QuotaManager] Restored cached state — isPremium: \(isPremium), features: \(availableFeatures.count)")
    }

    /// Persist plans to UserDefaults cache
    private func cachePlans(_ plans: [PlanInfo]) {
        if let data = try? JSONEncoder().encode(plans) {
            UserDefaults.standard.set(data, forKey: Self.cachedPlansKey)
            print("💾 [QuotaManager] Cached \(plans.count) plans")
        }
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
        // Short timeout: if Cloud Run is cold, fail fast so the catch block in sendQuery
        // lets the request proceed. The stream itself handles cold-start wait transparently.
        request.timeoutInterval = 5

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
            // iOS-6 fix: fail open on network error. Server-side check_and_reserve
            // in /vedic/api/predict/stream is the source of truth — the client gate
            // is purely a UX hint. Locking users out on a flaky network when the
            // server would allow the action is worse than letting them through and
            // having the predict endpoint reject if truly out of quota.
            print("⚠️ canAsk: network check failed, failing open (server will enforce): \(error)")
            return true
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
        cachePlans(plans)  // Persist for instant paywall rendering
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
        
        // Handle 403 Forbidden - account was soft-deleted
        if httpResponse.statusCode == 403 {
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let detail = json["detail"] as? [String: Any],
               let error = detail["error"] as? String,
               error == "account_deleted" {
                let message = detail["message"] as? String ?? "This account has been deleted."
                print("[QuotaManager] 🚫 Account deleted: \(message)")
                throw AccountDeletedError(message: message)
            }
        }
        
        guard httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        let status = try JSONDecoder().decode(SubscriptionStatus.self, from: data)
        updateFromStatus(status)
        lastSyncTime = Date() // Prevent immediate redundant syncStatus call
        
        // Pre-fetch plans to keep cache fresh (fire-and-forget)
        Task { try? await fetchPlans() }
    }
    
    /// Sync status from server
    /// Called on sign-out to wipe all subscription state so the next account
    /// starts from a clean slate. Without this, account A's Plus state bleeds
    /// into account B via UserDefaults and loadCachedSubscriptionState().
    func resetForSignOut() {
        isPremium = false
        currentPlan = nil
        subscriptionStatus = nil
        subscriptionExpiresAtString = nil
        autoRenewStatus = nil
        hasEverSubscribed = false
        previousObservedPlanId = nil
        lastSyncTime = nil
        availableFeatures = []
    }

    #if DEBUG
    /// Inject isPremium=true for unit tests that need to verify reset clears it.
    /// Only available in DEBUG builds — stripped from release.
    func simulatePremiumForTesting() {
        isPremium = true
    }
    #endif

    /// - Parameters:
    ///   - email: User email
    ///   - force: If true, bypass cooldown (used after purchase/upgrade)
    func syncStatus(email: String, force: Bool = false) async throws {
        // Short-circuit if synced recently (prevents redundant calls on tab switch, pull-to-refresh)
        if !force, let lastSync = lastSyncTime, Date().timeIntervalSince(lastSync) < syncCooldown {
            print("[QuotaManager] syncStatus skipped — last sync \(Int(Date().timeIntervalSince(lastSync)))s ago")
            return
        }
        
        var components = URLComponents(string: APIConfig.baseURL + "/subscription/status")!
        components.queryItems = [URLQueryItem(name: "email", value: email)]
        
        var request = URLRequest(url: components.url!)
        request.httpMethod = "GET"
        request.setValue("Bearer \(APIConfig.apiKey)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 10  // fail fast on cold Cloud Run; cache stays valid

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        let status = try JSONDecoder().decode(SubscriptionStatus.self, from: data)
        updateFromStatus(status)
        lastSyncTime = Date()

        // Pre-fetch plans to keep cache fresh (fire-and-forget)
        Task { try? await fetchPlans() }
    }
    
    /// Update local state from server status
    private func updateFromStatus(_ status: SubscriptionStatus) {
        // Detect external plan changes BEFORE overwriting state.
        // Skip when:
        //   - Direct in-app purchase is in progress (SubscriptionView shows its own modal)
        //   - This is the first observation after launch (previousObservedPlanId is nil)
        //   - Plan didn't actually change
        //   - New plan is free (only celebrate paid activations)
        let oldPlanId = previousObservedPlanId
        let newPlanId = status.planId
        let isFirstObservation = (oldPlanId == nil)
        let planChanged = (oldPlanId != newPlanId)
        let isPaidNow = status.isPremium
        let directPurchaseRunning = SubscriptionManager.shared.directPurchaseInProgress

        if !isFirstObservation, planChanged, isPaidNow, !directPurchaseRunning {
            externalPlanChangeAlert = ExternalPlanChange(
                previousPlanId: oldPlanId,
                newPlanId: newPlanId ?? "",
                newPlanDisplayName: status.plan?.displayName ?? newPlanId ?? "Premium",
                expiresAt: status.subscriptionExpiresAt,
                willAutoRenew: status.autoRenewStatus
            )
            print("🎁 [QuotaManager] External plan change detected: \(oldPlanId ?? "nil") -> \(newPlanId ?? "nil")")
        }
        previousObservedPlanId = newPlanId

        currentPlan = status.plan
        isPremium = status.isPremium
        availableFeatures = status.features
        totalQuestionsAsked = status.totalQuestionsAsked
        subscriptionStatus = status.subscriptionStatus
        subscriptionExpiresAtString = status.subscriptionExpiresAt
        hasEverSubscribed = status.hasEverSubscribed
        autoRenewStatus = status.autoRenewStatus

        UserDefaults.standard.set(status.isPremium, forKey: "isPremium")
        UserDefaults.standard.set(status.planId, forKey: "currentPlanId")
        UserDefaults.standard.set(status.subscriptionStatus, forKey: "subscriptionStatus")
        UserDefaults.standard.set(status.subscriptionExpiresAt, forKey: "subscriptionExpiresAt")
        if let willRenew = status.autoRenewStatus {
            UserDefaults.standard.set(willRenew, forKey: "autoRenewStatus")
        }
        if let name = status.plan?.displayName {
            UserDefaults.standard.set(name, forKey: "currentPlanDisplayName")
        }
        if let data = try? JSONEncoder().encode(status.features) {
            UserDefaults.standard.set(data, forKey: Self.cachedFeaturesKey)
        }

        if let profile = dataManager.getCurrentUserProfile() {
            profile.totalQuestionsAsked = status.totalQuestionsAsked
            try? dataManager.context.save()
        }
    }
    
    // MARK: - Convenience
    
    /// Display name for current plan (shows "Free Plan" for free tiers)
    var planDisplayName: String {
        if let plan = currentPlan {
            // Two-channel state model: plan_id encodes the user's plan
            // history; subscription_status encodes whether the paid
            // relationship is still active. When a paid plan is expired,
            // surface "Plus (expired)" / "Core (expired)" so the UI is
            // honest about the user's history without claiming active
            // entitlements.
            if !plan.isFree && _isInTerminalPaidStatus {
                return "\(plan.displayName) (expired)"
            }
            if plan.isFree {
                return "Free Plan"
            }
            return plan.displayName
        }
        return UserDefaults.standard.string(forKey: "currentPlanDisplayName") ?? "Free Plan"
    }

    /// True when the user's most recent paid subscription has ended
    /// (expired/billing_retry/revoked/refunded). Drives "Plus (expired)"
    /// labels and the trial-eligibility gate. NOTE: `canceled` is NOT
    /// terminal — Apple's contract says canceled users keep entitlement
    /// until expires_at; W1 hotfix removed it from the server's terminal
    /// set too. Mirror that here.
    private var _isInTerminalPaidStatus: Bool {
        switch (subscriptionStatus ?? "") {
        case "expired", "billing_retry", "revoked", "refunded":
            return true
        default:
            return false
        }
    }

    /// Check if user can upgrade
    var canUpgrade: Bool {
        // A paid-but-expired user can also upgrade (renew). Don't gate this
        // on isFree alone or expired Plus users will see no upgrade CTA.
        if _isInTerminalPaidStatus { return true }
        return currentPlan?.isFree ?? true
    }

    /// Simple sync check for UI - uses cached features list
    /// For authoritative check, use `canAsk(feature:email:)` async method
    var canAsk: Bool {
        availableFeatures.contains(FeatureID.aiQuestions.rawValue)
    }

    /// Check if user is on a free plan (free_guest or free_registered) OR
    /// a paid plan in terminal expired/canceled/revoked/refunded status.
    /// In all those cases the effective entitlements are free_registered.
    var isFreePlan: Bool {
        if _isInTerminalPaidStatus { return true }
        let planId = currentPlan?.planId ?? ""
        return planId == "free_guest" || planId == "free_registered"
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

        // INV-7: differentiate past vs future tense.
        //   - Active + auto-renew on  → "Renews on" (future renewal)
        //   - Grace period            → "Ends on"
        //   - Already past expiry     → "Expired on" (past tense)
        //   - Active+canceled or any future "expires"  → "Expires on" (future)
        let prefix: String
        let isPast = expiryDate <= Date()
        if subscriptionStatus == "active" && autoRenewStatus != false {
            prefix = "Renews on"
        } else if subscriptionStatus == "grace_period" {
            prefix = "Ends on"
        } else if isPast || subscriptionStatus == "expired" {
            prefix = "Expired on"
        } else {
            prefix = "Expires on"
        }

        return "\(prefix) \(formatter.string(from: expiryDate))"
    }

    /// Subscription status display: "Active", "Expired", "Grace Period", "Canceled"
    var subscriptionStatusDisplayText: String {
        switch subscriptionStatus {
        case "active": return "Active"
        case "expired": return "Expired"
        case "grace_period": return "Grace Period"
        case "canceled": return "Canceled"
        // W3: cover the rest of the state machine so ProfileView / paywall
        // copy is honest about why entitlement is/isn't granted.
        case "billing_retry": return "Payment Failed"
        case "revoked": return "Subscription Revoked"
        case "refunded": return "Refunded"
        default: return ""
        }
    }

    /// W5 F5.3: longer-form description for ProfileView. Each variant
    /// gets its own copy because the user-action and the framing are
    /// different per status.
    var subscriptionStatusDetailText: String {
        switch subscriptionStatus {
        case "active":
            if autoRenewStatus == false {
                return "Your plan is active and will end at the next renewal date."
            }
            return "Your subscription is active and renews automatically."
        case "expired":
            return "Your subscription has ended. Renew to keep premium features."
        case "grace_period":
            return "Apple is retrying your payment. Update your payment method to keep your subscription active."
        case "canceled":
            return "Auto-renew is off. You'll keep premium features until the period ends."
        case "billing_retry":
            return "Your payment failed. Update your payment method in Settings → Apple ID to restore access."
        case "revoked":
            return "Your subscription was revoked. This can happen after a refund or billing dispute. Subscribe again to restore premium features."
        case "refunded":
            return "Your purchase was refunded. Contact support if this was unexpected."
        default:
            return ""
        }
    }

    /// W5 F5.3: CTA label per status. iOS uses this on the
    /// ProfileView "Manage subscription" button. Returns nil when no
    /// CTA is appropriate (e.g., active+autorenew).
    var subscriptionStatusCTA: String? {
        switch subscriptionStatus {
        case "active":
            return autoRenewStatus == false ? "Re-enable auto-renew" : nil
        case "expired":
            return "Renew subscription"
        case "grace_period":
            return "Update payment method"
        case "canceled":
            return "Manage subscription"
        case "billing_retry":
            return "Update payment method"
        case "revoked":
            return "Resubscribe"
        case "refunded":
            return "Contact support"
        default:
            return nil
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
            // iOS-6: fail open on network error (consistent with canAsk). The
            // server enforces the maintain_profile entitlement on the actual
            // profile-create call; the client gate is purely UX. A flaky
            // network must not block legitimate users.
            return (true, -1, false)
        }
    }
}
