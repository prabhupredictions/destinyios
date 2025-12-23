import XCTest
@testable import ios_app

final class AuthViewModelTests: XCTestCase {
    
    var viewModel: AuthViewModel!
    var mockKeychain: KeychainService!
    
    override func setUp() {
        super.setUp()
        // Clear any existing session data
        KeychainService.shared.clearAll()
        UserDefaults.standard.removeObject(forKey: "isGuest")
        UserDefaults.standard.removeObject(forKey: "userEmail")
        UserDefaults.standard.removeObject(forKey: "userName")
        UserDefaults.standard.removeObject(forKey: "isAuthenticated")
        
        viewModel = AuthViewModel(authService: MockAuthService())
    }
    
    override func tearDown() {
        viewModel = nil
        // Clean up
        KeychainService.shared.clearAll()
        UserDefaults.standard.removeObject(forKey: "isGuest")
        UserDefaults.standard.removeObject(forKey: "userEmail")
        UserDefaults.standard.removeObject(forKey: "userName")
        UserDefaults.standard.removeObject(forKey: "isAuthenticated")
        super.tearDown()
    }
    
    // MARK: - Initial State Tests
    
    func testInitialState_NotAuthenticated() {
        XCTAssertFalse(viewModel.isAuthenticated)
        XCTAssertFalse(viewModel.isGuest)
        XCTAssertNil(viewModel.userEmail)
        XCTAssertNil(viewModel.userName)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
    }
    
    // MARK: - Guest Sign In Tests
    
    func testContinueAsGuest_SetsGuestState() {
        // Create expectation for async operation
        let expectation = XCTestExpectation(description: "Guest sign in")
        
        // When
        viewModel.continueAsGuest()
        
        // Wait for async
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // Then
            XCTAssertTrue(self.viewModel.isAuthenticated)
            XCTAssertTrue(self.viewModel.isGuest)
            XCTAssertNil(self.viewModel.userEmail)
            XCTAssertEqual(self.viewModel.userName, "Guest")
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 2.0)
    }
    
    // MARK: - Sign Out Tests
    
    func testSignOut_ClearsAllState() {
        // Given: Sign in as guest first
        let setupExpectation = XCTestExpectation(description: "Setup")
        viewModel.continueAsGuest()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            XCTAssertTrue(self.viewModel.isAuthenticated)
            setupExpectation.fulfill()
        }
        
        wait(for: [setupExpectation], timeout: 2.0)
        
        // When
        viewModel.signOut()
        
        // Then (after async)
        let signOutExpectation = XCTestExpectation(description: "Sign out")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            XCTAssertFalse(self.viewModel.isAuthenticated)
            XCTAssertFalse(self.viewModel.isGuest)
            XCTAssertNil(self.viewModel.userEmail)
            signOutExpectation.fulfill()
        }
        
        wait(for: [signOutExpectation], timeout: 2.0)
    }
    
    // MARK: - Apple Sign In Tests
    
    func testSignInWithApple_SetsAuthenticatedState() async {
        // When
        await viewModel.signInWithApple()
        
        // Then
        XCTAssertTrue(viewModel.isAuthenticated)
        XCTAssertFalse(viewModel.isGuest)
        XCTAssertNotNil(viewModel.userEmail)
        XCTAssertEqual(viewModel.userEmail, "user@icloud.com")
    }
    
    // MARK: - Google Sign In Tests
    
    func testSignInWithGoogle_SetsAuthenticatedState() async {
        // When
        await viewModel.signInWithGoogle()
        
        // Then
        XCTAssertTrue(viewModel.isAuthenticated)
        XCTAssertFalse(viewModel.isGuest)
        XCTAssertEqual(viewModel.userEmail, "user@gmail.com")
    }
    
    // MARK: - Loading State Tests
    
    func testSignIn_SetsLoadingState() async {
        // Given
        XCTAssertFalse(viewModel.isLoading)
        
        // When - start sign in
        let task = Task {
            await viewModel.signInWithApple()
        }
        
        // Give it a moment to start
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 sec
        
        // Then - should be loading
        XCTAssertTrue(viewModel.isLoading)
        
        // Wait for completion
        await task.value
        
        // After - should not be loading
        XCTAssertFalse(viewModel.isLoading)
    }
}
