import XCTest
import SwiftUI
@testable import ios_app

final class ChatInputBarStopTests: XCTestCase {
    /// Mirror Source struct so we can assert API shape from a unit test.
    /// If ChatInputBar's initializer changes, this fails to compile.
    func testChatInputBarHasOnStop() {
        let bar = ChatInputBar(
            text: .constant(""),
            isLoading: false,
            isStreaming: true,
            onSend: {},
            onStop: {}
        )
        // Existence of the initializer is the contract.
        _ = bar
    }
}
