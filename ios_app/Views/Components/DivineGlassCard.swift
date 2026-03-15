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
                .fill(AppTheme.Colors.cardBackground)
            
            // 2. Gold Rim Border
            RoundedRectangle(cornerRadius: cornerRadius)
                .strokeBorder(
                    LinearGradient(
                        stops: [
                            .init(color: Color.white.opacity(0.8), location: 0.05),
                            .init(color: AppTheme.Colors.gold, location: 0.2),
                            .init(color: AppTheme.Colors.gold.opacity(0.3), location: 0.5),
                            .init(color: AppTheme.Colors.gold, location: 0.8),
                            .init(color: Color.white.opacity(0.7), location: 0.98)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
            
            // 3. Content
            content
                .padding(16)
        }
        .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 6)
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
