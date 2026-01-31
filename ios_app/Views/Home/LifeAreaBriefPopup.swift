import SwiftUI

/// Compact tooltip popup for life area brief (matches OrbitAshtakoot Work tooltip)
struct LifeAreaBriefPopup: View {
    // Data
    let area: String
    let status: String
    let brief: String
    let iconName: String
    
    // Callbacks
    let onAskMore: () -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.spring(response: 0.3)) {
                        onDismiss()
                    }
                }
            
            // Compact Tooltip Card (Matches Work tooltip exactly)
            VStack(spacing: 12) {
                // Header
                HStack(alignment: .center, spacing: 12) {
                    Image(systemName: iconName)
                        .font(.system(size: 24))
                        .foregroundColor(statusColor)
                        .shadow(color: statusColor.opacity(0.6), radius: 8)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(area)
                            .font(AppTheme.Fonts.title(size: 18))
                            .foregroundColor(AppTheme.Colors.textPrimary)
                        
                        Text(status)
                            .font(AppTheme.Fonts.body(size: 14).bold())
                            .foregroundColor(statusColor)
                    }
                    
                    Spacer()
                    
                    // Close Button
                    Button(action: {
                        HapticManager.shared.play(.light)
                        withAnimation { onDismiss() }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(AppTheme.Colors.textSecondary)
                            .font(.system(size: 22))
                    }
                }
                
                Divider().background(AppTheme.Colors.gold.opacity(0.3))
                
                // Description
                Text(brief)
                    .font(AppTheme.Fonts.body(size: 14))
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                // Ask More Link (Simple text + icon, not button)
                Button(action: {
                    HapticManager.shared.play(.medium)
                    onAskMore()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 12))
                        Text("Ask More...")
                            .font(AppTheme.Fonts.body(size: 13))
                    }
                    .foregroundColor(AppTheme.Colors.gold)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .padding(16)
            .frame(width: 280)
            .background(
                ZStack {
                    AppTheme.Colors.mainBackground
                    
                    // Subtle cosmic glow
                    RadialGradient(
                        colors: [
                            AppTheme.Colors.gold.opacity(0.1),
                            Color.clear
                        ],
                        center: .topLeading,
                        startRadius: 0,
                        endRadius: 150
                    )
                }
                .clipShape(RoundedRectangle(cornerRadius: 16))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                AppTheme.Colors.gold.opacity(0.6),
                                AppTheme.Colors.gold.opacity(0.2)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: AppTheme.Colors.gold.opacity(0.25), radius: 15, x: 0, y: 8)
            .transition(.scale.combined(with: .opacity))
        }
    }
    
    // Status color helper
    private var statusColor: Color {
        switch status.lowercased() {
        case "good", "excellent":
            return AppTheme.Colors.success
        case "steady", "neutral":
            return AppTheme.Colors.warning
        case "caution", "difficult", "challenging":
            return AppTheme.Colors.error
        default:
            return AppTheme.Colors.textSecondary
        }
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        
        LifeAreaBriefPopup(
            area: "Finance",
            status: "Caution",
            brief: "Be wary of impulsive spending as Rahu creates illusions in your wealth house.",
            iconName: "banknote.fill",
            onAskMore: { print("Ask more tapped") },
            onDismiss: { print("Dismissed") }
        )
    }
}
