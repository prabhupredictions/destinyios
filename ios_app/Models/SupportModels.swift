import Foundation

// MARK: - Chat Thread (Matches verified API)
struct ChatThread: Codable, Identifiable {
    let id: String
    let title: String
    let preview: String
    let area: String
    let messageCount: Int
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id, title, preview, area
        case messageCount = "message_count"
        case updatedAt = "updated_at"
    }
}

// MARK: - Feedback Request (Matches verified API)
struct FeedbackRequest: Codable {
    let predictionId: String
    let rating: Int
    let feedbackText: String
    let userEmail: String
    let query: String
    let predictionText: String
    let area: String
    
    enum CodingKeys: String, CodingKey {
        case predictionId = "prediction_id"
        case feedbackText = "feedback_text"
        case userEmail = "user_email"
        case predictionText = "prediction_text"
        case rating, query, area
    }
}

// MARK: - Compatibility Request
struct CompatibilityRequest: Codable {
    let boy: BirthDetails
    let girl: BirthDetails
    var sessionId: String?
    var userEmail: String?
    
    enum CodingKeys: String, CodingKey {
        case boy, girl
        case sessionId = "session_id"
        case userEmail = "user_email"
    }
}

// MARK: - Birth Details (For Compatibility)
struct BirthDetails: Codable {
    let dob: String
    let time: String
    let lat: Double
    let lon: Double
    var name: String = "Native"
    var place: String = "Unknown"
}

// MARK: - Compatibility Response
struct CompatibilityResponse: Codable {
    let sessionId: String?
    let status: String
    
    enum CodingKeys: String, CodingKey {
        case sessionId = "session_id"
        case status
    }
}

// MARK: - User (Placeholder for Auth)
struct User: Codable, Identifiable {
    let id: String
    var email: String?
    var name: String?
}
