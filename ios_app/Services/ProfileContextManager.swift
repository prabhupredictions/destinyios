import Foundation
import SwiftData
import Combine

/// Manages the active profile context for the Switch Profile feature.
/// This singleton tracks which profile is currently active and provides
/// profile-scoped storage keys for caching.
@Observable
class ProfileContextManager {
    static let shared = ProfileContextManager()
    
    // MARK: - State
    
    /// The currently active profile (nil defaults to self)
    private(set) var activeProfile: PartnerProfile?
    
    /// Loading state during profile switch
    private(set) var isSwitching: Bool = false
    
    /// Error from last switch attempt
    private(set) var switchError: String?
    
    // MARK: - Computed Properties
    
    /// ID of the active profile
    /// Returns "self" for the main user's own profile (isSelf=true) to match backend convention
    var activeProfileId: String {
        // Always return "self" for the user's own profile to match backend profile_id convention
        if activeProfile?.isSelf == true {
            return "self"
        }
        return activeProfile?.id ?? "self"
    }
    
    /// Name of the active profile for display
    var activeProfileName: String {
        activeProfile?.name ?? userName
    }
    
    /// True if using the account owner's own profile
    var isUsingSelf: Bool {
        activeProfile?.isSelf ?? true
    }
    
    /// The main user's email - ALWAYS use this for plan/quota validation
    var ownerEmail: String {
        UserDefaults.standard.string(forKey: "userEmail") ?? "guest"
    }
    
    /// Main user's display name
    var userName: String {
        UserDefaults.standard.string(forKey: "userName") ?? "You"
    }
    
    // MARK: - Birth Data for Active Profile
    
    /// Get birth data for the currently active profile
    /// Used by Chat, Match, and Predictions
    var activeBirthData: UserBirthData? {
        guard let profile = activeProfile else {
            // Fall back to stored userBirthData
            return loadUserBirthData()
        }
        
        return UserBirthData(
            dob: profile.dateOfBirth,
            time: profile.timeOfBirth ?? "12:00",
            latitude: profile.latitude ?? 0,
            longitude: profile.longitude ?? 0,
            ayanamsa: UserDefaults.standard.string(forKey: "ayanamsa") ?? "lahiri",
            houseSystem: UserDefaults.standard.string(forKey: "houseSystem") ?? "placidus",
            cityOfBirth: profile.cityOfBirth ?? "",
            gender: profile.gender,
            birthTimeUnknown: profile.birthTimeUnknown
        )
    }
    
    // MARK: - Private Init
    
    private init() {
        // Load persisted active profile on init
        loadActiveProfile()
    }
    
    // MARK: - Profile Switching
    
    /// Switch to a different profile
    /// - Parameter profile: The profile to switch to
    /// - Returns: Success or failure
    @MainActor
    func switchTo(_ profile: PartnerProfile) async -> Bool {
        // 1. Check if main user can switch profiles (plan check)
        guard await canSwitchProfiles() else {
            switchError = "Upgrade to Premium to switch profiles"
            return false
        }
        
        // 2. Show loading state
        isSwitching = true
        switchError = nil
        
        do {
            // 3. Call backend to switch profile
            try await switchProfileOnServer(profileId: profile.id)
            
            // 4. Update local state
            activeProfile?.isActive = false
            profile.isActive = true
            activeProfile = profile
            
            // 5. Persist active profile ID
            UserDefaults.standard.set(profile.id, forKey: "activeProfileId")
            
            // 6. Post notification for observers
            NotificationCenter.default.post(
                name: .activeProfileChanged,
                object: profile
            )
            
            print("[ProfileContextManager] Switched to profile: \(profile.name)")
            isSwitching = false
            return true
            
        } catch {
            switchError = "Failed to switch profile: \(error.localizedDescription)"
            isSwitching = false
            return false
        }
    }
    
    /// Switch back to the account owner's profile
    @MainActor
    func switchToSelf(context: ModelContext) async -> Bool {
        guard let selfProfile = getSelfProfile(context: context) else {
            switchError = "Self profile not found"
            return false
        }
        return await switchTo(selfProfile)
    }
    
    // MARK: - Profile-Scoped Storage Keys
    
    /// Generate a profile-scoped storage key
    /// - Parameter baseKey: The base key (e.g., "todaysPrediction_response")
    /// - Returns: Key scoped to current profile: "{baseKey}_{email}_{profileId}"
    func profileScopedKey(_ baseKey: String) -> String {
        "\(baseKey)_\(ownerEmail)_\(activeProfileId)"
    }
    
    /// Reset active profile state on logout
    /// Clears activeProfile and UserDefaults to prevent stale state on re-login
    func resetActiveProfile() {
        activeProfile = nil
        UserDefaults.standard.removeObject(forKey: "activeProfileId")
        print("[ProfileContextManager] Reset active profile state for logout")
    }
    
    // MARK: - Private Helpers
    
    /// Check if user's plan allows profile switching
    private func canSwitchProfiles() async -> Bool {
        // Call backend to check feature access
        guard let encodedEmail = ownerEmail.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "\(APIConfig.baseURL)/subscription/can-access?email=\(encodedEmail)&feature=switch_profile") else {
            return false
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(APIConfig.apiKey)", forHTTPHeaderField: "Authorization")
        
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            if let json = try? JSONDecoder().decode(FeatureAccessResponse.self, from: data) {
                return json.canAccess
            }
        } catch {
            print("[ProfileContextManager] Failed to check feature access: \(error)")
        }
        
        return false
    }
    
    /// Switch profile on server
    private func switchProfileOnServer(profileId: String) async throws {
        guard let url = URL(string: "\(APIConfig.baseURL)/subscription/profiles/switch") else {
            throw ProfileSwitchError.invalidURL
        }
        
        struct SwitchRequest: Codable {
            let userEmail: String
            let profileId: String
            
            enum CodingKeys: String, CodingKey {
                case userEmail = "user_email"
                case profileId = "profile_id"
            }
        }
        
        let switchRequest = SwitchRequest(userEmail: ownerEmail, profileId: profileId)
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(APIConfig.apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONEncoder().encode(switchRequest)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ProfileSwitchError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            if httpResponse.statusCode == 403 {
                throw ProfileSwitchError.premiumRequired
            }
            throw ProfileSwitchError.serverError(statusCode: httpResponse.statusCode)
        }
        
        print("[ProfileContextManager] Server switch successful")
    }
    
    /// Load active profile from persistence
    private func loadActiveProfile() {
        // Will be called later with context when app initializes
    }
    
    /// Load active profile with SwiftData context
    /// Priority: 1) Profile with isActive=true (from server sync), 2) UserDefaults, 3) Self profile
    @MainActor
    func loadActiveProfile(context: ModelContext) {
        // First: Check for profile marked as active (from server sync)
        let activeDescriptor = FetchDescriptor<PartnerProfile>(
            predicate: #Predicate<PartnerProfile> { $0.isActive == true }
        )
        
        if let activeProfiles = try? context.fetch(activeDescriptor), 
           let serverActiveProfile = activeProfiles.first {
            // Partner profiles must have valid coordinates for predictions
            // If incomplete, fall through to self profile for consistency
            let hasValidBirthData = serverActiveProfile.isSelf || 
                (serverActiveProfile.latitude != nil && serverActiveProfile.longitude != nil)
            
            if hasValidBirthData {
                activeProfile = serverActiveProfile
                UserDefaults.standard.set(serverActiveProfile.id, forKey: "activeProfileId")
                print("[ProfileContextManager] Loaded active profile from server sync: \(serverActiveProfile.name)")
                
                // Notify observers to reload with new profile's data
                NotificationCenter.default.post(name: .activeProfileChanged, object: serverActiveProfile)
                return
            } else {
                print("[ProfileContextManager] Server active profile '\(serverActiveProfile.name)' has incomplete birth data, falling through to self")
                // Clear the is_active flag locally to prevent reselection
                serverActiveProfile.isActive = false
            }
        }
        
        // Second: Check UserDefaults (local persistence from previous session)
        if let activeId = UserDefaults.standard.string(forKey: "activeProfileId") {
            let predicate = #Predicate<PartnerProfile> { $0.id == activeId }
            let descriptor = FetchDescriptor<PartnerProfile>(predicate: predicate)
            
            if let profiles = try? context.fetch(descriptor), let profile = profiles.first {
                // Same validation as server sync: partner must have valid coordinates
                let hasValidBirthData = profile.isSelf || 
                    (profile.latitude != nil && profile.longitude != nil)
                
                if hasValidBirthData {
                    activeProfile = profile
                    print("[ProfileContextManager] Loaded active profile from UserDefaults: \(profile.name)")
                    
                    // Notify observers to reload with restored profile's data
                    NotificationCenter.default.post(name: .activeProfileChanged, object: profile)
                    return
                } else {
                    print("[ProfileContextManager] UserDefaults profile '\(profile.name)' has incomplete birth data, falling through to self")
                }
            }
        }
        
        // Third: Default to self profile
        if let selfProfile = getSelfProfile(context: context) {
            activeProfile = selfProfile
            print("[ProfileContextManager] Defaulting to self profile: \(selfProfile.name)")
        }
    }
    
    /// Get the self profile from local storage
    @MainActor
    func getSelfProfile(context: ModelContext) -> PartnerProfile? {
        let predicate = #Predicate<PartnerProfile> { $0.isSelf == true }
        let descriptor = FetchDescriptor<PartnerProfile>(predicate: predicate)
        return try? context.fetch(descriptor).first
    }
    
    /// Load user birth data from UserDefaults (fallback)
    private func loadUserBirthData() -> UserBirthData? {
        guard let data = UserDefaults.standard.data(forKey: "userBirthData") else {
            return nil
        }
        return try? JSONDecoder().decode(UserBirthData.self, from: data)
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let activeProfileChanged = Notification.Name("activeProfileChanged")
}

// MARK: - Errors

enum ProfileSwitchError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case serverError(statusCode: Int)
    case premiumRequired
    case profileNotFound
    
    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid URL"
        case .invalidResponse: return "Invalid server response"
        case .serverError(let code): return "Server error: \(code)"
        case .premiumRequired: return "Upgrade to Premium to switch profiles"
        case .profileNotFound: return "Profile not found"
        }
    }
}
