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
    
    // Selection state for placeholders (mandatory field tracking)
    var isDateSelected = false
    var isTimeSelected = false
    
    // MARK: - UI State
    var isLoading = false
    var errorMessage: String?
    var showLocationSearch = false
    var birthDataTakenEmail: String? = nil  // Set when guest tries to use registered user's birth data
    var birthDataTakenProvider: String? = nil  // "apple" or "google" - the provider of the conflicting account
    
    // MARK: - Dependencies
    private let dataManager: DataManager
    private var userEmail: String?
    private var isGuest: Bool = false
    
    // MARK: - Init
    init(dataManager: DataManager? = nil) {
        self.dataManager = dataManager ?? DataManager.shared
        reloadUserInfo()
    }
    
    // MARK: - Computed Properties
    
    var isValid: Bool {
        !userName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !cityOfBirth.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        latitude != 0 && longitude != 0 &&
        isDateSelected &&
        (isTimeSelected || timeUnknown) &&
        !gender.isEmpty  // Gender is mandatory
    }
    
    var formattedDate: String {
        guard isDateSelected else { return "select_date".localized }
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        return formatter.string(from: dateOfBirth)
    }
    
    var formattedTime: String {
        if timeUnknown { return "birth_time_unknown".localized }
        guard isTimeSelected else { return "select_time".localized }
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
    /// Reload user email and guest status from UserDefaults.
    /// IMPORTANT: Call this after sign-in completes to refresh cached values.
    func reloadUserInfo() {
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
            
            // NOTE: Server profile sync is now handled by BirthDataView.registerWithBackend()
            // which properly awaits the result and blocks on birth data conflicts.
            // We removed the duplicate sync here to prevent race conditions.
            
            // Sync chat history from server (restore any past conversations)
            // Works for both guests and registered users
            // - Guests: recover history if they erase data or login from another phone
            // - Registered: restore history on new device
            // Clear-before-sync in sync services prevents duplicates
            Task {
                await ChatHistorySyncService.shared.syncFromServer(userEmail: email, dataManager: dataManager)
                await CompatibilityHistoryService.shared.syncFromServer(userEmail: email)
            }
            
            // Create self partner profile for Switch Profile feature
            // This creates a PartnerProfile with is_self=true so user can switch back to themselves
            Task {
                await ProfileService.shared.createSelfPartnerProfile(
                    email: email,
                    userName: userName.isEmpty ? "Me" : userName,
                    birthProfile: ProfileService.BirthProfileResponse(
                        dateOfBirth: formattedDOB,
                        timeOfBirth: formattedTOB,
                        cityOfBirth: cityOfBirth,
                        latitude: latitude,
                        longitude: longitude,
                        gender: gender.isEmpty ? nil : gender,
                        birthTimeUnknown: timeUnknown
                    )
                )
            }
            
            return true
        } catch {
            errorMessage = "Failed to save birth data"
            return false
        }
    }
    
    /// Result of server profile sync
    enum SyncResult {
        case success
        case birthDataTaken(existingEmail: String?, provider: String?)
        case error(String)
    }
    
    /// Sync birth data to server profile - async version that can detect conflicts
    private func syncToServerProfileAsync(email: String) async -> SyncResult {
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
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("[ProfileSync] Server response: \(httpResponse.statusCode)")
                
                // Handle 409 Conflict - birth data already belongs to registered user
                if httpResponse.statusCode == 409 {
                    if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let detail = json["detail"] as? [String: Any] {
                        let existingEmail = detail["existing_email"] as? String
                        let provider = detail["provider"] as? String
                        return .birthDataTaken(existingEmail: existingEmail, provider: provider)
                    }
                    return .birthDataTaken(existingEmail: nil, provider: nil)
                }
                
                if httpResponse.statusCode == 200 {
                    return .success
                } else {
                    return .error("Server error: \(httpResponse.statusCode)")
                }
            }
            return .success
        } catch {
            print("[ProfileSync] Failed to sync: \(error)")
            return .error(error.localizedDescription)
        }
    }
    
    /// Fire-and-forget version for backwards compatibility
    private func syncToServerProfile(email: String) {
        Task {
            _ = await syncToServerProfileAsync(email: email)
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
