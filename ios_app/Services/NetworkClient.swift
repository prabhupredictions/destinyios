import Foundation

final class NetworkClient: NetworkClientProtocol, @unchecked Sendable {
    
    // MARK: - Properties
    private let session: URLSessionProtocol
    private let baseURL: String
    private let apiKey: String
    
    // MARK: - Init
    init(
        session: URLSessionProtocol = {
            let config = URLSessionConfiguration.default
            config.waitsForConnectivity = true
            config.timeoutIntervalForResource = 600  // 10 min — Opus can take 3-5 min
            return URLSession(configuration: config)
        }(),
        baseURL: String = APIConfig.baseURL,
        apiKey: String = APIConfig.apiKey
    ) {
        self.session = session
        self.baseURL = baseURL
        self.apiKey = apiKey
    }
    
    // MARK: - NetworkClientProtocol
    func request<T: Decodable>(
        endpoint: String,
        method: String,
        body: Encodable?
    ) async throws -> T {
        return try await requestWithRetry(
            endpoint: endpoint, method: method, body: body, allowRetry: true,
        )
    }

    /// W7: actual request execution. On 401 session_expired, we
    /// transparently call /auth/refresh and retry ONCE. Any second 401
    /// surfaces to the caller (which should route to sign-in).
    private func requestWithRetry<T: Decodable>(
        endpoint: String,
        method: String,
        body: Encodable?,
        allowRetry: Bool
    ) async throws -> T {

        // Build URL
        guard let url = URL(string: baseURL + endpoint) else {
            throw NetworkError.invalidURL
        }

        // Build Request
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        // W7: bundled API key in X-API-Key (anti-bot / app-identity).
        // Session JWT in Authorization: Bearer when available; otherwise
        // we send the API key in Authorization too so pre-W7 endpoints
        // continue to work.
        request.setValue(apiKey, forHTTPHeaderField: "X-API-Key")
        request.setValue("DestinyAI-iOS/1.7", forHTTPHeaderField: "User-Agent")

        if let sessionJwt = SessionTokenStore.shared.currentSessionJwt(),
           SessionTokenStore.shared.sessionIsFresh() {
            request.setValue("Bearer \(sessionJwt)", forHTTPHeaderField: "Authorization")
        } else {
            // Pre-W7 path: bearer = API key. Backend's APIKeyAuthMiddleware
            // (W7 step 8) skips JWT-shaped tokens, so this works.
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        }

        // Encode body (models have CodingKeys for snake_case)
        if let body = body {
            let encoder = JSONEncoder()
            request.httpBody = try encoder.encode(body)
        }

        // Execute request
        let (data, response) = try await session.data(for: request)

        // Validate response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.noData
        }

        // W7: on 401, attempt one refresh + retry.
        if httpResponse.statusCode == 401 && allowRetry {
            if let detailCode = Self.detailCode(data: data),
               detailCode == "session_expired" {
                do {
                    _ = try await AuthExchangeClient.shared.refresh()
                    // Retry once with the new token.
                    return try await requestWithRetry(
                        endpoint: endpoint, method: method, body: body, allowRetry: false,
                    )
                } catch let exchangeErr as AuthExchangeError {
                    // refresh_reused / refresh_unknown / refresh_expired:
                    // server told us to re-sign-in. Clear local state.
                    if case .reauthRequired = exchangeErr {
                        SessionTokenStore.shared.clearActiveSession()
                    }
                    throw NetworkError.unauthorized
                } catch {
                    throw NetworkError.unauthorized
                }
            }
            // Other 401 codes (session_revoked etc.): clear + surface
            if let detailCode = Self.detailCode(data: data),
               detailCode == "session_revoked" {
                SessionTokenStore.shared.clearActiveSession()
            }
        }

        // Handle status codes
        switch httpResponse.statusCode {
        case 200...299:
            break
        case 401:
            throw NetworkError.unauthorized
        case 400...499:
            // Detect quota rejection BEFORE the generic 4xx → serverError
            // path. The sync /predict endpoint returns:
            //   { "detail": { "code": "quota_exceeded", "reason": "...",
            //                 "message": "...", "upgrade_cta": {...},
            //                 "reset_at": "..." } }
            // We surface that as QuotaExhaustedError so ChatViewModel's
            // existing paywall path fires (matching the streaming behavior).
            if let quotaError = Self.quotaErrorIf403(data: data, statusCode: httpResponse.statusCode) {
                throw quotaError
            }
            // Try to parse error message from response body
            if let errorJson = try? JSONDecoder().decode([String: String].self, from: data) {
                // FastAPI {"detail": "string"} or {"message": "string"}
                if let message = errorJson["message"] ?? errorJson["detail"] {
                    throw NetworkError.serverError(message)
                }
            }
            // Try nested detail format (FastAPI style: {"detail": {"message": "..."}})
            if let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let detail = errorData["detail"] as? [String: Any],
               let message = detail["message"] as? String {
                throw NetworkError.serverError(message)
            }
            throw NetworkError.serverError("Client Error: \(httpResponse.statusCode)")
        case 500...599:
            // Try to parse structured error from response body
            if let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                // FastAPI {"detail": "string"}
                if let detail = errorData["detail"] as? String {
                    throw NetworkError.serverError(detail)
                }
                // Nested: {"detail": {"message": "..."}}
                if let detail = errorData["detail"] as? [String: Any],
                   let message = detail["message"] as? String {
                    throw NetworkError.serverError(message)
                }
                // {"message": "string"}
                if let message = errorData["message"] as? String {
                    throw NetworkError.serverError(message)
                }
            }
            throw NetworkError.serverError("Server Error: \(httpResponse.statusCode)")
        default:
            throw NetworkError.serverError("Unknown Error: \(httpResponse.statusCode)")
        }
        
        // Check data
        guard !data.isEmpty else {
            throw NetworkError.noData
        }
        
        // Decode response (models have CodingKeys for snake_case)
        do {
            let decoder = JSONDecoder()
            return try decoder.decode(T.self, from: data)
        } catch {
            throw NetworkError.decodingError(error)
        }
    }

    // MARK: - Quota Error Detection

    /// W7: extract detail.code from a FastAPI error envelope.
    /// FastAPI returns `{"detail": {"code": "session_expired", ...}}`
    /// for our auth errors. Returns nil if no code is present.
    static func detailCode(data: Data) -> String? {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        if let detail = json["detail"] as? [String: Any] {
            return detail["code"] as? String
        }
        return nil
    }

    /// Returns a `QuotaExhaustedError` if the 4xx response body matches the
    /// backend's quota-rejection shape:
    ///   { "detail": { "code": "quota_exceeded", "reason": "...",
    ///                 "message": "...", "upgrade_cta": {...},
    ///                 "reset_at": "..." } }
    /// or the legacy flat shape with "code" at the top level. Returns nil for
    /// any other 4xx so callers can fall through to the generic error path.
    static func quotaErrorIf403(data: Data, statusCode: Int) -> QuotaExhaustedError? {
        // Most quota rejections are 403, but 429 can also indicate rate limits.
        guard statusCode == 403 || statusCode == 429 else { return nil }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { return nil }

        // Unwrap FastAPI's {"detail": {...}} envelope if present, else use top level.
        let payload: [String: Any]
        if let detail = json["detail"] as? [String: Any] {
            payload = detail
        } else {
            payload = json
        }

        let code = payload["code"] as? String
        let reason = payload["reason"] as? String

        let isQuotaCode = (code == "quota_exceeded"
                           || code == "quota_exhausted"
                           || code == "rate_limited"
                           || code == "subscription_expired")
        let quotaReasons: Set<String> = [
            "daily_limit_reached",
            "overall_limit_reached",
            "quota_exhausted",
            "rate_limited",
            "subscription_expired",
        ]
        let isQuotaReason = reason.map { quotaReasons.contains($0) } ?? false
        guard isQuotaCode || isQuotaReason else { return nil }

        let cta = payload["upgrade_cta"] as? [String: Any]
        return QuotaExhaustedError(
            reason: reason ?? "overall_limit_reached",
            upgradeMessage: (cta?["message"] as? String) ?? (payload["message"] as? String),
            resetAt: payload["reset_at"] as? String,
            planId: payload["plan_id"] as? String,
            suggestedPlan: cta?["suggested_plan"] as? String,
            isFairUseViolation: payload["is_fair_use_violation"] as? Bool
        )
    }
}

extension NetworkClient {
    /// W7 — shared auth header for ALL URLSession callers.
    /// Returns Authorization Bearer value: JWT if available + fresh,
    /// else falls back to bundled API key. Use this anywhere you
    /// build a URLRequest manually instead of going through
    /// NetworkClient.request(...).
    ///
    /// Usage:
    ///     request.setValue(NetworkClient.authBearer(),
    ///                      forHTTPHeaderField: "Authorization")
    ///     request.setValue(APIConfig.apiKey,
    ///                      forHTTPHeaderField: "X-API-Key")
    static func authBearer() -> String {
        if let sessionJwt = SessionTokenStore.shared.currentSessionJwt(),
           SessionTokenStore.shared.sessionIsFresh() {
            return "Bearer \(sessionJwt)"
        }
        return "Bearer \(APIConfig.apiKey)"
    }

    /// Always returns the bundled API key. Use for X-API-Key header
    /// alongside authBearer() so backend's APIKeyAuthMiddleware can
    /// validate the iOS app identity on every request (W7 step 8).
    static func apiKeyHeader() -> String {
        return APIConfig.apiKey
    }
}
