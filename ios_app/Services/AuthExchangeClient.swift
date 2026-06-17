import Foundation

/// W7 — AuthExchangeClient: posts to /auth/exchange and /auth/refresh,
/// stores results in SessionTokenStore.
///
/// The iOS sign-in flow calls .signInWithApple(idToken:nonce:) right
/// after Apple returns the credential. /auth/exchange returns a session
/// JWT + refresh token + the canonical user_email for the row server-
/// side. Save them; iOS APIClient then sends them on every subsequent
/// authenticated call.
///
/// NETWORK ERRORS: surface as `AuthExchangeError` so callers can
/// distinguish IdP rejection (user must retry sign-in) from
/// transient network issues (offer retry).
final class AuthExchangeClient: @unchecked Sendable {
    static let shared = AuthExchangeClient()

    private let session: URLSession
    private let baseURL: String
    private let apiKey: String

    init(
        session: URLSession = .shared,
        baseURL: String = APIConfig.baseURL,
        apiKey: String = APIConfig.apiKey
    ) {
        self.session = session
        self.baseURL = baseURL
        self.apiKey = apiKey
    }

    // MARK: - /auth/exchange

    /// Exchange an Apple Sign-In id_token for a session JWT.
    /// nonce: the same nonce iOS passed to ASAuthorizationAppleIDProvider.
    @discardableResult
    func signInWithApple(idToken: String, nonce: String?, deviceId: String? = nil) async throws -> ExchangeResult {
        return try await exchange(body: [
            "idp": "apple",
            "id_token": idToken,
            "nonce": nonce as Any?,
            "device_id": deviceId as Any?,
        ].compactMapValues { $0 })
    }

    /// Exchange a Google Sign-In id_token for a session JWT.
    @discardableResult
    func signInWithGoogle(idToken: String, nonce: String?, deviceId: String? = nil) async throws -> ExchangeResult {
        return try await exchange(body: [
            "idp": "google",
            "id_token": idToken,
            "nonce": nonce as Any?,
            "device_id": deviceId as Any?,
        ].compactMapValues { $0 })
    }

    /// Bootstrap a guest session from a server-supplied (or birth-derived)
    /// email. is_generated_email=true assigns the free_guest plan;
    /// false assigns free_registered.
    @discardableResult
    func signInAsGuest(email: String, isGeneratedEmail: Bool = true, userName: String? = nil) async throws -> ExchangeResult {
        return try await exchange(body: [
            "idp": "guest",
            "guest_payload": [
                "user_email": email,
                "is_generated_email": isGeneratedEmail,
                "user_name": userName as Any?,
            ].compactMapValues { $0 },
        ])
    }

    private func exchange(body: [String: Any]) async throws -> ExchangeResult {
        let url = URL(string: baseURL + "/auth/exchange")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        // /auth/exchange is in the backend's PUBLIC_ENDPOINTS list; no
        // bearer required. We still send X-API-Key as anti-bot signal.
        request.setValue(apiKey, forHTTPHeaderField: "X-API-Key")
        request.setValue("DestinyAI-iOS/1.6", forHTTPHeaderField: "User-Agent")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthExchangeError.network("no http response")
        }
        if httpResponse.statusCode != 200 {
            throw Self.parseError(data: data, status: httpResponse.statusCode)
        }
        let result = try JSONDecoder.iso8601().decode(ExchangeResponseRaw.self, from: data)

        try SessionTokenStore.shared.setActiveSession(
            email: result.user_email,
            sessionJwt: result.session_jwt,
            sessionExpiresAt: result.session_jwt_expires_at,
            refreshToken: result.refresh_token,
            refreshExpiresAt: result.refresh_token_expires_at
        )

        return ExchangeResult(
            userEmail: result.user_email,
            sessionJwt: result.session_jwt,
            sessionExpiresAt: result.session_jwt_expires_at,
            refreshExpiresAt: result.refresh_token_expires_at
        )
    }

    // MARK: - /auth/refresh

    /// Trade in the stored refresh token for a new session JWT.
    /// Called automatically by APIClient on a 401 session_expired.
    @discardableResult
    func refresh(idToken: String? = nil) async throws -> ExchangeResult {
        guard let refreshToken = SessionTokenStore.shared.currentRefreshToken() else {
            throw AuthExchangeError.noRefreshToken
        }
        let url = URL(string: baseURL + "/auth/refresh")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "X-API-Key")
        request.setValue("DestinyAI-iOS/1.6", forHTTPHeaderField: "User-Agent")
        var body: [String: Any] = ["refresh_token": refreshToken]
        if let id = idToken {
            // Optional: needed for Google sessions older than 7 days
            // (server-enforced re-attest window).
            body["id_token"] = id
        }
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthExchangeError.network("no http response")
        }
        if httpResponse.statusCode != 200 {
            throw Self.parseError(data: data, status: httpResponse.statusCode)
        }
        let result = try JSONDecoder.iso8601().decode(RefreshResponseRaw.self, from: data)

        SessionTokenStore.shared.updateSession(
            sessionJwt: result.session_jwt,
            sessionExpiresAt: result.session_jwt_expires_at,
            refreshToken: result.refresh_token,
            refreshExpiresAt: result.refresh_token_expires_at
        )
        return ExchangeResult(
            userEmail: SessionTokenStore.shared.activeEmail ?? "",
            sessionJwt: result.session_jwt,
            sessionExpiresAt: result.session_jwt_expires_at,
            refreshExpiresAt: result.refresh_token_expires_at
        )
    }

    // MARK: - Error parsing

    private static func parseError(data: Data, status: Int) -> AuthExchangeError {
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let detail = json["detail"] as? [String: Any],
           let code = detail["code"] as? String {
            switch code {
            case "refresh_reused", "refresh_unknown", "refresh_expired",
                 "session_revoked", "google_reattest_required":
                return .reauthRequired(code: code)
            default:
                return .idpRejected(code: code, status: status)
            }
        }
        return .network("status \(status)")
    }
}

// MARK: - Response models

private struct ExchangeResponseRaw: Codable {
    let session_jwt: String
    let session_jwt_expires_at: Date
    let refresh_token: String
    let refresh_token_expires_at: Date
    let user_email: String
}

private struct RefreshResponseRaw: Codable {
    let session_jwt: String
    let session_jwt_expires_at: Date
    let refresh_token: String
    let refresh_token_expires_at: Date
}

// MARK: - Public types

struct ExchangeResult {
    let userEmail: String
    let sessionJwt: String
    let sessionExpiresAt: Date
    let refreshExpiresAt: Date
}

enum AuthExchangeError: Error, LocalizedError {
    /// IdP rejected the id_token (bad nonce, expired, wrong aud, etc.).
    /// User must repeat the sign-in flow.
    case idpRejected(code: String, status: Int)
    /// Server told us to re-sign-in. Clear local state, route to login.
    case reauthRequired(code: String)
    /// Transient network issue. Caller can retry.
    case network(String)
    /// No refresh token stored — caller should not have called refresh.
    case noRefreshToken

    var errorDescription: String? {
        switch self {
        case .idpRejected(let code, let status):
            return "Sign-in rejected (code=\(code), http=\(status))"
        case .reauthRequired(let code):
            return "Please sign in again (\(code))"
        case .network(let msg):
            return "Network error: \(msg)"
        case .noRefreshToken:
            return "No refresh token stored"
        }
    }
}

// MARK: - JSONDecoder ISO8601 with fractional seconds

extension JSONDecoder {
    /// W7 P3-HIGH fix: pre-fix fell back to Date(timeIntervalSince1970: 0)
    /// on unparseable timestamps. Backend datetime.utcnow() emits NAIVE
    /// timestamps without timezone; iOS ISO8601DateFormatter requires
    /// .withInternetDateTime which mandates a Z or +HH:MM. The mismatch
    /// silently produced a 1970 expiry, sessionIsFresh() returned false
    /// forever, and NetworkClient downgraded to API-key bearer for every
    /// subsequent request — defeating W7 entirely.
    ///
    /// New strategy:
    ///   1. Try ISO8601 with fractional seconds + tz
    ///   2. Try ISO8601 without fractional but with tz
    ///   3. Try the same WITH a synthetic "Z" appended (handles
    ///      Pydantic's naive-utcnow output)
    ///   4. THROW DecodingError.dataCorrupted — caller surfaces the
    ///      sign-in failure rather than silently downgrading to 1970.
    static func iso8601() -> JSONDecoder {
        let decoder = JSONDecoder()
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let formatterNoFrac = ISO8601DateFormatter()
        formatterNoFrac.formatOptions = [.withInternetDateTime]
        decoder.dateDecodingStrategy = .custom { container in
            let s = try container.singleValueContainer().decode(String.self)
            // Direct attempts.
            if let d = formatter.date(from: s) { return d }
            if let d = formatterNoFrac.date(from: s) { return d }
            // Pydantic naive-utcnow fallback: append Z and retry.
            let withZ = s.hasSuffix("Z") || s.contains("+") || s.range(of: "-", options: .backwards)?.lowerBound != nil && s.contains(":")
                ? s : s + "Z"
            if let d = formatter.date(from: withZ) { return d }
            if let d = formatterNoFrac.date(from: withZ) { return d }
            // Don't silently produce a 1970 epoch — let the caller fail
            // the sign-in and route the user to retry.
            throw DecodingError.dataCorrupted(.init(
                codingPath: container.codingPath,
                debugDescription: "Unparseable ISO8601 datetime: \(s)"
            ))
        }
        return decoder
    }
}
