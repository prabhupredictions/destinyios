import Foundation
import CryptoKit

/// Caches static astrological data locally to avoid redundant API calls.
/// All keys include userEmail + profileId to prevent data mixing between profiles.
/// - Full chart: Cached forever (keyed by email + profileId + birth data hash)
/// - Dasha: Cached per year (keyed by email + profileId + birth hash + year)
/// - Transits: Cached per year (keyed by email + profileId + birth hash + year)
class AstroDataCache {
    static let shared = AstroDataCache()
    
    // Version bump to invalidate old cache when model changes
    // v2: Added formation and reason fields to YogaDetail
    private let fullChartPrefix = "astro_chart_v2"
    private let dashaPrefix = "astro_dasha"
    private let transitsPrefix = "astro_transits"
    
    private init() {}
    
    /// Profile context for scoped keys
    private var profileContext: ProfileContextManager { .shared }
    
    /// Get current user's email for cache keys
    private var currentUserEmail: String {
        UserDefaults.standard.string(forKey: "userEmail") ?? "guest"
    }
    
    // MARK: - Birth Data Hash
    
    /// Generate a hash from birth data to use as cache key
    func birthHash(_ birthData: UserBirthData) -> String {
        let components = [
            birthData.dob,
            birthData.time,
            String(birthData.latitude),
            String(birthData.longitude),
            birthData.ayanamsa,
            birthData.houseSystem
        ]
        let combined = components.joined(separator: "|")
        
        // Simple hash using SHA256
        if let data = combined.data(using: .utf8) {
            let hash = SHA256.hash(data: data)
            return hash.compactMap { String(format: "%02x", $0) }.prefix(16).joined()
        }
        return combined.hashValue.description
    }
    
    // MARK: - Full Chart Cache (Forever, per profile)
    
    func getFullChart(birthHash: String) -> UserAstroDataResponse? {
        let key = profileContext.profileScopedKey("\(fullChartPrefix)_\(birthHash)")
        
        guard let data = UserDefaults.standard.data(forKey: key) else {
            return nil
        }
        
        do {
            let response = try JSONDecoder().decode(UserAstroDataResponse.self, from: data)
            print("[AstroDataCache] Full chart cache hit for profile \(profileContext.activeProfileId)")
            return response
        } catch {
            print("[AstroDataCache] Failed to decode full chart: \(error)")
            return nil
        }
    }
    
    func setFullChart(_ response: UserAstroDataResponse, birthHash: String) {
        let key = profileContext.profileScopedKey("\(fullChartPrefix)_\(birthHash)")
        
        do {
            let data = try JSONEncoder().encode(response)
            UserDefaults.standard.set(data, forKey: key)
            print("[AstroDataCache] Cached full chart for profile \(profileContext.activeProfileId)")
        } catch {
            print("[AstroDataCache] Failed to encode full chart: \(error)")
        }
    }
    
    // MARK: - Dasha Cache (Per Year, per profile)
    
    func getDasha(birthHash: String, year: Int) -> DashaResponse? {
        let key = profileContext.profileScopedKey("\(dashaPrefix)_\(birthHash)_\(year)")
        
        guard let data = UserDefaults.standard.data(forKey: key) else {
            return nil
        }
        
        do {
            let response = try JSONDecoder().decode(DashaResponse.self, from: data)
            print("[AstroDataCache] Dasha cache hit for profile \(profileContext.activeProfileId), year \(year)")
            return response
        } catch {
            print("[AstroDataCache] Failed to decode dasha: \(error)")
            return nil
        }
    }
    
    func setDasha(_ response: DashaResponse, birthHash: String, year: Int) {
        let key = profileContext.profileScopedKey("\(dashaPrefix)_\(birthHash)_\(year)")
        
        do {
            let data = try JSONEncoder().encode(response)
            UserDefaults.standard.set(data, forKey: key)
            print("[AstroDataCache] Cached dasha for profile \(profileContext.activeProfileId), year \(year)")
        } catch {
            print("[AstroDataCache] Failed to encode dasha: \(error)")
        }
    }
    
    // MARK: - Transits Cache (Per Year, per profile)
    
    func getTransits(birthHash: String, year: Int) -> TransitResponse? {
        let key = profileContext.profileScopedKey("\(transitsPrefix)_\(birthHash)_\(year)")
        
        guard let data = UserDefaults.standard.data(forKey: key) else {
            return nil
        }
        
        do {
            let response = try JSONDecoder().decode(TransitResponse.self, from: data)
            print("[AstroDataCache] Transits cache hit for profile \(profileContext.activeProfileId), year \(year)")
            return response
        } catch {
            print("[AstroDataCache] Failed to decode transits: \(error)")
            return nil
        }
    }
    
    func setTransits(_ response: TransitResponse, birthHash: String, year: Int) {
        let key = profileContext.profileScopedKey("\(transitsPrefix)_\(birthHash)_\(year)")
        
        do {
            let data = try JSONEncoder().encode(response)
            UserDefaults.standard.set(data, forKey: key)
            print("[AstroDataCache] Cached transits for profile \(profileContext.activeProfileId), year \(year)")
        } catch {
            print("[AstroDataCache] Failed to encode transits: \(error)")
        }
    }
    
    // MARK: - Clear Cache for User
    
    /// Clear all astro cache for a specific user (used on logout)
    func clearAll(forUser email: String) {
        let allKeys = UserDefaults.standard.dictionaryRepresentation().keys
        let userPrefix = "_\(email)_"
        
        for key in allKeys {
            if (key.hasPrefix(fullChartPrefix) || key.hasPrefix(dashaPrefix) || key.hasPrefix(transitsPrefix))
                && key.contains(userPrefix) {
                UserDefaults.standard.removeObject(forKey: key)
            }
        }
        
        print("[AstroDataCache] Cleared all cache for \(email)")
    }
    
    /// Clear all astro cache for current user
    func clearAll() {
        clearAll(forUser: currentUserEmail)
    }
    
    // MARK: - Convenience Methods
    
    /// Get cached full chart for birth data, returns nil if not cached
    func getFullChart(birthData: UserBirthData) -> UserAstroDataResponse? {
        let hash = birthHash(birthData)
        return getFullChart(birthHash: hash)
    }
    
    /// Get cached dasha for birth data and year
    func getDasha(birthData: UserBirthData, year: Int) -> DashaResponse? {
        let hash = birthHash(birthData)
        return getDasha(birthHash: hash, year: year)
    }
    
    /// Get cached transits for birth data and year
    func getTransits(birthData: UserBirthData, year: Int) -> TransitResponse? {
        let hash = birthHash(birthData)
        return getTransits(birthHash: hash, year: year)
    }
}

