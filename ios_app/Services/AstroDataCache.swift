import Foundation
import CryptoKit

/// Caches static astrological data locally to avoid redundant API calls.
/// - Full chart: Cached forever (keyed by birth data hash)
/// - Dasha: Cached per year (keyed by birth hash + year)
/// - Transits: Cached per year (keyed by birth hash + year)
class AstroDataCache {
    static let shared = AstroDataCache()
    
    private let fullChartKey = "astro_full_chart"
    private let dashaPrefixKey = "astro_dasha"
    private let transitsPrefixKey = "astro_transits"
    private let birthHashKey = "astro_birth_hash"
    
    private init() {}
    
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
    
    // MARK: - Full Chart Cache (Forever)
    
    func getFullChart(birthHash: String) -> UserAstroDataResponse? {
        // Check if hash matches stored hash
        guard let storedHash = UserDefaults.standard.string(forKey: birthHashKey),
              storedHash == birthHash,
              let data = UserDefaults.standard.data(forKey: fullChartKey)
        else {
            return nil
        }
        
        do {
            let response = try JSONDecoder().decode(UserAstroDataResponse.self, from: data)
            print("[AstroDataCache] Full chart cache hit for \(birthHash)")
            return response
        } catch {
            print("[AstroDataCache] Failed to decode full chart: \(error)")
            return nil
        }
    }
    
    func setFullChart(_ response: UserAstroDataResponse, birthHash: String) {
        do {
            let data = try JSONEncoder().encode(response)
            UserDefaults.standard.set(data, forKey: fullChartKey)
            UserDefaults.standard.set(birthHash, forKey: birthHashKey)
            print("[AstroDataCache] Cached full chart for \(birthHash)")
        } catch {
            print("[AstroDataCache] Failed to encode full chart: \(error)")
        }
    }
    
    // MARK: - Dasha Cache (Per Year)
    
    func getDasha(birthHash: String, year: Int) -> DashaResponse? {
        let key = "\(dashaPrefixKey)_\(birthHash)_\(year)"
        guard let data = UserDefaults.standard.data(forKey: key) else {
            return nil
        }
        
        do {
            let response = try JSONDecoder().decode(DashaResponse.self, from: data)
            print("[AstroDataCache] Dasha cache hit for \(birthHash), year \(year)")
            return response
        } catch {
            print("[AstroDataCache] Failed to decode dasha: \(error)")
            return nil
        }
    }
    
    func setDasha(_ response: DashaResponse, birthHash: String, year: Int) {
        let key = "\(dashaPrefixKey)_\(birthHash)_\(year)"
        do {
            let data = try JSONEncoder().encode(response)
            UserDefaults.standard.set(data, forKey: key)
            print("[AstroDataCache] Cached dasha for \(birthHash), year \(year)")
        } catch {
            print("[AstroDataCache] Failed to encode dasha: \(error)")
        }
    }
    
    // MARK: - Transits Cache (Per Year)
    
    func getTransits(birthHash: String, year: Int) -> TransitResponse? {
        let key = "\(transitsPrefixKey)_\(birthHash)_\(year)"
        guard let data = UserDefaults.standard.data(forKey: key) else {
            return nil
        }
        
        do {
            let response = try JSONDecoder().decode(TransitResponse.self, from: data)
            print("[AstroDataCache] Transits cache hit for \(birthHash), year \(year)")
            return response
        } catch {
            print("[AstroDataCache] Failed to decode transits: \(error)")
            return nil
        }
    }
    
    func setTransits(_ response: TransitResponse, birthHash: String, year: Int) {
        let key = "\(transitsPrefixKey)_\(birthHash)_\(year)"
        do {
            let data = try JSONEncoder().encode(response)
            UserDefaults.standard.set(data, forKey: key)
            print("[AstroDataCache] Cached transits for \(birthHash), year \(year)")
        } catch {
            print("[AstroDataCache] Failed to encode transits: \(error)")
        }
    }
    
    // MARK: - Clear All (when birth data changes)
    
    func clearAll(birthHash: String) {
        UserDefaults.standard.removeObject(forKey: fullChartKey)
        UserDefaults.standard.removeObject(forKey: birthHashKey)
        
        // Clear all dasha and transit keys for this birth hash
        // Note: UserDefaults doesn't have a "clear by prefix" method,
        // so we track used years or clear all astro_ keys
        let allKeys = UserDefaults.standard.dictionaryRepresentation().keys
        for key in allKeys {
            if key.hasPrefix(dashaPrefixKey) || key.hasPrefix(transitsPrefixKey) {
                UserDefaults.standard.removeObject(forKey: key)
            }
        }
        
        print("[AstroDataCache] Cleared all cache for \(birthHash)")
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
