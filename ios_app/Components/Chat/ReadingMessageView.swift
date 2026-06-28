import SwiftUI

/// Premium reading layout for AI prediction messages.
/// Canela italic question label → domain tag + kundali ring →
/// ritual progress → SF Pro Text body → depth layers → footer.
struct ReadingMessageView: View {
    let message: LocalChatMessage
    let userQuery: String
    let cosmicProgressSteps: [CosmicProgressStep]
    let isStreaming: Bool
    /// During streaming, the typewriter-revealed prefix of the answer (fed by
    /// ChatViewModel.streamingContent). Renders as live markdown so the user
    /// sees **bold**/headers/lists formatting appear as the text grows.
    /// On `.done`, ChatViewModel commits the full text to `message.content`
    /// and clears `streamingContent` — this view then renders `message.content`
    /// without re-parsing because the same MarkdownTextView instance receives
    /// the same final string at that instant.
    let streamingContent: String?

    @State private var showCopied = false

    /// What to render in the body. During the stream we show the typewriter
    /// buffer (live markdown); after `.done` we show the persisted content.
    private var displayContent: String {
        if isStreaming, let s = streamingContent, !s.isEmpty { return s }
        return message.content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // Cosmic progress (fades in step by step during streaming, hidden
            // the moment ANY answer text is on screen — token-stream or
            // typewriter — so the user never sees the progress card lingering
            // above the growing answer).
            if displayContent.isEmpty && cosmicProgressSteps.contains(where: { !$0.text.isEmpty }) {
                CosmicProgressView(steps: cosmicProgressSteps)
                    .transition(.opacity)
            }

            // Reading body — rendered markdown, SF Pro Text 16px.
            // Shown during streaming (typewriter buffer) AND after .done
            // (persisted content). The transition is just a content swap;
            // no opacity flash because the view is already on screen.
            if !displayContent.isEmpty {
                MarkdownTextView(
                    content: displayContent,
                    textColor: Color.white.opacity(0.92),
                    fontSize: 16
                )
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityIdentifier("reading_body_text")
                .padding(.bottom, 2)
            }

            // Depth layers and footer — only once streaming is done
            if !isStreaming && !message.content.isEmpty {
                DepthLayersView(
                    whyContent: message.advice,
                    timingContent: nil
                )
                .padding(.top, 4)

                HStack(spacing: 14) {
                    Button {
                        UIPasteboard.general.string = message.content
                        showCopied = true
                        HapticManager.shared.play(.light)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            showCopied = false
                        }
                    } label: {
                        Text(showCopied ? "copy_button_copied".localized : "copy_button_label".localized)
                            .font(.system(size: 11))
                            .foregroundColor(showCopied
                                ? AppTheme.Colors.gold
                                : Color.white.opacity(0.3))
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("copy_button")

                    Spacer()

                    if message.executionTimeMs > 0 {
                        Text("•")
                            .font(.system(size: 11))
                            .foregroundColor(Color.white.opacity(0.2))
                        Text(formatExecTime(message.executionTimeMs))
                            .font(.system(size: 11))
                            .foregroundColor(Color.white.opacity(0.2))
                    }

                    Text(message.createdAt, style: .time)
                        .font(.system(size: 11))
                        .foregroundColor(Color.white.opacity(0.2))

                    InlineMessageRating(
                        message: message,
                        query: userQuery.isEmpty ? "General question" : userQuery,
                        responseText: String(message.content.prefix(500)),
                        predictionId: message.traceId
                    )
                }
                .padding(.top, 10)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Destiny said: \(message.content)")
        .accessibilityIdentifier("reading_entry")
    }

    private func formatExecTime(_ ms: Double) -> String {
        let seconds = ms / 1000
        if seconds < 1 { return String(format: "%.0fms", ms) }
        else if seconds < 60 { return String(format: "%.1fs", seconds) }
        else {
            let mins = Int(seconds) / 60
            let secs = Int(seconds) % 60
            return "\(mins)m \(secs)s"
        }
    }
}
