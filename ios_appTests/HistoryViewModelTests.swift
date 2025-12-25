import XCTest
@testable import ios_app

@MainActor
final class HistoryViewModelTests: XCTestCase {
    
    var viewModel: HistoryViewModel!
    var mockDataManager: DataManager!
    
    override func setUp() async throws {
        // Use in-memory DataManager for testing
        mockDataManager = DataManager(inMemory: true)
        viewModel = HistoryViewModel(dataManager: mockDataManager)
    }
    
    override func tearDown() async throws {
        viewModel = nil
        mockDataManager = nil
    }
    
    // MARK: - Initial State Tests
    
    func testInitialState() {
        XCTAssertTrue(viewModel.threads.isEmpty, "Threads should be empty initially")
        XCTAssertFalse(viewModel.isLoading, "Should not be loading initially")
        XCTAssertNil(viewModel.errorMessage, "Should have no error initially")
    }
    
    // MARK: - Grouped Threads Tests
    
    func testGroupedThreadsEmpty() {
        let groups = viewModel.groupedThreads
        XCTAssertTrue(groups.isEmpty, "Grouped threads should be empty")
    }
    
    func testGroupedThreadsGroupsByDate() async {
        // Set user email in UserDefaults (required by loadThreads)
        let testEmail = "test@test.com"
        UserDefaults.standard.set(testEmail, forKey: "userEmail")
        
        // Create test threads in DataManager
        let session = mockDataManager.getOrCreateSession(for: testEmail)
        
        // Create thread for today
        let todayThread = mockDataManager.createThread(
            sessionId: session.sessionId,
            userEmail: testEmail,
            title: "Today's Thread"
        )
        XCTAssertNotNil(todayThread, "Thread should be created")
        
        // Load threads  
        await viewModel.loadThreads()
        
        // Verify threads loaded
        XCTAssertFalse(viewModel.threads.isEmpty, "Should have threads after loading")
        
        // At least one group should exist
        let groups = viewModel.groupedThreads
        XCTAssertFalse(groups.isEmpty, "Should have grouped threads")
        
        // Clean up UserDefaults
        UserDefaults.standard.removeObject(forKey: "userEmail")
    }
    
    // MARK: - Load Threads Tests
    
    func testLoadThreadsSetsLoadingState() async {
        // Start loading
        Task {
            await viewModel.loadThreads()
        }
        
        // After completion, loading should be false
        try? await Task.sleep(nanoseconds: 100_000_000)
        XCTAssertFalse(viewModel.isLoading, "Loading should be false after completion")
    }
    
    // MARK: - Format Date Tests
    
    func testFormatSectionDateToday() {
        let today = Date()
        let formatted = viewModel.formatSectionDate(today)
        XCTAssertEqual(formatted, "Today", "Today's date should format as 'Today'")
    }
    
    func testFormatSectionDateYesterday() {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let formatted = viewModel.formatSectionDate(yesterday)
        XCTAssertEqual(formatted, "Yesterday", "Yesterday's date should format as 'Yesterday'")
    }
    
    func testFormatSectionDateThisWeek() {
        // Get a date from earlier this week (if possible)
        let calendar = Calendar.current
        let today = Date()
        let weekday = calendar.component(.weekday, from: today)
        
        // If today is not Sunday, get the first day of this week
        if weekday > 2 { // If it's at least Tuesday
            let daysAgo = -(weekday - 2) // Days since Monday
            if let thisWeekDate = calendar.date(byAdding: .day, value: daysAgo, to: today) {
                let formatted = viewModel.formatSectionDate(thisWeekDate)
                // Should be either "This Week" or a specific date
                XCTAssertFalse(formatted.isEmpty, "Should have formatted date")
            }
        }
    }
    
    func testFormatSectionDateOlder() {
        let oldDate = Calendar.current.date(byAdding: .month, value: -2, to: Date())!
        let formatted = viewModel.formatSectionDate(oldDate)
        // Should be a month/day/year format
        XCTAssertFalse(formatted.isEmpty, "Should have formatted old date")
        XCTAssertNotEqual(formatted, "Today", "Old date should not be 'Today'")
        XCTAssertNotEqual(formatted, "Yesterday", "Old date should not be 'Yesterday'")
    }
}
