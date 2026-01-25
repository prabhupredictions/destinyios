import SwiftUI

/// A premium, glass-morphic segmented control
/// "Levitating" selection with mystical glow
struct GlassSegmentedControl: View {
    let options: [String]
    @Binding var selectedIndex: Int
    
    // Customization
    var height: CGFloat = 44
    var cornerRadius: CGFloat = 22
    
    @Namespace private var segmentAnimation
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<options.count, id: \.self) { index in
                ZStack {
                    // Selection background
                    if selectedIndex == index {
                        Capsule()
                            .fill(AppTheme.Colors.premiumGradient)
                            .matchedGeometryEffect(id: "selection", in: segmentAnimation)
                            .shadow(color: AppTheme.Colors.gold.opacity(0.4), radius: 6, x: 0, y: 2)
                    }
                    
                    // Text
                    Text(options[index])
                        .font(AppTheme.Fonts.body(size: 15).weight(.medium))
                        .foregroundColor(selectedIndex == index ? AppTheme.Colors.mainBackground : AppTheme.Colors.textSecondary)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    HapticManager.shared.play(.light)
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedIndex = index
                    }
                }
            }
        }
        .frame(height: height)
        .padding(3)
        .background(
            Capsule()
                .fill(Color.black.opacity(0.3)) // Darker, more subtle background
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(0.1), lineWidth: 0.5) // Fainter border
                )
        )
    }
}

#Preview {
    ZStack {
        AppTheme.Colors.mainBackground.ignoresSafeArea()
        GlassSegmentedControl(options: ["You", "Partner"], selectedIndex: .constant(0))
            .padding()
    }
}
