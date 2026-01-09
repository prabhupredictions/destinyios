import SwiftUI

/// Premium Dasha Insight Card
/// Shows current dasha period with quality badge, theme, and meaning
struct DashaInsightCard: View {
    let dasha: DashaInsight
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header Row: Period + Quality Badge
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
                
                // Period Name (no "Current Dasha" label - header is external now)
                Text(dasha.period)
                    .font(AppTheme.Fonts.premiumDisplay(size: 17))
                    .foregroundColor(.white)
                
                Spacer()
                
                // Quality Badge
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
            
            // Meaning
            if let meaning = dasha.meaning, !meaning.isEmpty {
                Text(meaning)
                    .font(AppTheme.Fonts.body(size: 13))
                    .foregroundColor(Color.white.opacity(0.7))
                    .lineLimit(2)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.15, green: 0.12, blue: 0.08).opacity(0.8),
                            Color(red: 0.1, green: 0.08, blue: 0.05).opacity(0.9)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(AppTheme.Colors.gold.opacity(0.3), lineWidth: 1)
                )
        )
        .shadow(color: AppTheme.Colors.gold.opacity(0.15), radius: 10, x: 0, y: 5)
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
