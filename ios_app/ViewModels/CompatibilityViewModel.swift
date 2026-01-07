import Foundation
import SwiftUI

/// ViewModel for Compatibility/Match screen
@Observable
class CompatibilityViewModel {
    // MARK: - State
    var boyName: String = ""
    var girlName: String = ""
    
    // Birth data for "You" (user)
    var boyBirthDate: Date = Date()
    var boyBirthTime: Date = Date()
    var boyCity: String = ""
    var boyLatitude: Double = 0
    var boyLongitude: Double = 0
    var boyTimeUnknown: Bool = false
    var boyGender: String = "" // male, female, non-binary
    var userDataLoaded: Bool = false // Track if user data was loaded from profile
    
    // Birth data for "Partner"
    var girlBirthDate: Date = Date()
    var girlBirthTime: Date = Date()
    var girlCity: String = ""
    var girlLatitude: Double = 0
    var girlLongitude: Double = 0
    var partnerTimeUnknown: Bool = false
    var partnerGender: String = "" // male, female, other
    
    // Analysis state
    var isAnalyzing = false
    var showResult = false
    var errorMessage: String?
    var result: CompatibilityResult?
    var sessionId: String? // For follow-up queries
    
    // Streaming progress state
    var currentStep: AnalysisStep = .calculatingCharts
    var streamingText: String = ""
    var showStreamingView: Bool = false
    
    // MARK: - Formatted Date Strings
    var formattedBoyDob: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        return formatter.string(from: boyBirthDate)
    }
    
    var formattedGirlDob: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        return formatter.string(from: girlBirthDate)
    }
    
    // MARK: - Dependencies
    private let compatibilityService: CompatibilityServiceProtocol
    
    // MARK: - Init
    init(compatibilityService: CompatibilityServiceProtocol = CompatibilityService()) {
        self.compatibilityService = compatibilityService
        loadUserDataFromProfile()
    }
    
    // MARK: - Load User Data
    /// Load user's birth data from profile (UserDefaults)
    private func loadUserDataFromProfile() {
        // Load name
        if let savedName = UserDefaults.standard.string(forKey: "userName"), !savedName.isEmpty {
            boyName = savedName
        }
        
        // Load birth data
        if let data = UserDefaults.standard.data(forKey: "userBirthData") {
            do {
                let birthData = try JSONDecoder().decode(BirthData.self, from: data)
                
                // Parse date
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd"
                if let date = dateFormatter.date(from: birthData.dob) {
                    boyBirthDate = date
                }
                
                // Parse time (handle both 24-hour "HH:mm" and legacy 12-hour "h:mm a")
                let timeFormatter = DateFormatter()
                timeFormatter.locale = Locale(identifier: "en_US_POSIX")
                timeFormatter.dateFormat = "HH:mm"
                if let time = timeFormatter.date(from: birthData.time) {
                    boyBirthTime = time
                } else {
                    // Fallback: try 12-hour format for legacy data
                    let formatter12 = DateFormatter()
                    formatter12.locale = Locale(identifier: "en_US_POSIX")
                    formatter12.dateFormat = "h:mm a"
                    if let time = formatter12.date(from: birthData.time) {
                        boyBirthTime = time
                        print("[CompatibilityViewModel] Parsed legacy 12-hour time: \(birthData.time)")
                    }
                }
                
                // Set location
                boyCity = birthData.cityOfBirth ?? ""
                boyLatitude = birthData.latitude
                boyLongitude = birthData.longitude
                
                // Load time unknown flag (using user-scoped key)
                if let email = UserDefaults.standard.string(forKey: "userEmail") {
                    let timeUnknownKey = StorageKeys.userKey(for: StorageKeys.birthTimeUnknown, email: email)
                    boyTimeUnknown = UserDefaults.standard.bool(forKey: timeUnknownKey)
                    
                    // Load gender (using user-scoped key)
                    let genderKey = StorageKeys.userKey(for: StorageKeys.userGender, email: email)
                    boyGender = UserDefaults.standard.string(forKey: genderKey) ?? ""
                } else {
                    // Fallback for legacy data
                    boyTimeUnknown = UserDefaults.standard.bool(forKey: "birthTimeUnknown")
                    boyGender = UserDefaults.standard.string(forKey: "userGender") ?? ""
                }
                
                userDataLoaded = true
            } catch {
                print("Failed to decode user birth data: \(error)")
            }
        }
    }
    
    // MARK: - Validation
    var isFormValid: Bool {
        // Names and locations are now required
        !boyName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !girlName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !boyCity.isEmpty &&
        !girlCity.isEmpty &&
        boyLatitude != 0 &&
        boyLongitude != 0 &&
        girlLatitude != 0 &&
        girlLongitude != 0
    }
    
    // Effective names with fallback
    var effectiveBoyName: String {
        boyName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Not Provided" : boyName
    }
    
    var effectiveGirlName: String {
        girlName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Not Provided" : girlName
    }
    
    // MARK: - Actions
    func analyzeMatch() async {
        guard isFormValid else {
            errorMessage = "Please fill in all required fields"
            return
        }
        
        // Check quota before proceeding
        let currentEmail = UserDefaults.standard.string(forKey: "userEmail") ?? "guest"
        
        await MainActor.run {
            isAnalyzing = true
            showStreamingView = true
            currentStep = .calculatingCharts
            streamingText = ""
            errorMessage = nil
        }
        
        // Verify quota with backend
        do {
            let accessResponse = try await QuotaManager.shared.canAccessFeature(.compatibility, email: currentEmail)
            if !accessResponse.canAccess {
                await MainActor.run {
                    isAnalyzing = false
                    showStreamingView = false
                    // Professional Quota UI - Daily=banner, Overall/Feature=sheet (handled by View)
                    if accessResponse.reason == "daily_limit_reached" {
                        // DAILY LIMIT: Show error message (banner), no sheet
                        if let resetAtStr = accessResponse.resetAt,
                           let date = ISO8601DateFormatter().date(from: resetAtStr) {
                            let timeFormatter = DateFormatter()
                            timeFormatter.timeStyle = .short
                            let timeStr = timeFormatter.string(from: date)
                            errorMessage = "Daily limit reached. Resets at \(timeStr)."
                        } else {
                            errorMessage = "Daily limit reached. Resets tomorrow."
                        }
                    } else if accessResponse.reason == "overall_limit_reached" {
                        // OVERALL LIMIT: Set flag for View to show sheet
                        if currentEmail.contains("guest") || currentEmail.contains("@gen.com") {
                            errorMessage = "FREE_LIMIT_GUEST"  // Special marker for View to show sheet
                        } else {
                            errorMessage = "FREE_LIMIT_REGISTERED"  // Special marker for View to show sheet
                        }
                    } else {
                        // FEATURE NOT AVAILABLE: Set flag for View to show sheet
                        errorMessage = "FEATURE_UPGRADE_REQUIRED"  // Special marker for View to show sheet
                    }
                }
                return
            }
        } catch {
            print("Quota check failed: \(error)")
        }
        
        // Quota is now recorded server-side by /compatibility/analyze endpoint

        await MainActor.run {
            isAnalyzing = true
            showStreamingView = true
            currentStep = .calculatingCharts
            streamingText = ""
            errorMessage = nil
        }
        
        do {
            // Build API request
            let dateFormatter = DateFormatter()
            dateFormatter.locale = Locale(identifier: "en_US_POSIX")  // Ensures Gregorian + ASCII
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let timeFormatter = DateFormatter()
            timeFormatter.locale = Locale(identifier: "en_US_POSIX")  // Ensures 24-hour format
            timeFormatter.dateFormat = "HH:mm:ss"
            
            // Round coordinates to 6 decimal places (backend validation requirement)
            let roundedBoyLat = (boyLatitude * 1_000_000).rounded() / 1_000_000
            let roundedBoyLon = (boyLongitude * 1_000_000).rounded() / 1_000_000
            let roundedGirlLat = (girlLatitude * 1_000_000).rounded() / 1_000_000
            let roundedGirlLon = (girlLongitude * 1_000_000).rounded() / 1_000_000
            
            let request = CompatibilityRequest(
                boy: BirthDetails(
                    dob: dateFormatter.string(from: boyBirthDate),
                    time: timeFormatter.string(from: boyBirthTime),
                    lat: roundedBoyLat,
                    lon: roundedBoyLon,
                    name: boyName,
                    place: boyCity
                ),
                girl: BirthDetails(
                    dob: dateFormatter.string(from: girlBirthDate),
                    time: timeFormatter.string(from: girlBirthTime),
                    lat: roundedGirlLat,
                    lon: roundedGirlLon,
                    name: girlName,
                    place: girlCity
                ),
                sessionId: "sess_\(Int(Date().timeIntervalSince1970 * 1000))",
                userEmail: UserDefaults.standard.string(forKey: "userEmail")  // Pass real email for history storage
            )
            
            // DEBUG: Log userEmail being sent
            let debugEmail = UserDefaults.standard.string(forKey: "userEmail")
            print("[CompatibilityViewModel] DEBUG: UserDefaults 'userEmail' = '\(debugEmail ?? "NIL")'")
            print("[CompatibilityViewModel] DEBUG: request.userEmail = '\(request.userEmail ?? "NIL")'")
            print("[CompatibilityViewModel] GENERATED session_id in request: \(request.sessionId ?? "NIL")")
            
            // Call streaming API with progress callback
            let response: CompatibilityResponse
            if let service = compatibilityService as? CompatibilityService {
                response = try await service.analyzeWithProgress(request: request) { [weak self] step, _ in
                    self?.updateStep(step)
                }
            } else {
                response = try await compatibilityService.analyzeStream(request: request)
            }
            
            // Parse ashtakoot data from response
            let result = parseApiResponse(response)
            
            await MainActor.run {
                self.currentStep = .complete
                self.result = result
                isAnalyzing = false
                showStreamingView = false
                showResult = true
                
                // Save to history
                self.saveToHistory(result: result)
            }
        } catch {
            await MainActor.run {
                errorMessage = "Analysis failed: \(error.localizedDescription)"
                isAnalyzing = false
                showStreamingView = false
            }
        }
    }
    
    // MARK: - History
    private func saveToHistory(result: CompatibilityResult) {
        guard let sid = result.sessionId else { return }
        // Use compat_ prefix to match backend thread_id format
        let storageSessionId = sid.hasPrefix("compat_") ? sid : "compat_\(sid)"
        
        let item = CompatibilityHistoryItem(
            sessionId: storageSessionId,
            timestamp: Date(),
            boyName: boyName,
            boyDob: formattedBoyDob,
            boyCity: boyCity,
            girlName: girlName,
            girlDob: formattedGirlDob,
            girlCity: girlCity,
            totalScore: result.totalScore,
            maxScore: result.maxScore,
            result: result,
            chatMessages: [] // Chat starts empty
        )
        
        CompatibilityHistoryService.shared.save(item)
    }
    
    /// Load state from a history item
    func loadFromHistory(_ item: CompatibilityHistoryItem) {
        // Restore properties
        boyName = item.boyName
        girlName = item.girlName
        boyCity = item.boyCity
        girlCity = item.girlCity
        
        // Restore dates (parsing strings back to dates if needed, or better to store dates in HistoryItem?)
        // The HistoryItem has formatted strings for display, but also SHOULD store raw dates if we want to edit.
        // For now, we update the display state. The ViewModel stores Date objects.
        // Ideally HistoryItem should store Date objects or TimeIntervals.
        // Looking at CompatibilityHistoryItem.swift, it has `timestamp` but inputs are strings?
        // Ah, in current HistoryItem I put `boyDob: String` (formatted).
        // If we want to fully restore the *form* state (dates), we might need to parse or store raw dates.
        // BUT, for displaying the result, we largely rely on `result` object.
        // Let's rely on `item.result` for the analysis data.
        
        // Restore result
        if let savedResult = item.result {
            self.result = savedResult
            self.showResult = true
        }
    }
    
    /// Map SSE step name to AnalysisStep enum
    private func updateStep(_ stepName: String) {
        // Backend sends: calculate_charts, ashtakoot, mangal_compat, yoga_kalsarpa, formatting, llm
        let stepMapping: [String: AnalysisStep] = [
            "calculate_charts": .calculatingCharts,
            "ashtakoot": .ashtakootMatching,
            "mangal_compat": .mangalDosha,
            "yoga_kalsarpa": .collectingYogas,
            "formatting": .collectingYogas,
            "llm": .generatingAnalysis
        ]
        
        if let step = stepMapping[stepName] {
            currentStep = step
        }
        print("[ViewModel] Step update: \(stepName) -> \(currentStep)")
    }
    
    /// Parse API response to CompatibilityResult with analysisData
    private func parseApiResponse(_ response: CompatibilityResponse) -> CompatibilityResult {
        var kutas: [KutaDetail] = []
        var totalScore: Int = 0
        let maxScore = 36
        
        // Extract Kuta details from ashtakoot matching if available
        if let joint = response.analysisData?.joint,
           let ashtakoot = joint.ashtakootMatching {
            
            // Parse kuta values from guna_scores nested inside ashtakoot_matching
            // API structure: ashtakoot_matching.guna_scores.varna.score
            let kutaNames = [
                ("varna", "Varna", 1),
                ("vashya", "Vashya", 2),
                ("tara", "Tara", 3),
                ("yoni", "Yoni", 4),
                ("maitri", "Maitri", 5),
                ("gana", "Gana", 6),
                ("bhakoot", "Bhakoot", 7),
                ("nadi", "Nadi", 8)
            ]
            
            // First try to get guna_scores nested object
            if let gunaScores = ashtakoot["guna_scores"]?.value as? [String: Any] {
                for (key, name, maxPoints) in kutaNames {
                    if let kutaData = gunaScores[key] as? [String: Any],
                       let score = kutaData["score"] as? Int {
                        kutas.append(KutaDetail(name: name, maxPoints: maxPoints, points: score))
                        totalScore += score
                    } else if let kutaData = gunaScores[key] as? [String: Any],
                              let score = kutaData["score"] as? Double {
                        let points = Int(score)
                        kutas.append(KutaDetail(name: name, maxPoints: maxPoints, points: points))
                        totalScore += points
                    }
                }
            } else {
                // Fallback: try direct access (old structure)
                for (key, name, maxPoints) in kutaNames {
                    if let kutaData = ashtakoot[key]?.value as? [String: Any],
                       let score = kutaData["score"] as? Double {
                        let points = Int(score)
                        kutas.append(KutaDetail(name: name, maxPoints: maxPoints, points: points))
                        totalScore += points
                    }
                }
            }
            
            // Extract total score if available
            if let total = ashtakoot["total_score"]?.value as? Double {
                totalScore = Int(total)
            } else if let total = ashtakoot["total_score"]?.value as? Int {
                totalScore = total
            }
        }
        
        // If no kutas parsed, generate mock
        if kutas.isEmpty {
            kutas = [
                KutaDetail(name: "Varna", maxPoints: 1, points: 1),
                KutaDetail(name: "Vashya", maxPoints: 2, points: 1),
                KutaDetail(name: "Tara", maxPoints: 3, points: 2),
                KutaDetail(name: "Yoni", maxPoints: 4, points: 2),
                KutaDetail(name: "Maitri", maxPoints: 5, points: 3),
                KutaDetail(name: "Gana", maxPoints: 6, points: 3),
                KutaDetail(name: "Bhakoot", maxPoints: 7, points: 4),
                KutaDetail(name: "Nadi", maxPoints: 8, points: 4)
            ]
            totalScore = 20
        }
        
        // Generate summary based on score
        let summary: String
        if totalScore >= 28 {
            summary = "This is an excellent match with strong compatibility across all major areas."
        } else if totalScore >= 21 {
            summary = "A good match with solid foundations. Some areas may require conscious effort."
        } else {
            summary = "This match has some challenging aspects that require awareness and effort."
        }
        let rec = totalScore >= 18 ? "Favorable for marriage" : "Additional remedies may be helpful"
        
        print("[CompatibilityViewModel] STORING session_id in result: \(response.sessionId ?? "NIL")")
        
        return CompatibilityResult(
            totalScore: totalScore,
            maxScore: maxScore,
            kutas: kutas,
            summary: response.llmAnalysis ?? "\(totalScore)/36",
            recommendation: rec,
            analysisData: response.analysisData,
            sessionId: response.sessionId
        )
    }
    
    func reset() {
        // Only reset partner data, keep user data from profile
        girlName = ""
        girlBirthDate = Date()
        girlBirthTime = Date()
        girlCity = ""
        girlLatitude = 0
        girlLongitude = 0
        partnerTimeUnknown = false
        result = nil
        showResult = false
        errorMessage = nil
        
        // Reload user data from profile
        loadUserDataFromProfile()
    }
    
    // MARK: - Mock Result
    private func generateMockResult() -> CompatibilityResult {
        let totalScore = Int.random(in: 18...32)
        let maxScore = 36
        
        let kutas = [
            KutaDetail(name: "Varna", maxPoints: 1, points: Int.random(in: 0...1)),
            KutaDetail(name: "Vashya", maxPoints: 2, points: Int.random(in: 0...2)),
            KutaDetail(name: "Tara", maxPoints: 3, points: Int.random(in: 0...3)),
            KutaDetail(name: "Yoni", maxPoints: 4, points: Int.random(in: 0...4)),
            KutaDetail(name: "Graha Maitri", maxPoints: 5, points: Int.random(in: 0...5)),
            KutaDetail(name: "Gana", maxPoints: 6, points: Int.random(in: 0...6)),
            KutaDetail(name: "Bhakoot", maxPoints: 7, points: Int.random(in: 0...7)),
            KutaDetail(name: "Nadi", maxPoints: 8, points: Int.random(in: 0...8))
        ]
        
        let summary: String
        if totalScore >= 28 {
            summary = "This is an excellent match with strong compatibility across all major areas. The couple shares deep emotional understanding and complementary energies."
        } else if totalScore >= 21 {
            summary = "A good match with solid foundations. Some areas may require conscious effort, but overall compatibility is favorable for a harmonious relationship."
        } else {
            summary = "This match has some challenging aspects that require awareness and effort. With understanding and patience, the relationship can still flourish."
        }
        
        return CompatibilityResult(
            totalScore: totalScore,
            maxScore: maxScore,
            kutas: kutas,
            summary: summary,
            recommendation: totalScore >= 18 ? "Favorable for marriage" : "Additional remedies may be helpful"
        )
    }
}

// MARK: - Models
struct CompatibilityResult: Identifiable, Codable {
    let id = UUID()
    let totalScore: Int
    let maxScore: Int
    let kutas: [KutaDetail]
    let summary: String
    let recommendation: String
    let analysisData: AnalysisData?
    let sessionId: String?
    
    var percentage: Double {
        guard maxScore > 0 else { return 0 }
        return Double(totalScore) / Double(maxScore)
    }
    
    init(
        totalScore: Int,
        maxScore: Int,
        kutas: [KutaDetail],
        summary: String,
        recommendation: String,
        analysisData: AnalysisData? = nil,
        sessionId: String? = nil
    ) {
        self.totalScore = totalScore
        self.maxScore = maxScore
        self.kutas = kutas
        self.summary = summary
        self.recommendation = recommendation
        self.analysisData = analysisData
        self.sessionId = sessionId
    }
}

struct KutaDetail: Identifiable, Codable {
    let id = UUID()
    let name: String
    let maxPoints: Int
    let points: Int
    
    var percentage: Double {
        guard maxPoints > 0 else { return 0 }
        return Double(points) / Double(maxPoints)
    }
}
