import SwiftUI

struct DoshaStatusRow: View {
    let title: String
    let icon: String // SF Symbol name
    let statusText: String
    let statusColor: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            HapticManager.shared.play(.light)
            action()
        }) {
            HStack(spacing: 12) { // Reduced spacing from 16
                // Icon
                ZStack {
                    Circle()
                        .fill(AppTheme.Colors.gold.opacity(0.1))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(AppTheme.Colors.gold)
                }
                
                // Title
                Text(title)
                    .font(AppTheme.Fonts.body(size: 15).weight(.medium)) // Reduced from 16
                    .foregroundColor(AppTheme.Colors.textPrimary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7) // Allow scaling down to 70%
                    .multilineTextAlignment(.leading)
                    .layoutPriority(1) // Prioritize this taking space
                
                Spacer(minLength: 8) // Reduced min length
                
                // Status Badge
                HStack(spacing: 6) {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 6, height: 6)
                    
                    Text(statusText.uppercased())
                        .font(AppTheme.Fonts.body(size: 11).weight(.bold))
                        .foregroundColor(statusColor)
                        .fixedSize(horizontal: true, vertical: false)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(statusColor.opacity(0.15))
                        .overlay(
                            Capsule().stroke(statusColor.opacity(0.3), lineWidth: 1)
                        )
                )
                
                // Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold)) // Bolder, smaller chevron
                    .foregroundColor(AppTheme.Colors.textTertiary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.03)) // Ultra subtle fill
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle()) // No standard highlight
    }
}

/// Non-button version for use as NavigationLink label
struct DoshaStatusRowLabel: View {
    let title: String
    let icon: String // SF Symbol name
    let statusText: String
    let statusColor: Color
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(AppTheme.Colors.gold.opacity(0.1))
                    .frame(width: 44, height: 44)
                
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(AppTheme.Colors.gold)
            }
            
            // Title + Status (stacked vertically)
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(AppTheme.Fonts.body(size: 14).weight(.medium))
                    .foregroundColor(AppTheme.Colors.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                    .multilineTextAlignment(.leading)
                
                // Status Badge on second line
                HStack(spacing: 6) {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 6, height: 6)
                    
                    Text(statusText.uppercased())
                        .font(AppTheme.Fonts.body(size: 11).weight(.bold))
                        .foregroundColor(statusColor)
                        .fixedSize(horizontal: true, vertical: false)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    Capsule()
                        .fill(statusColor.opacity(0.15))
                        .overlay(
                            Capsule().stroke(statusColor.opacity(0.3), lineWidth: 1)
                        )
                )
            }
            
            Spacer(minLength: 8)
            
            // Chevron
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(AppTheme.Colors.textTertiary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
    }
}
