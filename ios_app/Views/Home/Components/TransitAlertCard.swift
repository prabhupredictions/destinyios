import SwiftUI

struct TransitAlertCard: View {
    let transits: [HomeViewModel.TransitDisplayData]
    
    // Filter for major planets
    var significantTransits: [HomeViewModel.TransitDisplayData] {
        transits.filter { ["Saturn", "Jupiter", "Rahu", "Ketu", "Mars"].contains($0.planet) }
    }
    
    var body: some View {
        if !significantTransits.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                // Header (Tiny)
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 10))
                        .foregroundColor(AppTheme.Colors.gold)
                    
                    Text("cosmic_shifts".localized)
                        .font(AppTheme.Fonts.caption(size: 11))
                        .fontWeight(.bold)
                        .foregroundColor(AppTheme.Colors.gold)
                    
                    Spacer()
                }
                .padding(.horizontal, 12)
                
                // Horizontal Scroll of Alerts
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(significantTransits) { transit in
                            HStack(spacing: 6) {
                                Text(transit.planet)
                                    .fontWeight(.semibold)
                                Text("transit_in".localized)
                                    .fontWeight(.light)
                                Text(transit.sign)
                                    .fontWeight(.medium)
                            }
                            .font(AppTheme.Fonts.caption(size: 11))
                            .foregroundColor(AppTheme.Colors.textPrimary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(AppTheme.Colors.cardBackground.opacity(0.1)) // More transparent
                            )
                        }
                    }
                    .padding(.horizontal, 12)
                }
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(AppTheme.Colors.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(
                        AppTheme.Colors.gold.opacity(0.5),
                        lineWidth: 2
                    )
            )
            .shadow(color: AppTheme.Colors.gold.opacity(0.08), radius: 8, x: 0, y: 4)
        }
    }
}
