import SwiftUI

struct DashaProgressWidget: View {
    let currentPeriod: DashaPeriod?
    let upcomingPeriod: DashaPeriod?
    
    var body: some View {
        if let period = currentPeriod {
            HStack(spacing: 16) {
                // Progress Ring
                ZStack {
                    Circle()
                        .stroke(AppTheme.Colors.gold.opacity(0.1), lineWidth: 8)
                        .frame(width: 60, height: 60)
                    
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(
                            AppTheme.Colors.gold,
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .frame(width: 60, height: 60)
                    
                    Text(String(format: "percentage_format".localized, Int(progress * 100)))
                        .font(AppTheme.Fonts.caption(size: 10))
                        .foregroundColor(AppTheme.Colors.gold)
                }
                
                // Text Info
                VStack(alignment: .leading, spacing: 4) {
                    Text("current_phase".localized)
                        .font(.system(size: 11))
                        .foregroundColor(AppTheme.Colors.textSecondary)
                    
                    HStack(alignment: .bottom, spacing: 4) {
                        Text(localizedPlanetName(period.mahadasha))
                            .font(AppTheme.Fonts.title(size: 18))
                            .foregroundColor(AppTheme.Colors.textPrimary)
                        Text(String(format: "hyphen_format".localized, localizedPlanetName(period.antardasha)))
                            .font(AppTheme.Fonts.body(size: 14))
                            .foregroundColor(AppTheme.Colors.textSecondary)
                            .padding(.bottom, 2)
                    }
                    
                    if let end = formatDate(period.end) {
                        Text(String(format: "until_date_format".localized, end))
                            .font(AppTheme.Fonts.caption(size: 11))
                            .foregroundColor(AppTheme.Colors.textTertiary)
                    }
                }
                
                Spacer()
                
                // Next Up (Mini)
                if let next = upcomingPeriod {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("next_label".localized)
                            .font(AppTheme.Fonts.caption(size: 10))
                            .foregroundColor(AppTheme.Colors.textTertiary)
                        Text(localizedPlanetName(next.antardasha))
                            .font(AppTheme.Fonts.body(size: 12))
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(AppTheme.Colors.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        AppTheme.Colors.gold.opacity(0.5),
                        lineWidth: 2
                    )
            )
            .shadow(color: AppTheme.Colors.gold.opacity(0.08), radius: 8, x: 0, y: 4)
            .padding(.horizontal, 12)
        }
    }
    
    // Derived properties
    private var progress: Double {
        guard let period = currentPeriod,
              let start = parseDate(period.start),
              let end = parseDate(period.end) else { return 0 }
        
        let totalSpan = end.timeIntervalSince(start)
        let elapsed = Date().timeIntervalSince(start)
        return min(max(elapsed / totalSpan, 0), 1)
    }
    
    private func parseDate(_ dateString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: dateString)
    }
    
    private func formatDate(_ dateString: String) -> String? {
        guard let date = parseDate(dateString) else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }
    
    private func localizedPlanetName(_ planet: String) -> String {
        let key = planet.lowercased()
        switch key {
        case "sun": return "planet_sun".localized
        case "moon": return "planet_moon".localized
        case "mars": return "planet_mars".localized
        case "mercury": return "planet_mercury".localized
        case "jupiter": return "planet_jupiter".localized
        case "venus": return "planet_venus".localized
        case "saturn": return "planet_saturn".localized
        case "rahu": return "planet_rahu".localized
        case "ketu": return "planet_ketu".localized
        default: return planet
        }
    }
}
