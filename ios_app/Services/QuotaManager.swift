import Foundation
import Combine
import SwiftData

/// User types for quota tracking and backend identification
enum UserType: String, Codable, Sendable {
    case guest = "guest"              // Not logged in, using generated email
    case registered = "registered"    // Logged in with email/Google
    case premium = "premium"          // Active subscription
    
    /// Display name for UI
    var displayName: String {
        switch self {
        case .guest: return "Guest"
        case .registered: return "Free User"
        case .premium: return "Premium"
        }
    }
    
    /// Question limit for this user type
    var questionLimit: Int {
        switch self {
        case .guest: return 3
        case .registered: return 10
        case .premium: return Int.max // Unlimited
        }
    }
    
    /// Whether user can upgrade
    var canUpgrade: Bool {
        self != .premium
    }
    
    /// Upgrade message based on type
    var upgradeMessage: String {
        switch self {
        case .guest:
            return "Sign in for 10 free questions, or go Premium for unlimited access"
        case .registered:
            return "Upgrade to Premium for unlimited questions and exclusive features"
        case .premium:
            return ""
        }
    }
    
    /// Upgrade CTA button text
    var upgradeButtonText: String {
        switch self {
        case .guest: return "Sign In or Upgrade"
        case .registered: return "Upgrade to Premium"
        case .premium: return ""
        }
    }
}

/// Quota status for a user
struct QuotaStatus: Sendable {
    let userType: UserType
    let questionsUsed: Int
    let questionsLimit: Int
    let canAsk: Bool
    let remainingQuestions: Int
    
    init(userType: UserType, questionsUsed: Int) {
        self.userType = userType
        self.questionsUsed = questionsUsed
        self.questionsLimit = userType.questionLimit
        self.remainingQuestions = max(0, userType.questionLimit - questionsUsed)
        self.canAsk = questionsUsed < userType.questionLimit
    }
    
    /// Progress for UI (0.0 to 1.0)
    var progress: Double {
        if userType == .premium { return 1.0 }
        return Double(questionsUsed) / Double(questionsLimit)
    }
    
    /// Status text for display
    var statusText: String {
        if userType == .premium {
            return "Unlimited questions"
        }
        return "\(remainingQuestions) of \(questionsLimit) questions remaining"
    }
    
    /// Short status for header
    var shortStatus: String {
        if userType == .premium { return "∞" }
        return "\(remainingQuestions)"
    }
}

/// Manages user quota tracking
@MainActor
class QuotaManager: ObservableObject {
    static let shared = QuotaManager()
    
    @Published private(set) var currentStatus: QuotaStatus
    
    private let dataManager: DataManager
    
    init(dataManager: DataManager = DataManager.shared) {
        self.dataManager = dataManager
        self.currentStatus = QuotaStatus(userType: .guest, questionsUsed: 0)
        refresh()
    }
    
    /// Refresh quota status from storage
    func refresh() {
        let userType = getCurrentUserType()
        let questionsUsed = getQuestionsUsed()
        currentStatus = QuotaStatus(userType: userType, questionsUsed: questionsUsed)
    }
    
    /// Get current user type
    func getCurrentUserType() -> UserType {
        // Check premium first (StoreKit)
        if UserDefaults.standard.bool(forKey: "isPremium") {
            return .premium
        }
        
        // Check if logged in with real email
        let isGuest = UserDefaults.standard.bool(forKey: "isGuest")
        if !isGuest {
            if let email = UserDefaults.standard.string(forKey: "userEmail"),
               !email.isEmpty,
               !EmailGenerator.isGeneratedEmail(email) {
                return .registered
            }
        }
        
        return .guest
    }
    
    /// Get questions used from profile
    func getQuestionsUsed() -> Int {
        if let profile = dataManager.getCurrentUserProfile() {
            return profile.totalQuestionsAsked
        }
        return 0
    }
    
    /// Check if user can ask a question
    var canAsk: Bool {
        currentStatus.canAsk
    }
    
    /// Increment question count after successful question
    func recordQuestion() {
        if let profile = dataManager.getCurrentUserProfile() {
            profile.totalQuestionsAsked += 1
            try? dataManager.context.save()
            refresh()
        }
    }
    
    /// Reset quota (for testing or admin)
    func resetQuota() {
        if let profile = dataManager.getCurrentUserProfile() {
            profile.totalQuestionsAsked = 0
            try? dataManager.context.save()
            refresh()
        }
    }
    
    /// Get user type string for API
    var userTypeForAPI: String {
        getCurrentUserType().rawValue
    }
    
    // MARK: - Server Sync
    
    /// Response model from subscription API
    struct SubscriptionStatus: Codable {
        let userEmail: String
        let userType: String
        let questionsAsked: Int
        let questionsLimit: Int
        let questionsRemaining: Int
        let canAsk: Bool
        let isPremium: Bool
        let subscriptionStatus: String?
        let subscriptionExpiresAt: String?
        
        enum CodingKeys: String, CodingKey {
            case userEmail = "user_email"
            case userType = "user_type"
            case questionsAsked = "questions_asked"
            case questionsLimit = "questions_limit"
            case questionsRemaining = "questions_remaining"
            case canAsk = "can_ask"
            case isPremium = "is_premium"
            case subscriptionStatus = "subscription_status"
            case subscriptionExpiresAt = "subscription_expires_at"
        }
    }
    
    /// Register user with backend (call on birth data save or login)
    func registerWithServer(email: String, userType: UserType, isGeneratedEmail: Bool) async throws {
        let url = URL(string: APIConfig.baseURL + APIConfig.subscriptionRegister)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(APIConfig.apiKey)", forHTTPHeaderField: "Authorization")
        
        let body: [String: Any] = [
            "email": email,
            "user_type": userType.rawValue,
            "is_generated_email": isGeneratedEmail
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        let status = try JSONDecoder().decode(SubscriptionStatus.self, from: data)
        await MainActor.run {
            updateFromServerStatus(status)
        }
    }
    
    /// Sync status from server (call before predictions)
    func syncStatusFromServer(email: String) async throws -> Bool {
        var components = URLComponents(string: APIConfig.baseURL + APIConfig.subscriptionStatus)!
        components.queryItems = [URLQueryItem(name: "email", value: email)]
        
        var request = URLRequest(url: components.url!)
        request.httpMethod = "GET"
        request.setValue("Bearer \(APIConfig.apiKey)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        let status = try JSONDecoder().decode(SubscriptionStatus.self, from: data)
        await MainActor.run {
            updateFromServerStatus(status)
        }
        
        return status.canAsk
    }
    
    /// Record question with server (call after successful prediction)
    func recordQuestionOnServer(email: String) async throws {
        var components = URLComponents(string: APIConfig.baseURL + APIConfig.subscriptionRecord)!
        components.queryItems = [URLQueryItem(name: "email", value: email)]
        
        var request = URLRequest(url: components.url!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(APIConfig.apiKey)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        // Also update local state
        await MainActor.run {
            recordQuestion()  // Local update
        }
    }
    
    /// Update local state from server status
    private func updateFromServerStatus(_ status: SubscriptionStatus) {
        let serverUserType = UserType(rawValue: status.userType) ?? .guest
        
        // Update local storage
        UserDefaults.standard.set(status.isPremium, forKey: "isPremium")
        
        // Sync questions count with profile if available
        if let profile = dataManager.getCurrentUserProfile() {
            profile.totalQuestionsAsked = status.questionsAsked
            try? dataManager.context.save()
        }
        
        // Update published status
        currentStatus = QuotaStatus(userType: serverUserType, questionsUsed: status.questionsAsked)
    }
}

