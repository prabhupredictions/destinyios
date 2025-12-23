import Foundation

// MARK: - Prediction Request
struct PredictionRequest: Codable, Sendable {
    let query: String
    let birthData: BirthData
    var sessionId: String?
    var conversationId: String?
    var userEmail: String?
    var platform: String = "ios"
    var includeReasoningTrace: Bool = false
    
    enum CodingKeys: String, CodingKey {
        case query
        case birthData = "birth_data"
        case sessionId = "session_id"
        case conversationId = "conversation_id"
        case userEmail = "user_email"
        case platform
        case includeReasoningTrace = "include_reasoning_trace"
    }
}

// MARK: - Prediction Response
struct PredictionResponse: Codable, Identifiable, Sendable {
    let predictionId: String
    let sessionId: String
    let conversationId: String
    let status: String
    let answer: String
    let answerSummary: String?
    let timing: TimingPrediction?
    let confidence: Double
    let confidenceLabel: String
    let supportingFactors: [String]
    let challengingFactors: [String]
    let followUpSuggestions: [String]
    let lifeArea: String
    let executionTimeMs: Double
    let createdAt: String
    
    var id: String { predictionId }
    
    enum CodingKeys: String, CodingKey {
        case predictionId = "prediction_id"
        case sessionId = "session_id"
        case conversationId = "conversation_id"
        case status, answer
        case answerSummary = "answer_summary"
        case timing, confidence
        case confidenceLabel = "confidence_label"
        case supportingFactors = "supporting_factors"
        case challengingFactors = "challenging_factors"
        case followUpSuggestions = "follow_up_suggestions"
        case lifeArea = "life_area"
        case executionTimeMs = "execution_time_ms"
        case createdAt = "created_at"
    }
}

// MARK: - Timing Prediction
struct TimingPrediction: Codable, Sendable {
    let period: String?
    let dasha: String?
    let transit: String?
    let confidence: String
}

// MARK: - Network Error
enum NetworkError: Error {
    case invalidURL
    case noData
    case decodingError(Error)
    case serverError(String)
    case unauthorized
}
