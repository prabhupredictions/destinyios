//
//  AdditionalYogasSheet.swift
//  ios_app
//
//  Premium Yogas & Doshas sheet with filterable expandable cards
//

import SwiftUI

struct AdditionalYogasSheet: View {
    let boyData: YogaDoshaData?
    let girlData: YogaDoshaData?
    let boyName: String
    let girlName: String
    
    @State private var selectedPartner: Int = 0
    @State private var filterType: FilterType = .all
    @State private var expandedItems: Set<String> = []
    @Environment(\.dismiss) private var dismiss
    
    enum FilterType: String, CaseIterable {
        case all = "All"
        case yogas = "Yogas"
        case doshas = "Doshas"
    }
    
    private var currentData: YogaDoshaData? {
        selectedPartner == 0 ? boyData : girlData
    }
    
    private var filteredItems: [YogaItem] {
        guard let data = currentData else { return [] }
        let items: [YogaItem]
        switch filterType {
        case .all:
            items = data.allItems
        case .yogas:
            items = data.yogas ?? []
        case .doshas:
            items = data.doshas ?? []
        }
        
        // Sort by status: Active (A) first, then Reduced (R), then Cancelled (C)
        return items.sorted { item1, item2 in
            let order: [String: Int] = ["A": 0, "R": 1, "C": 2]
            let priority1 = order[item1.status.uppercased()] ?? 3
            let priority2 = order[item2.status.uppercased()] ?? 3
            return priority1 < priority2
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                AppTheme.Colors.mainBackground
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Partner Picker
                        partnerPicker
                        
                        // Filter Picker
                        filterPicker
                        
                        // Summary Cards
                        if let data = currentData {
                            summaryCards(data)
                        }
                        
                        // Yoga/Dosha List
                        if filteredItems.isEmpty {
                            emptyStateView
                        } else {
                            yogasList
                        }
                    }
                    .padding()
                    .padding(.bottom, 50)
                }
            }
            .navigationTitle("yogas_analysis".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(AppTheme.Colors.gold)
                            .frame(width: 32, height: 32)
                            .background(Circle().fill(AppTheme.Colors.secondaryBackground))
                            .overlay(Circle().stroke(AppTheme.Colors.gold.opacity(0.3), lineWidth: 1))
                    }
                }
            }
        }
    }
    
    // MARK: - Partner Picker
    
    private var partnerPicker: some View {
        HStack(spacing: 0) {
            ForEach([boyName, girlName].indices, id: \.self) { index in
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        selectedPartner = index
                    }
                } label: {
                    Text(index == 0 ? boyName : girlName)
                        .font(AppTheme.Fonts.caption(size: 14).weight(.semibold))
                        .foregroundColor(selectedPartner == index ? AppTheme.Colors.mainBackground : AppTheme.Colors.textSecondary)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                        .background(
                            selectedPartner == index
                            ? AppTheme.Colors.gold
                            : Color.clear
                        )
                }
            }
        }
        .background(AppTheme.Colors.inputBackground)
        .clipShape(Capsule())
        .overlay(
            Capsule().stroke(AppTheme.Colors.gold.opacity(0.3), lineWidth: 1)
        )
        .padding(.horizontal, 4)
    }
    
    // MARK: - Filter Picker
    
    private var filterPicker: some View {
        HStack(spacing: 8) {
            ForEach(FilterType.allCases, id: \.self) { type in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        filterType = type
                    }
                } label: {
                    HStack(spacing: 4) {
                        if type == .yogas {
                            Text("✨")
                        } else if type == .doshas {
                            Text("⚠️")
                        }
                        Text(type.rawValue)
                            .font(AppTheme.Fonts.caption(size: 13).weight(.medium))
                    }
                    .foregroundColor(filterType == type ? AppTheme.Colors.textPrimary : AppTheme.Colors.textSecondary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        filterType == type
                        ? AppTheme.Colors.inputBackground
                        : Color.clear
                    )
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .stroke(filterType == type ? AppTheme.Colors.gold : AppTheme.Colors.gold.opacity(0.1), lineWidth: 1)
                    )
                }
            }
        }
    }
    
    // MARK: - Summary Cards
    
    private func summaryCards(_ data: YogaDoshaData) -> some View {
        HStack(spacing: 16) {
            summaryCard(
                count: data.activeYogaCount,
                label: "Yogas",
                icon: "✨",
                color: AppTheme.Colors.success
            )
            
            summaryCard(
                count: data.activeDoshaCount,
                label: "Doshas",
                icon: "⚠️",
                color: AppTheme.Colors.error
            )
        }
    }
    
    private func summaryCard(count: Int, label: String, icon: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Text(icon)
                .font(.system(size: 24))
            
            Text("\(count)")
                .font(AppTheme.Fonts.title(size: 24))
                .foregroundColor(AppTheme.Colors.textPrimary)
            
            Text(label)
                .font(AppTheme.Fonts.caption())
                .foregroundColor(AppTheme.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Styles.cornerRadius)
                .fill(AppTheme.Colors.cardBackground)
                .overlay(AppTheme.Styles.goldBorder.stroke, in: RoundedRectangle(cornerRadius: AppTheme.Styles.cornerRadius))
        )
    }
    
    // MARK: - Yogas List
    
    private var yogasList: some View {
        LazyVStack(spacing: 12) {
            ForEach(filteredItems) { item in
                yogaItemCard(item)
            }
        }
    }
    
    private func yogaItemCard(_ item: YogaItem) -> some View {
        let isExpanded = expandedItems.contains(item.id)
        let isDosha = (currentData?.doshas?.contains(where: { $0.id == item.id }) ?? false)
        let statusColor = isDosha ? (item.status == "A" ? AppTheme.Colors.error : AppTheme.Colors.gold) : AppTheme.Colors.success
        
        return VStack(spacing: 0) {
            // Header
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    if isExpanded {
                        expandedItems.remove(item.id)
                    } else {
                        expandedItems.insert(item.id)
                    }
                }
            } label: {
                HStack(spacing: 12) {
                    Text(isDosha ? "⚠️" : "✨")
                        .font(.system(size: 18))
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.displayName)
                            .font(AppTheme.Fonts.body(size: 15).weight(.semibold))
                            .foregroundColor(AppTheme.Colors.textPrimary)
                        
                        // Strength bar
                        HStack(spacing: 8) {
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    Capsule()
                                        .fill(AppTheme.Colors.inputBackground)
                                    
                                    Capsule()
                                        .fill(statusColor)
                                        .frame(width: geometry.size.width * (item.strength))
                                }
                            }
                            .frame(height: 6)
                            
                            Text("\(item.strengthPercentage)%")
                                .font(AppTheme.Fonts.caption(size: 11).weight(.semibold))
                                .foregroundColor(AppTheme.Colors.textSecondary)
                                .frame(width: 35, alignment: .trailing)
                        }
                    }
                    
                    Spacer()
                    
                    // Status Badge
                    statusBadge(item.status, isDosha: isDosha)
                    
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(AppTheme.Colors.textTertiary)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
                .padding()
            }
            
            // Expanded Content
            if isExpanded {
                VStack(alignment: .leading, spacing: 12) {
                    Divider()
                        .background(AppTheme.Colors.gold.opacity(0.1))
                    
                    // Houses and Planets on same row
                    HStack {
                        // Left: Houses
                        if let houses = item.uniqueHouses, !houses.isEmpty {
                            HStack(spacing: 6) {
                                Image(systemName: "house.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(AppTheme.Colors.goldDim)
                                Text("Houses:")
                                    .font(AppTheme.Fonts.caption())
                                    .foregroundColor(AppTheme.Colors.textTertiary)
                                Text(houses)
                                    .font(AppTheme.Fonts.caption().weight(.medium))
                                    .foregroundColor(AppTheme.Colors.textPrimary)
                            }
                        }
                        
                        Spacer()
                        
                        // Right: Planets
                        if let planets = item.uniquePlanets, !planets.isEmpty {
                            HStack(spacing: 6) {
                                Image(systemName: "sparkle")
                                    .font(.system(size: 12))
                                    .foregroundColor(AppTheme.Colors.gold)
                                Text(planets)
                                    .font(AppTheme.Fonts.caption().weight(.medium))
                                    .foregroundColor(AppTheme.Colors.gold)
                            }
                        }
                    }
                    
                    if let category = item.category {
                        detailRow(icon: "tag.fill", label: "Category", value: category.capitalized)
                    }
                    
                    if let formation = item.formation, !formation.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Image(systemName: "info.circle.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(AppTheme.Colors.textTertiary)
                                Text("Formation")
                                    .font(AppTheme.Fonts.caption())
                                    .foregroundColor(AppTheme.Colors.textTertiary)
                            }
                            Text(formation)
                                .font(AppTheme.Fonts.body(size: 13))
                                .foregroundColor(AppTheme.Colors.textSecondary)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Styles.cornerRadius)
                .fill(AppTheme.Colors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.Styles.cornerRadius)
                        .stroke(statusColor.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    private func detailRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(AppTheme.Colors.textTertiary)
            Text(label + ":")
                .font(AppTheme.Fonts.caption())
                .foregroundColor(AppTheme.Colors.textTertiary)
            Text(value)
                .font(AppTheme.Fonts.caption().weight(.medium))
                .foregroundColor(AppTheme.Colors.textPrimary)
        }
    }
    
    private func statusBadge(_ status: String, isDosha: Bool) -> some View {
        let (text, color) = statusInfo(status, isDosha: isDosha)
        
        return Text(text)
            .font(AppTheme.Fonts.caption(size: 10).weight(.bold))
            .foregroundColor(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(AppTheme.Colors.inputBackground)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(color.opacity(0.3), lineWidth: 1))
    }
    
    private func statusInfo(_ status: String, isDosha: Bool) -> (String, Color) {
        switch status.uppercased() {
        case "A":
            return (DoshaDescriptions.status("A").uppercased(), isDosha ? AppTheme.Colors.error : AppTheme.Colors.success)
        case "R":
            return (DoshaDescriptions.status("R").uppercased(), AppTheme.Colors.gold)
        case "C":
            return (DoshaDescriptions.status("C").uppercased(), AppTheme.Colors.textTertiary)
        default:
            return (status, AppTheme.Colors.textTertiary)
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "sparkles")
                .font(.system(size: 48))
                .foregroundColor(AppTheme.Colors.textTertiary)
            
            Text("No \(filterType.rawValue) found")
                .font(AppTheme.Fonts.body(size: 16))
                .foregroundColor(AppTheme.Colors.textSecondary)
        }
        .padding(40)
    }
}

#Preview {
    AdditionalYogasSheet(
        boyData: nil,
        girlData: nil,
        boyName: "Partner A",
        girlName: "Partner B"
    )
}
