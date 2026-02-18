import SwiftUI

/// Professional popup for Yoga/Dosha detail display (matches LifeAreaBriefPopup style)
struct YogaDetailPopup: View {
    // Data
    let yoga: YogaDetail
    
    // Callbacks
    let onAskMore: () -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.spring(response: 0.3)) {
                        onDismiss()
                    }
                }
            
            // Popup Card
            VStack(spacing: 14) {
                // Header: Status Icon + Name + Close
                HStack(alignment: .top, spacing: 12) {
                    // Status Icon
                    ZStack {
                        Circle()
                            .fill(statusColor.opacity(0.15))
                            .frame(width: 44, height: 44)
                        
                        Image(systemName: statusIcon)
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(statusColor)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        // Yoga Name
                        Text(yoga.localizedName)
                            .font(AppTheme.Fonts.title(size: 17))
                            .foregroundColor(AppTheme.Colors.textPrimary)
                            .lineLimit(2)
                        
                        // Category + Status Badge Row
                        HStack(spacing: 8) {
                            // Category Tag
                            if let category = yoga.category {
                                Text(category)
                                    .font(AppTheme.Fonts.caption(size: 11))
                                    .foregroundColor(AppTheme.Colors.textSecondary)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(
                                        Capsule()
                                            .fill(AppTheme.Colors.surfaceBackground)
                                    )
                            }
                            
                            // Status Badge
                            Text(statusDisplayText)
                                .font(AppTheme.Fonts.caption(size: 11).bold())
                                .foregroundColor(statusColor)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(
                                    Capsule()
                                        .fill(statusColor.opacity(0.15))
                                        .overlay(
                                            Capsule()
                                                .strokeBorder(statusColor.opacity(0.3), lineWidth: 1)
                                        )
                                )
                        }
                    }
                    
                    Spacer()
                    
                    // Close Button
                    Button(action: {
                        HapticManager.shared.play(.light)
                        withAnimation { onDismiss() }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(AppTheme.Colors.textSecondary)
                            .font(.system(size: 24))
                    }
                }
                
                Divider().background(AppTheme.Colors.gold.opacity(0.3))
                
                // Detail Grid: Planets | Houses | Strength
                HStack(spacing: 0) {
                    // Planets
                    detailColumn(
                        icon: "sparkles",
                        label: "PLANETS",
                        value: yoga.planets.isEmpty ? "—" : yoga.planets
                    )
                    
                    Divider()
                        .frame(height: 40)
                        .background(AppTheme.Colors.separator)
                    
                    // Houses
                    detailColumn(
                        icon: "house.fill",
                        label: "HOUSES",
                        value: yoga.houses.isEmpty ? "—" : yoga.houses
                    )
                    
                    Divider()
                        .frame(height: 40)
                        .background(AppTheme.Colors.separator)
                    
                    // Strength
                    detailColumn(
                        icon: "bolt.fill",
                        label: "STRENGTH",
                        value: "\(Int(yoga.strength * 100))%"
                    )
                }
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(AppTheme.Colors.surfaceBackground.opacity(0.5))
                )
                
                // Outcome Description (professional interpretation)
                if let outcome = yoga.localizedOutcome, !outcome.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("yoga_outcome_label".localized)
                            .font(AppTheme.Fonts.caption(size: 10))
                            .foregroundColor(AppTheme.Colors.gold)
                        
                        Text(outcome)
                            .font(AppTheme.Fonts.body(size: 13))
                            .foregroundColor(AppTheme.Colors.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(AppTheme.Colors.gold.opacity(0.06))
                    )
                }
                
                // Formation Description (if available)
                if let formation = yoga.localizedFormation, !formation.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("yoga_formation_label".localized)
                            .font(AppTheme.Fonts.caption(size: 10))
                            .foregroundColor(AppTheme.Colors.textTertiary)
                        
                        Text(formation)
                            .font(AppTheme.Fonts.body(size: 13))
                            .foregroundColor(AppTheme.Colors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                // Reason (if cancelled/reduced)
                if let reason = yoga.reason, !reason.isEmpty, yoga.status != "A" {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 4) {
                            Image(systemName: "info.circle.fill")
                                .font(.system(size: 11))
                            Text(yoga.status == "R" ? "REDUCED BECAUSE" : "CANCELLED BECAUSE")
                                .font(AppTheme.Fonts.caption(size: 10))
                        }
                        .foregroundColor(statusColor)
                        
                        // Transform exception keys to human-readable text
                        Text(DoshaDescriptions.localizeExceptionKeys(in: reason))
                            .font(AppTheme.Fonts.body(size: 13))
                            .foregroundColor(AppTheme.Colors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(statusColor.opacity(0.08))
                    )
                }
                
                // Ask More Button
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
            .padding(18)
            .frame(maxWidth: 340)
            .background(
                ZStack {
                    // Dark background matching LifeAreaBriefPopup
                    AppTheme.Colors.mainBackground
                    
                    // Subtle cosmic glow
                    RadialGradient(
                        colors: [
                            AppTheme.Colors.gold.opacity(0.1),
                            Color.clear
                        ],
                        center: .topLeading,
                        startRadius: 0,
                        endRadius: 180
                    )
                }
                .clipShape(RoundedRectangle(cornerRadius: 20))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                statusColor.opacity(0.5),
                                statusColor.opacity(0.15)
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
        .ignoresSafeArea() // Float above tab bar
    }
    
    // MARK: - Helper Views
    
    @ViewBuilder
    private func detailColumn(icon: String, label: String, value: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(AppTheme.Colors.gold)
            
            Text(label)
                .font(AppTheme.Fonts.caption(size: 9))
                .foregroundColor(AppTheme.Colors.textTertiary)
            
            Text(value)
                .font(AppTheme.Fonts.body(size: 12).bold())
                .foregroundColor(AppTheme.Colors.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Computed Properties
    
    private var statusColor: Color {
        switch yoga.status {
        case "A": // Active
            return yoga.isDosha ? AppTheme.Colors.error : AppTheme.Colors.success
        case "R": // Reduced
            return AppTheme.Colors.warning
        case "C": // Cancelled
            return AppTheme.Colors.textTertiary
        default:
            return AppTheme.Colors.textSecondary
        }
    }
    
    private var statusIcon: String {
        switch yoga.status {
        case "A":
            return yoga.isDosha ? "exclamationmark.triangle.fill" : "checkmark.seal.fill"
        case "R":
            return "minus.circle.fill"
        case "C":
            return "xmark.circle.fill"
        default:
            return "questionmark.circle.fill"
        }
    }
    
    private var statusDisplayText: String {
        switch yoga.status {
        case "A": return "Active"
        case "R": return "Reduced"
        case "C": return "Cancelled"
        default: return yoga.status
        }
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        AppTheme.Colors.mainBackground.ignoresSafeArea()
        
        YogaDetailPopup(
            yoga: YogaDetail(
                name: "Gajakesari Yoga",
                yogaKey: "gajakesari_yoga",
                planets: "Moon, Jupiter",
                houses: "1, 7",
                status: "R",
                strength: 0.65,
                isDosha: false,
                category: "Wealth",
                formation: "Jupiter is in Kendra (7th house) from Moon",
                outcome: "Confers intelligence, eloquence, lasting reputation, and virtuous, wealthy character.",
                reason: "Jupiter is combust due to proximity to Sun"
            ),
            onAskMore: { print("Ask more tapped") },
            onDismiss: { print("Dismissed") }
        )
    }
}
