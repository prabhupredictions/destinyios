import SwiftUI

/// Premium reading layout for AI prediction messages.
/// Canela italic question label → domain tag + kundali ring →
/// ritual progress → SF Pro Text body → depth layers → footer.
struct ReadingMessageView: View {
    let message: LocalChatMessage
    let userQuery: String
    let cosmicProgressSteps: [CosmicProgressStep]
    let isStreaming: Bool

    @State private var showCopied = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // Cosmic progress (fades in step by step during streaming)
            CosmicProgressView(steps: cosmicProgressSteps)

            // Reading body — rendered markdown, SF Pro Text 16px
            if !message.content.isEmpty && !isStreaming {
                MarkdownTextView(
                    content: message.content,
                    textColor: Color.white.opacity(0.92),
                    fontSize: 16
                )
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityIdentifier("reading_body_text")
                .padding(.bottom, 2)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
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
                        Text(showCopied ? "Copied" : "⎘ Copy")
                            .font(.system(size: 11))
                            .foregroundColor(showCopied
                                ? AppTheme.Colors.gold
                                : Color.white.opacity(0.3))
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("copy_button")

                    Spacer()

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
        .animation(.easeIn(duration: 0.5), value: isStreaming)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Destiny said: \(message.content)")
        .accessibilityIdentifier("reading_entry")
    }
}
