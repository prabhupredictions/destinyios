import SwiftUI

/// A celestial glass orb representing a life area.
/// Features: Gold rim, glass interior, status glow aura, icon.
struct CelestialOrbView: View {
    let icon: String
    let title: String
    let status: String // "Good", "Steady", "Caution"
    let action: () -> Void
    
    // Size - Compact for premium density (Instagram story style ~75-80pt)
    private let orbSize: CGFloat = 75
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) { // Compact spacing
                // The Orb - Simplified to blend with background like Transit orbs
                ZStack {
                    // 1. Status Glow Aura (Subtle)
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    statusColor.opacity(0.5),
                                    statusColor.opacity(0.2),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: orbSize * 0.3,
                                endRadius: orbSize * 0.7
                            )
                        )
                        // Tighter glow frame to prevent excessive whitespace
                        .frame(width: orbSize * 1.4, height: orbSize * 1.4)
                        .blur(radius: 12)
                    
                    // 2. Glass Sphere Base (Seamless Edge)
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color(red: 0.18, green: 0.2, blue: 0.26),
                                    Color(red: 0.12, green: 0.14, blue: 0.18),
                                    Color(red: 0.08, green: 0.1, blue: 0.14).opacity(0.6),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: orbSize * 0.52
                            )
                        )
                        .frame(width: orbSize, height: orbSize)
                    
                    // 3. Inner Glass Bubble (3D Depth)
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.white.opacity(0.12),
                                    Color.clear,
                                    Color.black.opacity(0.15)
                                ],
                                center: UnitPoint(x: 0.35, y: 0.35),
                                startRadius: 0,
                                endRadius: orbSize * 0.45
                            )
                        )
                        .frame(width: orbSize * 0.85, height: orbSize * 0.85)
                    
                    // 4. Subtle Top-Left Highlight
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.white.opacity(0.4),
                                    Color.white.opacity(0.1),
                                    Color.clear
                                ],
                                center: UnitPoint(x: 0.25, y: 0.25),
                                startRadius: 0,
                                endRadius: orbSize * 0.3
                            )
                        )
                        .frame(width: orbSize, height: orbSize)
                    
                    // 5. Thin Gold Ring (Subtle, like Transit orbs)
                    Circle()
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    AppTheme.Colors.gold.opacity(0.6),
                                    AppTheme.Colors.gold.opacity(0.3),
                                    AppTheme.Colors.gold.opacity(0.5)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                        .frame(width: orbSize, height: orbSize)
                    
                    // 6. Icon
                    Image(systemName: icon)
                        .font(.system(size: 24, weight: .light))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [AppTheme.Colors.goldLight, AppTheme.Colors.gold],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .shadow(color: AppTheme.Colors.gold.opacity(0.5), radius: 8)
                }
                // Tighter frame to show more items (scroll hint)
                .frame(width: orbSize * 1.4, height: orbSize * 1.4)
                
                // Title Below Orb (HIG Compliant)
                Text(title.localized)
                    .font(AppTheme.Fonts.caption(size: 11)) // iOS minimum
                    .fontWeight(.medium)
                    .foregroundColor(AppTheme.Colors.goldLight)
                    .tracking(1) // Letter spacing
                    .textCase(.uppercase)
            }
        }
        .buttonStyle(ScaleButtonStyle())
    }
    
    // Status Color
    private var statusColor: Color {
        switch status.lowercased() {
        case "good", "excellent":
            return Color.green
        case "steady", "neutral":
            return AppTheme.Colors.gold
        case "caution", "difficult", "challenging":
            return Color.red
        default:
            return AppTheme.Colors.gold
        }
    }
}

// MARK: - Sparkle Decoration
struct SparkleDecoration: View {
    var size: CGFloat = 6
    
    var body: some View {
        Image(systemName: "sparkle")
            .font(.system(size: size))
            .foregroundColor(AppTheme.Colors.goldLight)
            .opacity(0.8)
    }
}

#Preview {
    ZStack {
        CosmicBackgroundView().ignoresSafeArea()
        
        HStack(spacing: 20) {
            CelestialOrbView(icon: "briefcase.fill", title: "Career", status: "Good") {}
            CelestialOrbView(icon: "heart.fill", title: "Love", status: "Steady") {}
            CelestialOrbView(icon: "banknote.fill", title: "Finance", status: "Caution") {}
        }
    }
}
