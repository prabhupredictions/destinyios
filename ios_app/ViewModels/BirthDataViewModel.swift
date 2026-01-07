import Foundation
import SwiftUI

/// ViewModel for birth data collection with location integration
@MainActor
@Observable
class BirthDataViewModel {
    // MARK: - Form State
    var userName = ""  // User's display name
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
        !userName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !cityOfBirth.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        latitude != 0 && longitude != 0
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        return formatter.string(from: dateOfBirth)
    }
    
    var formattedTime: String {
        if timeUnknown { return "birth_time_unknown".localized }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: timeOfBirth)
    }
    
    var formattedDOB: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")  // Ensures Gregorian calendar + ASCII digits
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: dateOfBirth)
    }
    
    var formattedTOB: String {
        if timeUnknown { return "12:00" }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")  // Ensures 24-hour format regardless of device
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
        
        // Auto-populate name from Apple/Google sign-in (not for guests)
        // For guests or email users, they need to enter name manually
        if !isGuest {
            if let signInName = UserDefaults.standard.string(forKey: "userName"),
               !signInName.isEmpty,
               signInName != "Guest" {
                userName = signInName
            }
        }
    }
    
    // MARK: - Load Saved Data
    func loadSaved() {
        let email = userEmail ?? "guest"
        
        // Try to load from SwiftData first
        if !isGuest {
            if let profile = dataManager.getBirthProfile(for: email) {
                loadFromProfile(profile)
                return
            }
        }
        
        // Fallback to UserDefaults (User-Scoped)
        let dataKey = StorageKeys.userKey(for: StorageKeys.userBirthData, email: email)
        if let data = UserDefaults.standard.data(forKey: dataKey),
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
            
            let genderKey = StorageKeys.userKey(for: StorageKeys.userGender, email: email)
            gender = UserDefaults.standard.string(forKey: genderKey) ?? ""
            
            let timeUnknownKey = StorageKeys.userKey(for: StorageKeys.birthTimeUnknown, email: email)
            timeUnknown = UserDefaults.standard.bool(forKey: timeUnknownKey)
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
        
        // Also save to UserDefaults (User-Scoped)
        let birthData = BirthData(
            dob: formattedDOB,
            time: formattedTOB,
            latitude: latitude,
            longitude: longitude,
            cityOfBirth: cityOfBirth
        )
        
        do {
            let encoded = try JSONEncoder().encode(birthData)
            
            // Use user-scoped keys for persistent storage
            let dataKey = StorageKeys.userKey(for: StorageKeys.userBirthData, email: email)
            UserDefaults.standard.set(encoded, forKey: dataKey)
            
            let hasDataKey = StorageKeys.userKey(for: StorageKeys.hasBirthData, email: email)
            UserDefaults.standard.set(true, forKey: hasDataKey)
            
            // ALSO update global session keys for immediate UI access
            UserDefaults.standard.set(encoded, forKey: "userBirthData")  // Global for HomeViewModel
            // NOTE: hasBirthData is now set by BirthDataView AFTER ProfileSetupLoadingView completes
            // This allows the loading screen to show before navigating to MainTabView
            
            let genderKey = StorageKeys.userKey(for: StorageKeys.userGender, email: email)
            UserDefaults.standard.set(gender, forKey: genderKey)
            
            let timeUnknownKey = StorageKeys.userKey(for: StorageKeys.birthTimeUnknown, email: email)
            UserDefaults.standard.set(timeUnknown, forKey: timeUnknownKey)
            
            // Store user name (global is fine for UI, verified on login)
            if !userName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                UserDefaults.standard.set(userName, forKey: "userName")
            }
            
            // Store generated email for guests
            if isGuest {
                UserDefaults.standard.set(email, forKey: "userEmail")
            }
            
            // Sync to server profile (fire and forget)
            syncToServerProfile(email: email)
            
            // Sync chat history from server (restore any past conversations)
            Task {
                await ChatHistorySyncService.shared.syncFromServer(userEmail: email, dataManager: dataManager)
                await CompatibilityHistoryService.shared.syncFromServer(userEmail: email)
            }
            
            return true
        } catch {
            errorMessage = "Failed to save birth data"
            return false
        }
    }
    
    /// Sync birth data to server profile for cross-device support
    private func syncToServerProfile(email: String) {
        Task {
            do {
                // Get user name from UserDefaults (set during Google/Apple sign-in)
                let storedUserName = UserDefaults.standard.string(forKey: "userName") ?? ""
                
                let profileRequest: [String: Any] = [
                    "email": email,
                    "user_name": storedUserName,  // From sign-in, backend defaults to "Destiny User" if empty
                    "user_type": isGuest ? "guest" : "registered",
                    "is_generated_email": isGuest,
                    "birth_profile": [
                        "date_of_birth": formattedDOB,
                        "time_of_birth": formattedTOB,
                        "city_of_birth": cityOfBirth,
                        "latitude": latitude,
                        "longitude": longitude,
                        "gender": gender.isEmpty ? nil : gender,
                        "birth_time_unknown": timeUnknown
                    ] as [String: Any?]
                ]
                
                let url = URL(string: "\(APIConfig.baseURL)/subscription/profile")!
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.setValue("Bearer \(APIConfig.apiKey)", forHTTPHeaderField: "Authorization")
                request.httpBody = try JSONSerialization.data(withJSONObject: profileRequest)
                
                let (_, response) = try await URLSession.shared.data(for: request)
                if let httpResponse = response as? HTTPURLResponse {
                    print("[ProfileSync] Saved to server: \(httpResponse.statusCode)")
                }
            } catch {
                print("[ProfileSync] Failed to sync: \(error)")
            }
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
