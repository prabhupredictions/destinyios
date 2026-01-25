import SwiftUI

struct FloatingContextButton: View {
    let icon: String // SF Symbol
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            HapticManager.shared.play(.medium)
            action()
        }) {
            ZStack {
                // Glow
                Circle()
                    .fill(AppTheme.Colors.gold.opacity(0.3))
                    .frame(width: 70, height: 70)
                    .blur(radius: 12)
                
                // Button
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [AppTheme.Colors.goldChampagne, AppTheme.Colors.gold],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 56, height: 56)
                    .shadow(color: AppTheme.Colors.gold.opacity(0.5), radius: 10, x: 0, y: 3)
                
                // Icon
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(AppTheme.Colors.mainBackground) // Dark icon on gold
            }
        }
        .scaleEffect(isPressed ? 0.9 : 1.0)
        .animation(.spring(response: 0.3), value: isPressed)
        .overlay(
            // "Ask" Label Pulse (Optional)
            Circle()
                .stroke(AppTheme.Colors.gold.opacity(0.5), lineWidth: 1)
                .scaleEffect(1.2)
                .opacity(0.5)
                .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: true)
        )
    }
}
