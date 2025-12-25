import SwiftUI

/// List of tappable suggested questions
struct SuggestedQuestions: View {
    let questions: [String]
    var onQuestionTap: ((String) -> Void)? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section header
            Text("Ask Destiny")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Color("TextDark").opacity(0.6))
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
                    .font(.system(size: 15))
                    .foregroundColor(Color("NavyPrimary"))
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                
                Spacer()
                
                // Arrow indicator
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color("NavyPrimary").opacity(0.4))
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
                    .shadow(
                        color: Color.black.opacity(isPressed ? 0.02 : 0.04),
                        radius: isPressed ? 4 : 8,
                        y: isPressed ? 1 : 2
                    )
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
