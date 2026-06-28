import XCTest

/// The streaming bubble MUST NOT import MarkdownTextView or call
/// AttributedString(markdown:). The whole point of the streaming-firewall
/// architecture is that partial token streams never reach the markdown
/// parser — that's what caused the 0x8BADF00D SIGKILLs in builds 415–426.
///
/// This test reads the file as text and asserts the forbidden symbols are
/// absent. Compiles in seconds, no simulator needed.
final class StreamingBubbleFirewallTests: XCTestCase {
    func testStreamingBubbleHasNoMarkdownReferences() throws {
        let path = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("ios_app/Components/Chat/StreamingBubbleView.swift")
        let text = try String(contentsOf: path)
        for forbidden in [
            "MarkdownTextView",
            "AttributedString(markdown",
            "NSRegularExpression",
            "isSafeForAttributedString",
            "parseBlocksStatic",
        ] {
            XCTAssertFalse(
                text.contains(forbidden),
                "StreamingBubbleView contains forbidden reference: '\(forbidden)'. " +
                "The streaming-firewall architecture requires plain Text only during the stream. " +
                "See docs/streaming_history.md."
            )
        }
        // Positive assertion — must use SwiftUI Text.
        XCTAssertTrue(
            text.contains("Text(") || text.contains("Text(text)"),
            "StreamingBubbleView must render via SwiftUI Text."
        )
    }
}
