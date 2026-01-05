import SwiftUI

/// Beautiful planet detail card showing all planet info
/// Displayed in a 3x3 grid below the chart
struct PlanetDetailCard: View {
    let planet: PlanetDisplayInfo
    let signAbbrev: String?  // "Ge", "Ca", etc.
    
    // Planet colors for visual distinction
    private var planetColor: Color {
        switch planet.code {
        case "Su": return Color.orange
        case "Mo": return Color(red: 0.8, green: 0.85, blue: 0.9)
        case "Ma": return Color.red
        case "Me": return Color.green
        case "Ju": return Color.yellow
        case "Ve": return Color.pink
        case "Sa": return Color(red: 0.3, green: 0.3, blue: 0.5)
        case "Ra": return Color(red: 0.4, green: 0.4, blue: 0.6)
        case "Ke": return Color(red: 0.5, green: 0.4, blue: 0.3)
        default: return Color.gray
        }
    }
    
    private var planetSymbol: String {
        switch planet.code {
        case "Su": return "☉"
        case "Mo": return "☽"
        case "Ma": return "♂"
        case "Me": return "☿"
        case "Ju": return "♃"
        case "Ve": return "♀"
        case "Sa": return "♄"
        case "Ra": return "☊"
        case "Ke": return "☋"
        default: return "★"
        }
    }
    
    var body: some View {
        VStack(spacing: 4) {
            // Planet header
            HStack(spacing: 4) {
                // Symbol
                Text(planetSymbol)
                    .font(AppTheme.Fonts.body(size: 14))
                    .foregroundColor(planetColor)
                
                // Code
                Text(planet.code)
                    .font(AppTheme.Fonts.title(size: 11))
                    .foregroundColor(Color("GoldAccent"))
                
                Spacer()
                
                // Status indicators
                statusBadges
            }
            
            Divider()
                .background(Color.white.opacity(0.15))
            
            // Details
            VStack(alignment: .leading, spacing: 2) {
                // Sign
                if let sign = signAbbrev {
                    detailRow(icon: "house.fill", value: ChartConstants.signFullNames[sign] ?? sign)
                }
                
                // Nakshatra
                if let nak = planet.nakshatra, let pada = planet.pada {
                    detailRow(icon: "star.fill", value: "\(nak) - \(pada)")
                } else if let nak = planet.nakshatra {
                    detailRow(icon: "star.fill", value: nak)
                }
            }
        }
        .padding(8)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(red: 0.1, green: 0.1, blue: 0.2).opacity(0.6)) // Dark bluish glass
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(
                    LinearGradient(
                        colors: [.white.opacity(0.1), .clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.5
                )
        )
    }
    
    @ViewBuilder
    private var statusBadges: some View {
        HStack(spacing: 2) {
            if planet.isRetrograde {
                statusBadge(text: "R", color: .red)
            }
            if planet.isVargottama {
                statusBadge(text: "V", color: .purple)
            }
            if planet.isCombust {
                statusBadge(text: "C", color: .orange)
            }
        }
    }
    
    private func statusBadge(text: String, color: Color) -> some View {
        Text(text)
            .font(AppTheme.Fonts.title(size: 8))
            .foregroundColor(color.opacity(0.9))
            .frame(width: 14, height: 14)
            .background(
                Circle()
                    .fill(color.opacity(0.2))
                    .strokeBorder(color.opacity(0.5), lineWidth: 0.5)
            )
    }
    
    private func detailRow(icon: String, value: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(AppTheme.Fonts.caption(size: 8))
                .foregroundColor(Color("GoldAccent").opacity(0.8))
            Text(value)
                .font(AppTheme.Fonts.caption(size: 9))
                .foregroundColor(.white.opacity(0.8))
                .lineLimit(1)
        }
    }
}

/// Grid of 9 planet detail cards (3x3)
struct PlanetCardsGrid: View {
    let chartData: ChartData
    let chartType: SouthIndianChartView.ChartType
    
    // All 9 planets in standard order
    private let planetOrder = ["Sun", "Moon", "Mars", "Mercury", "Jupiter", "Venus", "Saturn", "Rahu", "Ketu"]
    
    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 8),
            GridItem(.flexible(), spacing: 8),
            GridItem(.flexible(), spacing: 8)
        ], spacing: 8) {
            ForEach(planetOrder, id: \.self) { planetName in
                if let info = planetInfo(for: planetName) {
                    PlanetDetailCard(
                        planet: info.planet,
                        signAbbrev: info.sign
                    )
                }
            }
        }
    }
    
    private func planetInfo(for name: String) -> (planet: PlanetDisplayInfo, sign: String?)? {
        switch chartType {
        case .d1:
            guard let pos = chartData.d1[name] else { return nil }
            return (
                planet: PlanetDisplayInfo(
                    id: name,
                    code: ChartConstants.planetShortCodes[name] ?? String(name.prefix(2)),
                    isRetrograde: pos.retrograde ?? false,
                    isVargottama: pos.vargottama ?? false,
                    isCombust: pos.combust ?? false,
                    nakshatra: pos.nakshatra,
                    pada: pos.pada
                ),
                sign: pos.sign
            )
        case .d9:
            guard let pos = chartData.d9[name] else { return nil }
            return (
                planet: PlanetDisplayInfo(
                    id: name,
                    code: ChartConstants.planetShortCodes[name] ?? String(name.prefix(2)),
                    isRetrograde: false,
                    isVargottama: false,
                    isCombust: false,
                    nakshatra: nil,
                    pada: nil
                ),
                sign: pos.sign
            )
        }
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 16) {
            Text("Planet Cards")
                .font(.headline)
            
            PlanetCardsGrid(
                chartData: ChartData(
                    d1: [
                        "Sun": D1PlanetPosition(house: 1, sign: "Ge", degree: 76.5, retrograde: false, vargottama: true, combust: false, nakshatra: "Ardra", pada: 3),
                        "Moon": D1PlanetPosition(house: 8, sign: "Cp", degree: 290.0, retrograde: false, vargottama: false, combust: false, nakshatra: "Shravana", pada: 1),
                        "Mars": D1PlanetPosition(house: 4, sign: "Vi", degree: 151.0, retrograde: true, vargottama: false, combust: false, nakshatra: "Hasta", pada: 2),
                        "Mercury": D1PlanetPosition(house: 1, sign: "Ge", degree: 91.0, retrograde: false, vargottama: false, combust: true, nakshatra: "Mrigashira", pada: 1),
                        "Jupiter": D1PlanetPosition(house: 5, sign: "Li", degree: 195.0, retrograde: false, vargottama: false, combust: false, nakshatra: "Swati", pada: 3),
                        "Venus": D1PlanetPosition(house: 2, sign: "Ca", degree: 102.0, retrograde: false, vargottama: false, combust: false, nakshatra: "Pushya", pada: 2),
                        "Saturn": D1PlanetPosition(house: 10, sign: "Pi", degree: 340.0, retrograde: true, vargottama: false, combust: false, nakshatra: "Revati", pada: 4),
                        "Rahu": D1PlanetPosition(house: 3, sign: "Le", degree: 135.0, retrograde: false, vargottama: false, combust: false, nakshatra: "Magha", pada: 1),
                        "Ketu": D1PlanetPosition(house: 9, sign: "Aq", degree: 315.0, retrograde: false, vargottama: false, combust: false, nakshatra: "Shatabhisha", pada: 3)
                    ],
                    d9: [:]
                ),
                chartType: .d1
            )
            .padding(.horizontal)
        }
        .padding()
    }
    .background(Color(red: 0.95, green: 0.94, blue: 0.96))
}
