import Foundation

// MARK: - SSE Event Types
/// Events streamed from the prediction API
enum SSEEventType: String {
    case started = "started"
    case thought = "thought"
    case action = "action"
    case observation = "observation"
    case finalAnswer = "final_answer"
    case systemOpinion = "system_opinion"
    case error = "error"
    case complete = "complete"
}

/// Parsed SSE event
struct SSEEvent {
    let type: SSEEventType
    let data: [String: Any]
    
    var displayText: String? {
        data["display"] as? String
    }
    
    var content: String? {
        data["content"] as? String
    }
    
    var step: Int? {
        data["step"] as? Int
    }
}

// MARK: - Streaming Prediction Service
/// Service that streams predictions via SSE, showing thinking/observations like Claude
actor StreamingPredictionService {
    static let shared = StreamingPredictionService()
    
    private init() {}
    
    /// Stream prediction with real-time events
    /// Returns an AsyncThrowingStream of SSE events
    func predictStream(request: PredictionRequest) -> AsyncThrowingStream<SSEEvent, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    try await streamPrediction(request: request, continuation: continuation)
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
    
    private func streamPrediction(
        request: PredictionRequest,
        continuation: AsyncThrowingStream<SSEEvent, Error>.Continuation
    ) async throws {
        // Build URL
        let urlString = "\(APIConfig.baseURL)\(APIConfig.predictStream)"
        guard let url = URL(string: urlString) else {
            throw StreamingError.invalidURL
        }
        
        // Create request
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("text/event-stream", forHTTPHeaderField: "Accept")
        urlRequest.setValue(APIConfig.apiKey, forHTTPHeaderField: "X-API-Key")
        
        // Encode body
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        
        // Create stream request body
        let streamRequest = StreamPredictionRequest(
            query: request.query,
            birthData: request.birthData,
            sessionId: request.sessionId,
            conversationId: request.conversationId,
            userEmail: request.userEmail
        )
        urlRequest.httpBody = try encoder.encode(streamRequest)
        
        // Start streaming with URLSession bytes
        let (bytes, response) = try await URLSession.shared.bytes(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw StreamingError.serverError((response as? HTTPURLResponse)?.statusCode ?? 0)
        }
        
        // Parse SSE events line by line
        var currentEvent: String?
        var currentData: String = ""
        
        for try await line in bytes.lines {
            if line.hasPrefix("event:") {
                currentEvent = String(line.dropFirst(6)).trimmingCharacters(in: .whitespaces)
            } else if line.hasPrefix("data:") {
                currentData = String(line.dropFirst(5)).trimmingCharacters(in: .whitespaces)
            } else if line.isEmpty && !currentData.isEmpty {
                // Empty line = end of event, parse it
                if let event = currentEvent,
                   let eventType = SSEEventType(rawValue: event),
                   let jsonData = currentData.data(using: .utf8),
                   let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] {
                    
                    let sseEvent = SSEEvent(type: eventType, data: json)
                    continuation.yield(sseEvent)
                    
                    // Finish on complete or final_answer
                    if eventType == .complete {
                        continuation.finish()
                        return
                    }
                }
                
                // Reset for next event
                currentEvent = nil
                currentData = ""
            }
        }
        
        continuation.finish()
    }
}

// MARK: - Stream Request
struct StreamPredictionRequest: Encodable {
    let query: String
    let birthData: BirthData
    let sessionId: String?
    let conversationId: String?
    let userEmail: String?
    let stream: Bool = true
}

// MARK: - Errors
enum StreamingError: LocalizedError {
    case invalidURL
    case serverError(Int)
    case parseError
    
    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid streaming URL"
        case .serverError(let code): return "Server error: \(code)"
        case .parseError: return "Failed to parse SSE event"
        }
    }
}
