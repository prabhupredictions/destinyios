import Foundation
import SwiftData

/// Service for syncing user profiles with server
/// Handles POST (save) and GET (fetch) profile operations
class ProfileService {
    static let shared = ProfileService()
    
    private init() {}
    
    // MARK: - Response Models
    
    struct BirthProfileResponse: Codable {
        let dateOfBirth: String
        let timeOfBirth: String?
        let cityOfBirth: String?
        let latitude: Double?
        let longitude: Double?
        let gender: String?
        let birthTimeUnknown: Bool
        
        enum CodingKeys: String, CodingKey {
            case dateOfBirth = "date_of_birth"
            case timeOfBirth = "time_of_birth"
            case cityOfBirth = "city_of_birth"
            case latitude, longitude, gender
            case birthTimeUnknown = "birth_time_unknown"
        }
    }
    
    struct ProfileResponse: Codable {
        let userEmail: String
        let userName: String?
        let planId: String?
        let isGeneratedEmail: Bool
        let featureUsage: [String: FeatureUsageInfo]?
        let isPremium: Bool
        let subscriptionStatus: String?
        let subscriptionExpiresAt: String?
        let birthProfile: BirthProfileResponse?
        
        // Computed properties for backwards compatibility
        var questionsAsked: Int {
            featureUsage?["ai_questions"]?.overall ?? 0
        }
        
        enum CodingKeys: String, CodingKey {
            case userEmail = "user_email"
            case userName = "user_name"
            case planId = "plan_id"
            case isGeneratedEmail = "is_generated_email"
            case featureUsage = "feature_usage"
            case isPremium = "is_premium"
            case subscriptionStatus = "subscription_status"
            case subscriptionExpiresAt = "subscription_expires_at"
            case birthProfile = "birth_profile"
        }
    }
    
    struct FeatureUsageInfo: Codable {
        let daily: Int?
        let overall: Int?
        let lastUsed: String?
        
        enum CodingKeys: String, CodingKey {
            case daily, overall
            case lastUsed = "last_used"
        }
    }
    
    /// Response from /subscription/register
    struct RegisterResponse: Codable {
        let userEmail: String
        let planId: String?
        let isGeneratedEmail: Bool
        let isPremium: Bool
        let featureUsage: [String: FeatureUsageInfo]?
        let subscriptionStatus: String?
        
        enum CodingKeys: String, CodingKey {
            case userEmail = "user_email"
            case planId = "plan_id"
            case isGeneratedEmail = "is_generated_email"
            case isPremium = "is_premium"
            case featureUsage = "feature_usage"
            case subscriptionStatus = "subscription_status"
        }
    }
    
    // MARK: - Fetch Profile
    
    /// Fetch user profile from server (for restoring on login)
    /// Returns nil if profile not found (404)
    func fetchProfile(email: String) async throws -> ProfileResponse? {
        let urlString = "\(APIConfig.baseURL)/subscription/profile?email=\(email.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? email)"
        
        guard let url = URL(string: urlString) else {
            throw ProfileError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(APIConfig.apiKey)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ProfileError.invalidResponse
        }
        
        if httpResponse.statusCode == 404 {
            // User not found - this is expected for new users
            return nil
        }
        
        guard httpResponse.statusCode == 200 else {
            throw ProfileError.serverError(statusCode: httpResponse.statusCode)
        }
        
        // Debug: Print raw response to see what API returns
        if let jsonString = String(data: data, encoding: .utf8) {
            print("🔍 [ProfileService] Raw API response: \(jsonString)")
        }
        
        let decoder = JSONDecoder()
        let profile = try decoder.decode(ProfileResponse.self, from: data)
        print("🔍 [ProfileService] Decoded birthProfile: \(profile.birthProfile != nil ? "EXISTS" : "NIL")")
        return profile
    }
    
    // MARK: - Register User (with Identity Linking)
    
    /// Register user with platform identity (Apple ID, Google ID)
    /// This supports "Hide My Email" and "New Device" scenarios
    func registerUser(
        email: String,
        isGeneratedEmail: Bool,
        appleId: String? = nil,
        googleId: String? = nil
    ) async throws -> RegisterResponse? {
        guard let url = URL(string: "\(APIConfig.baseURL)/subscription/register") else {
            throw ProfileError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(APIConfig.apiKey)", forHTTPHeaderField: "Authorization")
        
        var body: [String: Any] = [
            "email": email,
            "is_generated_email": isGeneratedEmail
        ]
        if let appleId = appleId {
            body["apple_id"] = appleId
        }
        if let googleId = googleId {
            body["google_id"] = googleId
        }
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ProfileError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw ProfileError.serverError(statusCode: httpResponse.statusCode)
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode(RegisterResponse.self, from: data)
    }
    
    // MARK: - Upgrade Guest to Registered
    
    /// Upgrade guest user to registered user and migrate chat history
    /// Called when a guest signs in with Apple/Google
    /// This migrates chat_threads from old guest email to new registered email
    func upgradeGuestToRegistered(
        oldEmail: String,
        newEmail: String
    ) async throws {
        guard oldEmail != newEmail else {
            print("[ProfileService] upgradeGuestToRegistered: old and new email same, skipping")
            return
        }
        
        guard let url = URL(string: "\(APIConfig.baseURL)\(APIConfig.subscriptionUpgrade)") else {
            throw ProfileError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(APIConfig.apiKey)", forHTTPHeaderField: "Authorization")
        
        let body: [String: Any] = [
            "old_email": oldEmail,
            "new_email": newEmail
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        print("[ProfileService] 🔄 Upgrading guest to registered...")
        print("   - old_email: \(oldEmail)")
        print("   - new_email: \(newEmail)")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ProfileError.invalidResponse
        }
        
        if httpResponse.statusCode == 200 {
            print("[ProfileService] ✅ Guest upgrade successful - chat history migrated!")
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                print("   - response: \(json)")
            }
        } else {
            print("[ProfileService] ⚠️ Guest upgrade returned status \(httpResponse.statusCode)")
            // Non-fatal - don't throw, just log
        }
    }
    
    // MARK: - Save Profile
    
    /// Save user profile to server (fire and forget)
    func saveProfile(
        email: String,
        userName: String?,
        userType: String,
        isGeneratedEmail: Bool,
        birthProfile: BirthProfileData
    ) async throws {
        guard let url = URL(string: "\(APIConfig.baseURL)/subscription/profile") else {
            throw ProfileError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(APIConfig.apiKey)", forHTTPHeaderField: "Authorization")
        
        let body: [String: Any] = [
            "email": email,
            "user_name": userName ?? "",
            "user_type": userType,
            "is_generated_email": isGeneratedEmail,
            "birth_profile": [
                "date_of_birth": birthProfile.dateOfBirth,
                "time_of_birth": birthProfile.timeOfBirth ?? "12:00",
                "city_of_birth": birthProfile.cityOfBirth ?? "",
                "latitude": birthProfile.latitude ?? 0,
                "longitude": birthProfile.longitude ?? 0,
                "gender": birthProfile.gender ?? "",
                "birth_time_unknown": birthProfile.birthTimeUnknown
            ]
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ProfileError.invalidResponse
        }
        
        // Handle 409 Conflict - birth data already taken
        if httpResponse.statusCode == 409 {
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let detail = json["detail"] as? [String: Any],
               let existingEmail = detail["existing_email"] as? String {
                throw ProfileError.birthDataTaken(existingEmail: existingEmail)
            }
            throw ProfileError.birthDataTaken(existingEmail: nil)
        }
        
        guard httpResponse.statusCode == 200 else {
            throw ProfileError.serverError(statusCode: httpResponse.statusCode)
        }
        
        print("[ProfileService] Profile saved successfully")
    }
    
    /// Save user profile to server - overload for BirthData type
    /// Used by AuthViewModel for guest-to-registered upgrade with birth data carry-forward
    func saveProfile(
        email: String,
        userName: String,
        birthData: BirthData,
        isGuest: Bool,
        gender: String = ""  // BirthData doesn't have gender, so pass separately
    ) async throws -> ProfileResponse? {
        guard let url = URL(string: "\(APIConfig.baseURL)/subscription/profile") else {
            throw ProfileError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(APIConfig.apiKey)", forHTTPHeaderField: "Authorization")
        
        let body: [String: Any] = [
            "email": email,
            "user_name": userName,
            "is_generated_email": isGuest,
            "birth_profile": [
                "date_of_birth": birthData.dob,
                "time_of_birth": birthData.time,
                "city_of_birth": birthData.cityOfBirth ?? "",
                "latitude": birthData.latitude,
                "longitude": birthData.longitude,
                "gender": gender,
                "birth_time_unknown": false
            ]
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ProfileError.invalidResponse
        }
        
        // Handle 409 Conflict - birth data already taken by another registered user
        if httpResponse.statusCode == 409 {
            // Try to parse the existing_email from response
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let detail = json["detail"] as? [String: Any],
               let existingEmail = detail["existing_email"] as? String {
                throw ProfileError.birthDataTaken(existingEmail: existingEmail)
            }
            throw ProfileError.birthDataTaken(existingEmail: nil)
        }
        
        guard httpResponse.statusCode == 200 else {
            throw ProfileError.serverError(statusCode: httpResponse.statusCode)
        }
        
        print("[ProfileService] Profile saved successfully for \(email)")
        
        // Decode and return the response
        // Note: ProfileResponse has explicit CodingKeys, don't use .convertFromSnakeCase
        let decoder = JSONDecoder()
        return try decoder.decode(ProfileResponse.self, from: data)
    }
    
    // MARK: - Restore Profile Locally
    
    /// Restore profile data to local storage (UserDefaults + DataManager)
    @MainActor
    func restoreProfileLocally(_ profile: ProfileResponse, dataManager: DataManager? = nil) throws -> Bool {
        let dm = dataManager ?? DataManager.shared
        let defaults = UserDefaults.standard
        let savedEmail = profile.userEmail
        
        // Store user info
        if let name = profile.userName, !name.isEmpty {
            defaults.set(name, forKey: "userName")
        }
        defaults.set(savedEmail, forKey: "userEmail")
        
        // Store quota info (User-Scoped AND Global for session)
        let quotaKey = StorageKeys.userKey(for: StorageKeys.quotaUsed, email: savedEmail)
        defaults.set(profile.questionsAsked, forKey: quotaKey)
        defaults.set(profile.questionsAsked, forKey: "quotaUsed") // Global for UI
        defaults.set(profile.isPremium, forKey: "isPremium")
        
        // Store birth profile if exists
        if let birth = profile.birthProfile {
            // Create user-scoped keys
            let dataKey = StorageKeys.userKey(for: StorageKeys.userBirthData, email: savedEmail)
            let hasDataKey = StorageKeys.userKey(for: StorageKeys.hasBirthData, email: savedEmail)
            let genderKey = StorageKeys.userKey(for: StorageKeys.userGender, email: savedEmail)
            let timeUnknownKey = StorageKeys.userKey(for: StorageKeys.birthTimeUnknown, email: savedEmail)
            
            // Create BirthData for UserDefaults
            let birthData = BirthData(
                dob: birth.dateOfBirth,
                time: birth.timeOfBirth ?? "12:00",
                latitude: birth.latitude ?? 0,
                longitude: birth.longitude ?? 0,
                cityOfBirth: birth.cityOfBirth
            )
            
            if let encoded = try? JSONEncoder().encode(birthData) {
                defaults.set(encoded, forKey: dataKey)
                defaults.set(true, forKey: hasDataKey)
                
                // Update Global keys for session
                defaults.set(encoded, forKey: "userBirthData") // Temp global for legacy/UI
                defaults.set(true, forKey: "hasBirthData")
            }
            
            if let gender = birth.gender {
                defaults.set(gender, forKey: genderKey)
            }
            defaults.set(birth.birthTimeUnknown, forKey: timeUnknownKey)
            
            // Save to SwiftData
            let userProfile = UserBirthProfile(
                email: savedEmail,
                isGuestEmail: profile.isGeneratedEmail,
                dateOfBirth: birth.dateOfBirth,
                timeOfBirth: birth.timeOfBirth ?? "12:00",
                cityOfBirth: birth.cityOfBirth ?? "",
                latitude: birth.latitude ?? 0,
                longitude: birth.longitude ?? 0,
                placeId: nil,
                gender: birth.gender,
                timeUnknown: birth.birthTimeUnknown
            )
            dm.saveBirthProfile(userProfile)
            
            print("[ProfileService] Restored birth profile locally for \(savedEmail)")
            
            // Create self partner profile for Switch Profile feature
            Task {
                await createSelfPartnerProfile(
                    email: savedEmail,
                    userName: profile.userName ?? "Me",
                    birthProfile: birth
                )
            }
        }
        
        return true
    }
    
    // MARK: - Create Self Partner Profile
    
    /// Creates a PartnerProfile with is_self=true for the account owner
    /// This enables the Switch Profile feature
    func createSelfPartnerProfile(
        email: String,
        userName: String,
        birthProfile: BirthProfileResponse
    ) async {
        do {
            // First, check if self profile already exists
            let existingProfiles = try await PartnerProfileService.shared.fetchPartners(email: email)
            if existingProfiles.contains(where: { $0.isSelf }) {
                print("[ProfileService] Self profile already exists, skipping creation")
                return
            }
            
            // Create the self profile
            let selfProfile = PartnerProfile(
                id: UUID().uuidString,
                name: userName.components(separatedBy: " ").first ?? userName,
                gender: birthProfile.gender ?? "male",
                dateOfBirth: birthProfile.dateOfBirth,
                timeOfBirth: birthProfile.timeOfBirth,
                cityOfBirth: birthProfile.cityOfBirth,
                latitude: birthProfile.latitude,
                longitude: birthProfile.longitude,
                timezone: nil,
                birthTimeUnknown: birthProfile.birthTimeUnknown,
                consentGiven: true,
                isSynced: false,
                isSelf: true,
                isActive: true
            )
            
            let created = try await PartnerProfileService.shared.createPartner(selfProfile, email: email)
            print("[ProfileService] Created self partner profile: \(created.name)")
            
            // Set as active profile in ProfileContextManager
            await MainActor.run {
                ProfileContextManager.shared.loadActiveProfile(context: DataManager.shared.context)
            }
            
        } catch {
            print("[ProfileService] Failed to create self partner profile: \(error)")
        }
    }
}

// MARK: - Birth Profile Data (for API request)

struct BirthProfileData {
    let dateOfBirth: String
    let timeOfBirth: String?
    let cityOfBirth: String?
    let latitude: Double?
    let longitude: Double?
    let gender: String?
    let birthTimeUnknown: Bool
}

// MARK: - Errors

enum ProfileError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case serverError(statusCode: Int)
    case decodingError
    case birthDataTaken(existingEmail: String?)  // Birth data belongs to another registered user
    
    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid URL"
        case .invalidResponse: return "Invalid server response"
        case .serverError(let code): return "Server error: \(code)"
        case .decodingError: return "Failed to decode response"
        case .birthDataTaken(let email):
            if let email = email {
                return "This birth data is already registered. Please sign in as \(email)"
            }
            return "This birth data is already registered. Please sign in."
        }
    }
}
