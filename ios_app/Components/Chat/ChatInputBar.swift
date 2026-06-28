import SwiftUI

/// Input bar for composing chat messages
struct ChatInputBar: View {
    @Binding var text: String
    let isLoading: Bool
    let isStreaming: Bool
    let onSend: () -> Void
    let onStop: () -> Void

    @FocusState private var isFocused: Bool
    @State private var showStyleSelector = false
    @State private var lengthManager = ResponseLengthManager.shared

    private var canSend: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isLoading && !isStreaming
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

            // Right side: Send while idle, Stop while generating.
            if isLoading || isStreaming {
                Button(action: onStop) {
                    Image(systemName: "stop.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AppTheme.Colors.gold)
                        .frame(width: 40, height: 36)
                }
                .accessibilityIdentifier("chat_stop_button")
                .accessibilityLabel("Stop generating")
            } else {
                Button(action: onSend) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(canSend ? AppTheme.Colors.gold : AppTheme.Colors.textSecondary.opacity(0.4))
                        .frame(width: 40, height: 36)
                }
                .accessibilityIdentifier("chat_send_button")
                .accessibilityLabel("Send")
                .disabled(!canSend)
                .animation(.spring(response: 0.3), value: canSend)
            }
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

        var body: some View {
            VStack {
                Spacer()
                ChatInputBar(
                    text: $text,
                    isLoading: false,
                    isStreaming: false,
                    onSend: { print("Send") },
                    onStop: { print("Stop") }
                )
            }
            .background(AppTheme.Colors.mainBackground)
        }
    }

    return PreviewWrapper()
}
