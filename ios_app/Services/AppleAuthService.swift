import Foundation
import AuthenticationServices
import UIKit
#if canImport(GoogleSignIn)
import GoogleSignIn
#endif

/// Real Apple Sign-In implementation using AuthenticationServices
class AppleAuthService: NSObject, AuthServiceProtocol {
    
    private var signInContinuation: CheckedContinuation<User, Error>?
    
    // MARK: - Apple Sign In
    
    func signInWithApple() async throws -> User {
        return try await withCheckedThrowingContinuation { continuation in
            self.signInContinuation = continuation
            
            let request = ASAuthorizationAppleIDProvider().createRequest()
            request.requestedScopes = [.fullName, .email]
            
            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.performRequests()
        }
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
