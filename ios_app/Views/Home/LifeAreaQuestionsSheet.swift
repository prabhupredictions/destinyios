import SwiftUI

/// Premium Ask Destiny Sheet showing mind questions from API
struct AskDestinyQuestionsSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    // Mind questions from API
    let suggestedQuestions: [String]
    
    // Callback when question is selected
    let onQuestionSelected: (String) -> Void
    
    // Animation state
    @State private var isAppearing = false
    @State private var customQuestion = ""
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Dark background
                AppTheme.Colors.mainBackground
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 16) {
                        // Title
                        VStack(spacing: 8) {
                            Image(systemName: "sparkles")
                                .font(AppTheme.Fonts.title(size: 28))
                                .foregroundColor(AppTheme.Colors.gold)
                            
                            Text("Ask Destiny")
                                .font(.system(size: 24, weight: .semibold, design: .serif))
                                .foregroundColor(AppTheme.Colors.gold)
                            
                            Text("What's on your mind today?")
                                .font(AppTheme.Fonts.body(size: 14))
                                .foregroundColor(AppTheme.Colors.textSecondary)
                        }
                        .padding(.top, 10)
                        .opacity(isAppearing ? 1 : 0)
                        .offset(y: isAppearing ? 0 : -10)
                        
                        // Question Cards - from mind_questions
                        ForEach(Array(suggestedQuestions.enumerated()), id: \.1) { index, question in
                            MindQuestionCard(question: question) {
                                onQuestionSelected(question)
                                dismiss()
                            }
                            .opacity(isAppearing ? 1 : 0)
                            .offset(x: isAppearing ? 0 : 50)
                            .animation(
                                .spring(response: 0.5, dampingFraction: 0.7)
                                .delay(Double(index) * 0.08),
                                value: isAppearing
                            )
                        }
                        
                        // Divider
                        HStack {
                            Rectangle()
                                .fill(AppTheme.Colors.textSecondary.opacity(0.3))
                                .frame(height: 1)
                            Text("or ask your own")
                                .font(AppTheme.Fonts.caption(size: 12))
                                .foregroundColor(AppTheme.Colors.textSecondary)
                            Rectangle()
                                .fill(AppTheme.Colors.textSecondary.opacity(0.3))
                                .frame(height: 1)
                        }
                        .padding(.top, 8)
                        .opacity(isAppearing ? 1 : 0)
                        
                        // Custom Input
                        HStack(spacing: 12) {
                            TextField("Type your question...", text: $customQuestion)
                                .foregroundColor(AppTheme.Colors.textPrimary)
                                .font(AppTheme.Fonts.body(size: 16))
                                .focused($isInputFocused)
                                .submitLabel(.send)
                                .onSubmit {
                                    if !customQuestion.isEmpty {
                                        onQuestionSelected(customQuestion)
                                        dismiss()
                                    }
                                }
                            
                            Button(action: {
                                if !customQuestion.isEmpty {
                                    onQuestionSelected(customQuestion)
                                    dismiss()
                                }
                            }) {
                                Image(systemName: "arrow.up.circle.fill")
                                    .font(AppTheme.Fonts.title(size: 28))
                                    .foregroundColor(customQuestion.isEmpty ? AppTheme.Colors.textSecondary : AppTheme.Colors.gold)
                            }
                            .disabled(customQuestion.isEmpty)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(AppTheme.Colors.cardBackground)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(AppTheme.Colors.gold.opacity(0.3), lineWidth: 1)
                                )
                        )
                        .opacity(isAppearing ? 1 : 0)
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(AppTheme.Fonts.title(size: 24))
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                }
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.3)) {
                isAppearing = true
            }
        }
    }
}

// MARK: - Mind Question Card (simple text card)
struct MindQuestionCard: View {
    let question: String
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Text(question)
                    .font(AppTheme.Fonts.body(size: 16))
                    .foregroundColor(AppTheme.Colors.textPrimary)
                    .multilineTextAlignment(.leading)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(AppTheme.Fonts.title(size: 14))
                    .foregroundColor(AppTheme.Colors.gold.opacity(0.6))
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(AppTheme.Colors.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(AppTheme.Colors.gold.opacity(0.25), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview
#Preview {
    AskDestinyQuestionsSheet(
        suggestedQuestions: [
            "What steps can enhance my career growth?",
            "How can I improve my health routine?",
            "What strategies can strengthen my family relationships?",
            "What financial decisions should I consider today?"
        ],
        onQuestionSelected: { question in
            print("Selected: \(question)")
        }
    )
}
