import XCTest

/// Guardrail: the 10 static helpers on MarkdownTextView MUST stay `nonisolated`.
///
/// If even one drops back to MainActor-inherited isolation, Task.detached
/// becomes a no-op and AttributedString(markdown:) + NSRegularExpression
/// run on main. That caused the 0x8BADF00D scene-update SIGKILLs in
/// builds 415–426 (commit 663bfcc post-mortem). See docs/streaming_history.md.
final class MarkdownTextViewNonisolatedTests: XCTestCase {
    func testAllStaticHelpersAreNonisolated() throws {
        let path = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("ios_app/Components/Chat/MarkdownTextView.swift")
        let text = try String(contentsOf: path)

        let required = [
            "parse",
            "isDivider",
            "parseHeader",
            "parseBoldLabel",
            "isTableSeparator",
            "parseTableRow",
            "isNumberedListItem",
            "extractNumberedItem",
            "neutralizeDangerousMarkers",
            "stripAllMarkers",
        ]

        for helper in required {
            // For each helper that exists in the file, the line declaring it
            // must contain `nonisolated`. We match the declaration line by
            // looking for `static func <helper>` or `static var <helper>`.
            guard let declRange = text.range(of: "func \(helper)") ?? text.range(of: "var \(helper)") else {
                // If the helper has been renamed, the contract has changed.
                // Update this test deliberately rather than silently passing.
                XCTFail("Helper '\(helper)' not found — was it renamed? Update the guardrail list.")
                continue
            }
            // Walk back to the start of the line.
            let lineStart = text[..<declRange.lowerBound].range(of: "\n", options: .backwards)?.upperBound ?? text.startIndex
            let lineText = String(text[lineStart..<declRange.lowerBound])
            XCTAssertTrue(
                lineText.contains("nonisolated"),
                "Helper '\(helper)' must be declared `nonisolated static`. " +
                "See docs/streaming_history.md for why this is load-bearing."
            )
        }
    }
}
