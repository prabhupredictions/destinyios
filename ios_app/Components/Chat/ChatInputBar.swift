import SwiftUI

/// Input bar for composing chat messages
struct ChatInputBar: View {
    @Binding var text: String
    @FocusState.Binding var isFocused: Bool
    let isLoading: Bool
    let isStreaming: Bool
    let onSend: () -> Void
    
    private var canSend: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isLoading && !isStreaming
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Text field
            TextField("Ask anything...", text: $text, axis: .vertical)
                .font(AppTheme.Fonts.body(size: 16))
                .foregroundColor(AppTheme.Colors.textPrimary)
                .lineLimit(1...5)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(AppTheme.Colors.inputBackground)
                        .shadow(color: isFocused ? AppTheme.Colors.gold.opacity(0.15) : .clear, radius: 10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(isFocused ? AppTheme.Colors.gold : AppTheme.Colors.gold.opacity(0.3), lineWidth: isFocused ? 1.5 : 1)
                        )
                )
                .focused($isFocused)
                .onSubmit {
                    if canSend {
                        onSend()
                    }
                }
            
            // Send button
            Button(action: onSend) {
                ZStack {
                    Group {
                        if canSend {
                            Circle()
                                .fill(AppTheme.Colors.premiumGradient)
                        } else {
                            Circle()
                                .fill(AppTheme.Colors.surfaceBackground)
                        }
                    }
                        .frame(width: 48, height: 48)
                        .shadow(
                            color: canSend ? AppTheme.Colors.gold.opacity(0.3) : Color.clear,
                            radius: 8,
                            y: 4
                        )
                    
                    if isLoading || isStreaming {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.Colors.gold))
                            .scaleEffect(0.9)
                    } else {
                        Image(systemName: "arrow.up")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(canSend ? AppTheme.Colors.mainBackground : AppTheme.Colors.textSecondary)
                    }
                }
            }
            .disabled(!canSend)
            .accessibilityLabel("Send message")
            .animation(.spring(response: 0.3), value: canSend)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(AppTheme.Colors.mainBackground)
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
                    isStreaming: false
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
