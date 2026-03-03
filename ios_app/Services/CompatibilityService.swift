import Foundation

// MARK: - Compatibility Errors
enum CompatibilityError: LocalizedError {
    case serverError(String)
    case noResponse
    case decodingFailed(Error)
    
    var errorDescription: String? {
        switch self {
        case .serverError(let message):
            return "Server error: \(message)"
        case .noResponse:
            return "No response received from server. Please try again."
        case .decodingFailed(let error):
            return "Failed to process response: \(error.localizedDescription)"
        }
    }
}

final class CompatibilityService: CompatibilityServiceProtocol {
    
    private let networkClient: NetworkClientProtocol
    private let streamSession: URLSession
    
    init(networkClient: NetworkClientProtocol = NetworkClient()) {
        self.networkClient = networkClient
        
        // Configure session for streaming with no caching
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 120
        config.timeoutIntervalForResource = 300
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        config.waitsForConnectivity = true
        self.streamSession = URLSession(configuration: config)
    }
    
    func analyze(request: CompatibilityRequest) async throws -> CompatibilityResponse {
        try await networkClient.request(
            endpoint: APIConfig.compatibility,
            method: "POST",
            body: request
        )
    }
    
    /// Stream-based analysis that calls SSE endpoint and extracts final_json
    func analyzeStream(request: CompatibilityRequest) async throws -> CompatibilityResponse {
        try await analyzeWithProgress(request: request, onStep: { _, _ in })
    }
    
    /// Stream-based analysis with step progress callback
    /// - Parameters:
    ///   - request: Compatibility request
    ///   - onStep: Callback with (stepName, displayText) for each SSE step_start/step_done event
    func analyzeWithProgress(
        request: CompatibilityRequest,
        onStep: @escaping (String, String) -> Void
    ) async throws -> CompatibilityResponse {
        // Build URL
        guard let url = URL(string: APIConfig.baseURL + APIConfig.compatibilityStream) else {
            throw URLError(.badURL)
        }
        
        print("[CompatibilityService] Calling: \(url.absoluteString)")
        
        // Create request with SSE headers
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("text/event-stream", forHTTPHeaderField: "Accept")
        urlRequest.setValue("Bearer \(APIConfig.apiKey)", forHTTPHeaderField: "Authorization")
        urlRequest.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
        urlRequest.httpBody = try JSONEncoder().encode(request)
        
        // DEBUG: Log the JSON being sent
        if let jsonBody = urlRequest.httpBody, let jsonString = String(data: jsonBody, encoding: .utf8) {
            print("[CompatibilityService] DEBUG: Sending JSON body:")
            print("[CompatibilityService] DEBUG: user_email in JSON = \(jsonString.contains("user_email") ? "PRESENT" : "MISSING")")
            // Print just the user_email part
            if let range = jsonString.range(of: "user_email") {
                let start = jsonString.index(range.lowerBound, offsetBy: -1, limitedBy: jsonString.startIndex) ?? range.lowerBound
                let end = jsonString.index(range.upperBound, offsetBy: 50, limitedBy: jsonString.endIndex) ?? jsonString.endIndex
                print("[CompatibilityService] DEBUG: user_email snippet: \(jsonString[start..<end])...")
            }
        }
        
        // Make streaming request
        let (bytes, response) = try await streamSession.bytes(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        print("[CompatibilityService] Status: \(httpResponse.statusCode)")
        
        guard httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        var finalJsonData: Data?
        var currentEvent = ""
        
        // Parse SSE stream line by line
        for try await line in bytes.lines {
            print("[SSE] \(line.prefix(120))")
            
            if line.hasPrefix("event:") {
                currentEvent = line.replacingOccurrences(of: "event:", with: "").trimmingCharacters(in: .whitespaces)
            } else if line.hasPrefix("data:") {
                // IMPORTANT: Only strip the SSE "data:" prefix, not all occurrences
                let dataString = String(line.dropFirst(5)).trimmingCharacters(in: .whitespaces)
                
                // Handle step events for progress UI
                if currentEvent == "step_start" || currentEvent == "step_done" {
                    if let data = dataString.data(using: .utf8),
                       let stepInfo = try? JSONDecoder().decode(StepEvent.self, from: data) {
                        await MainActor.run {
                            onStep(stepInfo.step, stepInfo.display ?? stepInfo.step)
                        }
                    }
                } else if currentEvent == "error" {
                    // Server sent an error event — extract message and throw
                    var serverMessage = "Unknown server error"
                    if let data = dataString.data(using: .utf8),
                       let errorInfo = try? JSONDecoder().decode(SSEErrorEvent.self, from: data) {
                        serverMessage = errorInfo.message
                    } else {
                        serverMessage = dataString
                    }
                    print("[CompatibilityService] SERVER ERROR: \(serverMessage)")
                    throw CompatibilityError.serverError(serverMessage)
                } else if currentEvent == "final_json" {
                    finalJsonData = dataString.data(using: .utf8)
                    print("[CompatibilityService] Got final_json: \(dataString.prefix(200))...")
                    break // Found what we need
                }
            }
        }
        
        guard let data = finalJsonData else {
            print("[CompatibilityService] ERROR: No final_json found in stream")
            throw CompatibilityError.noResponse
        }
        
        // Decode the final_json payload
        let decoder = JSONDecoder()
        do {
            let result = try decoder.decode(CompatibilityResponse.self, from: data)
            print("[CompatibilityService] Decoded successfully, analysisData: \(result.analysisData != nil)")
            print("[CompatibilityService] SESSION_ID from response: \(result.sessionId ?? "NIL")")
            print("[CompatibilityService] DEBUG hardNoFlags: \(String(describing: result.hardNoFlags))")
            print("[CompatibilityService] DEBUG rejectionReasons: \(result.hardNoFlags?.rejectionReasons ?? [])")
            print("[CompatibilityService] DEBUG doshaSummary: \(String(describing: result.doshaSummary))")
            // Debug chart_data
            print("[CompatibilityService] boy: \(result.analysisData?.boy != nil)")
            print("[CompatibilityService] boy.chartData: \(result.analysisData?.boy?.chartData != nil)")
            if let boyChart = result.analysisData?.boy?.chartData {
                print("[CompatibilityService] boy.chartData.d1 count: \(boyChart.d1.count)")
            }
            return result
        } catch let error as CompatibilityError {
            throw error  // Re-throw our custom errors
        } catch {
            print("[CompatibilityService] Decode error: \(error)")
            throw CompatibilityError.decodingFailed(error)
        }
    }
    
    /// Follow-up question for Ask Destiny feature
    func followUp(request: CompatibilityFollowUpRequest) async throws -> CompatibilityFollowUpResponse {
        print("[CompatibilityService] Follow-up request with SESSION_ID: \(request.sessionId)")
        return try await networkClient.request(
            endpoint: APIConfig.compatibilityFollowUp,
            method: "POST",
            body: request
        )
    }
}

// MARK: - SSE Step Event
struct StepEvent: Decodable {
    let step: String
    let display: String?
}

// MARK: - SSE Error Event
struct SSEErrorEvent: Decodable {
    let message: String
}
