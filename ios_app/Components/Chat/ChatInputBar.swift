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
                .font(.system(size: 16))
                .foregroundColor(Color("NavyPrimary"))
                .lineLimit(1...5)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color.white)
                        .shadow(color: Color.black.opacity(0.05), radius: 8, y: 2)
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
                    Circle()
                        .fill(
                            canSend
                            ? LinearGradient(
                                colors: [Color("NavyPrimary"), Color("NavyPrimary").opacity(0.85)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            : LinearGradient(
                                colors: [Color("NavyPrimary").opacity(0.3), Color("NavyPrimary").opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)
                        .shadow(
                            color: canSend ? Color("NavyPrimary").opacity(0.3) : Color.clear,
                            radius: 8,
                            y: 4
                        )
                    
                    if isLoading || isStreaming {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "arrow.up")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
            }
            .disabled(!canSend)
            .animation(.spring(response: 0.3), value: canSend)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            Color(red: 0.96, green: 0.95, blue: 0.98)
                .ignoresSafeArea(edges: .bottom)
        )
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
            .background(Color(red: 0.96, green: 0.95, blue: 0.98))
        }
    }
    
    return PreviewWrapper()
}
