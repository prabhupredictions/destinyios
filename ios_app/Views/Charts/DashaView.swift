import SwiftUI

struct DashaView: View {
    let dashaResponse: DashaResponse?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "hourglass")
                    .font(AppTheme.Fonts.body(size: 14))
                    .foregroundColor(Color("GoldAccent"))
                
                Text("Vimshottari Dasha (\(dashaResponse?.year ?? 2024))")
                    .font(AppTheme.Fonts.title(size: 14))
                    .foregroundColor(AppTheme.Colors.textPrimary)
            }
            
            if let periods = dashaResponse?.periods {
                VStack(spacing: 0) {
                    ForEach(periods, id: \.start) { period in
                        DashaRow(period: period)
                        if period.start != periods.last?.start {
                            Divider()
                        }
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white)
                        .shadow(color: Color.black.opacity(0.05), radius: 5, y: 2)
                )
            } else {
                Text("Select a year to view dasha periods")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 10, y: 4)
        )
    }
}

struct DashaRow: View {
    let period: DashaPeriod
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(period.mahadasha) - \(period.antardasha)")
                    .font(AppTheme.Fonts.title(size: 14))
                    .foregroundColor(Color("NavyPrimary"))
                Text(period.pratyantardasha)
                    .font(AppTheme.Fonts.caption(size: 12))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(period.start)
                    .font(AppTheme.Fonts.caption(size: 12))
                Text(period.end)
                    .font(AppTheme.Fonts.caption(size: 12))
            }
            .foregroundColor(Color("TextDark").opacity(0.6))
        }
        .padding()
    }
}
