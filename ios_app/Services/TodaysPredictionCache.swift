import Foundation

/// Local cache for today's prediction to avoid redundant API calls
/// Caches by userEmail + profileId + date - automatically invalidates at midnight or profile switch
class TodaysPredictionCache {
    static let shared = TodaysPredictionCache()
    
    private let responsePrefixKey = "todaysPrediction_response"
    private let datePrefixKey = "todaysPrediction_date"
    
    private init() {}
    
    /// Profile context for scoped keys
    private var profileContext: ProfileContextManager { .shared }
    
    /// Get current user's email for cache keys
    private var currentUserEmail: String {
        UserDefaults.standard.string(forKey: "userEmail") ?? "guest"
    }
    
    /// Get profile-scoped response key
    private var responseKey: String {
        profileContext.profileScopedKey(responsePrefixKey)
    }
    
    /// Get profile-scoped date key
    private var dateKey: String {
        profileContext.profileScopedKey(datePrefixKey)
    }
    
    /// Get cached prediction if it's from today AND for current profile
    func get() -> TodaysPredictionResponse? {
        let key = responseKey
        let dKey = dateKey
        print("[TodaysPredictionCache] Looking for key: \(key)")
        
        guard let cachedDate = UserDefaults.standard.string(forKey: dKey),
              cachedDate == todayString,
              let data = UserDefaults.standard.data(forKey: key)
        else {
            print("[TodaysPredictionCache] Cache miss - no data for key: \(key)")
            return nil
        }
        
        do {
            let response = try JSONDecoder().decode(TodaysPredictionResponse.self, from: data)
            print("[TodaysPredictionCache] Cache hit for profile \(profileContext.activeProfileId) on \(todayString)")
            return response
        } catch {
            print("[TodaysPredictionCache] Failed to decode cached response: \(error)")
            return nil
        }
    }
    
    /// Cache today's prediction for current profile
    func set(_ response: TodaysPredictionResponse) {
        do {
            let data = try JSONEncoder().encode(response)
            UserDefaults.standard.set(data, forKey: responseKey)
            UserDefaults.standard.set(todayString, forKey: dateKey)
            print("[TodaysPredictionCache] Cached prediction for profile \(profileContext.activeProfileId) on \(todayString)")
        } catch {
            print("[TodaysPredictionCache] Failed to encode response: \(error)")
        }
    }
    
    /// Clear cache for current profile
    func clear() {
        UserDefaults.standard.removeObject(forKey: responseKey)
        UserDefaults.standard.removeObject(forKey: dateKey)
        print("[TodaysPredictionCache] Cache cleared for profile \(profileContext.activeProfileId)")
    }
    
    /// Clear cache for a specific user (used on logout) - clears ALL profiles
    func clear(forUser email: String) {
        // Clear all profile caches for this user
        let allKeys = UserDefaults.standard.dictionaryRepresentation().keys
        let userPrefix = "\(email)_"
        
        for key in allKeys {
            if (key.hasPrefix(responsePrefixKey) || key.hasPrefix(datePrefixKey)) && key.contains(userPrefix) {
                UserDefaults.standard.removeObject(forKey: key)
            }
        }
        print("[TodaysPredictionCache] Cleared all profile caches for \(email)")
    }
    
    /// Clear cache for a specific profile
    func clear(forProfile profileId: String) {
        let email = currentUserEmail
        let profileResponseKey = "\(responsePrefixKey)_\(email)_\(profileId)"
        let profileDateKey = "\(datePrefixKey)_\(email)_\(profileId)"
        
        UserDefaults.standard.removeObject(forKey: profileResponseKey)
        UserDefaults.standard.removeObject(forKey: profileDateKey)
        print("[TodaysPredictionCache] Cache cleared for profile \(profileId)")
    }
    
    /// Today's date string in format matching backend
    private var todayString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
}

