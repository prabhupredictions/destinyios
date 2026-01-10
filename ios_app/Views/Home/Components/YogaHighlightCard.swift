import SwiftUI

struct YogaHighlightCard: View {
    let yogas: [YogaDetail]
    
    @State private var selectedFilter: FilterType = .all
    
    enum FilterType: String, CaseIterable {
        case all = "All"
        case good = "Good"
        case caution = "Caution"
    }
    
    var filteredYogas: [YogaDetail] {
        switch selectedFilter {
        case .all:
            return yogas
        case .good:
            return yogas.filter { !$0.isDosha }
        case .caution:
            return yogas.filter { $0.isDosha }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            
            // Header & Filter
            VStack(alignment: .leading, spacing: 10) {
                Text("Positive & Negative Combinations")
                    .font(AppTheme.Fonts.premiumDisplay(size: 18))
                    .goldGradient()
                
                // Filter Tabs
                HStack(spacing: 8) {
                    ForEach(FilterType.allCases, id: \.self) { filter in
                        Button(action: {
                            HapticManager.shared.play(.light)
                            withAnimation(.smooth) {
                                selectedFilter = filter
                            }
                        }) {
                            Text(filter.rawValue)
                                .font(AppTheme.Fonts.caption(size: 13))
                                .fontWeight(selectedFilter == filter ? .semibold : .regular)
                                .foregroundColor(selectedFilter == filter ? AppTheme.Colors.gold : AppTheme.Colors.textSecondary)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    Capsule()
                                        .fill(selectedFilter == filter ? AppTheme.Colors.gold.opacity(0.15) : Color.clear)
                                        .overlay(
                                            Capsule()
                                                .strokeBorder(
                                                    selectedFilter == filter ? AppTheme.Colors.gold.opacity(0.5) : AppTheme.Colors.separator,
                                                    lineWidth: 1
                                                )
                                        )
                                )
                        }
                    }
                }
            }
            .padding(.horizontal, 12) // Align with other headers which use 12 padding
            
            // Content
            if filteredYogas.isEmpty {
                Text("No combinations found for this category.")
                    .font(AppTheme.Fonts.caption(size: 14))
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(filteredYogas, id: \.name) { yoga in
                            PremiumYogaCard(yoga: yoga)
                        }
                    }
                    .padding(.horizontal, 12) // Internal spacing
                }
                .padding(.horizontal, -12) // Extend to screen edges (matches Transit section)
            }
        }
    }
}

struct PremiumYogaCard: View {
    let yoga: YogaDetail
    
    // Status Logic
    var statusText: String {
        switch yoga.status {
        case "A": return "Active"
        case "C": return "Cancelled"
        case "R": return "Reduced"
        default: return "Inactive"
        }
    }
    
    // Color Logic
    var baseColor: Color {
        if yoga.isDosha {
            return AppTheme.Colors.error // Red for Caution
        } else {
            return Color.green // Green for Good
        }
    }
    
    var iconName: String {
        return yoga.isDosha ? "exclamationmark.triangle.fill" : "star.fill"
    }
    
    // Badge Color
    var badgeColor: Color {
        switch yoga.status {
        case "A": return baseColor
        case "C": return AppTheme.Colors.textSecondary
        case "R": return Color.orange
        default: return AppTheme.Colors.textSecondary
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header: Icon + Status Badge
            HStack(alignment: .center) {
                ZStack {
                    Circle()
                        .fill(baseColor.opacity(0.1))
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: iconName)
                        .font(.system(size: 14))
                        .foregroundColor(baseColor)
                }
                
                Spacer()
                
                // Status Badge
                Text(statusText)
                    .font(AppTheme.Fonts.caption(size: 10))
                    .fontWeight(.bold)
                    .foregroundColor(badgeColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .strokeBorder(badgeColor.opacity(0.4), lineWidth: 1)
                            .background(Capsule().fill(badgeColor.opacity(0.1)))
                    )
            }
            
            // Yoga Name (Limit 2 lines)
            Text(yoga.name)
                .font(AppTheme.Fonts.title(size: 14))
                .foregroundColor(Color.white)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
                .frame(height: 36, alignment: .topLeading) // Fixed height for alignment
            
            // Divider
            Rectangle()
                .fill(LinearGradient(
                    colors: [baseColor.opacity(0.5), .clear],
                    startPoint: .leading,
                    endPoint: .trailing
                ))
                .frame(height: 1)
            
            // Details: Planets & Houses
            HStack(alignment: .top) {
                // Left: Planets
                VStack(alignment: .leading, spacing: 2) {
                    Text("PLANETS")
                        .font(AppTheme.Fonts.caption(size: 9))
                        .foregroundColor(AppTheme.Colors.textTertiary)
                        .tracking(1)
                    
                    Text(yoga.planets.isEmpty ? "Unknown" : yoga.planets)
                        .font(AppTheme.Fonts.caption(size: 11))
                        .foregroundColor(AppTheme.Colors.textSecondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Right: Houses
                if !yoga.houses.isEmpty {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("HOUSES")
                            .font(AppTheme.Fonts.caption(size: 9))
                            .foregroundColor(AppTheme.Colors.textTertiary)
                            .tracking(1)
                        
                        Text(formatHouses(yoga.houses))
                            .font(AppTheme.Fonts.caption(size: 11))
                            .foregroundColor(AppTheme.Colors.textSecondary)
                            .lineLimit(1)
                    }
                }
            }
            
            // Spacer to push content up if needed
            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(width: 170, height: 160) // Increased height to fit Houses
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
        // Tinted shadow
        .shadow(color: baseColor.opacity(0.08), radius: 10)
    }
    
    private func formatHouses(_ houses: String) -> String {
        let items = houses.split(separator: ",")
        return items.map { "H\($0.trimmingCharacters(in: .whitespaces))" }.joined(separator: ", ")
    }
}
