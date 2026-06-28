import XCTest

/// Guardrail: dead typewriter symbols must not return.
/// String-grep test — runs in seconds, no simulator required.
final class TypewriterRemovalTests: XCTestCase {
    func testTypewriterSymbolsAreDeleted() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()  // ios_appTests/
            .deletingLastPathComponent()  // ios_app/
            .appendingPathComponent("ios_app")
        let banned = [
            "enableTypewriter",
            "typewriterTimer",
            "revealedContent",
            "typewriterFinished",
            "startTypewriter",
            "onTypewriterFinished",
            "onTypewriterProgress",
            "BlinkingCursor",
            "typewriterMessageId",
        ]
        let fm = FileManager.default
        let enumerator = fm.enumerator(at: root, includingPropertiesForKeys: nil)!
        for case let url as URL in enumerator where url.pathExtension == "swift" {
            let text = (try? String(contentsOf: url)) ?? ""
            for sym in banned {
                XCTAssertFalse(
                    text.contains(sym),
                    "Banned typewriter symbol '\(sym)' found in \(url.lastPathComponent). " +
                    "Streaming-typewriter v2 uses ChatViewModel.startTypewriterReveal, not in-bubble Timers."
                )
            }
        }
    }
}
