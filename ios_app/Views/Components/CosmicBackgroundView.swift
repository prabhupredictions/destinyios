import SwiftUI

/// Premium cosmic background with rotating nebulae and twinkling stars
/// Responds to device tilt for parallax effect
///
/// BATTERY OPTIMIZATION v2: Made fully static. This view is instantiated 41+ times
/// across the app — even GPU-driven repeatForever animations compound to significant drain.
/// Static nebulae + stars provide the same premium look at zero animation cost.
struct CosmicBackgroundView: View {
    private let nebulaRotation: Double = 25 // Fixed aesthetic angle
    private let starBrightness: Double = 0.7 // Fixed comfortable brightness
    
    private let stars: [Star]
    
    init() {
        // Generate random star positions
        var generatedStars: [Star] = []
        for _ in 0..<AppTheme.Onboarding.starCount {
            generatedStars.append(Star(
                x: CGFloat.random(in: 0...1),
                y: CGFloat.random(in: 0...1),
                size: CGFloat.random(in: AppTheme.Onboarding.starMinSize...AppTheme.Onboarding.starMaxSize),
                opacity: Double.random(in: 0.3...0.9)
            ))
        }
        self.stars = generatedStars
    }
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Deep space background
                AppTheme.Colors.mainBackground
                    .ignoresSafeArea()
                
                // Rotating nebula - gold (top-left)
                Circle()
                    .fill(AppTheme.CosmicGradients.nebulaGold)
                    .frame(width: AppTheme.Onboarding.nebulaSize, height: AppTheme.Onboarding.nebulaSize)
                    .blur(radius: AppTheme.Onboarding.nebulaBlur)
                    .offset(x: -geo.size.width * 0.3, y: -geo.size.height * 0.2)
                    .rotationEffect(.degrees(nebulaRotation))
                    .motionParallax(intensity: 1.5)
                
                // Rotating nebula - purple (bottom-right)
                Circle()
                    .fill(AppTheme.CosmicGradients.nebulaPurple)
                    .frame(width: AppTheme.Onboarding.nebulaSize * 0.7, height: AppTheme.Onboarding.nebulaSize * 0.7)
                    .blur(radius: AppTheme.Onboarding.nebulaBlur * 0.8)
                    .offset(x: geo.size.width * 0.35, y: geo.size.height * 0.3)
                    .rotationEffect(.degrees(-nebulaRotation * 0.7))
                    .motionParallax(intensity: 1.2)
                
                // Secondary gold nebula (center-bottom)
                Circle()
                    .fill(AppTheme.CosmicGradients.nebulaGold)
                    .frame(width: AppTheme.Onboarding.nebulaSize * 0.5, height: AppTheme.Onboarding.nebulaSize * 0.5)
                    .blur(radius: AppTheme.Onboarding.nebulaBlur * 0.6)
                    .offset(x: geo.size.width * 0.1, y: geo.size.height * 0.45)
                    .rotationEffect(.degrees(nebulaRotation * 0.5))
                    .motionParallax(intensity: 0.8)
                
                // Stars layer — gentle breathing glow (single animation, no timer)
                ForEach(Array(stars.enumerated()), id: \.offset) { _, star in
                    Circle()
                        .fill(AppTheme.Colors.goldLight)
                        .frame(width: star.size, height: star.size)
                        .position(
                            x: star.x * geo.size.width,
                            y: star.y * geo.size.height
                        )
                        .opacity(star.opacity * starBrightness)
                        .blur(radius: 0.5)
                }
                .motionParallax(intensity: 0.5)
            }
        }
        .accessibilityHidden(true)
    }
}

// MARK: - Star Model
private struct Star {
    let x: CGFloat
    let y: CGFloat
    let size: CGFloat
    let opacity: Double
}

#Preview {
    CosmicBackgroundView()
}
