import SwiftUI

struct TransitsView: View {
    let transitResponse: TransitResponse?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.system(size: 14))
                    .foregroundColor(Color("GoldAccent"))
                
                Text("Transits (\(transitResponse?.year ?? 2024))")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppTheme.Colors.textPrimary)
            }
            
            if let transits = transitResponse?.transits {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(Array(transits.keys).sorted(), id: \.self) { planet in
                        if let events = transits[planet] {
                            TransitPlanetSection(planet: planet, events: events)
                        }
                    }
                }
            } else {
                Text("Select a year to view transits")
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

struct TransitPlanetSection: View {
    let planet: String
    let events: [TransitEvent]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(planet)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(Color("NavyPrimary"))
            
            ForEach(events, id: \.date) { event in
                HStack {
                    Text(event.date)
                        .font(.custom("Menlo", size: 12))
                        .foregroundColor(.secondary)
                    
                    Image(systemName: "arrow.right")
                        .font(.system(size: 10))
                        .foregroundColor(.gray)
                    
                    Text("\(event.sign) (H\(event.houseFromLagna))")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color("NavyPrimary"))
                }
                .padding(.leading, 8)
            }
        }
        .padding(.bottom, 8)
    }
}
