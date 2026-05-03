import Foundation
import SwiftData

/// Sliding window of the last N messages to prevent LazyVStack recycling crash.
/// Older messages are paginated from SwiftData on demand via loadOlderPage().
@MainActor
@Observable
class MessageWindowManager {
    private let windowSize = 50
    private(set) var allMessages: [LocalChatMessage] = []
    private(set) var hasOlderMessages = false

    var visibleMessages: [LocalChatMessage] {
        if allMessages.count <= windowSize { return allMessages }
        return Array(allMessages.suffix(windowSize))
    }

    func replaceAll(_ messages: [LocalChatMessage]) {
        allMessages = messages
        hasOlderMessages = false
    }

    func append(_ message: LocalChatMessage) {
        allMessages.append(message)
    }

    func remove(id: String) {
        allMessages.removeAll { $0.id == id }
    }

    func removeLast() {
        guard !allMessages.isEmpty else { return }
        allMessages.removeLast()
    }

    func prepend(_ messages: [LocalChatMessage], hasMore: Bool) {
        allMessages = messages + allMessages
        hasOlderMessages = hasMore
    }

    func updateLast(content: String) {
        guard !allMessages.isEmpty else { return }
        allMessages[allMessages.count - 1].content = content
    }
}
