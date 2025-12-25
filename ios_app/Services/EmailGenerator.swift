import Foundation

/// Generates email from birth data for guest users
struct EmailGenerator {
    
    /// Generate email from birth profile
    /// Format: YYYYMMDD_HHMM_CityPrefix_LatInt_LngInt@daa.com
    static func generate(from profile: UserBirthProfile) -> String {
        generateFromComponents(
            dateOfBirth: profile.dateOfBirth,
            timeOfBirth: profile.timeOfBirth,
            cityOfBirth: profile.cityOfBirth,
            latitude: profile.latitude,
            longitude: profile.longitude
        )
    }
    
    /// Generate email from individual components
    /// Format: YYYYMMDD_HHMM_CityPrefix_LatInt_LngInt@daa.com
    static func generateFromComponents(
        dateOfBirth: String,
        timeOfBirth: String,
        cityOfBirth: String,
        latitude: Double,
        longitude: Double
    ) -> String {
        // Remove separators from date (YYYY-MM-DD -> YYYYMMDD)
        let dob = dateOfBirth.replacingOccurrences(of: "-", with: "")
        
        // Remove separators from time (HH:MM -> HHMM)
        let tob = timeOfBirth.replacingOccurrences(of: ":", with: "")
        
        // Get first 3 letters of city (or "Unk" if empty)
        let city = cityOfBirth.trimmingCharacters(in: .whitespacesAndNewlines)
        let cityPrefix = city.isEmpty ? "Unk" : String(city.prefix(3))
        
        // Get integer part of lat/lng (convert negative to positive)
        let latInt = abs(Int(latitude))
        let lngInt = abs(Int(longitude))
        
        // Combine into email
        return "\(dob)_\(tob)_\(cityPrefix)_\(latInt)_\(lngInt)@daa.com"
    }
    
    /// Validate if email is a generated guest email
    static func isGeneratedEmail(_ email: String) -> Bool {
        email.hasSuffix("@daa.com")
    }
}
