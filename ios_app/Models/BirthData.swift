import Foundation

struct BirthData: Codable, Equatable, Sendable {
    var dob: String           // "YYYY-MM-DD"
    var time: String          // "HH:MM"
    var latitude: Double
    var longitude: Double
    var cityOfBirth: String?
    var ayanamsa: String
    var houseSystem: String
    
    enum CodingKeys: String, CodingKey {
        case dob, time, latitude, longitude
        case cityOfBirth = "city_of_birth"
        case ayanamsa
        case houseSystem = "house_system"
    }
    
    // Default initializer
    init(
        dob: String,
        time: String,
        latitude: Double,
        longitude: Double,
        cityOfBirth: String? = nil,
        ayanamsa: String = "lahiri",
        houseSystem: String = "equal"
    ) {
        self.dob = dob
        self.time = time
        self.latitude = latitude
        self.longitude = longitude
        self.cityOfBirth = cityOfBirth
        self.ayanamsa = ayanamsa
        self.houseSystem = houseSystem
    }
    
    // Custom decoder to handle missing optional fields
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        dob = try container.decode(String.self, forKey: .dob)
        time = try container.decode(String.self, forKey: .time)
        latitude = try container.decode(Double.self, forKey: .latitude)
        longitude = try container.decode(Double.self, forKey: .longitude)
        cityOfBirth = try container.decodeIfPresent(String.self, forKey: .cityOfBirth)
        ayanamsa = try container.decodeIfPresent(String.self, forKey: .ayanamsa) ?? "lahiri"
        houseSystem = try container.decodeIfPresent(String.self, forKey: .houseSystem) ?? "equal"
    }
    
    // Validation
    func isValid() -> Bool {
        // Date format YYYY-MM-DD
        let dateRegex = "^\\d{4}-\\d{2}-\\d{2}$"
        guard dob.range(of: dateRegex, options: .regularExpression) != nil else {
            return false
        }
        
        // Time format HH:MM
        let timeRegex = "^\\d{2}:\\d{2}$"
        guard time.range(of: timeRegex, options: .regularExpression) != nil else {
            return false
        }
        
        // Latitude/Longitude ranges
        guard (-90...90).contains(latitude) && (-180...180).contains(longitude) else {
            return false
        }
        
        return true
    }
}
