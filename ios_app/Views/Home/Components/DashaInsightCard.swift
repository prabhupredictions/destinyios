import SwiftUI

/// Premium Dasha Insight Card with animated golden border
/// Professional layout: Steady badge top right, Arrow bottom right
struct DashaInsightCard: View {
    let dasha: DashaInsight
    
    @State private var shimmerAngle: Double = 0
    @State private var arrowScale: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            // Main content
            VStack(alignment: .leading, spacing: 12) {
                // Header Row: Icon + Period (Steady badge is in overlay at top right)
                HStack(spacing: 12) {
                    // Dasha Icon
                    ZStack {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [AppTheme.Colors.gold.opacity(0.4), AppTheme.Colors.gold.opacity(0.1)],
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: 25
                                )
                            )
                            .frame(width: 44, height: 44)
                        
                        Image(systemName: "sparkles")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(AppTheme.Colors.gold)
                    }
                    
                    // Period Name
                    Text(dasha.period)
                        .font(AppTheme.Fonts.premiumDisplay(size: 17))
                        .foregroundColor(.white)
                    
                    Spacer()
                }
                
                // Theme
                HStack(spacing: 8) {
                    Image(systemName: "theatermasks.fill")
                        .font(.system(size: 12))
                        .foregroundColor(AppTheme.Colors.gold.opacity(0.8))
                    
                    Text("Theme: \(dasha.theme)")
                        .font(AppTheme.Fonts.body(size: 14))
                        .fontWeight(.medium)
                        .foregroundColor(AppTheme.Colors.goldLight)
                }
                
                // Meaning (if available)
                if let meaning = dasha.meaning, !meaning.isEmpty {
                    Text(meaning)
                        .font(AppTheme.Fonts.body(size: 13))
                        .foregroundColor(Color.white.opacity(0.7))
                        .lineLimit(2)
                }
                
                // Spacer to push arrow to bottom
                Spacer(minLength: 0)
            }
            .padding(16)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            
            // Top Right: Quality Badge (overlay)
            VStack {
                HStack {
                    Spacer()
                    Text(dasha.quality)
                        .font(AppTheme.Fonts.caption(size: 11))
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(qualityColor)
                        )
                }
                Spacer()
            }
            .padding(.top, 16)
            .padding(.trailing, 16)
            
            // Bottom Right: Animated Arrow click indicator
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Image(systemName: "arrow.forward.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [AppTheme.Colors.goldLight, AppTheme.Colors.gold],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .scaleEffect(arrowScale)
                }
            }
            .padding(.bottom, 12)
            .padding(.trailing, 12)
        }
        .frame(minHeight: 120)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.10, green: 0.12, blue: 0.18).opacity(0.8),
                            Color(red: 0.08, green: 0.10, blue: 0.15).opacity(0.9)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(
                    AngularGradient(
                        gradient: Gradient(stops: [
                            .init(color: AppTheme.Colors.gold.opacity(0.1), location: 0.0),
                            .init(color: AppTheme.Colors.gold.opacity(0.6), location: 0.15),
                            .init(color: AppTheme.Colors.goldLight.opacity(0.9), location: 0.2),
                            .init(color: AppTheme.Colors.gold.opacity(0.6), location: 0.25),
                            .init(color: AppTheme.Colors.gold.opacity(0.1), location: 0.4),
                            .init(color: AppTheme.Colors.gold.opacity(0.05), location: 1.0)
                        ]),
                        center: .center,
                        startAngle: .degrees(shimmerAngle),
                        endAngle: .degrees(shimmerAngle + 360)
                    ),
                    lineWidth: 1.5
                )
        )
        .shadow(color: AppTheme.Colors.gold.opacity(0.08), radius: 8, x: 0, y: 4)
        .onAppear {
            // Animate the golden shimmer border (slower: 10s per rotation)
            withAnimation(.linear(duration: 10).repeatForever(autoreverses: false)) {
                shimmerAngle = 360
            }
            
            // Animate arrow pulse scale
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                arrowScale = 1.15
            }
        }
    }
    
    // MARK: - Computed Properties
    
    var qualityColor: Color {
        switch dasha.quality.lowercased() {
        case "good": return Color.green
        case "steady": return AppTheme.Colors.gold
        case "caution": return Color.orange
        default: return AppTheme.Colors.gold
        }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        
        VStack {
            DashaInsightCard(dasha: DashaInsight(
                period: "Rahu-Rahu-Rahu",
                quality: "Steady",
                theme: "Discipline & Structure",
                endDate: "2026-03-15",
                meaning: "Focus on long-term goals. Saturn rewards patience and hard work."
            ))
        }
    }
}
