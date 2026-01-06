import Foundation

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
        let userType: String
        let isGeneratedEmail: Bool
        let questionsAsked: Int
        let questionsLimit: Int
        let questionsRemaining: Int
        let canAsk: Bool
        let isPremium: Bool
        let subscriptionStatus: String?
        let subscriptionExpiresAt: String?
        let birthProfile: BirthProfileResponse?
        
        enum CodingKeys: String, CodingKey {
            case userEmail = "user_email"
            case userName = "user_name"
            case userType = "user_type"
            case isGeneratedEmail = "is_generated_email"
            case questionsAsked = "questions_asked"
            case questionsLimit = "questions_limit"
            case questionsRemaining = "questions_remaining"
            case canAsk = "can_ask"
            case isPremium = "is_premium"
            case subscriptionStatus = "subscription_status"
            case subscriptionExpiresAt = "subscription_expires_at"
            case birthProfile = "birth_profile"
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
        
        let decoder = JSONDecoder()
        return try decoder.decode(ProfileResponse.self, from: data)
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
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ProfileError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw ProfileError.serverError(statusCode: httpResponse.statusCode)
        }
        
        print("[ProfileService] Profile saved successfully")
    }
    
    // MARK: - Restore Profile Locally
    
    /// Restore profile data to local storage (UserDefaults + DataManager)
    @MainActor
    func restoreProfileLocally(_ profile: ProfileResponse, dataManager: DataManager = .shared) throws -> Bool {
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
            dataManager.saveBirthProfile(userProfile)
            
            print("[ProfileService] Restored birth profile locally for \(savedEmail)")
        }
        
        return true
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
    
    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid URL"
        case .invalidResponse: return "Invalid server response"
        case .serverError(let code): return "Server error: \(code)"
        case .decodingError: return "Failed to decode response"
        }
    }
}
