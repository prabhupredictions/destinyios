import Foundation
import SwiftUI

/// ViewModel for the Home screen
@Observable
class HomeViewModel {
    // MARK: - State
    var userName: String = ""
    var quotaRemaining: Int = 3
    var quotaTotal: Int = 3
    var renewalDate: Date = Date()
    var dailyInsight: String = ""
    var suggestedQuestions: [String] = []
    var isLoading = false
    var errorMessage: String?
    var isGuest = false
    var isPremium = false
    var userType: UserType = .guest
    
    // MARK: - Dependencies
    private let predictionService: PredictionServiceProtocol?
    private let quotaManager = QuotaManager.shared
    
    // MARK: - Init
    init(predictionService: PredictionServiceProtocol? = nil) {
        self.predictionService = predictionService
        loadUserInfo()
    }
    
    // MARK: - Load User Info
    private func loadUserInfo() {
        // Load from UserDefaults
        userName = UserDefaults.standard.string(forKey: "userName") ?? "there"
        isGuest = UserDefaults.standard.bool(forKey: "isGuest")
        
        // Set user type based on flags
        if isPremium {
            userType = .premium
            quotaTotal = Int.max
            quotaRemaining = Int.max
        } else if isGuest {
            userType = .guest
            quotaTotal = 3  // Guest quota
        } else {
            userType = .registered
            quotaTotal = 10  // Registered user quota
        }
        
        // Load cached quota (will be updated from backend in loadHomeData)
        let cachedUsed = UserDefaults.standard.integer(forKey: "quotaUsed")
        quotaRemaining = max(0, quotaTotal - cachedUsed)
        
        // Set renewal date (first of next month)
        let calendar = Calendar.current
        if let nextMonth = calendar.date(byAdding: .month, value: 1, to: Date()) {
            renewalDate = calendar.date(from: calendar.dateComponents([.year, .month], from: nextMonth)) ?? Date()
        }
    }
    
    // MARK: - Load Home Data (with backend sync)
    func loadHomeData() async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        // Sync quota from backend
        await syncQuotaFromBackend()
        
        // Generate daily insight
        await MainActor.run {
            dailyInsight = generateDailyInsight()
            
            suggestedQuestions = [
                "What should I be mindful of today?",
                "How can I improve my focus and productivity?",
                "What's a good time for important decisions?",
                "What does my chart say about relationships?"
            ]
            
            isLoading = false
        }
    }
    
    // MARK: - Backend Sync
    private func syncQuotaFromBackend() async {
        guard let userEmail = UserDefaults.standard.string(forKey: "userEmail"),
              !userEmail.isEmpty else {
            return
        }
        
        do {
            // Sync with server - this updates QuotaManager's internal state
            _ = try await quotaManager.syncStatusFromServer(email: userEmail)
            
            // Get the updated status from QuotaManager
            let status = quotaManager.currentStatus
            await MainActor.run {
                // Update from status
                let questionsUsed = status.questionsUsed
                let questionsLimit = status.questionsLimit
                
                quotaTotal = questionsLimit
                quotaRemaining = status.remainingQuestions
                isPremium = status.userType == .premium
                userType = status.userType
                
                // Cache for offline
                UserDefaults.standard.set(questionsUsed, forKey: "quotaUsed")
            }
        } catch {
            print("Failed to sync quota from backend: \(error)")
            // Keep using cached/local values
        }
    }
    
    // MARK: - Actions
    func decrementQuota() {
        if quotaRemaining > 0 && userType != .premium {
            quotaRemaining -= 1
            let used = quotaTotal - quotaRemaining
            UserDefaults.standard.set(used, forKey: "quotaUsed")
        }
    }
    
    func refreshQuota() async {
        await syncQuotaFromBackend()
    }
    
    // MARK: - Computed Properties
    var quotaProgress: Double {
        guard quotaTotal > 0, userType != .premium else { return 1.0 }
        return Double(quotaTotal - quotaRemaining) / Double(quotaTotal)
    }
    
    var renewalDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: renewalDate)
    }
    
    var greetingMessage: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<5: return "Good night"
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        default: return "Good evening"
        }
    }
    
    var displayName: String {
        if isGuest {
            return "Guest"
        }
        return userName.isEmpty ? "there" : userName.components(separatedBy: " ").first ?? userName
    }
    
    // MARK: - Private Helpers
    private func generateDailyInsight() -> String {
        let insights = [
            "Trust your instincts in financial decisions today. Jupiter's transit supports your material endeavors.",
            "You're more sensitive to tone than words today. Mercury's position heightens your intuition about communication.",
            "Today favors practical matters over creative pursuits. Saturn's influence brings focus to your responsibilities.",
            "A good day for important conversations. Venus aspects your communication house, making your words more persuasive.",
            "Focus on self-care and reflection. The Moon's position suggests introspection will bring clarity."
        ]
        
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 0
        return insights[dayOfYear % insights.count]
    }
}
