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
                    
                    Text("Cosmic Shifts")
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
                                Text("in")
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
            .background(
                // Dark Glass Strip (Cinematic Anchor)
                // Soft gradient bar that provides structure without hard edges
                LinearGradient(
                    colors: [
                        Color.black.opacity(0.0),
                        Color.black.opacity(0.4),
                        Color.black.opacity(0.4),
                        Color.black.opacity(0.0)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .padding(.vertical, -4) // Slight bleed
            )
            .overlay(
                EmptyView() // Removed outer golden border
            )
        }
    }
}
