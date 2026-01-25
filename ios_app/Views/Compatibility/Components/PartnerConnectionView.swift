import SwiftUI

struct PartnerConnectionView: View {
    let boyName: String
    let girlName: String
    
    var body: some View {
        HStack(spacing: 24) {
            // Partner 1 (Left)
            PartnerAvatarPill(name: boyName, alignRight: true)
            
            // Connection Symbol
            ZStack {
                Circle()
                    .fill(AppTheme.Colors.gold.opacity(0.1))
                    .frame(width: 32, height: 32) // Reduced from 40 for elegance
                    .blur(radius: 4)
                
                Image(systemName: "link")
                    .font(.system(size: 12, weight: .bold)) // Smaller icon
                    .foregroundColor(AppTheme.Colors.gold)
                    .rotationEffect(.degrees(45))
            }
            .overlay(
                // Animated pulse or static glow
                Circle()
                    .stroke(AppTheme.Colors.gold.opacity(0.3), lineWidth: 1)
                    .scaleEffect(1.2)
                    .opacity(0.5)
            )
            
            // Partner 2 (Right)
            PartnerAvatarPill(name: girlName, alignRight: false)
        }
        .padding(.vertical, 8)
    }
}

// Inner helper for the Avatar + Name block
struct PartnerAvatarPill: View {
    let name: String
    let alignRight: Bool
    
    var initial: String {
        String(name.prefix(1)).uppercased()
    }
    
    var body: some View {
        HStack(spacing: 12) {
            if alignRight {
                textInfo
                avatarCircle
            } else {
                avatarCircle
                textInfo
            }
        }
    }
    
    var textInfo: some View {
        Text(name)
            .font(AppTheme.Fonts.body(size: 15).weight(.regular)) // Reduced size and weight
            .foregroundColor(AppTheme.Colors.textSecondary) // Softer color
            .lineLimit(1)
            .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
            // .fixedSize() // Removed to allow truncation if needed, but flex frame is better
    }
    
    var avatarCircle: some View {
        ZStack {
            // Initial
            Text(initial)
                .font(AppTheme.Fonts.premiumDisplay(size: 18)) // Slightly smaller
                .foregroundColor(AppTheme.Colors.gold)
            
            // Glass Ring
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [AppTheme.Colors.gold.opacity(0.6), AppTheme.Colors.gold.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
                .frame(width: 40, height: 40) // Reduced from 44
            
            // Fill
            Circle()
                .fill(Color.white.opacity(0.05))
                .frame(width: 40, height: 40)
        }
    }
}
