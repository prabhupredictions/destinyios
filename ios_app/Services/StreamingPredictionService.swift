import Foundation
import os

// MARK: - Streaming Prediction Service
/// SSE client for real-time streaming predictions with progress updates

class StreamingPredictionService {
    static let shared = StreamingPredictionService()
    private init() {}

    /// Instruments signpost log — bracketed around the .finalAnswer → .done
    /// window so the coalescer's main-thread cost can be measured under
    /// Time Profiler. Task 12 requirement.
    private static let signpostLog = OSLog(
        subsystem: "com.destinyai.streaming",
        category: "predict_stream"
    )

    // MARK: - Test Hooks

    /// Optional URLSession factory used by tests to inject MockURLProtocol.
    /// Production code path leaves this nil and uses the locally-configured session below.
    static var urlSessionFactory: (() -> URLSession)? = nil

    // MARK: - Event Types
    
    enum StreamEvent {
        case thought(step: Int, content: String, display: String)
        case action(step: Int, tool: String, display: String)
        case observation(step: Int, display: String)
        case progressStep(phase: String, group: Int, groupCount: Int, isDone: Bool, displayKey: String?, elapsedMs: Int)
        case finalAnswer(content: String)
        case answer(response: PredictionResponse)
        case done(totalSteps: Int)
        case backpressure(retryAfterSeconds: Int)
        case error(message: String)
    }
    
    // MARK: - Streaming Predict
    
    /// Stream predictions with progress updates via SSE
    /// 270s timeout (10% headroom under Cloud Run 300s); per-send Idempotency-Key
    /// lets the server replay a cached final answer if a client retries inside
    /// the 5-minute cache window. Prevents double-billing on transient network
    /// loss after .done.
    func predictStream(
        request: PredictionRequest,
        idempotencyKey: String,
        onEvent: @escaping (StreamEvent) -> Void
    ) async throws {
        let url = URL(string: "\(APIConfig.baseURL)/vedic/api/predict/stream")!

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        // W7 — send session JWT when available, else fall back to bundled API key.
        // Adding X-API-Key alongside lets backend's APIKeyAuthMiddleware identify
        // the iOS app while SessionAuthMiddleware reads the Bearer for user identity.
        urlRequest.setValue(NetworkClient.authBearer(), forHTTPHeaderField: "Authorization")
        urlRequest.setValue(APIConfig.apiKey, forHTTPHeaderField: "X-API-Key")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("text/event-stream", forHTTPHeaderField: "Accept")
        // Per docs/superpowers/plans/2026-06-28-streaming-typewriter-v2.md task 12:
        // - Idempotency-Key lets the server replay a cached final answer if a
        //   client retries inside the 5-minute cache window. Prevents
        //   double-billing on transient network loss after .done.
        urlRequest.setValue(idempotencyKey, forHTTPHeaderField: "Idempotency-Key")
        urlRequest.timeoutInterval = 270  // 10% headroom under Cloud Run's 300s
        
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
            "language": request.language,
            "response_style": request.responseStyle ?? "",
            "response_length": request.responseLength ?? "",
            "profile_id": ProfileContextManager.shared.activeProfileId  // Profile-scoped threads
        ]
        
        urlRequest.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        // Use dedicated URLSession configuration for SSE
        let session: URLSession = {
            if let factory = StreamingPredictionService.urlSessionFactory {
                return factory()
            }
            let config = URLSessionConfiguration.default
            config.timeoutIntervalForRequest = 270   // 10% headroom under Cloud Run's 300s
            config.timeoutIntervalForResource = 270
            config.waitsForConnectivity = false  // airplane mode must surface in ≤5s, not 5min
            return URLSession(configuration: config)
        }()

        defer {
            // Per task 12: invalidateAndCancel() actually terminates the body
            // byte stream when the consuming Task is cancelled, not just the
            // Swift Task wrapper. Without this, cancelled streams still
            // consume LLM tokens server-side.
            session.invalidateAndCancel()
        }

        // Instruments signpost — bracket the .finalAnswer → .done window so
        // the coalescer's main-thread cost is visible in Time Profiler.
        let signpostID = OSSignpostID(log: Self.signpostLog)
        var signpostStarted = false

        // Use bytes for SSE streaming
        let (asyncBytes, response) = try await session.bytes(for: urlRequest)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw StreamError.invalidResponse
        }

        // iOS-1: Detect server-side quota rejection (HTTP 403 with quota body marker).
        // Backend's check_and_reserve race-loser path may surface here if the
        // streaming endpoint ever switches from SSE-error to HTTP-403. We also
        // catch SSE-quota errors below in parseEvent → throw QuotaExhaustedError
        // so ChatViewModel can route both to the paywall instead of a generic banner.
        if httpResponse.statusCode == 403 {
            // Drain a small body to inspect quota markers without holding the stream open.
            var bodyText = ""
            for try await line in asyncBytes.lines {
                bodyText += line + "\n"
                if bodyText.count > 4096 { break }
            }
            if Self.bodyIndicatesQuotaExhaustion(bodyText) {
                throw QuotaExhaustedError(
                    reason: Self.extractQuotaReason(bodyText) ?? "overall_limit_reached",
                    upgradeMessage: Self.extractUpgradeMessage(bodyText),
                    resetAt: Self.extractResetAt(bodyText)
                )
            }
            print("[SSE] HTTP 403 (non-quota): \(bodyText.prefix(200))")
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

                // iOS-1: If this SSE event is a server-side quota rejection
                // (race between /can-access and /predict), throw a typed error
                // so ChatViewModel can route to the paywall instead of the
                // generic stream-failed banner. Backend emits this for the
                // streaming endpoint as event:error with code/reason markers.
                if currentEventType == "error",
                   let typed = Self.quotaErrorIfQuotaPayload(currentData) {
                    throw typed
                }

                // Process complete event on main actor
                if let event = parseEvent(type: currentEventType, data: currentData) {
                    // Task 12 signpost: begin on .finalAnswer, end on .done — the
                    // coalescer/atomic-flip window the brief asks Instruments to see.
                    if case .finalAnswer = event, !signpostStarted {
                        os_signpost(.begin, log: Self.signpostLog, name: "finalAnswer→done", signpostID: signpostID)
                        signpostStarted = true
                    }
                    await MainActor.run {
                        onEvent(event)
                    }

                    // If done event, break out of loop
                    if case .done = event {
                        if signpostStarted {
                            os_signpost(.end, log: Self.signpostLog, name: "finalAnswer→done", signpostID: signpostID)
                        }
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
            
        case "progress_step":
            return .progressStep(
                phase:      json["phase"]       as? String ?? "",
                group:      json["group"]       as? Int    ?? 0,
                groupCount: json["group_count"] as? Int    ?? 1,
                isDone:     json["is_done"]     as? Bool   ?? false,
                displayKey: json["display_key"] as? String,
                elapsedMs:  json["elapsed_ms"]  as? Int    ?? 0
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

        case "backpressure":
            // C-2: server is shedding load; client must fall back to sync /predict.
            // ChatViewModel handles this event by tearing down the streaming bubble
            // and replaying via sendMessageSync.
            let retryAfter = json["retry_after_seconds"] as? Int ?? 5
            return .backpressure(retryAfterSeconds: retryAfter)
            
        case "error":
            // Backend sends 'error' for exceptions, but 'message' for quota errors
            let errorMsg = json["error"] as? String ?? json["message"] as? String ?? "Unknown error"
            
            // If quota error with reason, create user-friendly message
            if let reason = json["reason"] as? String {
                switch reason {
                case "daily_limit_reached":
                    return .error(message: "Daily limit reached. Try again tomorrow.")
                case "overall_limit_reached":
                    return .error(message: "create_account_to_continue".localized)
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

// MARK: - Quota Exhaustion Detection (iOS-1)

/// Typed error surfaced when the backend rejects /predict/stream because the
/// user's quota is exhausted. ChatViewModel must catch this and present the
/// paywall (showQuotaSheet=true) instead of the generic stream-failed banner.
///
/// The proper backend-side fix is reservation-style /can-access (tracked as
/// iOS-1b); this client-side mitigation closes the user-visible regression
/// while that is being designed.
struct QuotaExhaustedError: Error {
    /// Backend-supplied reason, e.g. "daily_limit_reached", "overall_limit_reached".
    let reason: String
    /// Optional server-curated upgrade message (per-plan CTA).
    let upgradeMessage: String?
    /// Optional ISO8601 reset timestamp for daily limits.
    let resetAt: String?
    /// User's plan_id at time of rejection — needed by QuotaErrorInfo so
    /// the paywall can render plan-specific copy. Optional for back-compat
    /// with older payloads.
    var planId: String? = nil
    /// Backend-suggested upgrade plan ("core" / "plus") from upgrade_cta.
    var suggestedPlan: String? = nil
    /// Authoritative server flag: Plus user hit the lifetime cap → Contact
    /// Support flow. Optional; iOS falls back to heuristic when nil.
    var isFairUseViolation: Bool? = nil
}

extension StreamingPredictionService {

    /// Returns a QuotaExhaustedError if the SSE `data:` payload represents a
    /// quota rejection. Backend (predict.py:946) emits:
    /// `{"code":"quota_exceeded","message":...,"reason":"...","reset_at":...,"upgrade_cta":...}`
    static func quotaErrorIfQuotaPayload(_ data: String) -> QuotaExhaustedError? {
        guard let jsonData = data.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any]
        else { return nil }

        let code = json["code"] as? String
        let reason = json["reason"] as? String

        let isQuotaCode = (code == "quota_exceeded" || code == "quota_exhausted" || code == "rate_limited")
        let quotaReasons: Set<String> = [
            "daily_limit_reached",
            "overall_limit_reached",
            "quota_exhausted",
            "rate_limited"
        ]
        let isQuotaReason = reason.map { quotaReasons.contains($0) } ?? false

        guard isQuotaCode || isQuotaReason else { return nil }

        let cta = json["upgrade_cta"] as? [String: Any]
        return QuotaExhaustedError(
            reason: reason ?? "overall_limit_reached",
            upgradeMessage: cta?["message"] as? String ?? json["message"] as? String,
            resetAt: json["reset_at"] as? String
        )
    }

    /// Cheap substring scan over an HTTP 403 body for quota markers.
    static func bodyIndicatesQuotaExhaustion(_ body: String) -> Bool {
        let markers = [
            "quota_exhausted",
            "quota_exceeded",
            "rate_limited",
            "daily_limit_reached",
            "overall_limit_reached"
        ]
        return markers.contains(where: { body.contains($0) })
    }

    static func extractQuotaReason(_ body: String) -> String? {
        guard let jsonData = body.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any]
        else { return nil }
        return json["reason"] as? String ?? (json["detail"] as? [String: Any])?["reason"] as? String
    }

    static func extractUpgradeMessage(_ body: String) -> String? {
        guard let jsonData = body.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any]
        else { return nil }
        if let cta = json["upgrade_cta"] as? [String: Any], let msg = cta["message"] as? String { return msg }
        if let detail = json["detail"] as? [String: Any],
           let cta = detail["upgrade_cta"] as? [String: Any],
           let msg = cta["message"] as? String { return msg }
        return json["message"] as? String
    }

    static func extractResetAt(_ body: String) -> String? {
        guard let jsonData = body.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any]
        else { return nil }
        return json["reset_at"] as? String ?? (json["detail"] as? [String: Any])?["reset_at"] as? String
    }
}
