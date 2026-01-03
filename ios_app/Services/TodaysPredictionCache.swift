import Foundation

/// Local cache for today's prediction to avoid redundant API calls
/// Caches by userEmail + date - automatically invalidates at midnight or user switch
class TodaysPredictionCache {
    static let shared = TodaysPredictionCache()
    
    private let responsePrefixKey = "todaysPrediction_response_"
    private let datePrefixKey = "todaysPrediction_date_"
    
    private init() {}
    
    /// Get current user's email for cache keys
    private var currentUserEmail: String {
        UserDefaults.standard.string(forKey: "userEmail") ?? "guest"
    }
    
    /// Get cached prediction if it's from today AND for current user
    func get() -> TodaysPredictionResponse? {
        let email = currentUserEmail
        let responseKey = "\(responsePrefixKey)\(email)"
        let dateKey = "\(datePrefixKey)\(email)"
        
        guard let cachedDate = UserDefaults.standard.string(forKey: dateKey),
              cachedDate == todayString,
              let data = UserDefaults.standard.data(forKey: responseKey)
        else {
            return nil
        }
        
        do {
            let response = try JSONDecoder().decode(TodaysPredictionResponse.self, from: data)
            print("[TodaysPredictionCache] Cache hit for \(email) on \(todayString)")
            return response
        } catch {
            print("[TodaysPredictionCache] Failed to decode cached response: \(error)")
            return nil
        }
    }
    
    /// Cache today's prediction for current user
    func set(_ response: TodaysPredictionResponse) {
        let email = currentUserEmail
        let responseKey = "\(responsePrefixKey)\(email)"
        let dateKey = "\(datePrefixKey)\(email)"
        
        do {
            let data = try JSONEncoder().encode(response)
            UserDefaults.standard.set(data, forKey: responseKey)
            UserDefaults.standard.set(todayString, forKey: dateKey)
            print("[TodaysPredictionCache] Cached prediction for \(email) on \(todayString)")
        } catch {
            print("[TodaysPredictionCache] Failed to encode response: \(error)")
        }
    }
    
    /// Clear cache for current user
    func clear() {
        let email = currentUserEmail
        let responseKey = "\(responsePrefixKey)\(email)"
        let dateKey = "\(datePrefixKey)\(email)"
        
        UserDefaults.standard.removeObject(forKey: responseKey)
        UserDefaults.standard.removeObject(forKey: dateKey)
        print("[TodaysPredictionCache] Cache cleared for \(email)")
    }
    
    /// Clear cache for a specific user (used on logout)
    func clear(forUser email: String) {
        let responseKey = "\(responsePrefixKey)\(email)"
        let dateKey = "\(datePrefixKey)\(email)"
        
        UserDefaults.standard.removeObject(forKey: responseKey)
        UserDefaults.standard.removeObject(forKey: dateKey)
        print("[TodaysPredictionCache] Cache cleared for \(email)")
    }
    
    /// Today's date string in format matching backend
    private var todayString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
}

