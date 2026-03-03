import Foundation

// MARK: - Streaming Prediction Service
/// SSE client for real-time streaming predictions with progress updates

class StreamingPredictionService {
    static let shared = StreamingPredictionService()
    private init() {}
    
    // MARK: - Event Types
    
    enum StreamEvent {
        case thought(step: Int, content: String, display: String)
        case action(step: Int, tool: String, display: String)
        case observation(step: Int, display: String)
        case finalAnswer(content: String)
        case answer(response: PredictionResponse)
        case done(totalSteps: Int)
        case error(message: String)
    }
    
    // MARK: - Streaming Predict
    
    /// Stream predictions with progress updates via SSE
    /// Has 30 second timeout, falls back to regular API on failure
    func predictStream(
        request: PredictionRequest,
        onEvent: @escaping (StreamEvent) -> Void
    ) async throws {
        let url = URL(string: "\(APIConfig.baseURL)/vedic/api/predict/stream")!
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("Bearer \(APIConfig.apiKey)", forHTTPHeaderField: "Authorization")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("text/event-stream", forHTTPHeaderField: "Accept")
        urlRequest.timeoutInterval = 60  // 60 second timeout for long predictions
        
        // Build request body using correct BirthData properties
        let body: [String: Any] = [
            "query": request.query,
            "birth_data": [
                "dob": request.birthData.dob,  // YYYY-MM-DD
                "time": request.birthData.time,  // HH:MM
                "city_of_birth": request.birthData.cityOfBirth ?? "",
                "latitude": request.birthData.latitude,
                "longitude": request.birthData.longitude,
                "ayanamsa": request.birthData.ayanamsa,
                "house_system": request.birthData.houseSystem
            ],
            "session_id": request.sessionId ?? UUID().uuidString,
            "conversation_id": request.conversationId ?? UUID().uuidString,
            "user_email": request.userEmail ?? "",
            "profile_id": ProfileContextManager.shared.activeProfileId  // Profile-scoped threads
        ]
        
        urlRequest.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        // Use dedicated URLSession configuration for SSE
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 60
        config.timeoutIntervalForResource = 120
        config.waitsForConnectivity = true
        let session = URLSession(configuration: config)
        
        // Use bytes for SSE streaming
        let (asyncBytes, response) = try await session.bytes(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw StreamError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            print("[SSE] HTTP error: \(httpResponse.statusCode)")
            throw StreamError.invalidResponse
        }
        
        // Parse SSE events
        var currentEventType = ""
        var currentData = ""
        
        for try await line in asyncBytes.lines {
            // Check for cancellation
            try Task.checkCancellation()
            
            if line.hasPrefix("event: ") {
                currentEventType = String(line.dropFirst(7))
            } else if line.hasPrefix("data: ") {
                currentData = String(line.dropFirst(6))
                
                // Process complete event on main actor
                if let event = parseEvent(type: currentEventType, data: currentData) {
                    await MainActor.run {
                        onEvent(event)
                    }
                    
                    // If done event, break out of loop
                    if case .done = event {
                        break
                    }
                }
                
                currentEventType = ""
                currentData = ""
            }
        }
    }
    
    // MARK: - Event Parsing
    
    private func parseEvent(type: String, data: String) -> StreamEvent? {
        guard let jsonData = data.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
            return nil
        }
        
        switch type {
        case "thought":
            return .thought(
                step: json["step"] as? Int ?? 0,
                content: json["content"] as? String ?? "",
                display: json["display"] as? String ?? "💭 Thinking..."
            )
            
        case "action":
            return .action(
                step: json["step"] as? Int ?? 0,
                tool: json["tool"] as? String ?? "",
                display: json["display"] as? String ?? "🔧 Processing..."
            )
            
        case "observation":
            return .observation(
                step: json["step"] as? Int ?? 0,
                display: json["display"] as? String ?? "📊 Analyzing..."
            )
            
        case "final_answer":
            return .finalAnswer(
                content: json["content"] as? String ?? ""
            )
            
        case "answer":
            // Parse full response with all required fields
            let response = PredictionResponse(
                predictionId: json["prediction_id"] as? String ?? "",
                sessionId: json["session_id"] as? String ?? "",
                conversationId: json["conversation_id"] as? String ?? "",
                status: json["status"] as? String ?? "completed",
                answer: json["answer"] as? String ?? "",
                answerSummary: json["answer_summary"] as? String,
                timing: nil,  // Parse separately if needed
                confidence: json["confidence"] as? Double ?? 0.5,
                confidenceLabel: json["confidence_label"] as? String ?? "MEDIUM",
                supportingFactors: json["supporting_factors"] as? [String] ?? [],
                challengingFactors: json["challenging_factors"] as? [String] ?? [],
                followUpSuggestions: json["follow_up_suggestions"] as? [String] ?? [],
                lifeArea: json["life_area"] as? String ?? "",
                executionTimeMs: json["execution_time_ms"] as? Double ?? 0,
                createdAt: json["created_at"] as? String ?? ISO8601DateFormatter().string(from: Date()),
                reasoningTrace: nil,
                reasoningSummary: json["reasoning_summary"] as? String,
                advice: json["advice"] as? String,
                sources: json["sources"] as? [String],
                query: json["query"] as? String,
                subArea: json["sub_area"] as? String,
                ascendant: json["ascendant"] as? String,
                plannerUsed: json["planner_used"] as? String,
                llmCalls: json["llm_calls"] as? Int,
                trainingSampleId: json["training_sample_id"] as? String,
                completedAt: json["completed_at"] as? String
            )
            return .answer(response: response)
            
        case "done":
            return .done(totalSteps: json["total_steps"] as? Int ?? 0)
            
        case "error":
            // Backend sends 'error' for exceptions, but 'message' for quota errors
            let errorMsg = json["error"] as? String ?? json["message"] as? String ?? "Unknown error"
            
            // If quota error with reason, create user-friendly message
            if let reason = json["reason"] as? String {
                switch reason {
                case "daily_limit_reached":
                    return .error(message: "Daily limit reached. Try again tomorrow.")
                case "overall_limit_reached":
                    return .error(message: "free_limit_reached".localized)
                default:
                    return .error(message: errorMsg)
                }
            }
            return .error(message: errorMsg)
            
        default:
            return nil
        }
    }
    
    enum StreamError: Error {
        case invalidResponse
        case connectionFailed
    }
}
