import Foundation
import XCTest
@testable import ios_app

/// Mock URL protocol that intercepts URLSession.shared requests.
///
/// Use this in tests that hit code with hardcoded `URLSession.shared` calls
/// (like `QuotaManager.canAccessFeature`) where dependency injection is not
/// available. The default URLSession.shared cannot be replaced — but Apple's
/// URLProtocol mechanism allows custom protocols to be registered globally
/// and intercept matching requests.
///
/// Register handlers per URL substring; the first matching handler wins.
/// Unmatched requests fall through to the standard URL loading system
/// (which in tests means they fail with NSURLErrorCannotConnectToHost
/// since no server is running on localhost:8000).
///
/// Usage in setUp:
///   MockURLProtocol.reset()
///   MockURLProtocol.handler(for: "/subscription/can-access") { _ in
///       (200, """
///       {"can_access": true, "reason": null, "limits": {}, "reset_at": null, "upgrade_cta": null}
///       """.data(using: .utf8)!)
///   }
///   URLProtocol.registerClass(MockURLProtocol.self)
///
/// In tearDown:
///   URLProtocol.unregisterClass(MockURLProtocol.self)
///   MockURLProtocol.reset()
final class MockURLProtocol: URLProtocol {

    // MARK: - Configuration

    /// Tuple of (statusCode, body). Returned synchronously to the URLProtocolClient.
    typealias Response = (Int, Data)

    /// Each handler matches if `request.url?.absoluteString.contains(pattern)` is true.
    private static var handlers: [(pattern: String, response: (URLRequest) -> Response)] = []

    /// Register a handler for any request whose URL contains `pattern`.
    static func handler(for pattern: String, _ response: @escaping (URLRequest) -> Response) {
        handlers.append((pattern, response))
    }

    /// Clear all registered handlers. Call in setUp + tearDown.
    static func reset() {
        handlers = []
    }

    // MARK: - URLProtocol overrides

    override class func canInit(with request: URLRequest) -> Bool {
        guard let url = request.url?.absoluteString else { return false }
        return handlers.contains { url.contains($0.pattern) }
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let url = request.url?.absoluteString,
              let match = MockURLProtocol.handlers.first(where: { url.contains($0.pattern) }) else {
            client?.urlProtocol(self, didFailWithError: URLError(.unsupportedURL))
            return
        }

        let (status, data) = match.response(request)
        let response = HTTPURLResponse(
            url: request.url!,
            statusCode: status,
            httpVersion: "HTTP/1.1",
            headerFields: ["Content-Type": "application/json"]
        )!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: data)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() { /* no-op */ }
}

// MARK: - Convenience extensions for ChatViewModelTests

extension MockURLProtocol {

    /// Stub `/subscription/can-access` to return `can_access: true`.
    /// Use in tests that exercise sendMessage past the quota gate but don't care about quota.
    static func stubQuotaAllowAll() {
        handler(for: "/subscription/can-access") { _ in
            let body = """
            {"can_access": true, "reason": null, "limits": {}, "reset_at": null, "upgrade_cta": null}
            """.data(using: .utf8)!
            return (200, body)
        }
    }

    /// Stub `/subscription/can-access` to return `can_access: false` with the given reason.
    static func stubQuotaDeny(reason: String, resetAt: String? = nil) {
        handler(for: "/subscription/can-access") { _ in
            let resetAtJson = resetAt.map { "\"\($0)\"" } ?? "null"
            let body = """
            {"can_access": false, "reason": "\(reason)", "limits": {}, "reset_at": \(resetAtJson), "upgrade_cta": null}
            """.data(using: .utf8)!
            return (200, body)
        }
    }

    /// Stub `/subscription/can-access` to return `can_access: false` with the given reason
    /// AND a server-curated `upgrade_cta` payload. Used by iOS-11 regression tests that
    /// verify the iOS client surfaces the per-plan server message instead of a generic
    /// localized fallback.
    static func stubQuotaDenyWithUpgradeCta(
        reason: String,
        ctaMessage: String,
        suggestedPlan: String = "premium_yearly",
        resetAt: String? = nil
    ) {
        handler(for: "/subscription/can-access") { _ in
            let resetAtJson = resetAt.map { "\"\($0)\"" } ?? "null"
            // Escape quotes in the message so we don't break JSON in tests with special chars.
            let escaped = ctaMessage
                .replacingOccurrences(of: "\\", with: "\\\\")
                .replacingOccurrences(of: "\"", with: "\\\"")
            let body = """
            {"can_access": false, "reason": "\(reason)", "limits": {}, "reset_at": \(resetAtJson), "upgrade_cta": {"message": "\(escaped)", "suggested_plan": "\(suggestedPlan)"}}
            """.data(using: .utf8)!
            return (200, body)
        }
    }

    /// Stub `/subscription/status` to return a minimal valid response — covers
    /// the `loadUserSession → syncStatus` path that fires from ChatViewModel init.
    static func stubSubscriptionStatusEmpty() {
        handler(for: "/subscription/status") { _ in
            let body = """
            {"plan_id": "free_registered", "is_premium": false, "available_features": ["ai_questions"], "expires_at": null, "auto_renew_status": null, "total_questions_asked": 0}
            """.data(using: .utf8)!
            return (200, body)
        }
    }

    /// iOS-1: Stub `/vedic/api/predict/stream` to return HTTP 403 with a quota
    /// exhaustion body, simulating the server-side reject after a /can-access
    /// vs /predict race. StreamingPredictionService must detect this and throw
    /// QuotaExhaustedError so ChatViewModel routes to the paywall.
    static func stubPredictStreamQuota403(reason: String = "overall_limit_reached", ctaMessage: String? = nil) {
        handler(for: "/vedic/api/predict/stream") { _ in
            let cta = ctaMessage.map { "{\"message\": \"\($0)\", \"suggested_plan\": \"premium_yearly\"}" } ?? "null"
            let body = """
            {"code": "quota_exceeded", "reason": "\(reason)", "message": "Quota exhausted", "upgrade_cta": \(cta)}
            """.data(using: .utf8)!
            return (403, body)
        }
    }

    /// Returns a URLSession configured with MockURLProtocol so test stubs
    /// (registered via `handler(for:_:)`) intercept its requests. Used by
    /// StreamingPredictionService.urlSessionFactory in tests.
    static func makeSession() -> URLSession {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self] + (config.protocolClasses ?? [])
        config.timeoutIntervalForRequest = 5
        config.timeoutIntervalForResource = 10
        return URLSession(configuration: config)
    }
}
