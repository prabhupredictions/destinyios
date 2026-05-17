import SwiftUI

/// Input bar for composing chat messages
struct ChatInputBar: View {
    @Binding var text: String
    @FocusState.Binding var isFocused: Bool
    let isLoading: Bool
    let isStreaming: Bool
    let isTyping: Bool  // disable during typewriter effect
    let onSend: () -> Void

    @State private var showStyleSelector = false
    @State private var lengthManager = ResponseLengthManager.shared

    private var canSend: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isLoading && !isStreaming && !isTyping
    }

    var body: some View {
        // Single full-width pill — + and ↑ live inside
        HStack(alignment: .bottom, spacing: 0) {

            // + button (left, inside pill)
            if !isLoading {
                Button { showStyleSelector = true } label: {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(AppTheme.Colors.gold)
                        .frame(width: 40, height: 36)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("style_selector_button")
                .accessibilityLabel(lengthManager.currentLength.label)
            }

            // Text field — grows between the two buttons
            TextField("Ask anything...", text: $text, axis: .vertical)
                .font(.system(size: 16))
                .foregroundColor(AppTheme.Colors.textPrimary)
                .lineLimit(1...5)
                .padding(.vertical, 11)
                .frame(maxWidth: .infinity)
                .focused($isFocused)
                .onSubmit { if canSend { onSend() } }
                .accessibilityIdentifier("chat_input")

            // Send / loading indicator (right, inside pill)
            Button(action: onSend) {
                ZStack {
                    if isLoading || isStreaming {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.Colors.gold))
                            .scaleEffect(0.75)
                            .frame(width: 40, height: 36)
                    } else {
                        Image(systemName: "arrow.up")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(canSend ? AppTheme.Colors.gold : AppTheme.Colors.textSecondary.opacity(0.4))
                            .frame(width: 40, height: 36)
                    }
                }
            }
            .disabled(!canSend)
            .accessibilityLabel("a11y_send_message".localized)
            .accessibilityIdentifier("send_button")
            .animation(.spring(response: 0.3), value: canSend)
        }
        .padding(.leading, 4)
        .padding(.trailing, 4)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(AppTheme.Colors.inputBackground)
                .shadow(color: isFocused ? AppTheme.Colors.gold.opacity(0.12) : .clear, radius: 8)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(isFocused ? AppTheme.Colors.gold : AppTheme.Colors.gold.opacity(0.25),
                                lineWidth: isFocused ? 1.5 : 1)
                )
        )
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .padding(.bottom, 4)
        .background(AppTheme.Colors.mainBackground)
        .sheet(isPresented: $showStyleSelector) {
            ResponseLengthSheet()
        }
    }
}

// MARK: - Preview
#Preview {
    struct PreviewWrapper: View {
        @State private var text = ""
        @FocusState private var isFocused: Bool

        var body: some View {
            VStack {
                Spacer()
                ChatInputBar(
                    text: $text,
                    isFocused: $isFocused,
                    isLoading: false,
                    isStreaming: false,
                    isTyping: false
                ) {
                    print("Send: \(text)")
                    text = ""
                }
            }
            .background(AppTheme.Colors.mainBackground)
        }
    }

    return PreviewWrapper()
}
