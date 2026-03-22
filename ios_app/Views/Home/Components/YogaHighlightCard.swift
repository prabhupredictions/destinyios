import SwiftUI

struct YogaHighlightCard: View {
    let yogas: [YogaDetail]
    var onQuestionSelected: ((String) -> Void)?
    var onYogaTapped: ((YogaDetail) -> Void)?  // Callback to show popup at parent level
    
    @State private var selectedFilter: FilterType = .all
    
    enum FilterType: String, CaseIterable {
        case all = "filter_all"
        case wealth = "filter_wealth"
        case career = "filter_career"
        case love = "filter_relationship"
        case health = "filter_health"
        case family = "filter_family"
        case education = "filter_education"
        case spiritual = "filter_spiritual"
        case foundation = "filter_foundation"
        case personality = "filter_personality"
        case special = "filter_special"
        
        var displayName: String {
            return self.rawValue.localized
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
                    Text("yoga_positive_negative".localized)
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
                    Text("no_combinations_found".localized)
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
        case "A": return "yoga_status_active".localized
        case "C": return "yoga_status_cancelled".localized
        case "R": return "yoga_status_reduced".localized
        default: return "yoga_status_inactive".localized
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
        ZStack {
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
                        Text("planets_label".localized)
                            .font(AppTheme.Fonts.caption(size: 9))
                            .foregroundColor(AppTheme.Colors.textTertiary)
                            .tracking(1)
                        
                        Text(yoga.planets.isEmpty ? "Unknown" : localizedPlanets(yoga.planets))
                            .font(AppTheme.Fonts.caption(size: 11))
                            .foregroundColor(AppTheme.Colors.textSecondary)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    // Right: Houses
                    if !yoga.houses.isEmpty {
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("houses_label".localized)
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
            
            // Bottom Right: Animated Arrow click indicator
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Image(systemName: "arrow.forward.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [AppTheme.Colors.goldLight, AppTheme.Colors.gold],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .scaleEffect(1.0)
                }
            }
            .padding(.bottom, 12)
            .padding(.trailing, 12)
        }
        .frame(width: 170, height: 170)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppTheme.Colors.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    // Static border matching comparison result card style
                    yoga.isDosha ? AppTheme.Colors.error.opacity(0.4) : AppTheme.Colors.gold.opacity(0.5),
                    lineWidth: yoga.isDosha ? 1.5 : 2
                )
        )
        .shadow(color: baseColor.opacity(0.08), radius: 8, x: 0, y: 4)
    }
    
    private func formatHouses(_ houses: String) -> String {
        let items = houses.split(separator: ",")
        return items.map { "H\($0.trimmingCharacters(in: .whitespaces))" }.joined(separator: ", ")
    }
    
    private func localizedPlanets(_ planets: String) -> String {
        let planetNames = planets.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        let localized = planetNames.map { planet -> String in
            let key = planet.lowercased()
            switch key {
            case "sun": return "planet_sun".localized
            case "moon": return "planet_moon".localized
            case "mars": return "planet_mars".localized
            case "mercury": return "planet_mercury".localized
            case "jupiter": return "planet_jupiter".localized
            case "venus": return "planet_venus".localized
            case "saturn": return "planet_saturn".localized
            case "rahu": return "planet_rahu".localized
            case "ketu": return "planet_ketu".localized
            default: return planet
            }
        }
        return localized.joined(separator: ", ")
    }
}
