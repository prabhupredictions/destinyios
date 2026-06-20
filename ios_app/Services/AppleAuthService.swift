import Foundation
import AuthenticationServices
import CryptoKit
import UIKit
#if canImport(GoogleSignIn)
import GoogleSignIn
#endif

/// Real Apple Sign-In implementation using AuthenticationServices
class AppleAuthService: NSObject, AuthServiceProtocol {

    private var signInContinuation: CheckedContinuation<User, Error>?

    /// W7 — nonce generated per sign-in attempt. ASAuthorizationAppleIDProvider
    /// requires the SHA-256 hash of the nonce in the request, then includes
    /// the raw nonce in the resulting id_token. The backend verifies the
    /// match in /auth/exchange.
    private var currentNonce: String?

    // MARK: - Apple Sign In

    func signInWithApple() async throws -> User {
        return try await withCheckedThrowingContinuation { continuation in
            self.signInContinuation = continuation

            // W7: generate per-attempt nonce. The hash goes into the
            // request; the raw value goes into the id_token Apple
            // signs; we compare server-side in /auth/exchange.
            let nonce = Self.randomNonce()
            self.currentNonce = nonce

            let request = ASAuthorizationAppleIDProvider().createRequest()
            request.requestedScopes = [.fullName, .email]
            request.nonce = Self.sha256(nonce)

            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.performRequests()
        }
    }

    // MARK: - Nonce helpers

    private static func randomNonce(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remaining = length
        while remaining > 0 {
            let randoms = (0..<16).map { _ -> UInt8 in
                var random: UInt8 = 0
                _ = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                return random
            }
            for r in randoms where remaining > 0 {
                if r < charset.count {
                    result.append(charset[Int(r)])
                    remaining -= 1
                }
            }
        }
        return result
    }

    private static func sha256(_ input: String) -> String {
        let data = Data(input.utf8)
        let hash = SHA256.hash(data: data)
        return hash.map { String(format: "%02x", $0) }.joined()
    }
    
    // MARK: - Google Sign In

    @MainActor
    func signInWithGoogle() async throws -> User {
        #if canImport(GoogleSignIn)
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            print("❌ [AppleAuth] No root view controller found")
            throw AuthError.notImplemented("No root view controller found")
        }

        print("🚀 [AppleAuth] Starting Google Sign-In...")
        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)
        print("✅ [AppleAuth] Google Sign-In Success!")
        let googleUser = result.user

        // W7 P3 — exchange Google id_token for backend session JWT.
        // Mirrors the Apple flow above. Without this, Google users
        // never mint a session JWT → APIClient relies on legacy UA
        // passthrough → strict-mode kill-switch (W7_REQUIRE_NEW_AGENT=1)
        // would lock them out of every authenticated endpoint.
        // Fail loud on exchange error so AuthViewModel.performSignIn
        // routes to the sign-in screen instead of MainTabView with
        // no session.
        guard let idToken = googleUser.idToken?.tokenString else {
            print("⚠️ [AppleAuth] Google sign-in returned no id_token — W7 exchange skipped")
            // Without an id_token we can't mint a backend session.
            // Fail rather than proceed sessionless (would silently break
            // strict-mode features like /predict-stream once kill-switch fires).
            throw AuthError.networkError("Google sign-in did not return an id_token")
        }
        // Clear any stale active session so a slow /auth/exchange
        // can't be observed mid-flight returning the previous user's JWT.
        SessionTokenStore.shared.clearActiveSession()
        do {
            _ = try await AuthExchangeClient.shared.signInWithGoogle(
                idToken: idToken, nonce: nil,
            )
            print("[AppleAuth] W7 session minted via /auth/exchange (google)")
        } catch let exchangeErr as AuthExchangeError {
            // Cross-IdP collision: surface as a typed AuthError so the
            // sign-in screen can show "Sign in with <bound_idp>"
            // instead of a generic network error.
            if case .crossIdpCollision(let boundIdp, _, _) = exchangeErr {
                print("⚠️ [AppleAuth] cross-IdP collision (google): bound_idp=\(boundIdp ?? "?")")
                throw AuthError.crossIdpCollision(boundIdp: boundIdp)
            }
            print("⚠️ [AppleAuth] W7 /auth/exchange failed (google): \(exchangeErr)")
            throw AuthError.networkError(exchangeErr.localizedDescription)
        } catch {
            print("⚠️ [AppleAuth] W7 /auth/exchange failed (google): \(error)")
            throw AuthError.networkError(error.localizedDescription)
        }

        return User(
            id: googleUser.userID ?? "unknown_google_id",
            email: googleUser.profile?.email,
            name: googleUser.profile?.name,
            provider: "google"
        )
        #else
        throw AuthError.notImplemented("GoogleSignIn SDK not imported. Please add the package via Xcode.")
        #endif
    }
    
    // MARK: - Guest Sign In
    
    func signInAsGuest() async -> User {
        let guestId = "guest_\(UUID().uuidString.prefix(8))"
        return User(
            id: guestId,
            email: nil,
            name: nil,  // Backend will default to "Destiny User"
            provider: "guest"
        )
    }
    
    // MARK: - Sign Out
    
    func signOut() async {
        // Apple doesn't require explicit sign-out
        // Just clear local state (handled by AuthViewModel)
    }
}

// MARK: - ASAuthorizationControllerDelegate

extension AppleAuthService: ASAuthorizationControllerDelegate {
    
    private var keychain: KeychainService { KeychainService.shared }
    
    func authorizationController(controller: ASAuthorizationController, 
                                didCompleteWithAuthorization authorization: ASAuthorization) {
        
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            signInContinuation?.resume(throwing: AuthError.invalidCredential)
            signInContinuation = nil
            return
        }
        
        // Extract user info
        let userId = credential.user
        
        // Apple only provides email and name on FIRST sign-in
        // On subsequent sign-ins, we retrieve from stored values
        var email = credential.email
        var displayName: String? = nil
        
        // Build display name from Apple-provided name components
        if let fullName = credential.fullName {
            if let givenName = fullName.givenName {
                displayName = givenName
                if let familyName = fullName.familyName {
                    displayName = "\(givenName) \(familyName)"
                }
            }
        }
        
        // FIRST SIGN-IN: Store in both Keychain (primary) and UserDefaults (fallback)
        if let newEmail = email {
            // Primary: Keychain (persists after app delete)
            try? keychain.saveString(newEmail, forKey: "appleEmail_\(userId)")
            // Fallback: UserDefaults
            UserDefaults.standard.set(newEmail, forKey: "appleUserEmail_\(userId)")
        }
        if let newName = displayName {
            try? keychain.saveString(newName, forKey: "appleName_\(userId)")
            UserDefaults.standard.set(newName, forKey: "appleUserName_\(userId)")
        }
        
        // SUBSEQUENT SIGN-INS: Try Keychain first, then UserDefaults as fallback
        if email == nil {
            email = keychain.loadString(forKey: "appleEmail_\(userId)")
                ?? UserDefaults.standard.string(forKey: "appleUserEmail_\(userId)")
        }
        if displayName == nil {
            displayName = keychain.loadString(forKey: "appleName_\(userId)")
                ?? UserDefaults.standard.string(forKey: "appleUserName_\(userId)")
        }
        
        // Store the user identifier
        UserDefaults.standard.set(userId, forKey: "appleUserID")

        let user = User(
            id: userId,
            email: email,
            name: displayName,
            provider: "apple"
        )

        print("[AppleAuth] User: id=\(userId), email=\(email ?? "nil"), name=\(displayName ?? "nil")")

        // W7 P3 fix: trade the Apple-issued id_token for a server-issued
        // session JWT + refresh token. We do this BEFORE resuming the
        // continuation so APIClient.request always has the new tokens
        // on its first call.
        //
        // Pre-fix used Task.detached fire-and-forget which raced the
        // first API call after sign-in. Worse, on /auth/exchange
        // failure the continuation still resumed with success, leaving
        // the user "signed in" client-side but locked out server-side.
        // Now: clear any stale active session BEFORE exchange, await
        // the result, fail loud on error.
        if let identityTokenData = credential.identityToken,
           let idToken = String(data: identityTokenData, encoding: .utf8) {
            let nonce = currentNonce
            currentNonce = nil
            // Clear any stale active session so a slow /auth/exchange
            // can't be observed mid-flight returning the previous
            // user's JWT.
            SessionTokenStore.shared.clearActiveSession()
            // Await the exchange before resuming. If it fails, throw —
            // AuthViewModel.performSignIn will route to the sign-in
            // screen rather than into MainTabView with no session.
            Task { [idToken, nonce, weak self] in
                do {
                    _ = try await AuthExchangeClient.shared.signInWithApple(
                        idToken: idToken, nonce: nonce,
                    )
                    print("[AppleAuth] W7 session minted via /auth/exchange")
                    self?.signInContinuation?.resume(returning: user)
                } catch let exchangeErr as AuthExchangeError {
                    // Cross-IdP collision: surface as a typed AuthError
                    // so AuthView can show "Sign in with <bound_idp>"
                    // instead of a generic network error.
                    if case .crossIdpCollision(let boundIdp, _, _) = exchangeErr {
                        print("⚠️ [AppleAuth] cross-IdP collision: bound_idp=\(boundIdp ?? "?")")
                        self?.signInContinuation?.resume(throwing:
                            AuthError.crossIdpCollision(boundIdp: boundIdp))
                    } else {
                        print("⚠️ [AppleAuth] W7 /auth/exchange failed: \(exchangeErr)")
                        self?.signInContinuation?.resume(throwing:
                            AuthError.networkError(exchangeErr.localizedDescription))
                    }
                } catch {
                    print("⚠️ [AppleAuth] W7 /auth/exchange failed: \(error)")
                    self?.signInContinuation?.resume(throwing: AuthError.networkError(error.localizedDescription))
                }
                self?.signInContinuation = nil
            }
            // Skip the immediate resume below — we'll resume from the
            // Task above.
            return
        } else {
            print("⚠️ [AppleAuth] No identityToken in credential — W7 sign-in skipped")
        }

        signInContinuation?.resume(returning: user)
        signInContinuation = nil
    }
    
    func authorizationController(controller: ASAuthorizationController, 
                                didCompleteWithError error: Error) {
        signInContinuation?.resume(throwing: error)
        signInContinuation = nil
    }
}

// MARK: - Auth Errors

enum AuthError: Error, LocalizedError {
    case invalidCredential
    case cancelled
    case notImplemented(String)
    /// W7 P3 fix: surface /auth/exchange failures.
    case networkError(String)
    /// Email is registered with a different IdP. boundIdp is "google"
    /// or "apple" (or nil if older backend). AuthView routes to the
    /// correct sign-in flow based on this.
    case crossIdpCollision(boundIdp: String?)

    var errorDescription: String? {
        switch self {
        case .invalidCredential: return "Invalid Apple ID credential"
        case .cancelled: return "Sign in was cancelled"
        case .notImplemented(let msg): return msg
        case .networkError(let msg): return "Sign in network error: \(msg)"
        case .crossIdpCollision(let boundIdp):
            if let idp = boundIdp {
                let pretty = idp.capitalized
                return NSLocalizedString(
                    "auth.cross_idp_collision.\(idp)",
                    value: "This email is registered with \(pretty). Sign in with \(pretty) to continue.",
                    comment: "Cross-IdP collision — wrong sign-in method"
                )
            }
            return NSLocalizedString(
                "auth.cross_idp_collision.generic",
                value: "This email is registered with a different sign-in method.",
                comment: "Cross-IdP collision — no IdP hint from server"
            )
        }
    }
}
