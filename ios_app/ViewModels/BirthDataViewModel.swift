import Foundation
import SwiftUI

/// ViewModel for birth data collection with location integration
@Observable
class BirthDataViewModel {
    // MARK: - Form State
    var dateOfBirth = Calendar.current.date(byAdding: .year, value: -25, to: Date()) ?? Date()
    var timeOfBirth = Date()
    var cityOfBirth = ""
    var latitude: Double = 0
    var longitude: Double = 0
    var placeId: String?
    var gender = ""
    var timeUnknown = false
    
    // MARK: - UI State
    var isLoading = false
    var errorMessage: String?
    var showLocationSearch = false
    
    // MARK: - Dependencies
    private let dataManager: DataManager
    private var userEmail: String?
    private var isGuest: Bool = false
    
    // MARK: - Init
    init(dataManager: DataManager = DataManager.shared) {
        self.dataManager = dataManager
        loadUserInfo()
    }
    
    // MARK: - Computed Properties
    
    var isValid: Bool {
        !cityOfBirth.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        latitude != 0 && longitude != 0
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: dateOfBirth)
    }
    
    var formattedTime: String {
        if timeUnknown { return "Unknown" }
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: timeOfBirth)
    }
    
    var formattedDOB: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: dateOfBirth)
    }
    
    var formattedTOB: String {
        if timeUnknown { return "12:00" }
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: timeOfBirth)
    }
    
    /// Get the email to use (actual or generated)
    var effectiveEmail: String {
        if let email = userEmail, !email.isEmpty, !isGuest {
            return email
        }
        
        // Generate email from birth data
        return EmailGenerator.generateFromComponents(
            dateOfBirth: formattedDOB,
            timeOfBirth: formattedTOB,
            cityOfBirth: cityOfBirth,
            latitude: latitude,
            longitude: longitude
        )
    }
    
    // MARK: - Load User Info
    private func loadUserInfo() {
        userEmail = UserDefaults.standard.string(forKey: "userEmail")
        isGuest = UserDefaults.standard.bool(forKey: "isGuest")
    }
    
    // MARK: - Load Saved Data
    func loadSaved() {
        // Try to load from SwiftData first
        if let email = userEmail, !isGuest {
            if let profile = dataManager.getBirthProfile(for: email) {
                loadFromProfile(profile)
                return
            }
        }
        
        // Fallback to UserDefaults
        if let data = UserDefaults.standard.data(forKey: "userBirthData"),
           let saved = try? JSONDecoder().decode(BirthData.self, from: data) {
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            if let date = dateFormatter.date(from: saved.dob) {
                dateOfBirth = date
            }
            
            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "HH:mm"
            if let time = timeFormatter.date(from: saved.time) {
                timeOfBirth = time
            }
            
            cityOfBirth = saved.cityOfBirth ?? ""
            latitude = saved.latitude
            longitude = saved.longitude
            gender = UserDefaults.standard.string(forKey: "userGender") ?? ""
            timeUnknown = UserDefaults.standard.bool(forKey: "birthTimeUnknown")
        }
    }
    
    private func loadFromProfile(_ profile: UserBirthProfile) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        if let date = dateFormatter.date(from: profile.dateOfBirth) {
            dateOfBirth = date
        }
        
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        if let time = timeFormatter.date(from: profile.timeOfBirth) {
            timeOfBirth = time
        }
        
        cityOfBirth = profile.cityOfBirth
        latitude = profile.latitude
        longitude = profile.longitude
        placeId = profile.placeId
        gender = profile.gender ?? ""
        timeUnknown = profile.timeUnknown
    }
    
    // MARK: - Save
    
    /// Validate and save birth data to SwiftData
    func save() -> Bool {
        errorMessage = nil
        
        guard !cityOfBirth.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Please select your city of birth"
            return false
        }
        
        guard latitude != 0 && longitude != 0 else {
            errorMessage = "Please select a valid city from the search"
            return false
        }
        
        // Create profile
        let email = effectiveEmail
        let profile = UserBirthProfile(
            email: email,
            isGuestEmail: isGuest || (userEmail?.isEmpty ?? true),
            dateOfBirth: formattedDOB,
            timeOfBirth: formattedTOB,
            cityOfBirth: cityOfBirth.trimmingCharacters(in: .whitespacesAndNewlines),
            latitude: latitude,
            longitude: longitude,
            placeId: placeId,
            gender: gender.isEmpty ? nil : gender,
            timeUnknown: timeUnknown
        )
        
        // Save to SwiftData
        dataManager.saveBirthProfile(profile)
        
        // Also save to UserDefaults for backward compatibility
        let birthData = BirthData(
            dob: formattedDOB,
            time: formattedTOB,
            latitude: latitude,
            longitude: longitude,
            cityOfBirth: cityOfBirth
        )
        
        do {
            let encoded = try JSONEncoder().encode(birthData)
            UserDefaults.standard.set(encoded, forKey: "userBirthData")
            UserDefaults.standard.set(true, forKey: "hasBirthData")
            UserDefaults.standard.set(gender, forKey: "userGender")
            UserDefaults.standard.set(timeUnknown, forKey: "birthTimeUnknown")
            
            // Store generated email for guests
            if isGuest {
                UserDefaults.standard.set(email, forKey: "userEmail")
            }
            
            return true
        } catch {
            errorMessage = "Failed to save birth data"
            return false
        }
    }
    
    // MARK: - Location Selection
    
    /// Update location from search result
    func setLocation(city: String, lat: Double, lng: Double, id: String?) {
        cityOfBirth = city
        latitude = lat
        longitude = lng
        placeId = id
    }
}
