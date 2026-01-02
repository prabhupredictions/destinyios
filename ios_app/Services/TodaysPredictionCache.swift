import Foundation

/// Local cache for today's prediction to avoid redundant API calls
/// Caches by date - automatically invalidates at midnight
class TodaysPredictionCache {
    static let shared = TodaysPredictionCache()
    
    private let responseKey = "todaysPredictionResponse"
    private let dateKey = "todaysPredictionDate"
    
    private init() {}
    
    /// Get cached prediction if it's from today
    func get() -> TodaysPredictionResponse? {
        guard let cachedDate = UserDefaults.standard.string(forKey: dateKey),
              cachedDate == todayString,
              let data = UserDefaults.standard.data(forKey: responseKey)
        else {
            return nil
        }
        
        do {
            let response = try JSONDecoder().decode(TodaysPredictionResponse.self, from: data)
            print("[TodaysPredictionCache] Cache hit for \(todayString)")
            return response
        } catch {
            print("[TodaysPredictionCache] Failed to decode cached response: \(error)")
            return nil
        }
    }
    
    /// Cache today's prediction
    func set(_ response: TodaysPredictionResponse) {
        do {
            let data = try JSONEncoder().encode(response)
            UserDefaults.standard.set(data, forKey: responseKey)
            UserDefaults.standard.set(todayString, forKey: dateKey)
            print("[TodaysPredictionCache] Cached prediction for \(todayString)")
        } catch {
            print("[TodaysPredictionCache] Failed to encode response: \(error)")
        }
    }
    
    /// Clear cache (useful for testing or force refresh)
    func clear() {
        UserDefaults.standard.removeObject(forKey: responseKey)
        UserDefaults.standard.removeObject(forKey: dateKey)
        print("[TodaysPredictionCache] Cache cleared")
    }
    
    /// Today's date string in format matching backend
    private var todayString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
}
