import XCTest
@testable import ios_app

/// Tests for ChatViewModel
@MainActor
final class ChatViewModelTests: XCTestCase {
    
    var viewModel: ChatViewModel!
    var testDataManager: DataManager!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Use isolated in-memory data manager
        testDataManager = DataManager(inMemory: true)
        
        // Set up test user
        UserDefaults.standard.set("test@example.com", forKey: "userEmail")
        
        // Initialize ViewModel with test data manager
        viewModel = ChatViewModel(dataManager: testDataManager)
    }
    
    override func tearDown() async throws {
        UserDefaults.standard.removeObject(forKey: "userEmail")
        UserDefaults.standard.removeObject(forKey: "userBirthData")
        viewModel = nil
        testDataManager = nil
        try await super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testInit_CreatesSession() async throws {
        // Then
        XCTAssertFalse(viewModel.currentSessionId.isEmpty)
    }
    
    func testInit_CreatesThread() async throws {
        // Then
        XCTAssertFalse(viewModel.currentThreadId.isEmpty)
    }
    
    func testInit_HasWelcomeMessage() async throws {
        // Then
        XCTAssertFalse(viewModel.messages.isEmpty)
        XCTAssertEqual(viewModel.messages.first?.messageRole, .assistant)
    }
    
    func testInit_SetsUserEmail() async throws {
        // Then
        XCTAssertEqual(viewModel.userEmail, "test@example.com")
    }
    
    // MARK: - State Tests
    
    func testCanSend_ReturnsFalseWhenEmpty() async throws {
        // Given
        viewModel.inputText = ""
        
        // Then
        XCTAssertFalse(viewModel.canSend)
    }
    
    func testCanSend_ReturnsFalseWhenWhitespace() async throws {
        // Given
        viewModel.inputText = "   "
        
        // Then
        XCTAssertFalse(viewModel.canSend)
    }
    
    func testCanSend_ReturnsTrueWithText() async throws {
        // Given
        viewModel.inputText = "Hello"
        viewModel.isLoading = false
        viewModel.isStreaming = false
        
        // Then
        XCTAssertTrue(viewModel.canSend)
    }
    
    func testCanSend_ReturnsFalseWhenLoading() async throws {
        // Given
        viewModel.inputText = "Hello"
        viewModel.isLoading = true
        
        // Then
        XCTAssertFalse(viewModel.canSend)
    }
    
    func testCanSend_ReturnsFalseWhenStreaming() async throws {
        // Given
        viewModel.inputText = "Hello"
        viewModel.isStreaming = true
        
        // Then
        XCTAssertFalse(viewModel.canSend)
    }
    
    // MARK: - New Chat Tests
    
    func testStartNewChat_CreatesNewThread() async throws {
        // Given
        let originalThreadId = viewModel.currentThreadId
        
        // When
        viewModel.startNewChat()
        
        // Then
        XCTAssertNotEqual(viewModel.currentThreadId, originalThreadId)
    }
    
    func testStartNewChat_ClearsMessages() async throws {
        // Given - add a message
        let msg = LocalChatMessage(threadId: viewModel.currentThreadId, role: .user, content: "Test")
        viewModel.messages.append(msg)
        
        // When
        viewModel.startNewChat()
        
        // Then - should have only welcome message
        XCTAssertEqual(viewModel.messages.count, 1)
        XCTAssertEqual(viewModel.messages.first?.messageRole, .assistant)
    }
    
    func testStartNewChat_UpdatesHistory() async throws {
        // When
        viewModel.startNewChat()
        viewModel.startNewChat()
        
        // Then
        XCTAssertGreaterThanOrEqual(viewModel.chatHistory.count, 2)
    }
    
    // MARK: - History Tests
    
    func testLoadHistory_PopulatesHistory() async throws {
        // Given
        viewModel.startNewChat()
        viewModel.startNewChat()
        
        // When
        viewModel.loadHistory()
        
        // Then
        XCTAssertFalse(viewModel.chatHistory.isEmpty)
    }
    
    // MARK: - Thread Management Tests
    
    func testDeleteThread_RemovesFromHistory() async throws {
        // Given - create an additional thread so we have 2 total
        viewModel.startNewChat()
        viewModel.loadHistory()
        
        let initialCount = viewModel.chatHistory.count
        XCTAssertGreaterThanOrEqual(initialCount, 2, "Should have at least 2 threads")
        
        // Find a thread that is NOT the current one to avoid auto-creation of new thread
        let currentId = viewModel.currentThreadId
        let threadToDelete = viewModel.chatHistory.first(where: { $0.id != currentId })!
        
        // When
        viewModel.deleteThread(threadToDelete)
        
        // Then
        XCTAssertEqual(viewModel.chatHistory.count, initialCount - 1)
        XCTAssertFalse(viewModel.chatHistory.contains(where: { $0.id == threadToDelete.id }))
    }
    
    func testTogglePinThread_PinsThread() async throws {
        // Given
        let thread = viewModel.chatHistory.first!
        XCTAssertFalse(thread.isPinned)
        
        // When
        viewModel.togglePinThread(thread)
        
        // Then
        XCTAssertTrue(thread.isPinned)
    }
    
    // MARK: - Clear Chat Tests
    
    func testClearChat_RemovesMessages() async throws {
        // Given
        let msg = LocalChatMessage(threadId: viewModel.currentThreadId, role: .user, content: "Test")
        viewModel.messages.append(msg)
        viewModel.dataManager.saveMessage(msg)
        
        // When
        viewModel.clearChat()
        
        // Then - should have only welcome message
        XCTAssertEqual(viewModel.messages.count, 1)
    }
    
    // MARK: - Send Message Tests
    
    func testSendMessage_WithoutBirthData_SetsError() async throws {
        // Given
        viewModel.inputText = "What's my horoscope?"
        UserDefaults.standard.removeObject(forKey: "userBirthData")
        
        // When
        await viewModel.sendMessage()
        
        // Then
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertTrue(viewModel.errorMessage?.contains("birth data") ?? false)
    }
    
    func testSendMessage_ClearsInputText() async throws {
        // Given
        viewModel.inputText = "Hello"
        
        // Set up birth data
        let birthData = BirthData(
            dob: "1990-01-15",
            time: "10:30",
            latitude: 19.076,
            longitude: 72.877,
            cityOfBirth: "Mumbai"
        )
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(birthData) {
            UserDefaults.standard.set(data, forKey: "userBirthData")
        }
        
        // When
        await viewModel.sendMessage()
        
        // Then
        XCTAssertTrue(viewModel.inputText.isEmpty)
    }
    
    func testSendMessage_AddsUserMessage() async throws {
        // Given
        let birthData = BirthData(
            dob: "1990-01-15",
            time: "10:30",
            latitude: 19.076,
            longitude: 72.877,
            cityOfBirth: "Mumbai"
        )
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(birthData) {
            UserDefaults.standard.set(data, forKey: "userBirthData")
        }
        
        viewModel.inputText = "What's my horoscope?"
        let initialCount = viewModel.messages.count
        
        // When
        await viewModel.sendMessage()
        
        // Then - should have user message and AI response
        XCTAssertGreaterThan(viewModel.messages.count, initialCount)
    }
}
