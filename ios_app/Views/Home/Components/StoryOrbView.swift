import SwiftUI

/// Instagram Stories-style life area orb — Premium Edition.
///
/// Visual recipe (researched from Instagram + premium astrology apps):
/// 1. Outer glow aura (status-colored, soft blur)
/// 2. Thick gradient ring (3.5pt AngularGradient) with gentle pulse
/// 3. 3pt transparent gap (matches dark background)
/// 4. Glass-like inner sphere with specular highlight
/// 5. Gold icon with subtle shadow
/// 6. Status dot (top-right) with dark border
/// 7. Area label below in gold uppercase
///
/// The combination of glow + ring + pulse makes it unmistakably tappable.
struct StoryOrbView: View {
    let icon: String
    let title: String
    let status: String // "Good", "Steady", "Caution"
    var size: CGFloat = 72 // Standardized: shows ~4.5 orbs on screen
    let action: () -> Void
    
    @State private var pulsePhase: Bool = false
    
    // Ring geometry
    private var ringWidth: CGFloat { 2.5 }
    private var gapWidth: CGFloat { 3 }
    private var innerSize: CGFloat { size - (ringWidth + gapWidth) * 2 }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack {
                    // 0. BREATHING OUTER RING (like Match screen PlanetBubble)
                    // This is the key "alive" indicator that invites tapping
                    Circle()
                        .stroke(
                            statusDotColor.opacity(pulsePhase ? 0.5 : 0.12),
                            lineWidth: 2
                        )
                        .frame(width: size + 8, height: size + 8)
                        .scaleEffect(pulsePhase ? 1.12 : 1.0)
                    
                    // 1. Glow Aura (soft, status-colored)
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    statusDotColor.opacity(pulsePhase ? 0.4 : 0.15),
                                    statusDotColor.opacity(0.08),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: size * 0.3,
                                endRadius: size * 0.7
                            )
                        )
                        .frame(width: size * 1.4, height: size * 1.4)
                        .blur(radius: 10)
                    
                    // 2. Gradient Ring (status-colored AngularGradient)
                    Circle()
                        .strokeBorder(
                            AngularGradient(
                                gradient: Gradient(colors: ringColors),
                                center: .center,
                                startAngle: .degrees(-90),
                                endAngle: .degrees(270)
                            ),
                            lineWidth: ringWidth
                        )
                        .frame(width: size, height: size)
                    
                    // 3. Glass inner sphere (dark with depth)
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color(red: 0.16, green: 0.18, blue: 0.24),
                                    Color(red: 0.10, green: 0.12, blue: 0.16),
                                    Color(red: 0.06, green: 0.08, blue: 0.12)
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: innerSize * 0.55
                            )
                        )
                        .frame(width: innerSize, height: innerSize)
                    
                    // 4. Specular highlight (top-left, glass refraction)
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.white.opacity(0.15),
                                    Color.white.opacity(0.03),
                                    Color.clear
                                ],
                                center: UnitPoint(x: 0.30, y: 0.28),
                                startRadius: 0,
                                endRadius: innerSize * 0.4
                            )
                        )
                        .frame(width: innerSize, height: innerSize)
                    
                    // 5. Gold definition ring
                    Circle()
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    AppTheme.Colors.gold.opacity(0.35),
                                    AppTheme.Colors.gold.opacity(0.12),
                                    AppTheme.Colors.gold.opacity(0.30)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                        .frame(width: innerSize, height: innerSize)
                    
                    // 6. Icon (gold gradient with glow)
                    Image(systemName: icon)
                        .font(.system(size: size * 0.28, weight: .semibold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [AppTheme.Colors.goldLight, AppTheme.Colors.gold],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .shadow(color: AppTheme.Colors.gold.opacity(0.6), radius: 6)
                    
                    // 7. Status dot (top-right)
                    Circle()
                        .fill(statusDotColor)
                        .frame(width: 11, height: 11)
                        .overlay(
                            Circle()
                                .strokeBorder(Color(red: 0.06, green: 0.08, blue: 0.12), lineWidth: 2.5)
                        )
                        .shadow(color: statusDotColor.opacity(0.8), radius: 4)
                        .offset(x: size * 0.34, y: -size * 0.34)
                }
                .frame(width: size + 16, height: size + 16)
                
                // Label below
                Text(title.localized)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(AppTheme.Colors.goldLight)
                    .tracking(0.3)
                    .lineLimit(1)
                    .frame(width: size + 8)
            }
        }
        .buttonStyle(StoryOrbButtonStyle())
        .accessibilityLabel("\(title): \(status)")
        .accessibilityHint("Double tap for details")
        .onAppear {
            // Staggered breathing animation (like PlanetBubble)
            let randomDelay = Double.random(in: 0...1.5)
            withAnimation(
                .easeInOut(duration: 1.8)
                .repeatForever(autoreverses: true)
                .delay(randomDelay)
            ) {
                pulsePhase = true
            }
        }
    }
    
    // MARK: - Status-based colors
    
    /// Gradient colors for the ring — vibrant, status-coded
    private var ringColors: [Color] {
        switch status.lowercased() {
        case "good", "excellent":
            return [
                Color(red: 0.15, green: 0.85, blue: 0.45),
                Color(red: 0.10, green: 0.70, blue: 0.55),
                Color(red: 0.20, green: 0.90, blue: 0.50),
                Color(red: 0.10, green: 0.75, blue: 0.40),
                Color(red: 0.15, green: 0.85, blue: 0.45)
            ]
        case "steady", "neutral":
            return [
                AppTheme.Colors.gold,
                Color(red: 0.95, green: 0.75, blue: 0.25),
                AppTheme.Colors.goldLight,
                Color(red: 0.85, green: 0.65, blue: 0.20),
                AppTheme.Colors.gold
            ]
        case "caution", "difficult", "challenging":
            return [
                Color(red: 0.92, green: 0.22, blue: 0.18),
                Color(red: 0.95, green: 0.50, blue: 0.18),
                Color(red: 0.90, green: 0.30, blue: 0.25),
                Color(red: 0.95, green: 0.45, blue: 0.15),
                Color(red: 0.92, green: 0.22, blue: 0.18)
            ]
        default:
            return [
                AppTheme.Colors.gold,
                AppTheme.Colors.goldLight,
                AppTheme.Colors.gold
            ]
        }
    }
    
    /// Solid dot color for the small status indicator
    private var statusDotColor: Color {
        switch status.lowercased() {
        case "good", "excellent": return Color(red: 0.15, green: 0.85, blue: 0.45)
        case "steady", "neutral": return AppTheme.Colors.gold
        case "caution", "difficult", "challenging": return Color(red: 0.92, green: 0.22, blue: 0.18)
        default: return AppTheme.Colors.gold
        }
    }
}

// MARK: - Custom Button Style (Instagram-like press effect)

/// Mimics Instagram's tap-down effect: scale to 0.88 with a snappy spring + slight brightness
struct StoryOrbButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.88 : 1.0)
            .brightness(configuration.isPressed ? 0.1 : 0)
            .animation(.spring(response: 0.2, dampingFraction: 0.65), value: configuration.isPressed)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        CosmicBackgroundView().ignoresSafeArea()
        
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                StoryOrbView(icon: "briefcase.fill", title: "Career", status: "Good") {}
                StoryOrbView(icon: "heart.fill", title: "Relationship", status: "Caution") {}
                StoryOrbView(icon: "banknote.fill", title: "Finance", status: "Steady") {}
                StoryOrbView(icon: "cross.case.fill", title: "Health", status: "Good") {}
                StoryOrbView(icon: "house.fill", title: "Family", status: "Steady") {}
            }
            .padding(.horizontal, 16)
        }
    }
}
