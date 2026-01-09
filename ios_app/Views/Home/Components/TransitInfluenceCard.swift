import SwiftUI

/// Premium Transit Influence Card matching reference mockup
/// Shows planet icon, badge, description with cosmic background
struct TransitInfluenceCard: View {
    let transit: TransitInfluence
    
    var body: some View {
        HStack(spacing: 16) {
            // Planet Icon (3D style)
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [planetGlowColor.opacity(0.6), planetGlowColor.opacity(0.1)],
                            center: .center,
                            startRadius: 0,
                            endRadius: 30
                        )
                    )
                    .frame(width: 56, height: 56)
                
                Image(systemName: planetSymbol)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.white, planetGlowColor],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: planetGlowColor.opacity(0.8), radius: 8)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                // Planet Name + Badge
                HStack(spacing: 8) {
                    Text("\(transit.planet) Transit")
                        .font(AppTheme.Fonts.premiumDisplay(size: 16))
                        .foregroundColor(.white)
                    
                    // Badge Pill
                    Text(transit.badge)
                        .font(AppTheme.Fonts.caption(size: 10))
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(badgeColor)
                        )
                }
                
                // Description
                Text(transit.description)
                    .font(AppTheme.Fonts.body(size: 13))
                    .foregroundColor(Color.white.opacity(0.8))
                    .lineLimit(2)
            }
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.black.opacity(0.4),
                            Color(red: 0.1, green: 0.1, blue: 0.15).opacity(0.6)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(badgeColor.opacity(0.3), lineWidth: 1)
                )
        )
        .shadow(color: badgeColor.opacity(0.2), radius: 10, x: 0, y: 5)
    }
    
    // MARK: - Computed Properties
    
    var planetSymbol: String {
        switch transit.planet.lowercased() {
        case "sun": return "sun.max.fill"
        case "moon": return "moon.fill"
        case "mars": return "flame.fill"
        case "mercury": return "sparkle"
        case "jupiter": return "globe"
        case "venus": return "heart.fill"
        case "saturn": return "circle.hexagongrid.fill"
        case "rahu": return "arrow.up.circle.fill"
        case "ketu": return "arrow.down.circle.fill"
        default: return "star.fill"
        }
    }
    
    var planetGlowColor: Color {
        switch transit.planet.lowercased() {
        case "sun": return Color.orange
        case "moon": return Color.white
        case "mars": return Color.red
        case "mercury": return Color.green
        case "jupiter": return Color.yellow
        case "venus": return Color.pink
        case "saturn": return Color.blue
        case "rahu": return Color.purple
        case "ketu": return Color.gray
        default: return AppTheme.Colors.gold
        }
    }
    
    var badgeColor: Color {
        switch transit.badgeType.lowercased() {
        case "positive": return Color.green
        case "caution": return Color.orange
        case "warning": return Color.red
        case "neutral": return Color.gray
        default: return AppTheme.Colors.gold
        }
    }
}

/// Compact Transit Orb (like CelestialOrbView for life areas)
struct TransitOrbView: View {
    let transit: TransitInfluence
    
    var body: some View {
        VStack(spacing: 8) { // iOS HIG: 8pt grid
            // Planet Orb
            ZStack {
                // Glow background
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [planetGlowColor.opacity(0.4), planetGlowColor.opacity(0.1)],
                            center: .center,
                            startRadius: 0,
                            endRadius: 30
                        )
                    )
                    .frame(width: 56, height: 56)
                
                // Icon
                Image(systemName: planetSymbol)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.white, planetGlowColor],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: planetGlowColor.opacity(0.8), radius: 6)
            }
            .overlay(alignment: .bottomTrailing) {
                // Status Dot
                Circle()
                    .fill(badgeColor)
                    .frame(width: 10, height: 10)
                    .overlay(
                        Circle()
                            .strokeBorder(Color.black, lineWidth: 1.5)
                    )
                    .offset(x: 4, y: 4)
            }
            
            // Planet Name
            Text(transit.planet)
                .font(AppTheme.Fonts.caption(size: 10))
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            // Sign (Full Name)
            Text(fullSignName)
                .font(AppTheme.Fonts.caption(size: 9))
                .foregroundColor(AppTheme.Colors.textSecondary)
        }
        .frame(width: 75) // Slightly wider to fit full sign names
    }
    
    // MARK: - Computed Properties
    
    var planetSymbol: String {
        switch transit.planet.lowercased() {
        case "sun": return "sun.max.fill"
        case "moon": return "moon.fill"
        case "mars": return "flame.fill"
        case "mercury": return "sparkle"
        case "jupiter": return "globe"
        case "venus": return "heart.fill"
        case "saturn": return "circle.hexagongrid.fill"
        case "rahu": return "arrow.up.circle.fill"
        case "ketu": return "arrow.down.circle.fill"
        default: return "star.fill"
        }
    }
    
    var planetGlowColor: Color {
        switch transit.planet.lowercased() {
        case "sun": return Color.orange
        case "moon": return Color.white
        case "mars": return Color.red
        case "mercury": return Color.green
        case "jupiter": return Color.yellow
        case "venus": return Color.pink
        case "saturn": return Color.blue
        case "rahu": return Color.purple
        case "ketu": return Color.gray
        default: return AppTheme.Colors.gold
        }
    }
    
    var badgeColor: Color {
        switch transit.badgeType.lowercased() {
        case "positive": return Color.green
        case "caution": return Color.orange
        case "warning": return Color.red
        case "neutral": return Color.gray
        default: return AppTheme.Colors.gold
        }
    }
    
    /// Convert abbreviated sign to full name
    var fullSignName: String {
        let signMap: [String: String] = [
            "Ar": "Aries", "Ta": "Taurus", "Ge": "Gemini",
            "Ca": "Cancer", "Le": "Leo", "Vi": "Virgo",
            "Li": "Libra", "Sc": "Scorpio", "Sg": "Sagittarius",
            "Cp": "Capricorn", "Aq": "Aquarius", "Pi": "Pisces"
        ]
        return signMap[transit.sign] ?? transit.sign
    }
}

/// Section displaying transit influences as horizontal scroll
struct TransitInfluencesSection: View {
    let transits: [TransitInfluence]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header (no extra padding - parent handles it)
            Text("Current Transits")
                .font(AppTheme.Fonts.premiumDisplay(size: 18))
                .goldGradient()
            
            // Horizontal Scroll Orbs (needs negative margin to go edge-to-edge)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    ForEach(transits) { transit in
                        TransitOrbView(transit: transit)
                    }
                }
                .padding(.horizontal, 12) // Match parent edge
                .padding(.vertical, 4)
            }
            .padding(.horizontal, -12) // Negative margin to extend to edges
        }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        
        VStack {
            TransitInfluencesSection(transits: [
                TransitInfluence(planet: "Saturn", sign: "Pisces", house: 10, description: "Saturn in 10th - Career responsibilities", badge: "Neutral", badgeType: "neutral"),
                TransitInfluence(planet: "Jupiter", sign: "Gemini", house: 1, description: "Jupiter blessing your Ascendant", badge: "Auspicious", badgeType: "positive"),
                TransitInfluence(planet: "Mars", sign: "Scorpio", house: 12, description: "Mars in 12th - Hidden conflicts may arise", badge: "Challenging", badgeType: "caution")
            ])
        }
    }
}
