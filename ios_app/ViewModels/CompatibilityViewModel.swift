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
                
                // Parse time
                let timeFormatter = DateFormatter()
                timeFormatter.dateFormat = "HH:mm"
                if let time = timeFormatter.date(from: birthData.time) {
                    boyBirthTime = time
                }
                
                // Set location
                boyCity = birthData.cityOfBirth ?? ""
                boyLatitude = birthData.latitude
                boyLongitude = birthData.longitude
                
                // Load time unknown flag
                boyTimeUnknown = UserDefaults.standard.bool(forKey: "birthTimeUnknown")
                
                // Load gender
                boyGender = UserDefaults.standard.string(forKey: "userGender") ?? ""
                
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
        
        await MainActor.run {
            isAnalyzing = true
            errorMessage = nil
        }
        
        // Simulate API call
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        
        await MainActor.run {
            // Generate mock result
            result = generateMockResult()
            isAnalyzing = false
            showResult = true
        }
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
struct CompatibilityResult: Identifiable {
    let id = UUID()
    let totalScore: Int
    let maxScore: Int
    let kutas: [KutaDetail]
    let summary: String
    let recommendation: String
    
    var percentage: Double {
        guard maxScore > 0 else { return 0 }
        return Double(totalScore) / Double(maxScore)
    }
}

struct KutaDetail: Identifiable {
    let id = UUID()
    let name: String
    let maxPoints: Int
    let points: Int
    
    var percentage: Double {
        guard maxPoints > 0 else { return 0 }
        return Double(points) / Double(maxPoints)
    }
}
