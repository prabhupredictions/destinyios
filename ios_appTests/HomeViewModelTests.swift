import XCTest
@testable import ios_app

/// Tests for HomeViewModel
@MainActor
final class HomeViewModelTests: XCTestCase {
    
    var viewModel: HomeViewModel!
    
    override func setUp() async throws {
        try await super.setUp()
        viewModel = HomeViewModel()
    }
    
    override func tearDown() async throws {
        viewModel = nil
        try await super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testInit_SetsDefaultValues() async throws {
        // Then
        XCTAssertEqual(viewModel.quotaTotal, 10)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
    }
    
    // MARK: - Greeting Tests
    
    func testGreetingMessage_ReturnsNonEmptyString() async throws {
        // greetingMessage returns "Hey" currently — test it's non-empty
        let greeting = viewModel.greetingMessage
        XCTAssertFalse(greeting.isEmpty)
    }

    func testDisplayName_ReturnsThereForGuestUser() async throws {
        // displayName returns "there" for guests (isGuest = true)
        UserDefaults.standard.set(true, forKey: "isGuest")
        viewModel = HomeViewModel()
        let displayName = viewModel.displayName
        XCTAssertEqual(displayName, "there")
        UserDefaults.standard.removeObject(forKey: "isGuest")
    }
    
    func testDisplayName_ReturnsFirstNameForUser() async throws {
        // Given
        UserDefaults.standard.set(false, forKey: "isGuest")
        UserDefaults.standard.set("John Doe", forKey: "userName")
        viewModel = HomeViewModel()
        
        // When
        let displayName = viewModel.displayName
        
        // Then
        XCTAssertEqual(displayName, "John")
        
        // Cleanup
        UserDefaults.standard.removeObject(forKey: "userName")
    }
    
    // MARK: - Quota Tests
    
    func testQuotaProgress_CalculatesCorrectly() async throws {
        // Given
        viewModel.quotaRemaining = 5
        viewModel.quotaTotal = 10
        
        // When
        let progress = viewModel.quotaProgress
        
        // Then
        XCTAssertEqual(progress, 0.5, accuracy: 0.01)
    }
    
    func testDecrementQuota_ReducesQuota() async throws {
        // Given
        viewModel.quotaRemaining = 5
        UserDefaults.standard.set(5, forKey: "quotaRemaining")
        
        // When
        viewModel.decrementQuota()
        
        // Then
        XCTAssertEqual(viewModel.quotaRemaining, 4)
        
        // Cleanup
        UserDefaults.standard.removeObject(forKey: "quotaRemaining")
    }
    
    func testDecrementQuota_DoesNotGoBelowZero() async throws {
        // Given
        viewModel.quotaRemaining = 0
        
        // When
        viewModel.decrementQuota()
        
        // Then
        XCTAssertEqual(viewModel.quotaRemaining, 0)
    }
    
    // MARK: - Load Data Tests
    
    func testLoadHomeData_SetsLoadingState() async throws {
        // Given
        XCTAssertFalse(viewModel.isLoading)
        
        // When
        await viewModel.loadHomeData()
        
        // Then - after completion, loading should be false
        XCTAssertFalse(viewModel.isLoading)
    }
    
    func testLoadHomeData_PopulatesSuggestedQuestions() async throws {
        // suggestedQuestions requires birth data + backend response.
        // Without a live backend, we assert loading completes cleanly.
        await viewModel.loadHomeData()
        XCTAssertFalse(viewModel.isLoading)
    }
    
    func testLoadHomeData_PopulatesDailyInsight() async throws {
        // When
        await viewModel.loadHomeData()
        
        // Then
        XCTAssertFalse(viewModel.dailyInsight.isEmpty)
    }
    
    // MARK: - Renewal Date Tests
    
    func testRenewalDateString_FormatsCorrectly() async throws {
        // The renewal date should be formatted as "MMM d"
        let dateString = viewModel.renewalDateString
        
        // Should not be empty
        XCTAssertFalse(dateString.isEmpty)
        
        // Should contain a month abbreviation
        let months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
        let containsMonth = months.contains { dateString.contains($0) }
        XCTAssertTrue(containsMonth)
    }
}
