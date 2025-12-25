import SwiftUI

/// Typing indicator showing animated dots
struct TypingIndicator: View {
    @State private var dotScale: [CGFloat] = [1, 1, 1]
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Avatar
            AvatarView()
            
            // Dots
            HStack(spacing: 6) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(Color("NavyPrimary").opacity(0.4))
                        .frame(width: 8, height: 8)
                        .scaleEffect(dotScale[index])
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.05), radius: 5, y: 2)
            )
            
            Spacer()
        }
        .onAppear {
            startAnimation()
        }
    }
    
    private func startAnimation() {
        // Staggered bounce animation
        for i in 0..<3 {
            withAnimation(
                .easeInOut(duration: 0.4)
                .repeatForever(autoreverses: true)
                .delay(Double(i) * 0.15)
            ) {
                dotScale[i] = 1.5
            }
        }
    }
}

// MARK: - Preview
#Preview {
    TypingIndicator()
        .padding()
        .background(Color(red: 0.96, green: 0.95, blue: 0.98))
}
