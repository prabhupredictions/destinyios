import SwiftUI

struct YogaHighlightCard: View {
    let yogas: [YogaDetail]
    var onQuestionSelected: ((String) -> Void)?
    var onYogaTapped: ((YogaDetail) -> Void)?  // Callback to show popup at parent level
    
    @State private var selectedFilter: FilterType = .all
    
    enum FilterType: String, CaseIterable {
        case all = "All"
        case wealth = "Wealth"
        case career = "Career"
        case love = "Relationship"
        case health = "Health"
        case family = "Family"
        case education = "Education"
        case spiritual = "Spiritual"
        case foundation = "Basic Foundation"
        case personality = "Personality"
        case special = "Special"
        
        var displayName: String {
            switch self {
            case .love: return "Love"
            case .foundation: return "Foundation"
            default: return self.rawValue
            }
        }
        
        // All possible backend values that match this filter
        var matchingCategories: [String] {
            switch self {
            case .all: return []
            case .wealth: return ["Wealth", "wealth", "finance", "Finance", "WL"]
            case .career: return ["Career", "career", "CR"]
            case .love: return ["Relationship", "relationship", "RL"]
            case .health: return ["Health", "health", "HL"]
            case .family: return ["Family", "family", "FM"]
            case .education: return ["Education", "education", "ED"]
            case .spiritual: return ["Spiritual", "spiritual", "SR"]
            case .foundation: return ["Basic Foundation", "basic_foundation", "BF"]
            case .personality: return ["Personality", "personality", "PE"]
            case .special: return ["Special", "special", "SP"]
            }
        }
    }
    
    // All filters in display order
    private var allFilters: [FilterType] {
        FilterType.allCases
    }
    
    var filteredYogas: [YogaDetail] {
        if selectedFilter == .all {
            return yogas
        }
        return yogas.filter { yoga in
            guard let category = yoga.category else { return false }
            return selectedFilter.matchingCategories.contains(category)
        }
    }
    
    // Filter button helper
    @ViewBuilder
    private func filterButton(for filter: FilterType) -> some View {
        Button(action: {
            HapticManager.shared.play(.light)
            withAnimation(.smooth) {
                selectedFilter = filter
            }
        }) {
            Text(filter.displayName)
                .font(AppTheme.Fonts.caption(size: 11))
                .fontWeight(selectedFilter == filter ? .semibold : .regular)
                .foregroundColor(selectedFilter == filter ? AppTheme.Colors.gold : AppTheme.Colors.textSecondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(selectedFilter == filter ? AppTheme.Colors.gold.opacity(0.1) : Color.clear)
                        .overlay(
                            Capsule()
                                .strokeBorder(
                                    selectedFilter == filter ? AppTheme.Colors.gold.opacity(0.5) : AppTheme.Colors.textSecondary.opacity(0.2),
                                    lineWidth: 1
                                )
                        )
                )
        }
    }
    
    var body: some View {
        ZStack {
            VStack(alignment: .leading, spacing: 12) {
                
                // Header & Filter
                VStack(alignment: .leading, spacing: 10) {
                    Text("Positive & Negative Combinations")
                        .font(AppTheme.Fonts.premiumDisplay(size: 18))
                        .goldGradient()
                    
                    // Filter Tabs - Single Horizontal Scroll with scroll hint
                    ZStack(alignment: .trailing) {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(allFilters, id: \.self) { filter in
                                    filterButton(for: filter)
                                }
                                // Extra padding at end to prevent last item hiding under fade
                                Spacer().frame(width: 24)
                            }
                        }
                        
                        // Right edge fade gradient to hint more content
                        HStack(spacing: 4) {
                            LinearGradient(
                                colors: [.clear, AppTheme.Colors.mainBackground],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                            .frame(width: 40)
                            
                            // Small arrow hint
                            Image(systemName: "chevron.right")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(AppTheme.Colors.textTertiary)
                        }
                        .allowsHitTesting(false) // Don't block scroll gestures
                    }
                }
                .padding(.horizontal, 12)
                
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
                                    .onTapGesture {
                                        HapticManager.shared.play(.light)
                                        onYogaTapped?(yoga)
                                    }
                            }
                        }
                        .padding(.horizontal, 12)
                    }
                }
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
            Text(yoga.localizedName)
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
                .fill(AppTheme.Colors.cardBackground)
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
