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
    
    // MARK: - User Type
    
    /// Get user type based on profile
    var userType: UserType {
        if isPremium { return .premium }
        if isGuestEmail { return .guest }
        return .registered
    }
    
    // MARK: - Quota Logic
    
    /// Question limit based on user type
    var questionLimit: Int {
        userType.questionLimit
    }
    
    /// Check if user can ask another question
    var canAskQuestion: Bool {
        totalQuestionsAsked < questionLimit
    }
    
    /// Remaining questions
    var remainingQuestions: Int {
        max(0, questionLimit - totalQuestionsAsked)
    }
    
    /// Increment question count
    func incrementQuestionCount() {
        totalQuestionsAsked += 1
        updatedAt = Date()
    }
    
    /// Get quota status
    var quotaStatus: QuotaStatus {
        QuotaStatus(userType: userType, questionsUsed: totalQuestionsAsked)
    }
}

