import Foundation
import SwiftUI

/// ViewModel for authentication state and actions
@MainActor
@Observable
class AuthViewModel {
    // MARK: - Published State
    var isLoading = false
    var errorMessage: String?
    var isAuthenticated = false
    var userEmail: String?
    var userName: String?
    var isGuest = false
    
    // MARK: - Dependencies
    private let authService: AuthServiceProtocol
    private let keychain: KeychainService
    
    // MARK: - Init
    /// Use AppleAuthService for real Apple Sign-In (Google still needs SDK setup)
    init(authService: AuthServiceProtocol = AppleAuthService(), keychain: KeychainService = .shared) {
        self.authService = authService
        self.keychain = keychain
        checkExistingSession()
    }
    
    // MARK: - Session Management
    
    /// Check for existing session on app launch
    private func checkExistingSession() {
        if keychain.exists(forKey: KeychainService.Keys.userId) {
            self.isAuthenticated = true
            self.isGuest = UserDefaults.standard.bool(forKey: "isGuest")
            self.userEmail = UserDefaults.standard.string(forKey: "userEmail")
            self.userName = UserDefaults.standard.string(forKey: "userName")
        }
    }
    
    // MARK: - Authentication Actions
    
    /// Sign in with Apple
    func signInWithApple() async {
        await performSignIn {
            try await self.authService.signInWithApple()
        }
    }
    
    /// Sign in with Google
    func signInWithGoogle() async {
        await performSignIn {
            try await self.authService.signInWithGoogle()
        }
    }
    
    /// Continue as guest user
    func continueAsGuest() {
        Task {
            await continueAsGuestAsync()
        }
    }
    
    /// Async version for testing
    func continueAsGuestAsync() async {
        self.isLoading = true
        
        let guestUser = await authService.signInAsGuest()
        
        handleAuthSuccess(user: guestUser, isGuest: true)
        self.isLoading = false
    }
    
    /// Sign out current user
    func signOut() {
        Task {
            await signOutAsync()
        }
    }
    
    /// Async version for testing
    func signOutAsync() async {
        let wasGuest = UserDefaults.standard.bool(forKey: "isGuest")
        
        await authService.signOut()
        
        // Clear state
        isAuthenticated = false
        isGuest = false
        userEmail = nil
        userName = nil
        errorMessage = nil
        
        // Clear secure storage
        keychain.delete(forKey: KeychainService.Keys.userId)
        keychain.delete(forKey: KeychainService.Keys.authToken)
        
        // Clear user session defaults
        UserDefaults.standard.removeObject(forKey: "isGuest")
        UserDefaults.standard.removeObject(forKey: "userEmail")
        UserDefaults.standard.removeObject(forKey: "userName")
        UserDefaults.standard.set(false, forKey: "isAuthenticated")
        
        // For GUEST users: clear birth data and quota (they get fresh start)
        // For REGISTERED users: keep birth data locally cached by email
        if wasGuest {
            UserDefaults.standard.removeObject(forKey: "quotaUsed")
            UserDefaults.standard.removeObject(forKey: "userBirthData")
            UserDefaults.standard.removeObject(forKey: "hasBirthData")
            UserDefaults.standard.removeObject(forKey: "userGender")
            UserDefaults.standard.removeObject(forKey: "birthTimeUnknown")
        }
        // Note: Registered users' birth data is preserved in SwiftData by email key
    }
    
    // MARK: - Private Helpers
    
    private func performSignIn(_ action: @escaping () async throws -> User) async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            let user = try await action()
            await MainActor.run {
                handleAuthSuccess(user: user, isGuest: false)
            }
        } catch {
            await MainActor.run {
                errorMessage = "Sign in failed. Please try again."
            }
        }
        
        await MainActor.run {
            isLoading = false
        }
    }
    
    private func handleAuthSuccess(user: User, isGuest: Bool) {
        self.isAuthenticated = true
        self.isGuest = isGuest
        self.userEmail = user.email
        self.userName = user.name
        
        // Securely store user ID
        try? keychain.saveString(user.id, forKey: KeychainService.Keys.userId)
        
        // Store non-sensitive state
        UserDefaults.standard.set(true, forKey: "isAuthenticated")
        UserDefaults.standard.set(isGuest, forKey: "isGuest")
        
        if let email = user.email {
            UserDefaults.standard.set(email, forKey: "userEmail")
        }
        if let name = user.name {
            UserDefaults.standard.set(name, forKey: "userName")
        }
        
        // For registered users, try to fetch existing profile from server
        if !isGuest, let email = user.email {
            Task {
                await fetchAndRestoreProfile(email: email)
            }
        }
    }
    
    /// Fetch user profile from server and restore locally
    private func fetchAndRestoreProfile(email: String) async {
        do {
            if let profile = try await ProfileService.shared.fetchProfile(email: email) {
                // Restore profile data locally
                ProfileService.shared.restoreProfileLocally(profile)
                
                // Update hasBirthData flag if profile has birth data
                if profile.birthProfile != nil {
                    UserDefaults.standard.set(true, forKey: "hasBirthData")
                    print("[AuthViewModel] Restored profile from server: \(email)")
                }
                
                // Update quota from server
                UserDefaults.standard.set(profile.questionsAsked, forKey: "quotaUsed")
            } else {
                print("[AuthViewModel] No existing profile found on server for: \(email)")
            }
            
            // Sync chat history from server
            await ChatHistorySyncService.shared.syncFromServer(userEmail: email, dataManager: DataManager.shared)
            
        } catch {
            print("[AuthViewModel] Failed to fetch profile: \(error)")
        }
    }
}

// MARK: - Mock Auth Service
class MockAuthService: AuthServiceProtocol {
    func signInWithApple() async throws -> User {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 1_500_000_000)
        return User(
            id: UUID().uuidString,
            email: "user@icloud.com",
            name: "Apple User"
        )
    }
    
    func signInWithGoogle() async throws -> User {
        try await Task.sleep(nanoseconds: 1_500_000_000)
        return User(
            id: UUID().uuidString,
            email: "user@gmail.com",
            name: "Google User"
        )
    }
    
    func signInAsGuest() async -> User {
        // Generate persistent guest ID
        let guestId = "guest_\(UUID().uuidString.prefix(8))"
        return User(
            id: guestId,
            email: nil,
            name: "Guest"
        )
    }
    
    func signOut() async {
        // No-op for mock
    }
}
