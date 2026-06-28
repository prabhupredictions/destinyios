import XCTest
@testable import ios_app

final class StreamingPredictionServiceTests: XCTestCase {
    /// Source-level assertions to lock invariants without spinning a network.
    func testServiceHasIdempotencyKeyHeader() throws {
        let path = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("ios_app/Services/StreamingPredictionService.swift")
        let text = try String(contentsOf: path)
        XCTAssertTrue(
            text.contains("Idempotency-Key"),
            "StreamingPredictionService must set the Idempotency-Key header per send."
        )
    }

    func testServiceUsesShortTimeout() throws {
        let path = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("ios_app/Services/StreamingPredictionService.swift")
        let text = try String(contentsOf: path)
        XCTAssertTrue(
            text.contains("270"),
            "timeoutIntervalForResource must be 270s (10% headroom below Cloud Run 300s)."
        )
        XCTAssertTrue(
            text.contains("waitsForConnectivity = false"),
            "waitsForConnectivity must be false so airplane-mode surfaces ≤5s, not 5min."
        )
    }

    func testServiceUsesInvalidateAndCancel() throws {
        let path = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("ios_app/Services/StreamingPredictionService.swift")
        let text = try String(contentsOf: path)
        XCTAssertTrue(
            text.contains("invalidateAndCancel"),
            "Cancel path must invalidateAndCancel() the session so the body byte stream actually exits."
        )
    }

    func testChatViewModelHasFlagRoutedSend() throws {
        let path = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("ios_app/ViewModels/ChatViewModel.swift")
        let text = try String(contentsOf: path)
        XCTAssertTrue(
            text.contains("AppConfig.shared.shouldStreamFor"),
            "ChatViewModel.sendMessage must gate on AppConfig.shared.shouldStreamFor(userId:)."
        )
        XCTAssertTrue(
            text.contains("sendMessageStreaming"),
            "ChatViewModel must define sendMessageStreaming."
        )
        // Hard guardrail: outside the .done handler, messages[idx].content must NOT be mutated.
        // We check by counting assignments — there should be a comment marker near each
        // assignment proving it's the .done path.
        let assignments = text.components(separatedBy: ".content = ").count - 1
        let doneMarkers = text.components(separatedBy: "DONE-ONLY-MUTATION").count - 1
        XCTAssertEqual(
            assignments, doneMarkers,
            "Every messages[idx].content = ... assignment must carry the DONE-ONLY-MUTATION marker comment."
        )
    }
}
