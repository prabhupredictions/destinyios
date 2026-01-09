import SwiftUI

/// A component representing a "physical" slab of glass with a gold chamfered edge.
/// This is the core visual atom of the "Divine Luxury" aesthetic (Sensory Home 2.0).
/// Used for: Hero Cards, Feature Slabs, Important Alerts.
// MARK: - The "Divine Crystal" Card (Luminous & Live)
struct DivineGlassCard<Content: View>: View {
    let content: Content
    var cornerRadius: CGFloat = 24
    var active: Bool = true // For animations later
    
    init(cornerRadius: CGFloat = 24, @ViewBuilder content: () -> Content) {
        self.cornerRadius = cornerRadius
        self.content = content()
    }
    
    var body: some View {
        ZStack {
            // 1. Crystal Base (Tinted Glass)
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.1, green: 0.12, blue: 0.18).opacity(0.8),  // Dark blue tint
                            Color(red: 0.08, green: 0.1, blue: 0.15).opacity(0.9)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            // 2. Glass Material Overlay
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(.ultraThinMaterial)
                .opacity(0.5)
            
            // 3. Inner Depth Layer (Simulates Thickness)
            RoundedRectangle(cornerRadius: cornerRadius)
                .strokeBorder(Color.black.opacity(0.4), lineWidth: 4)
                .blur(radius: 6)
                .mask(RoundedRectangle(cornerRadius: cornerRadius))
            
            // 4. Surface Gloss (Visible Sheen)
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.25),
                            Color.clear,
                            Color.white.opacity(0.08)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .blendMode(.overlay)
            
            // 5. The "Rim Light" Bevel (Bright Gold Edge)
            RoundedRectangle(cornerRadius: cornerRadius)
                .strokeBorder(
                    LinearGradient(
                        stops: [
                            .init(color: Color.white.opacity(1.0), location: 0.05), // Pure white highlight
                            .init(color: AppTheme.Colors.gold, location: 0.2), // Solid gold
                            .init(color: AppTheme.Colors.gold.opacity(0.3), location: 0.5),
                            .init(color: AppTheme.Colors.gold, location: 0.8), // Gold return
                            .init(color: Color.white.opacity(0.9), location: 0.98) // Rim light
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5 // Thicker for visibility
                )
            
            // 6. Ambient Glow
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(AppTheme.Colors.gold.opacity(0.2), lineWidth: 4)
                .blur(radius: 10)
            
            // 7. Content
            content
                .padding(16)
        }
        // 8. Physicality
        .tilt3D(intensity: 12)
        .premiumInertia(intensity: 0.7)
        .shadow(color: Color.black.opacity(0.5), radius: 15, x: 0, y: 10)
    }
}

#Preview {
    ZStack {
        CosmicBackgroundView().ignoresSafeArea()
        
        DivineGlassCard {
            Text("Luminous Crystal")
                .font(AppTheme.Fonts.premiumDisplay(size: 24))
                .goldGradient()
        }
        .padding(40)
    }
}
#Preview {
    ZStack {
        CosmicBackgroundView().ignoresSafeArea()
        
        DivineGlassCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("Cosmic Vibe")
                    .font(AppTheme.Fonts.premiumDisplay(size: 24))
                    .goldGradient()
                
                Text("Today is powerful for bold moves.")
                    .font(AppTheme.Fonts.body(size: 16))
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(30)
    }
}
