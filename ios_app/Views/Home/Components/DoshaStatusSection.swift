import SwiftUI

struct DoshaStatusSection: View {
    let mangalDosha: AstroMangalDoshaResult?
    let kalaSarpa: AstroKalaSarpaResult?
    
    var body: some View {
        if let mangal = mangalDosha, let kala = kalaSarpa {
            VStack(alignment: .leading, spacing: 10) {
                // Header
                Text("Dosha Insights")
                    .font(AppTheme.Fonts.premiumDisplay(size: 18))
                    .goldGradient()
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        // Mangal Dosha Card
                        PremiumDoshaCard(
                            title: "Mangal Dosha",
                            status: mangal.hasDosha ? "Active" : "None",
                            severity: mangal.severity,
                            isPositive: !mangal.hasDosha,
                            icon: "flame.fill",
                            description: mangal.hasDosha ? "Mars influence present" : "No Mars affliction"
                        )
                        
                        // Kala Sarpa Card
                        PremiumDoshaCard(
                            title: "Kala Sarpa",
                            status: kala.yogaPresent ? "Active" : "None",
                            severity: kala.severity.capitalized,
                            isPositive: !kala.yogaPresent,
                            icon: "alternatives",
                            description: kala.yogaPresent ? (kala.yogaType ?? "Planetary Hemming") : "Planets are free"
                        )
                    }
                    .padding(.horizontal, 12)
                }
            }
        }
    }
}

struct PremiumDoshaCard: View {
    let title: String
    let status: String
    let severity: String
    let isPositive: Bool
    let icon: String
    let description: String
    
    // Theme Colors
    var baseColor: Color {
        isPositive ? Color.green : Color.red
    }
    
    // Badge Color
    var badgeColor: Color {
        isPositive ? Color.green : (status.lowercased() == "active" ? Color.orange : Color.gray) // Active -> Orange/Red text
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header: Icon + Status Badge
            HStack(alignment: .center) {
                ZStack {
                    Circle()
                        .fill(baseColor.opacity(0.1))
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: icon)
                        .font(.system(size: 14))
                        .foregroundColor(baseColor)
                }
                
                Spacer()
                
                // Status Badge
                Text(status)
                    .font(AppTheme.Fonts.caption(size: 10))
                    .fontWeight(.bold)
                    .foregroundColor(baseColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .strokeBorder(baseColor.opacity(0.4), lineWidth: 1)
                            .background(Capsule().fill(baseColor.opacity(0.1)))
                    )
            }
            
            // Title
            Text(title)
                .font(AppTheme.Fonts.title(size: 14))
                .foregroundColor(AppTheme.Colors.textPrimary)
                .lineLimit(1)
            
            // Divider
            Rectangle()
                .fill(LinearGradient(
                    colors: [baseColor.opacity(0.5), .clear],
                    startPoint: .leading,
                    endPoint: .trailing
                ))
                .frame(height: 1)
            
            // Details: Description + Severity
            VStack(alignment: .leading, spacing: 2) {
                Text(severity.isEmpty ? "STATUS" : severity.uppercased())
                    .font(AppTheme.Fonts.caption(size: 9))
                    .foregroundColor(AppTheme.Colors.textTertiary)
                    .tracking(1)
                
                Text(description)
                    .font(AppTheme.Fonts.caption(size: 11))
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(width: 170, height: 160) // Matched to Yoga Card size
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.12, green: 0.12, blue: 0.14),
                            Color(red: 0.08, green: 0.08, blue: 0.10)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            baseColor.opacity(0.3),
                            Color.white.opacity(0.05)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        // Shadow matches base color
        .shadow(color: baseColor.opacity(0.08), radius: 10)
    }
}
