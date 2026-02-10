import SwiftUI

/// A premium glass tab bar for filtering lists.
struct PremiumTabBar: View {
    let tabs: [String]
    @Binding var selectedTab: String
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(tabs, id: \.self) { tab in
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedTab = tab
                        }
                        HapticManager.shared.play(.light)
                    }) {
                        // Glass Pill
                        ZStack {
                            if selectedTab == tab {
                                // Active Glow
                                Capsule()
                                    .fill(AppTheme.Colors.gold.opacity(0.2))
                                    .blur(radius: 10)
                            }
                            
                            // Reusing DivineGlassCard logic but as Capsule
                            DivineGlassCard(cornerRadius: 100) {
                                Text(tab)
                                    .font(AppTheme.Fonts.caption(size: 13))
                                    .fontWeight(.medium)
                                    .foregroundColor(selectedTab == tab ? AppTheme.Colors.gold : .white.opacity(0.8))
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                            }
                            // Override styling for active state if needed? 
                            // DivineGlassCard handles the look well enough.
                        }
                    }
                    .buttonStyle(ScaleButtonStyle())
                    .accessibilityAddTraits(selectedTab == tab ? .isSelected : [])
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10) // Breathing room for shadows
        }
    }
}

#Preview {
    ZStack {
        CosmicBackgroundView().ignoresSafeArea()
        PremiumTabBar(tabs: ["All", "Good", "Steady", "Caution"], selectedTab: .constant("Good"))
    }
}
