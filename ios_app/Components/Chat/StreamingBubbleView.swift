import SwiftUI

/// Transient bubble rendered ONLY while a stream is active.
///
/// CRITICAL: This view must never import the markdown renderer or call
/// the AttributedString markdown initializer. Partial token streams handed
/// to the markdown parser caused the 0x8BADF00D SIGKILLs in builds 415–426.
/// The architectural firewall is that during streaming, we render plain Text;
/// once `.done` commits the final answer to SwiftData, the persisted
/// message renders via the existing MessageBubble → markdown renderer path.
///
/// See docs/streaming_history.md for the post-mortem.
struct StreamingBubbleView: View {
    let text: String
    var accessibilityLabel: String = "Assistant is composing"

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var caretVisible: Bool = true

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            VStack(alignment: .leading, spacing: 6) {
                // Plain Text — no AttributedString, no markdown. The stream
                // can drop tokens like '**' and partial fenced-code openings;
                // they render as literal characters until .done.
                HStack(alignment: .firstTextBaseline, spacing: 0) {
                    Text(text)
                        .font(AppTheme.Fonts.body(size: 16))
                        .foregroundColor(.white)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityLabel(accessibilityLabel)
                        .accessibilityValue(text)

                    // Blinking caret — frame-rate-paced, single character, free.
                    // Skipped under Reduce Motion.
                    if !reduceMotion {
                        Text("▍")
                            .font(AppTheme.Fonts.body(size: 16))
                            .foregroundColor(AppTheme.Colors.gold.opacity(caretVisible ? 0.9 : 0.2))
                            .accessibilityHidden(true)
                    }
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.black.opacity(0.35))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(AppTheme.Colors.gold.opacity(0.3), lineWidth: 1)
                    )
            )
            Spacer(minLength: 60)
        }
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                caretVisible.toggle()
            }
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        StreamingBubbleView(text: "")
        StreamingBubbleView(text: "The planets suggest a gentle")
        StreamingBubbleView(text: "Long-form streaming response with **markdown** that renders as literal characters until the .done event commits the message. This is by design — the streaming bubble is plain Text only.")
    }
    .padding()
    .background(Color.black)
}
