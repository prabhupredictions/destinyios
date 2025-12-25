import XCTest
import SwiftData
@testable import ios_app

/// Tests for DataManager SwiftData operations
@MainActor
final class DataManagerTests: XCTestCase {
    
    var dataManager: DataManager!
    
    override func setUp() async throws {
        try await super.setUp()
        // Use in-memory data manager for isolation
        dataManager = DataManager(inMemory: true)
    }
    
    override func tearDown() async throws {
        dataManager.clearAllData()
        dataManager = nil
        try await super.tearDown()
    }
    
    // MARK: - Session Tests
    
    func testGetOrCreateSession_CreatesNewSession() async throws {
        // Given
        let email = "test@example.com"
        
        // When
        let session = dataManager.getOrCreateSession(for: email)
        
        // Then
        XCTAssertEqual(session.userEmail, email)
        XCTAssertTrue(session.isActive)
        XCTAssertNotNil(session.sessionId)
    }
    
    func testGetOrCreateSession_ReturnsExistingSession() async throws {
        // Given
        let email = "test@example.com"
        let firstSession = dataManager.getOrCreateSession(for: email)
        
        // When
        let secondSession = dataManager.getOrCreateSession(for: email)
        
        // Then
        XCTAssertEqual(firstSession.sessionId, secondSession.sessionId)
    }
    
    func testGetSession_ReturnsNilForNonexistent() async throws {
        // When
        let session = dataManager.getSession(id: "nonexistent-id")
        
        // Then
        XCTAssertNil(session)
    }
    
    // MARK: - Thread Tests
    
    func testCreateThread_CreatesNewThread() async throws {
        // Given
        let session = dataManager.getOrCreateSession(for: "test@example.com")
        
        // When
        let thread = dataManager.createThread(
            sessionId: session.sessionId,
            userEmail: session.userEmail,
            title: "Test Thread"
        )
        
        // Then
        XCTAssertEqual(thread.title, "Test Thread")
        XCTAssertEqual(thread.sessionId, session.sessionId)
        XCTAssertEqual(thread.messageCount, 0)
        XCTAssertFalse(thread.isArchived)
        XCTAssertFalse(thread.isPinned)
    }
    
    func testFetchThreads_ReturnsThreadsForSession() async throws {
        // Given
        let session = dataManager.getOrCreateSession(for: "test@example.com")
        _ = dataManager.createThread(sessionId: session.sessionId, userEmail: session.userEmail, title: "Thread 1")
        _ = dataManager.createThread(sessionId: session.sessionId, userEmail: session.userEmail, title: "Thread 2")
        
        // When
        let threads = dataManager.fetchThreads(for: session.sessionId)
        
        // Then
        XCTAssertEqual(threads.count, 2)
    }
    
    func testFetchThreads_ExcludesArchived() async throws {
        // Given
        let session = dataManager.getOrCreateSession(for: "test@example.com")
        let thread1 = dataManager.createThread(sessionId: session.sessionId, userEmail: session.userEmail)
        let thread2 = dataManager.createThread(sessionId: session.sessionId, userEmail: session.userEmail)
        dataManager.archiveThread(thread2)
        
        // When
        let threads = dataManager.fetchThreads(for: session.sessionId, includeArchived: false)
        
        // Then
        XCTAssertEqual(threads.count, 1)
        XCTAssertEqual(threads.first?.id, thread1.id)
    }
    
    func testTogglePinThread_PinsAndUnpins() async throws {
        // Given
        let session = dataManager.getOrCreateSession(for: "test@example.com")
        let thread = dataManager.createThread(sessionId: session.sessionId, userEmail: session.userEmail)
        XCTAssertFalse(thread.isPinned)
        
        // When - Pin
        dataManager.togglePinThread(thread)
        
        // Then
        XCTAssertTrue(thread.isPinned)
        
        // When - Unpin
        dataManager.togglePinThread(thread)
        
        // Then
        XCTAssertFalse(thread.isPinned)
    }
    
    func testDeleteThread_RemovesThread() async throws {
        // Given
        let session = dataManager.getOrCreateSession(for: "test@example.com")
        let thread = dataManager.createThread(sessionId: session.sessionId, userEmail: session.userEmail)
        let threadId = thread.id
        
        // When
        dataManager.deleteThread(thread)
        
        // Then
        let fetched = dataManager.getThread(id: threadId)
        XCTAssertNil(fetched)
    }
    
    // MARK: - Message Tests
    
    func testSaveMessage_PersistsMessage() async throws {
        // Given
        let session = dataManager.getOrCreateSession(for: "test@example.com")
        let thread = dataManager.createThread(sessionId: session.sessionId, userEmail: session.userEmail)
        
        let message = LocalChatMessage(
            threadId: thread.id,
            role: .user,
            content: "Hello world"
        )
        
        // When
        dataManager.saveMessage(message)
        
        // Then
        let messages = dataManager.fetchMessages(for: thread.id)
        XCTAssertEqual(messages.count, 1)
        XCTAssertEqual(messages.first?.content, "Hello world")
    }
    
    func testSaveMessage_UpdatesThreadMessageCount() async throws {
        // Given
        let session = dataManager.getOrCreateSession(for: "test@example.com")
        let thread = dataManager.createThread(sessionId: session.sessionId, userEmail: session.userEmail)
        
        // When
        let message = LocalChatMessage(threadId: thread.id, role: .user, content: "Test")
        dataManager.saveMessage(message)
        
        // Then
        XCTAssertEqual(thread.messageCount, 1)
    }
    
    func testFetchMessages_ReturnsSortedByDate() async throws {
        // Given
        let session = dataManager.getOrCreateSession(for: "test@example.com")
        let thread = dataManager.createThread(sessionId: session.sessionId, userEmail: session.userEmail)
        
        let msg1 = LocalChatMessage(threadId: thread.id, role: .user, content: "First")
        let msg2 = LocalChatMessage(threadId: thread.id, role: .assistant, content: "Second")
        
        dataManager.saveMessage(msg1)
        dataManager.saveMessage(msg2)
        
        // When
        let messages = dataManager.fetchMessages(for: thread.id)
        
        // Then
        XCTAssertEqual(messages.count, 2)
        XCTAssertEqual(messages[0].content, "First")
        XCTAssertEqual(messages[1].content, "Second")
    }
    
    // MARK: - Grouping Tests
    
    func testFetchThreadsGroupedByDate_GroupsCorrectly() async throws {
        // Given
        let session = dataManager.getOrCreateSession(for: "test@example.com")
        _ = dataManager.createThread(sessionId: session.sessionId, userEmail: session.userEmail, title: "Today Thread")
        
        // When
        let grouped = dataManager.fetchThreadsGroupedByDate(for: session.sessionId)
        
        // Then
        XCTAssertFalse(grouped.isEmpty)
        XCTAssertEqual(grouped.first?.0, "Today")
    }
    
    // MARK: - Cleanup Tests
    
    func testClearAllData_RemovesEverything() async throws {
        // Given
        let session = dataManager.getOrCreateSession(for: "test@example.com")
        let thread = dataManager.createThread(sessionId: session.sessionId, userEmail: session.userEmail)
        let message = LocalChatMessage(threadId: thread.id, role: .user, content: "Test")
        dataManager.saveMessage(message)
        
        // When
        dataManager.clearAllData()
        
        // Then
        let threads = dataManager.fetchThreads(for: session.sessionId)
        XCTAssertTrue(threads.isEmpty)
    }
}
