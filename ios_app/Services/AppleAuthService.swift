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
        let user = result.user
        
        return User(
            id: user.userID ?? "unknown_google_id",
            email: user.profile?.email,
            name: user.profile?.name,
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

        // W7: trade the Apple-issued id_token for a server-issued
        // session JWT + refresh token. We do this BEFORE returning
        // the User up the call stack so APIClient.request can pick
        // up the new tokens on its very next call.
        if let identityTokenData = credential.identityToken,
           let idToken = String(data: identityTokenData, encoding: .utf8) {
            let nonce = currentNonce
            currentNonce = nil
            Task.detached { [idToken, nonce] in
                do {
                    _ = try await AuthExchangeClient.shared.signInWithApple(
                        idToken: idToken, nonce: nonce,
                    )
                    print("[AppleAuth] W7 session minted via /auth/exchange")
                } catch {
                    // Non-fatal: legacy flow still works (the iOS user
                    // is signed in via Apple, just not bound to a
                    // server session). We log and continue.
                    print("⚠️ [AppleAuth] W7 /auth/exchange failed: \(error). Falling back to legacy auth.")
                }
            }
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
    
    var errorDescription: String? {
        switch self {
        case .invalidCredential: return "Invalid Apple ID credential"
        case .cancelled: return "Sign in was cancelled"
        case .notImplemented(let msg): return msg
        }
    }
}
