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
        HStack(alignment: .bottom, spacing: 8) {
            // Text field — takes all available width
            TextField("Ask anything...", text: $text, axis: .vertical)
                .font(AppTheme.Fonts.body(size: 16))
                .foregroundColor(AppTheme.Colors.textPrimary)
                .lineLimit(1...5)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 22)
                        .fill(AppTheme.Colors.inputBackground)
                        .shadow(color: isFocused ? AppTheme.Colors.gold.opacity(0.15) : .clear, radius: 10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 22)
                                .stroke(isFocused ? AppTheme.Colors.gold : AppTheme.Colors.gold.opacity(0.3),
                                        lineWidth: isFocused ? 1.5 : 1)
                        )
                )
                .focused($isFocused)
                .onSubmit { if canSend { onSend() } }
                .accessibilityIdentifier("chat_input")

            // Style capsule (hidden while loading initial request only)
            if !isLoading {
                Button { showStyleSelector = true } label: {
                    HStack(spacing: 3) {
                        Text(lengthManager.currentLength.label)
                            .font(.system(size: 11, weight: .semibold))
                        Image(systemName: "chevron.up")
                            .font(.system(size: 9, weight: .bold))
                    }
                    .foregroundColor(AppTheme.Colors.gold)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(AppTheme.Colors.gold.opacity(0.1))
                            .overlay(Capsule().stroke(AppTheme.Colors.gold.opacity(0.3), lineWidth: 1))
                    )
                }
                .buttonStyle(.plain)
            }

            // Send / stop button
            Button(action: onSend) {
                ZStack {
                    Circle()
                        .fill(canSend ? AnyShapeStyle(AppTheme.Colors.premiumGradient) : AnyShapeStyle(AppTheme.Colors.surfaceBackground))
                        .frame(width: 42, height: 42)
                        .shadow(color: canSend ? AppTheme.Colors.gold.opacity(0.3) : .clear, radius: 8, y: 4)

                    if isLoading || isStreaming {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.Colors.gold))
                            .scaleEffect(0.75)
                    } else {
                        Image(systemName: "arrow.up")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(canSend ? AppTheme.Colors.mainBackground : AppTheme.Colors.textSecondary)
                    }
                }
            }
            .disabled(!canSend)
            .accessibilityLabel("a11y_send_message".localized)
            .accessibilityIdentifier("send_button")
            .animation(.spring(response: 0.3), value: canSend)
        }
        .padding(.horizontal, 16)
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
