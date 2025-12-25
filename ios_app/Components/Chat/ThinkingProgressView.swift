import SwiftUI

// MARK: - Thinking Progress View
/// Claude-like thinking display showing AI reasoning steps
struct ThinkingProgressView: View {
    let steps: [ThinkingStep]
    
    @State private var expandedStepId: UUID? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack(spacing: 8) {
                // Animated thinking indicator
                LoadingDots()
                
                Text("Analyzing your chart...")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color("NavyPrimary").opacity(0.7))
            }
            
            // Steps
            ForEach(steps) { step in
                ThinkingStepRow(step: step, isExpanded: expandedStepId == step.id)
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3)) {
                            expandedStepId = expandedStepId == step.id ? nil : step.id
                        }
                    }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color("NavyPrimary").opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color("GoldAccent").opacity(0.2), lineWidth: 1)
                )
        )
    }
}

// MARK: - Thinking Step Row
struct ThinkingStepRow: View {
    let step: ThinkingStep
    let isExpanded: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                Text(step.type.icon)
                    .font(.system(size: 12))
                
                Text(step.display)
                    .font(.system(size: 13))
                    .foregroundColor(Color("NavyPrimary").opacity(0.8))
                
                Spacer()
                
                if step.content != nil {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 10))
                        .foregroundColor(Color("NavyPrimary").opacity(0.4))
                }
            }
            
            // Expanded content
            if isExpanded, let content = step.content {
                Text(content.prefix(200) + (content.count > 200 ? "..." : ""))
                    .font(.system(size: 11))
                    .foregroundColor(Color("NavyPrimary").opacity(0.5))
                    .lineLimit(4)
                    .padding(.leading, 20)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Loading Dots Animation
struct LoadingDots: View {
    @State private var animating = [false, false, false]
    
    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(Color("GoldAccent"))
                    .frame(width: 6, height: 6)
                    .opacity(animating[index] ? 1 : 0.3)
                    .scaleEffect(animating[index] ? 1.2 : 0.8)
            }
        }
        .onAppear {
            for index in 0..<3 {
                withAnimation(
                    Animation.easeInOut(duration: 0.4)
                        .repeatForever(autoreverses: true)
                        .delay(Double(index) * 0.12)
                ) {
                    animating[index] = true
                }
            }
        }
    }
}

// MARK: - Preview
#Preview("Thinking Progress") {
    VStack(spacing: 20) {
        ThinkingProgressView(steps: [
            ThinkingStep(step: 1, type: .thought, display: "💭 Understanding your question...", content: nil),
            ThinkingStep(step: 2, type: .action, display: "🔧 Analyzing planetary positions...", content: "Checking Moon in 7th house"),
            ThinkingStep(step: 3, type: .observation, display: "📊 Found relevant transits", content: "Saturn transit through 7th house indicates...")
        ])
        
        Spacer()
    }
    .padding()
    .background(Color(red: 0.98, green: 0.97, blue: 0.99))
}
