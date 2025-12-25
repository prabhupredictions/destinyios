import Foundation

// MARK: - Feedback Service
/// Service to submit user feedback/ratings on AI predictions to the backend
/// Connects to the /feedback/submit endpoint for RL training

actor FeedbackService {
    static let shared = FeedbackService()
    
    private init() {}
    
    /// Submit a rating for an AI response
    /// - Parameters:
    ///   - predictionId: Unique ID from the prediction (if available)
    ///   - rating: 1-5 star rating
    ///   - query: The user's original question
    ///   - predictionText: The AI's response text
    ///   - area: Life area category
    func submitRating(
        predictionId: String?,
        rating: Int,
        query: String,
        predictionText: String,
        area: String = "general"
    ) async throws {
        let userEmail = UserDefaults.standard.string(forKey: "userEmail") ?? ""
        
        // Create request matching backend UnifiedFeedbackRequest
        let request = UnifiedFeedbackPayload(
            predictionId: predictionId,
            sessionId: UUID().uuidString,
            conversationId: nil,
            userEmail: userEmail.isEmpty ? nil : userEmail,
            query: query,
            predictionText: predictionText,
            area: area,
            subArea: nil,
            ascendant: nil,
            system: "vedic",
            rating: rating
        )
        
        // Build URL
        let urlString = "\(APIConfig.baseURL)\(APIConfig.feedback)"
        guard let url = URL(string: urlString) else {
            throw FeedbackError.invalidURL
        }
        
        // Create request
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue(APIConfig.apiKey, forHTTPHeaderField: "X-API-Key")
        
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        urlRequest.httpBody = try encoder.encode(request)
        
        // Submit
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw FeedbackError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw FeedbackError.serverError(httpResponse.statusCode, errorMessage)
        }
        
        print("✅ Feedback submitted successfully: \(rating) stars")
    }
}

// MARK: - Request Payload
private struct UnifiedFeedbackPayload: Encodable {
    let predictionId: String?
    let sessionId: String?
    let conversationId: String?
    let userEmail: String?
    let query: String
    let predictionText: String
    let area: String
    let subArea: String?
    let ascendant: String?
    let system: String
    let rating: Int
}

// MARK: - Errors
enum FeedbackError: LocalizedError {
    case invalidURL
    case invalidResponse
    case serverError(Int, String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid feedback URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .serverError(let code, let message):
            return "Server error (\(code)): \(message)"
        }
    }
}
