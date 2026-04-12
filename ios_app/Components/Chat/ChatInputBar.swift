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
        VStack(spacing: 10) {
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
            
            // Bottom Controls Row
            HStack {
                // Style Selector Capsule
                Button {
                    showStyleSelector = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: lengthManager.currentLength.icon)
                            .font(.system(size: 12))
                        Text(lengthManager.currentLength.label)
                            .font(AppTheme.Fonts.body(size: 13).weight(.medium))
                        Image(systemName: "chevron.up")
                            .font(.system(size: 10, weight: .bold))
                            .padding(.leading, 2)
                    }
                    .foregroundColor(AppTheme.Colors.gold)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(AppTheme.Colors.gold.opacity(0.1))
                            .overlay(
                                Capsule()
                                    .stroke(AppTheme.Colors.gold.opacity(0.3), lineWidth: 1)
                            )
                    )
                }
                .buttonStyle(.plain)
                
                Spacer()
                
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
                        .frame(width: 44, height: 44) // slightly smaller in row layout
                        .shadow(
                            color: canSend ? AppTheme.Colors.gold.opacity(0.3) : Color.clear,
                            radius: 8,
                            y: 4
                        )
                        
                        if isLoading || isStreaming {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.Colors.gold))
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "arrow.up")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(canSend ? AppTheme.Colors.mainBackground : AppTheme.Colors.textSecondary)
                        }
                    }
                }
                .disabled(!canSend)
                .accessibilityLabel("a11y_send_message".localized)
                .animation(.spring(response: 0.3), value: canSend)
            }
            .padding(.horizontal, 4)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
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
