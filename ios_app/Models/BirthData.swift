import Foundation

struct BirthData: Codable, Equatable, Sendable, Identifiable {
    var id: String { "\(dob)_\(time)_\(latitude)_\(longitude)" }
    
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
    
    /// Round a coordinate to 6 decimal places (backend validation requirement)
    private static func roundCoordinate(_ value: Double) -> Double {
        (value * 1_000_000).rounded() / 1_000_000
    }
    
    // Default initializer - auto-rounds coordinates
    init(
        dob: String,
        time: String,
        latitude: Double,
        longitude: Double,
        cityOfBirth: String? = nil,
        ayanamsa: String = "lahiri",
        houseSystem: String = "whole_sign"
    ) {
        self.dob = dob
        self.time = time
        self.latitude = Self.roundCoordinate(latitude)
        self.longitude = Self.roundCoordinate(longitude)
        self.cityOfBirth = cityOfBirth
        self.ayanamsa = ayanamsa
        self.houseSystem = houseSystem
    }
    
    // Custom decoder to handle missing optional fields - auto-rounds coordinates
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        dob = try container.decode(String.self, forKey: .dob)
        time = try container.decode(String.self, forKey: .time)
        latitude = Self.roundCoordinate(try container.decode(Double.self, forKey: .latitude))
        longitude = Self.roundCoordinate(try container.decode(Double.self, forKey: .longitude))
        cityOfBirth = try container.decodeIfPresent(String.self, forKey: .cityOfBirth)
        ayanamsa = try container.decodeIfPresent(String.self, forKey: .ayanamsa) ?? "lahiri"
        houseSystem = try container.decodeIfPresent(String.self, forKey: .houseSystem) ?? "whole_sign"
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
