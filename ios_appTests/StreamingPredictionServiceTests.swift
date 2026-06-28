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

        // I-2: Hard guardrail — outside the .done handler, messages[idx].content
        // must NOT be mutated. Per-line proximity check: each line that performs
        // `messages[...].content = ...` must have a `DONE-ONLY-MUTATION` marker
        // within the previous 6 lines (or on the same line). And every marker
        // must pair with such an assignment within the next 6 lines — no
        // orphan markers planted to defeat the test.
        //
        // (Window=6 lets the marker sit above a multi-line explanatory comment
        // block that precedes the assignment, the dominant real-world pattern;
        // an unrelated assignment far from any marker still fails.)
        //
        // Regex matches: messages[<anything>].content = ...   (assignment, not equality)
        let lines = text.components(separatedBy: "\n")
        let assignmentRegex = try NSRegularExpression(
            pattern: #"messages\[[^\]]+\]\.content\s*="#
        )

        func lineMatchesAssignment(_ line: String) -> Bool {
            let range = NSRange(line.startIndex..., in: line)
            guard let m = assignmentRegex.firstMatch(in: line, range: range) else { return false }
            // Exclude == comparisons — the regex already requires single `=` not preceded
            // by `=`, but be defensive: peek at the next char after the match.
            let matchEnd = m.range.upperBound
            if matchEnd < line.utf16.count {
                let idx = line.index(line.startIndex, offsetBy: matchEnd, limitedBy: line.endIndex) ?? line.endIndex
                if idx < line.endIndex && line[idx] == "=" {
                    return false
                }
            }
            return true
        }

        let proximityWindow = 6

        // Pass 1: every assignment must have a marker within the window.
        var assignmentLineIndices: [Int] = []
        for (i, line) in lines.enumerated() where lineMatchesAssignment(line) {
            assignmentLineIndices.append(i)
            let lowerBound = max(0, i - proximityWindow)
            let windowLines = lines[lowerBound...i]
            let hasMarker = windowLines.contains { $0.contains("DONE-ONLY-MUTATION") }
            XCTAssertTrue(
                hasMarker,
                "Line \(i + 1) mutates messages[...].content but no DONE-ONLY-MUTATION marker " +
                "appears within the prior \(proximityWindow) lines:\n  \(line.trimmingCharacters(in: .whitespaces))"
            )
        }

        // Pass 2: every DONE-ONLY-MUTATION marker must pair with an assignment
        // within the next `proximityWindow` lines (or on the same line). Orphan markers fail.
        for (i, line) in lines.enumerated() where line.contains("DONE-ONLY-MUTATION") {
            let upperBound = min(lines.count - 1, i + proximityWindow)
            let windowLines = lines[i...upperBound]
            let hasAssignment = windowLines.contains { lineMatchesAssignment($0) }
            XCTAssertTrue(
                hasAssignment,
                "Line \(i + 1) carries DONE-ONLY-MUTATION but no messages[...].content = " +
                "assignment appears within the next \(proximityWindow) lines (orphan marker — must not exist)."
            )
        }

        // Sanity: at least one paired assignment exists (proving the test actually runs).
        XCTAssertGreaterThan(
            assignmentLineIndices.count, 0,
            "Expected at least one messages[idx].content = assignment in ChatViewModel.swift."
        )
    }
}
