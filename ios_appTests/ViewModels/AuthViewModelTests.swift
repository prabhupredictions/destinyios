import XCTest
@testable import ios_app

@MainActor
final class AuthViewModelTests: XCTestCase {
    
    var viewModel: AuthViewModel!
    
    override func setUp() async throws {
        try await super.setUp()
        // Clear any existing session data - ensure clean state
        await clearAllState()
        
        // Create fresh viewModel with mock service
        viewModel = AuthViewModel(authService: TestAuthService())
    }
    
    override func tearDown() async throws {
        viewModel = nil
        await clearAllState()
        try await super.tearDown()
    }
    
    private func clearAllState() async {
        KeychainService.shared.clearAll()
        UserDefaults.standard.removeObject(forKey: "isGuest")
        UserDefaults.standard.removeObject(forKey: "userEmail")
        UserDefaults.standard.removeObject(forKey: "userName")
        UserDefaults.standard.removeObject(forKey: "isAuthenticated")
        UserDefaults.standard.synchronize()
    }
    
    // MARK: - Initial State Tests
    
    func testInitialState_NotAuthenticated() async throws {
        XCTAssertFalse(viewModel.isAuthenticated)
        XCTAssertFalse(viewModel.isGuest)
        XCTAssertNil(viewModel.userEmail)
        XCTAssertNil(viewModel.userName)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
    }
    
    // MARK: - Guest Sign In Tests
    
    func testContinueAsGuest_SetsGuestState() async throws {
        // When
        await viewModel.continueAsGuestAsync()
        
        // Then
        XCTAssertTrue(viewModel.isAuthenticated)
        XCTAssertTrue(viewModel.isGuest)
        XCTAssertNil(viewModel.userEmail)
        XCTAssertEqual(viewModel.userName, "Guest")
    }
    
    // MARK: - Sign Out Tests
    
    func testSignOut_ClearsAllState() async throws {
        // Given: Sign in as guest first
        await viewModel.continueAsGuestAsync()
        XCTAssertTrue(viewModel.isAuthenticated, "Should be authenticated after guest sign in")
        
        // When
        await viewModel.signOutAsync()
        
        // Then
        XCTAssertFalse(viewModel.isAuthenticated, "Should not be authenticated after sign out")
        XCTAssertFalse(viewModel.isGuest, "Should not be guest after sign out")
        XCTAssertNil(viewModel.userEmail, "Email should be nil after sign out")
    }
    
    // MARK: - Apple Sign In Tests
    
    func testSignInWithApple_SetsAuthenticatedState() async throws {
        // When
        await viewModel.signInWithApple()
        
        // Then
        XCTAssertTrue(viewModel.isAuthenticated)
        XCTAssertFalse(viewModel.isGuest)
        XCTAssertNotNil(viewModel.userEmail)
        XCTAssertEqual(viewModel.userEmail, "user@icloud.com")
    }
    
    // MARK: - Google Sign In Tests
    
    func testSignInWithGoogle_SetsAuthenticatedState() async throws {
        // When
        await viewModel.signInWithGoogle()
        
        // Then
        XCTAssertTrue(viewModel.isAuthenticated)
        XCTAssertFalse(viewModel.isGuest)
        XCTAssertEqual(viewModel.userEmail, "user@gmail.com")
    }
    
    // MARK: - Loading State Tests
    
    func testSignIn_SetsLoadingState() async throws {
        // Given
        XCTAssertFalse(viewModel.isLoading)
        
        // When
        await viewModel.signInWithApple()
        
        // Then - after completion, should not be loading
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertTrue(viewModel.isAuthenticated)
    }
}

// MARK: - Test Auth Service (faster than Mock)

class TestAuthService: AuthServiceProtocol {
    func signInWithApple() async throws -> User {
        // No delay for tests
        return User(
            id: UUID().uuidString,
            email: "user@icloud.com",
            name: "Apple User"
        )
    }
    
    func signInWithGoogle() async throws -> User {
        return User(
            id: UUID().uuidString,
            email: "user@gmail.com",
            name: "Google User"
        )
    }
    
    func signInAsGuest() async -> User {
        let guestId = "guest_test_\(UUID().uuidString.prefix(8))"
        return User(
            id: guestId,
            email: nil,
            name: "Guest"
        )
    }
    
    func signOut() async {
        // No-op for test
    }
}
