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
    var planDisplayName: String = "Free"
    
    // MARK: - New Premium State
    var currentDasha: String = "Loading..."
    var moonSign: String = ""
    var lifeAreas: [String: LifeAreaStatus] = [:]
    var currentTransits: [TransitDisplayData] = []
    
    struct TransitDisplayData: Identifiable {
        let id = UUID()
        let planet: String
        let sign: String
        let house: Int
    }
    
    // MARK: - Dependencies
    private let predictionService: PredictionServiceProtocol
    private let quotaManager = QuotaManager.shared
    
    // MARK: - Init
    init(predictionService: PredictionServiceProtocol = PredictionService()) {
        self.predictionService = predictionService
        loadUserInfo()
    }
    
    // MARK: - Load User Info
    private func loadUserInfo() {
        // Load from UserDefaults
        userName = UserDefaults.standard.string(forKey: "userName") ?? "there"
        isGuest = UserDefaults.standard.bool(forKey: "isGuest")
        isPremium = UserDefaults.standard.bool(forKey: "isPremium")
        
        // Set default quota based on local flags (will be updated from server)
        if isPremium {
            quotaTotal = Int.max
            quotaRemaining = Int.max
        } else if isGuest {
            quotaTotal = 3  // Guest default
        } else {
            quotaTotal = 10  // Registered default
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
    
    // MARK: - Load Home Data
    func loadHomeData() async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        // Sync quota
        await syncQuotaFromBackend()
        
        // Fetch Prediction
        guard let birthData = loadBirthData() else {
            // Guest or no data - fallback to generic
            await MainActor.run { 
                self.dailyInsight = "Sign in or add birth details to unlock your daily cosmic forecast."
                self.isLoading = false 
            }
            return
        }
        
        // Check local cache first
        if let cached = TodaysPredictionCache.shared.get() {
            await MainActor.run {
                self.applyPredictionResponse(cached)
                self.isLoading = false
            }
            return
        }
        
        do {
            // Pass user email for backend caching
            let userEmail = UserDefaults.standard.string(forKey: "userEmail")
            let request = UserAstroDataRequest(birthData: birthData, userEmail: userEmail)
            let response = try await predictionService.getTodaysPrediction(request: request)
            
            // Cache locally
            TodaysPredictionCache.shared.set(response)
            
            await MainActor.run {
                self.applyPredictionResponse(response)
                self.isLoading = false
            }
        } catch {
            print("Error fetching prediction: \(error)")
            await MainActor.run {
                self.errorMessage = "Failed to load cosmic data."
                self.isLoading = false
            }
        }
    }
    
    /// Apply prediction response to view state
    private func applyPredictionResponse(_ response: TodaysPredictionResponse) {
        self.dailyInsight = response.todaysInsight
        self.currentDasha = response.currentDasha
        self.suggestedQuestions = response.mindQuestions
        self.lifeAreas = response.lifeAreas
        
        // Parse Transits
        if let transits = response.currentTransits {
            self.currentTransits = transits.map { key, value in
                TransitDisplayData(planet: key, sign: value.sign, house: value.houseFromLagna)
            }.sorted { $0.house < $1.house }
            
            // Set Moon Sign
            if let moon = transits["Moon"] {
                self.moonSign = moon.sign
            }
        }
    }
    
    private func loadBirthData() -> UserBirthData? {
        // Try userBirthData (new) then birthData (legacy)
        let key = UserDefaults.standard.object(forKey: "userBirthData") != nil ? "userBirthData" : "birthData"
        guard let data = UserDefaults.standard.data(forKey: key),
              let birthData = try? JSONDecoder().decode(UserBirthData.self, from: data) else {
            return nil
        }
        return birthData
    }
    
    // MARK: - Backend Sync
    private func syncQuotaFromBackend() async {
        guard let userEmail = UserDefaults.standard.string(forKey: "userEmail"),
              !userEmail.isEmpty else {
            return
        }
        
        do {
            // Sync with server - this updates QuotaManager's internal state
            try await quotaManager.syncStatus(email: userEmail)
            
            // Get the updated status from QuotaManager
            await MainActor.run {
                isPremium = quotaManager.isPremium
                planDisplayName = quotaManager.planDisplayName
                
                // For now, quota info comes from server via canAccessFeature
                // Local tracking is a fallback
                UserDefaults.standard.set(quotaManager.totalQuestionsAsked, forKey: "quotaUsed")
            }
        } catch {
            print("Failed to sync quota from backend: \(error)")
            // Keep using cached/local values
        }
    }
    
    // MARK: - Actions
    func decrementQuota() {
        if quotaRemaining > 0 && !isPremium {
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
        guard quotaTotal > 0, !isPremium else { return 1.0 }
        return Double(quotaTotal - quotaRemaining) / Double(quotaTotal)
    }
    
    var renewalDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: renewalDate)
    }
    
    var greetingMessage: String {
        return "Hey"
    }
    
    var displayName: String {
        if isGuest {
            return "there"
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
