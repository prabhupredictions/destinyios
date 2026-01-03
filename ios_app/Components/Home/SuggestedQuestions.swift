import SwiftUI

/// List of tappable suggested questions
struct SuggestedQuestions: View {
    let questions: [String]
    var onQuestionTap: ((String) -> Void)? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section header
            Text("ask_destiny".localized)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Color("TextDark").opacity(0.7))
                .padding(.leading, 4)
            
            // Questions list
            VStack(spacing: 10) {
                ForEach(questions, id: \.self) { question in
                    QuestionRow(question: question) {
                        onQuestionTap?(question)
                    }
                }
            }
        }
    }
}

// MARK: - Question Row
struct QuestionRow: View {
    let question: String
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Question text
                Text(question)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(AppTheme.Colors.textPrimary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                
                Spacer()
                
                // Arrow indicator
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color("NavyPrimary").opacity(0.35))
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color("NavyPrimary").opacity(0.06), lineWidth: 1)
            )
            .shadow(
                color: Color("NavyPrimary").opacity(isPressed ? 0.03 : 0.06),
                radius: isPressed ? 6 : 12,
                x: 0,
                y: isPressed ? 2 : 4
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isPressed = false
                    }
                }
        )
    }
}

// MARK: - Preview
#Preview {
    SuggestedQuestions(
        questions: [
            "What should I be mindful of today?",
            "How can I improve my focus and productivity?",
            "What's a good time for important decisions?"
        ]
    ) { question in
        print("Selected: \(question)")
    }
    .padding()
    .background(Color(red: 0.96, green: 0.95, blue: 0.98))
}
