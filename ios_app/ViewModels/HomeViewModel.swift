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
    
    // New Data for Enhanced Sections
    var fullAstroData: UserAstroDataResponse?
    var dashaResponse: DashaResponse?
    var currentDashaPeriod: DashaPeriod?
    var upcomingDashaPeriod: DashaPeriod?
    var yogaCombinations: [YogaDetail] = []
    var doshaStatus: (mangal: AstroMangalDoshaResult?, kalaSarpa: AstroKalaSarpaResult?) = (nil, nil)
    
    // NEW: Premium Transit & Dasha UI
    var dashaInsight: DashaInsight?
    var transitInfluences: [TransitInfluence] = []

    
    struct TransitDisplayData: Identifiable {
        let id = UUID()
        let planet: String
        let sign: String
        let house: Int
    }
    
    // MARK: - Computed Properties
    var ascendantSign: String {
        // Safe access to house 1 (Ascendant)
        guard let data = fullAstroData,
              let house1 = data.houses["1"] else {
            return "Asc"
        }
        
        let signNum = house1.signNum
        // Ensure signNum is valid (1-12)
        guard signNum >= 1 && signNum <= 12 else { return "Asc" }
        
        // Convert to index (0-11)
        let index = signNum - 1
        let abbrev = ChartConstants.orderedSigns[index]
        return ChartConstants.signFullNames[abbrev] ?? abbrev
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
        // Prevent concurrent calls (e.g., .task + profile switch firing close together)
        guard !isLoading else {
            print("[HomeViewModel] loadHomeData already in progress — skipping")
            return
        }
        
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
        
        // Create a task group to fetch all data concurrently
        await withTaskGroup(of: Void.self) { group in
            // 1. Fetch Todays Prediction (Existing)
            group.addTask {
                await self.fetchTodaysPrediction(birthData: birthData)
            }
            
            // 2. Fetch Full Chart Data (for Yogas, Doshas)
            group.addTask {
                await self.fetchFullChart(birthData: birthData)
            }
            
            // 3. Fetch Dasha Periods (for Widget)
            group.addTask {
                await self.fetchDashaPeriods(birthData: birthData)
            }
        }
        
        await MainActor.run {
            self.isLoading = false
        }
    }
    
    private func fetchTodaysPrediction(birthData: UserBirthData) async {
        let profileId = ProfileContextManager.shared.activeProfileId
        let profileName = ProfileContextManager.shared.activeProfileName
        
        print("[HomeViewModel] fetchTodaysPrediction for profile: \(profileName) (id: \(profileId))")
        print("[HomeViewModel] Birth data DOB: \(birthData.dob)")
        
        // Check local cache first (profile-scoped via TodaysPredictionCache)
        if let cached = TodaysPredictionCache.shared.get() {
            print("[HomeViewModel] Cache HIT for profile: \(profileId)")
            await MainActor.run {
                self.applyPredictionResponse(cached)
            }
            return
        }
        
        print("[HomeViewModel] Cache MISS for profile: \(profileId) - calling API...")
        
        do {
            let userEmail = UserDefaults.standard.string(forKey: "userEmail")
            var request = UserAstroDataRequest(birthData: birthData, userEmail: userEmail)
            
            let response = try await predictionService.getTodaysPrediction(request: request)
            
            print("[HomeViewModel] API response received for profile: \(profileId)")
            TodaysPredictionCache.shared.set(response)
            
            await MainActor.run {
                self.applyPredictionResponse(response)
            }
        } catch {
            print("[HomeViewModel] Prediction error for \(profileId): \(error)")
            await MainActor.run {
                // Don't override general error if other calls succeed, just log it
                // self.errorMessage = "Failed to load prediction" 
            }
        }
    }
    
    private func fetchFullChart(birthData: UserBirthData) async {
        do {
            let response = try await UserChartService.shared.fetchFullChartData(birthData: birthData)
            await MainActor.run {
                self.fullAstroData = response
                // Process Yogas & Doshas
                // Process All Yogas & Doshas
                var allCombinations: [YogaDetail] = []
                
                if let yogas = response.analysis.yogas?.yogas {
                    allCombinations.append(contentsOf: yogas)
                }
                
                if let doshas = response.analysis.yogas?.doshas {
                    allCombinations.append(contentsOf: doshas)
                }
                
                // Sort: Active first, then by strength
                self.yogaCombinations = allCombinations.sorted {
                    if $0.status == "A" && $1.status != "A" { return true }
                    if $0.status != "A" && $1.status == "A" { return false }
                    return $0.strength > $1.strength
                }
                self.doshaStatus = (response.analysis.mangalDosha, response.analysis.kalaSarpa)
            }
        } catch {
            print("[HomeViewModel] Full Chart error: \(error)")
        }
    }
    
    private func fetchDashaPeriods(birthData: UserBirthData) async {
        do {
            let response = try await UserChartService.shared.fetchDashaPeriods(birthData: birthData)
            await MainActor.run {
                self.dashaResponse = response
                self.calculateCurrentDashaPeriod(response)
            }
        } catch {
            print("[HomeViewModel] Dasha error: \(error)")
        }
    }
    
    private func calculateCurrentDashaPeriod(_ response: DashaResponse) {
        let now = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        // Find current period
        if let current = response.periods.first(where: { period in
            guard let start = dateFormatter.date(from: period.start),
                  let end = dateFormatter.date(from: period.end) else { return false }
            return start <= now && end >= now
        }) {
            self.currentDashaPeriod = current
            
            // Find next period
            if let index = response.periods.firstIndex(where: { $0.start == current.start }),
               index + 1 < response.periods.count {
                self.upcomingDashaPeriod = response.periods[index + 1]
            }
        }
    }
    
    /// Apply prediction response to view state
    private func applyPredictionResponse(_ response: TodaysPredictionResponse) {
        self.dailyInsight = response.todaysInsight
        self.currentDasha = response.currentDasha
        self.suggestedQuestions = response.mindQuestions
        self.lifeAreas = response.lifeAreas
        
        // NEW: Apply Dasha Insight
        self.dashaInsight = response.dashaInsight
        
        // NEW: Apply Transit Influences
        self.transitInfluences = response.transitInfluences ?? []
        
        // Parse Transits (legacy)
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
        // Check active profile first (for Switch Profile feature)
        if let profileBirthData = ProfileContextManager.shared.activeBirthData {
            print("[HomeViewModel] Using birth data from active profile: \(ProfileContextManager.shared.activeProfileName)")
            return normalizeTimeFormat(profileBirthData)
        }
        
        // Fallback: Try userBirthData (new) then birthData (legacy)
        let key = UserDefaults.standard.object(forKey: "userBirthData") != nil ? "userBirthData" : "birthData"
        guard let data = UserDefaults.standard.data(forKey: key),
              var birthData = try? JSONDecoder().decode(UserBirthData.self, from: data) else {
            return nil
        }
        
        // Normalize time to 24-hour format (HH:mm)
        // This handles legacy data that may be stored as "8:30 PM" instead of "20:30"
        birthData = normalizeTimeFormat(birthData)
        
        return birthData
    }
    
    /// Convert 12-hour time (e.g., "8:30 PM") to 24-hour (e.g., "20:30")
    private func normalizeTimeFormat(_ data: UserBirthData) -> UserBirthData {
        let time = data.time
        
        // Check if already in HH:mm format (24-hour)
        let hhmmRegex = "^\\d{2}:\\d{2}$"
        if time.range(of: hhmmRegex, options: .regularExpression) != nil {
            return data // Already normalized
        }
        
        // Try to parse 12-hour format (h:mm a or hh:mm a)
        let formatter12 = DateFormatter()
        formatter12.locale = Locale(identifier: "en_US_POSIX")
        formatter12.dateFormat = "h:mm a"
        
        if let date = formatter12.date(from: time) {
            let formatter24 = DateFormatter()
            formatter24.dateFormat = "HH:mm"
            let normalizedTime = formatter24.string(from: date)
            
            print("[HomeViewModel] Normalized time from '\(time)' to '\(normalizedTime)'")
            
            // Create new UserBirthData with normalized time
            return UserBirthData(
                dob: data.dob,
                time: normalizedTime,
                latitude: data.latitude,
                longitude: data.longitude,
                ayanamsa: data.ayanamsa,
                houseSystem: data.houseSystem,
                cityOfBirth: data.cityOfBirth
            )
        }
        
        // If can't parse, return as-is (API will catch the error)
        return data
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
