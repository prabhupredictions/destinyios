import XCTest
import SwiftUI
@testable import ios_app

final class AccessibilityBaselineTests: XCTestCase {
    /// CosmicProgressView must declare its accessibility label as a static
    /// string. Detected by string-grep — runtime would require UI testing.
    func testCosmicProgressLabelIsStatic() throws {
        let path = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("ios_app/Components/Chat/CosmicProgressView.swift")
        let text = try String(contentsOf: path)
        XCTAssertTrue(
            text.contains(".accessibilityLabel(\"Destiny is composing your reading\")"),
            "CosmicProgressView must have a static a11y label so VoiceOver doesn't re-read cycling text."
        )
        XCTAssertTrue(
            text.contains("accessibilityReduceMotion"),
            "CosmicProgressView must honor Reduce Motion."
        )
    }

    func testUserBubbleHasTextSelection() throws {
        let path = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("ios_app/Components/Chat/MessageBubble.swift")
        let text = try String(contentsOf: path)
        XCTAssertTrue(
            text.contains(".textSelection(.enabled)"),
            "User bubble Text must have .textSelection(.enabled) for copy/paste."
        )
    }
}
