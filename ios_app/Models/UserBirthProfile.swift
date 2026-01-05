import Foundation
import SwiftData

/// User birth profile stored in SwiftData
@Model
final class UserBirthProfile {
    @Attribute(.unique) var id: String
    var email: String               // Actual email or generated for guests
    var isGuestEmail: Bool          // true if auto-generated
    var dateOfBirth: String         // YYYY-MM-DD
    var timeOfBirth: String         // HH:MM
    var cityOfBirth: String
    var latitude: Double
    var longitude: Double
    var placeId: String?            // Google/Apple place ID
    var gender: String?
    var timeUnknown: Bool
    
    // Quota tracking (total, not monthly)
    var totalQuestionsAsked: Int
    var isPremium: Bool
    
    var createdAt: Date
    var updatedAt: Date
    
    init(
        id: String = UUID().uuidString,
        email: String,
        isGuestEmail: Bool = false,
        dateOfBirth: String,
        timeOfBirth: String,
        cityOfBirth: String,
        latitude: Double,
        longitude: Double,
        placeId: String? = nil,
        gender: String? = nil,
        timeUnknown: Bool = false,
        totalQuestionsAsked: Int = 0,
        isPremium: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.email = email
        self.isGuestEmail = isGuestEmail
        self.dateOfBirth = dateOfBirth
        self.timeOfBirth = timeOfBirth
        self.cityOfBirth = cityOfBirth
        self.latitude = latitude
        self.longitude = longitude
        self.placeId = placeId
        self.gender = gender
        self.timeUnknown = timeUnknown
        self.totalQuestionsAsked = totalQuestionsAsked
        self.isPremium = isPremium
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    // MARK: - Quota Helpers
    
    /// Increment question count
    func incrementQuestionCount() {
        totalQuestionsAsked += 1
        updatedAt = Date()
    }
}

// MARK: - Codable

extension UserBirthProfile: Codable {
    enum CodingKeys: String, CodingKey {
        case id, email, isGuestEmail
        case dateOfBirth, timeOfBirth, cityOfBirth
        case latitude, longitude, placeId, gender, timeUnknown
        case totalQuestionsAsked, isPremium, createdAt, updatedAt
    }
    
    convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let id = try container.decode(String.self, forKey: .id)
        let email = try container.decode(String.self, forKey: .email)
        let isGuestEmail = try container.decode(Bool.self, forKey: .isGuestEmail)
        let dateOfBirth = try container.decode(String.self, forKey: .dateOfBirth)
        let timeOfBirth = try container.decode(String.self, forKey: .timeOfBirth)
        let cityOfBirth = try container.decode(String.self, forKey: .cityOfBirth)
        let latitude = try container.decode(Double.self, forKey: .latitude)
        let longitude = try container.decode(Double.self, forKey: .longitude)
        let placeId = try container.decodeIfPresent(String.self, forKey: .placeId)
        let gender = try container.decodeIfPresent(String.self, forKey: .gender)
        let timeUnknown = try container.decode(Bool.self, forKey: .timeUnknown)
        let totalQuestionsAsked = try container.decode(Int.self, forKey: .totalQuestionsAsked)
        let isPremium = try container.decode(Bool.self, forKey: .isPremium)
        let createdAt = try container.decode(Date.self, forKey: .createdAt)
        let updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        
        self.init(
            id: id,
            email: email,
            isGuestEmail: isGuestEmail,
            dateOfBirth: dateOfBirth,
            timeOfBirth: timeOfBirth,
            cityOfBirth: cityOfBirth,
            latitude: latitude,
            longitude: longitude,
            placeId: placeId,
            gender: gender,
            timeUnknown: timeUnknown,
            totalQuestionsAsked: totalQuestionsAsked,
            isPremium: isPremium,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(email, forKey: .email)
        try container.encode(isGuestEmail, forKey: .isGuestEmail)
        try container.encode(dateOfBirth, forKey: .dateOfBirth)
        try container.encode(timeOfBirth, forKey: .timeOfBirth)
        try container.encode(cityOfBirth, forKey: .cityOfBirth)
        try container.encode(latitude, forKey: .latitude)
        try container.encode(longitude, forKey: .longitude)
        try container.encode(placeId, forKey: .placeId)
        try container.encode(gender, forKey: .gender)
        try container.encode(timeUnknown, forKey: .timeUnknown)
        try container.encode(totalQuestionsAsked, forKey: .totalQuestionsAsked)
        try container.encode(isPremium, forKey: .isPremium)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
    }
}

