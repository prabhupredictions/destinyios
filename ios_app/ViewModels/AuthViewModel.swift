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
    init(authService: AuthServiceProtocol? = nil, keychain: KeychainService? = nil) {
        self.authService = authService ?? AppleAuthService()
        self.keychain = keychain ?? KeychainService.shared
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
        
        // DEBUG: Print state after guest login
        let hasBirth = UserDefaults.standard.bool(forKey: "hasBirthData")
        print("[DEBUG] After guest login - hasBirthData: \(hasBirth), isAuthenticated: \(isAuthenticated)")
        
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
        let previousEmail = UserDefaults.standard.string(forKey: "userEmail") ?? "guest"
        
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
        
        // Clear global session keys (UI resets to no birth data)
        UserDefaults.standard.removeObject(forKey: "userBirthData")
        UserDefaults.standard.set(false, forKey: "hasBirthData")
        UserDefaults.standard.removeObject(forKey: "quotaUsed")
        UserDefaults.standard.removeObject(forKey: "isPremium")
        
        print("[DEBUG] SignOut - hasBirthData set to false, isAuthenticated: \(UserDefaults.standard.bool(forKey: "isAuthenticated"))")
        
        // For GUEST users: clear their user-scoped data (they get fresh start)
        // For REGISTERED users: keep birth data locally cached by email for quick re-login
        if wasGuest {
            // Clear all user-scoped data for this guest
            let keys = StorageKeys.allKeys(for: previousEmail)
            keys.forEach { UserDefaults.standard.removeObject(forKey: $0) }
            
            // Also clear caches for guest
            TodaysPredictionCache.shared.clear(forUser: previousEmail)
            AstroDataCache.shared.clearAll(forUser: previousEmail)
        }
        
        // Clear compatibility history for ALL users (profile-scoped data can cause contamination)
        // This data is local-only and preventing cross-profile issues is more important than caching
        CompatibilityHistoryService.shared.clearAll(forUser: previousEmail)
        
        // Also reset ProfileContextManager active profile to prevent stale state
        ProfileContextManager.shared.resetActiveProfile()
    }
    
    // MARK: - Private Helpers
    
    private func performSignIn(_ action: @escaping () async throws -> User) async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        // PHASE 12: Capture guest birth data BEFORE sign-in changes user context
        // This enables seamless upgrade: guest birth data → registered user profile
        let wasGuest = UserDefaults.standard.bool(forKey: "isGuest")
        let guestHadBirthData = UserDefaults.standard.bool(forKey: "hasBirthData")
        let guestEmail = UserDefaults.standard.string(forKey: "userEmail") ?? ""
        var guestBirthData: BirthData? = nil
        var guestUserName: String? = nil
        var guestGender: String = ""
        
        if wasGuest && guestHadBirthData {
            // Capture guest's birth data before we switch users
            if let data = UserDefaults.standard.data(forKey: "userBirthData"),
               let birthData = try? JSONDecoder().decode(BirthData.self, from: data) {
                guestBirthData = birthData
                guestUserName = UserDefaults.standard.string(forKey: "userName")
                
                // Gender is stored with user-scoped key: userGender_<email>
                let genderKey = StorageKeys.userKey(for: StorageKeys.userGender, email: guestEmail)
                guestGender = UserDefaults.standard.string(forKey: genderKey) ?? ""
                
                print("🔄 [AuthViewModel] Captured guest birth data for carry-forward (gender: \(guestGender))")
                
                // CRITICAL: Clear local guest history BEFORE sign-in
                // Backend already has guest's history (synced during guest session)
                // After migration, we'll re-sync from server with correct user email
                // This prevents duplicates from local (guest IDs) vs server (migrated IDs)
                print("🗑️ [AuthViewModel] Clearing local guest history before sign-in...")
                DataManager.shared.deleteAllThreads(for: guestEmail)
                print("✅ [AuthViewModel] Local guest history cleared")
            }
        }
        
        do {
            let user = try await action()
            print("========================================")
            print("🔐 [AuthViewModel] SIGN-IN RETURNED")
            print("   - id: \(user.id)")
            print("   - email: \(user.email ?? "NIL")")
            print("   - name: \(user.name ?? "NIL")")
            print("   - provider: \(user.provider ?? "NIL")")
            print("========================================")
            
            if let email = user.email {
                // Determine provider ID type
                var appleId: String? = nil
                var googleId: String? = nil
                
                if user.provider == "apple" {
                    appleId = user.id
                } else if user.provider == "google" {
                    googleId = user.id
                }
                
                print("📤 [AuthViewModel] Calling registerUser...")
                print("   - email: \(email)")
                print("   - appleId: \(appleId ?? "nil")")
                print("   - googleId: \(googleId ?? "nil")")
                
                // Register user with platform identity for linking
                // The response contains the ACTUAL stored email (may differ if found by ID)
                let registerResponse = try? await ProfileService.shared.registerUser(
                    email: email,
                    isGeneratedEmail: false,
                    appleId: appleId,
                    googleId: googleId
                )
                
                print("📥 [AuthViewModel] registerUser response:")
                print("   - userEmail: \(registerResponse?.userEmail ?? "nil")")
                
                // Use the server-returned email (critical for apple_id/google_id recovery)
                let actualEmail = registerResponse?.userEmail ?? email
                print("📧 [AuthViewModel] Using actualEmail for profile fetch: \(actualEmail)")
                
                // Fetch profile to check if user already has birth data
                // Skip background sync during guest→registered upgrade (we'll sync after migration)
                let isGuestUpgrade = guestBirthData != nil
                var profileHasBirthData = await fetchAndRestoreProfile(email: actualEmail, skipSync: isGuestUpgrade)
                print("📊 [AuthViewModel] fetchAndRestoreProfile returned: \(profileHasBirthData)")
                
                // PHASE 12: Guest birth data carry-forward
                // If registered user has no birth data BUT guest had birth data, save it now
                if !profileHasBirthData, let guestData = guestBirthData {
                    print("🔄 [AuthViewModel] Carrying forward guest birth data to registered user...")
                    
                    let userName = user.name ?? guestUserName ?? "User"
                    let saveSuccess = await saveGuestBirthDataForRegisteredUser(
                        email: actualEmail,
                        userName: userName,
                        birthData: guestData,
                        gender: guestGender
                    )
                    
                    if saveSuccess {
                        profileHasBirthData = true
                        print("✅ [AuthViewModel] Guest birth data saved to registered user. Migration happened on backend.")
                        
                        // Sync history AFTER migration completes on backend
                        // Local guest history was cleared before sign-in
                        // This sync fetches the migrated threads with correct IDs
                        print("🔄 [AuthViewModel] Syncing migrated history from server...")
                        await ChatHistorySyncService.shared.syncFromServer(userEmail: actualEmail, dataManager: DataManager.shared)
                        await CompatibilityHistoryService.shared.syncFromServer(userEmail: actualEmail)
                        print("✅ [AuthViewModel] Post-migration history sync complete")
                    } else {
                        print("⚠️ [AuthViewModel] Failed to save guest birth data. User will need to re-enter.")
                    }
                }
                
                // CRITICAL: Set hasBirthData BEFORE isAuthenticated on MainActor
                // This ensures SwiftUI sees both flags atomically
                await MainActor.run {
                    if profileHasBirthData {
                        UserDefaults.standard.set(true, forKey: "hasBirthData")
                        print("✅ [AuthViewModel] hasBirthData set to TRUE on MainActor")
                    } else {
                        print("⚠️ [AuthViewModel] profileHasBirthData is FALSE - NOT setting hasBirthData")
                    }
                    print("🚀 [AuthViewModel] Calling handleAuthSuccess...")
                    handleAuthSuccess(user: user, isGuest: false)
                    
                    // Force immediate UserDefaults persistence
                    // This fixes race condition where ProfileSwitcherSheet may open before
                    // userEmail is updated, causing it to use stale guest email for API calls
                    UserDefaults.standard.synchronize()
                    
                    print("✅ [AuthViewModel] handleAuthSuccess completed. isAuthenticated=\(isAuthenticated)")
                }
            } else {
                // Email is nil - common with Apple "Hide My Email" on subsequent logins
                // Try to find user by apple_id/google_id and get their stored email
                print("⚠️ [AuthViewModel] No email from sign-in, attempting ID-based lookup...")
                
                var appleId: String? = nil
                var googleId: String? = nil
                
                if user.provider == "apple" {
                    appleId = user.id
                    print("📤 [AuthViewModel] Looking up user by appleId: \(appleId ?? "nil")")
                } else if user.provider == "google" {
                    googleId = user.id
                    print("📤 [AuthViewModel] Looking up user by googleId: \(googleId ?? "nil")")
                }
                
                // Call registerUser with a placeholder email - backend will find by ID and return stored email
                let registerResponse = try? await ProfileService.shared.registerUser(
                    email: "lookup-by-id@placeholder.local",
                    isGeneratedEmail: true,
                    appleId: appleId,
                    googleId: googleId
                )
                
                print("📥 [AuthViewModel] registerUser (ID lookup) response:")
                print("   - userEmail: \(registerResponse?.userEmail ?? "nil")")
                
                if let storedEmail = registerResponse?.userEmail, storedEmail != "lookup-by-id@placeholder.local" {
                    // Found existing user! Fetch their profile
                    print("✅ [AuthViewModel] Found existing user by ID! Email: \(storedEmail)")
                    
                    let profileHasBirthData = await fetchAndRestoreProfile(email: storedEmail)
                    print("📊 [AuthViewModel] fetchAndRestoreProfile returned: \(profileHasBirthData)")
                    
                    await MainActor.run {
                        if profileHasBirthData {
                            UserDefaults.standard.set(true, forKey: "hasBirthData")
                            print("✅ [AuthViewModel] hasBirthData set to TRUE on MainActor")
                        } else {
                            print("⚠️ [AuthViewModel] profileHasBirthData is FALSE - NOT setting hasBirthData")
                        }
                        // Store the recovered email
                        UserDefaults.standard.set(storedEmail, forKey: "userEmail")
                        print("🚀 [AuthViewModel] Calling handleAuthSuccess with recovered email...")
                        handleAuthSuccess(user: user, isGuest: false)
                        UserDefaults.standard.synchronize()  // Force immediate persistence
                        print("✅ [AuthViewModel] handleAuthSuccess completed. isAuthenticated=\(isAuthenticated)")
                    }
                } else {
                    // No existing user found by ID - this is a new user without email
                    print("⚠️ [AuthViewModel] No existing user found by ID, proceeding as new user")
                    await MainActor.run {
                        handleAuthSuccess(user: user, isGuest: false)
                        UserDefaults.standard.synchronize()  // Force immediate persistence
                    }
                }
            }
        } catch {
            print("❌ [AuthViewModel] Sign in error: \(error)")
            await MainActor.run {
                errorMessage = "Sign in failed. Please try again. (\(error.localizedDescription))"
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
            
            // HYDRATE SESSION FROM LOCAL CACHE (Instant Login)
            // Check if we have data for this user isolated locally
            let dataKey = StorageKeys.userKey(for: StorageKeys.userBirthData, email: email)
            let hasDataKey = StorageKeys.userKey(for: StorageKeys.hasBirthData, email: email)
            let quotaKey = StorageKeys.userKey(for: StorageKeys.quotaUsed, email: email)
            let genderKey = StorageKeys.userKey(for: StorageKeys.userGender, email: email)
            
            if UserDefaults.standard.bool(forKey: hasDataKey),
               let data = UserDefaults.standard.data(forKey: dataKey) {
                
                // Copy to Session (Global) keys for UI
                UserDefaults.standard.set(data, forKey: "userBirthData")
                UserDefaults.standard.set(true, forKey: "hasBirthData")
                print("[AuthViewModel] Hydrated session from local cache for: \(email)")
                
                if let gender = UserDefaults.standard.string(forKey: genderKey) {
                    UserDefaults.standard.set(gender, forKey: "userGender")
                }
            }
            
            // Restore Quota
            if let quota = UserDefaults.standard.object(forKey: quotaKey) as? Int {
                UserDefaults.standard.set(quota, forKey: "quotaUsed")
            }
        }
        if let name = user.name {
            UserDefaults.standard.set(name, forKey: "userName")
        }
        
        // Note: Profile fetch is now done in performSignIn BEFORE calling this method
        // This ensures hasBirthData is set correctly before UI transition
    }
    
    /// Fetch user profile from server and restore locally
    /// Returns: true if profile exists AND has birth data, false otherwise
    /// - skipSync: When true, skips background history sync (used during guest→registered upgrade
    ///             where explicit sync happens after migration)
    private func fetchAndRestoreProfile(email: String, skipSync: Bool = false) async -> Bool {
        print("🔍 [AuthViewModel] fetchAndRestoreProfile called with email: \(email), skipSync: \(skipSync)")
        do {
            if let profile = try await ProfileService.shared.fetchProfile(email: email) {
                print("✅ [AuthViewModel] Profile fetched successfully")
                print("   - userEmail: \(profile.userEmail)")
                print("   - birthProfile: \(profile.birthProfile != nil ? "EXISTS" : "NIL")")
                
                // Restore profile data locally
                try ProfileService.shared.restoreProfileLocally(profile)
                
                // Update quota from server
                UserDefaults.standard.set(profile.questionsAsked, forKey: "quotaUsed")
                
                // Return whether profile has birth data
                // NOTE: hasBirthData flag is now set by caller on MainActor
                let hasBirth = profile.birthProfile != nil
                if hasBirth {
                    print("✅ [AuthViewModel] Profile has birth data - will skip birth chart screen")
                } else {
                    print("⚠️ [AuthViewModel] Profile exists but NO birth data")
                }
                
                // Sync history in background (don't block UI)
                // Skip during guest→registered upgrade - caller will sync after migration
                if !skipSync {
                    Task {
                        // Sync history in background
                        await ChatHistorySyncService.shared.syncFromServer(userEmail: email, dataManager: DataManager.shared)
                        await CompatibilityHistoryService.shared.syncFromServer(userEmail: email)
                        
                        // Sync Quota/Plan Status (Pre-fetch to prevent Subscription screen flicker)
                        try? await QuotaManager.shared.syncStatus(email: email)
                    }
                } else {
                    print("⏭️ [AuthViewModel] Skipping background sync (will sync after migration)")
                }
                
                return hasBirth
            } else {
                print("⚠️ [AuthViewModel] fetchProfile returned NIL for: \(email)")
                return false
            }
        } catch {
            print("❌ [AuthViewModel] Failed to fetch profile: \(error)")
            return false
        }
    }
    
    /// PHASE 12: Save guest birth data for the newly registered user
    /// This triggers backend migration (guest history → registered user)
    private func saveGuestBirthDataForRegisteredUser(
        email: String,
        userName: String,
        birthData: BirthData,
        gender: String
    ) async -> Bool {
        do {
            let response = try await ProfileService.shared.saveProfile(
                email: email,
                userName: userName,
                birthData: birthData,
                isGuest: false,
                gender: gender
            )
            
            if let response = response {
                print("✅ [AuthViewModel] Profile saved for \(response.userEmail)")
                
                // Store birth data locally for session
                if let encoded = try? JSONEncoder().encode(birthData) {
                    UserDefaults.standard.set(encoded, forKey: "userBirthData")
                    
                    // Also store in user-scoped keys
                    let dataKey = StorageKeys.userKey(for: StorageKeys.userBirthData, email: email)
                    let hasDataKey = StorageKeys.userKey(for: StorageKeys.hasBirthData, email: email)
                    UserDefaults.standard.set(encoded, forKey: dataKey)
                    UserDefaults.standard.set(true, forKey: hasDataKey)
                }
                
                // Store gender in user-scoped key for registered user
                if !gender.isEmpty {
                    let genderKey = StorageKeys.userKey(for: StorageKeys.userGender, email: email)
                    UserDefaults.standard.set(gender, forKey: genderKey)
                    print("✅ [AuthViewModel] Gender '\(gender)' saved for \(email)")
                }
                
                // Create self partner profile for Switch Profile feature
                // This makes the upgraded user work exactly like a normal registered user
                print("👤 [AuthViewModel] Creating self partner profile...")
                await ProfileService.shared.createSelfPartnerProfile(
                    email: email,
                    userName: userName,
                    birthProfile: ProfileService.BirthProfileResponse(
                        dateOfBirth: birthData.dob,
                        timeOfBirth: birthData.time,
                        cityOfBirth: birthData.cityOfBirth ?? "",
                        latitude: birthData.latitude,
                        longitude: birthData.longitude,
                        gender: gender.isEmpty ? nil : gender,
                        birthTimeUnknown: false
                    )
                )
                print("✅ [AuthViewModel] Self partner profile created")
                
                return true
            }
            return false
        } catch {
            print("❌ [AuthViewModel] Failed to save guest birth data: \(error)")
            return false
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
