import Foundation
import Security

/// W7 — SessionTokenStore: encrypted at-rest store for the user's
/// session JWT + refresh token + their expiries.
///
/// Backed by KeychainService (which uses kSecAttrAccessibleWhenUnlocked-
/// ThisDeviceOnly so the data never sync to iCloud and is wiped on
/// device unenrollment).
///
/// Keys are scoped per-email so logging out one account doesn't
/// leak to another. The current-active scope is tracked via
/// UserDefaults("w7_current_session_email") so APIClient can look up
/// the active session in O(1).
///
/// Concurrency: a serial DispatchQueue serializes ALL reads/writes
/// so two simultaneous network requests don't race on token rotation.
final class SessionTokenStore: @unchecked Sendable {
    static let shared = SessionTokenStore()

    private let queue = DispatchQueue(label: "destinyai.sessionTokenStore", qos: .userInitiated)
    private let keychain = KeychainService.shared
    private let userDefaults = UserDefaults.standard

    // MARK: - Storage keys

    private static let activeEmailKey = "w7_current_session_email"

    private static func sessionJwtKey(email: String) -> String {
        "w7_session_jwt::\(email.lowercased())"
    }
    private static func refreshTokenKey(email: String) -> String {
        "w7_refresh_token::\(email.lowercased())"
    }
    private static func sessionExpiryKey(email: String) -> String {
        "w7_session_expires::\(email.lowercased())"
    }
    private static func refreshExpiryKey(email: String) -> String {
        "w7_refresh_expires::\(email.lowercased())"
    }

    // MARK: - Active session

    /// The email currently active for outbound requests, or nil if
    /// the user is not signed in (or W7 sign-in hasn't completed).
    var activeEmail: String? {
        return queue.sync { userDefaults.string(forKey: Self.activeEmailKey) }
    }

    /// Set the active email + persist all four tokens for it.
    /// Atomic per email: if any write fails, all are rolled back.
    /// H2 (1.7) — all 4 writes use throwing saveString; on failure,
    /// the partial state is rolled back so the keychain never holds
    /// a half-written rotation pair.
    func setActiveSession(
        email: String,
        sessionJwt: String,
        sessionExpiresAt: Date,
        refreshToken: String,
        refreshExpiresAt: Date
    ) throws {
        try queue.sync {
            let normalized = email.lowercased()
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            do {
                try keychain.saveString(sessionJwt, forKey: Self.sessionJwtKey(email: normalized))
                try keychain.saveString(refreshToken, forKey: Self.refreshTokenKey(email: normalized))
                try keychain.saveString(formatter.string(from: sessionExpiresAt), forKey: Self.sessionExpiryKey(email: normalized))
                try keychain.saveString(formatter.string(from: refreshExpiresAt), forKey: Self.refreshExpiryKey(email: normalized))
                userDefaults.set(normalized, forKey: Self.activeEmailKey)
            } catch {
                // Rollback partial state — never leave keychain inconsistent.
                keychain.delete(forKey: Self.sessionJwtKey(email: normalized))
                keychain.delete(forKey: Self.refreshTokenKey(email: normalized))
                keychain.delete(forKey: Self.sessionExpiryKey(email: normalized))
                keychain.delete(forKey: Self.refreshExpiryKey(email: normalized))
                throw error
            }
        }
    }

    // MARK: - Read

    func currentSessionJwt() -> String? {
        return queue.sync { () -> String? in
            guard let email = userDefaults.string(forKey: Self.activeEmailKey) else { return nil }
            return keychain.loadString(forKey: Self.sessionJwtKey(email: email))
        }
    }

    func currentRefreshToken() -> String? {
        return queue.sync { () -> String? in
            guard let email = userDefaults.string(forKey: Self.activeEmailKey) else { return nil }
            return keychain.loadString(forKey: Self.refreshTokenKey(email: email))
        }
    }

    /// W7 P3 fix — look up the session JWT for a SPECIFIC email,
    /// regardless of which email is currently the active session.
    /// Used during guest→registered upgrade where the active session
    /// has already been swapped to the IdP user but we still need
    /// the GUEST's JWT to authorize the /subscription/upgrade call
    /// (W7 ownership check binds caller identity to old_email).
    func sessionJwt(forEmail email: String) -> String? {
        return queue.sync { () -> String? in
            keychain.loadString(forKey: Self.sessionJwtKey(email: email.lowercased()))
        }
    }

    /// W7 P3 fix — drop only the keychain entries for one email
    /// (used after a successful guest→registered upgrade where the
    /// guest row no longer exists server-side).
    func clearSession(forEmail email: String) {
        queue.sync {
            let normalized = email.lowercased()
            keychain.delete(forKey: Self.sessionJwtKey(email: normalized))
            keychain.delete(forKey: Self.refreshTokenKey(email: normalized))
            keychain.delete(forKey: Self.sessionExpiryKey(email: normalized))
            keychain.delete(forKey: Self.refreshExpiryKey(email: normalized))
            if userDefaults.string(forKey: Self.activeEmailKey)?.lowercased() == normalized {
                userDefaults.removeObject(forKey: Self.activeEmailKey)
            }
        }
    }

    /// True if the current session JWT is still valid (with 60s skew).
    /// Returns false if no JWT or it's about to expire.
    func sessionIsFresh() -> Bool {
        return queue.sync {
            guard let email = userDefaults.string(forKey: Self.activeEmailKey),
                  let raw = keychain.loadString(forKey: Self.sessionExpiryKey(email: email))
            else { return false }
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            guard let expiry = formatter.date(from: raw) else { return false }
            // 60s clock-skew margin; refresh proactively before the
            // server starts rejecting.
            return expiry.timeIntervalSinceNow > 60
        }
    }

    // MARK: - Update (refresh)

    /// H2 (1.7) — Update the session JWT + refresh token + both expiries on
    /// rotation. ATOMIC: all 4 writes succeed, or we clear the session
    /// entirely and return false. A partial write (e.g. JWT saved but
    /// refresh token failed) would leave the device with a token that
    /// can never be rotated again — silent lockout. Better to force
    /// the user back through sign-in than to persist an inconsistent
    /// keychain state.
    ///
    /// Returns true on success, false if any save threw (in which case
    /// the active session has been cleared as a safety measure — the
    /// caller MUST treat this as "not signed in" and surface to UX).
    @discardableResult
    func updateSession(
        sessionJwt: String,
        sessionExpiresAt: Date,
        refreshToken: String,
        refreshExpiresAt: Date
    ) -> Bool {
        return queue.sync { () -> Bool in
            guard let email = userDefaults.string(forKey: Self.activeEmailKey) else { return false }
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            do {
                try keychain.saveString(sessionJwt, forKey: Self.sessionJwtKey(email: email))
                try keychain.saveString(refreshToken, forKey: Self.refreshTokenKey(email: email))
                try keychain.saveString(formatter.string(from: sessionExpiresAt), forKey: Self.sessionExpiryKey(email: email))
                try keychain.saveString(formatter.string(from: refreshExpiresAt), forKey: Self.refreshExpiryKey(email: email))
                return true
            } catch {
                print("⚠️ [SessionTokenStore] updateSession failed (\(error)) — clearing session to avoid inconsistent state")
                keychain.delete(forKey: Self.sessionJwtKey(email: email))
                keychain.delete(forKey: Self.refreshTokenKey(email: email))
                keychain.delete(forKey: Self.sessionExpiryKey(email: email))
                keychain.delete(forKey: Self.refreshExpiryKey(email: email))
                userDefaults.removeObject(forKey: Self.activeEmailKey)
                return false
            }
        }
    }

    // MARK: - Clear

    /// Remove the active session entirely. Use on logout, account-
    /// deletion, or refresh-reuse-detection (server told us to re-sign-in).
    func clearActiveSession() {
        queue.sync {
            guard let email = userDefaults.string(forKey: Self.activeEmailKey) else {
                userDefaults.removeObject(forKey: Self.activeEmailKey)
                return
            }
            keychain.delete(forKey: Self.sessionJwtKey(email: email))
            keychain.delete(forKey: Self.refreshTokenKey(email: email))
            keychain.delete(forKey: Self.sessionExpiryKey(email: email))
            keychain.delete(forKey: Self.refreshExpiryKey(email: email))
            userDefaults.removeObject(forKey: Self.activeEmailKey)
        }
    }
}

// MARK: - KeychainService convenience for non-throwing string saves

extension KeychainService {
    /// Save a string; swallow errors. Used for non-critical paths
    /// (expiry timestamps) where a write failure shouldn't bring down
    /// a successful sign-in.
    func saveStringSafe(_ value: String, forKey key: String) {
        do {
            try saveString(value, forKey: key)
        } catch {
            print("⚠️ [Keychain] saveStringSafe failed key=\(key): \(error)")
        }
    }
}
