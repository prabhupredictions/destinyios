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
                // Background gradient
                LinearGradient(
                    colors: [
                        Color(hex: "1a1a2e").opacity(0.98),
                        Color(hex: "2d2d4e").opacity(0.95),
                        Color(hex: "1a1a2e").opacity(0.98)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
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
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
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
                    withAnimation(.easeInOut(duration: 0.3)) {
                        selectedPartner = index
                    }
                } label: {
                    Text(index == 0 ? boyName : girlName)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(selectedPartner == index ? .white : .white.opacity(0.6))
                        .padding(.vertical, 10)
                        .padding(.horizontal, 24)
                        .background(
                            selectedPartner == index
                            ? Color.white.opacity(0.2)
                            : Color.clear
                        )
                        .clipShape(Capsule())
                }
            }
        }
        .padding(4)
        .background(Color.white.opacity(0.1))
        .clipShape(Capsule())
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
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundColor(filterType == type ? .white : .white.opacity(0.5))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        filterType == type
                        ? Color.white.opacity(0.15)
                        : Color.clear
                    )
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .stroke(Color.white.opacity(filterType == type ? 0.3 : 0.1), lineWidth: 1)
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
                gradient: [Color.purple, Color.blue]
            )
            
            summaryCard(
                count: data.activeDoshaCount,
                label: "Doshas",
                icon: "⚠️",
                gradient: [Color.orange, Color.red]
            )
        }
    }
    
    private func summaryCard(count: Int, label: String, icon: String, gradient: [Color]) -> some View {
        VStack(spacing: 8) {
            Text(icon)
                .font(.system(size: 24))
            
            Text("\(count)")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: gradient.map { $0.opacity(0.2) },
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                colors: gradient.map { $0.opacity(0.4) },
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
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
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                        
                        // Strength bar
                        HStack(spacing: 8) {
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    Capsule()
                                        .fill(Color.white.opacity(0.1))
                                    
                                    Capsule()
                                        .fill(strengthGradient(item: item, isDosha: isDosha))
                                        .frame(width: geometry.size.width * (item.strength))
                                }
                            }
                            .frame(height: 6)
                            
                            Text("\(item.strengthPercentage)%")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.white.opacity(0.6))
                                .frame(width: 35, alignment: .trailing)
                        }
                    }
                    
                    Spacer()
                    
                    // Status Badge
                    statusBadge(item.status, isDosha: isDosha)
                    
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white.opacity(0.4))
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
                .padding()
            }
            
            // Expanded Content
            if isExpanded {
                VStack(alignment: .leading, spacing: 12) {
                    Divider()
                        .background(Color.white.opacity(0.1))
                    
                    // Houses and Planets on same row
                    HStack {
                        // Left: Houses
                        if let houses = item.uniqueHouses, !houses.isEmpty {
                            HStack(spacing: 6) {
                                Image(systemName: "house.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(.white.opacity(0.5))
                                Text("Houses:")
                                    .font(.system(size: 12))
                                    .foregroundColor(.white.opacity(0.5))
                                Text(houses)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.white.opacity(0.8))
                            }
                        }
                        
                        Spacer()
                        
                        // Right: Planets
                        if let planets = item.uniquePlanets, !planets.isEmpty {
                            HStack(spacing: 6) {
                                Image(systemName: "sparkle")
                                    .font(.system(size: 12))
                                    .foregroundColor(.cyan.opacity(0.7))
                                Text(planets)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.cyan)
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
                                    .foregroundColor(.white.opacity(0.5))
                                Text("Formation")
                                    .font(.system(size: 11))
                                    .foregroundColor(.white.opacity(0.5))
                            }
                            Text(formation)
                                .font(.system(size: 13))
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            isDosha
                            ? (item.status == "A" ? Color.red.opacity(0.3) : Color.orange.opacity(0.2))
                            : Color.purple.opacity(0.2),
                            lineWidth: 1
                        )
                )
        )
    }
    
    private func detailRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.5))
            Text(label + ":")
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.5))
            Text(value)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
        }
    }
    
    private func statusBadge(_ status: String, isDosha: Bool) -> some View {
        let (text, color) = statusInfo(status, isDosha: isDosha)
        
        return Text(text)
            .font(.system(size: 10, weight: .bold))
            .foregroundColor(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.15))
            .clipShape(Capsule())
    }
    
    private func statusInfo(_ status: String, isDosha: Bool) -> (String, Color) {
        switch status.uppercased() {
        case "A":
            return (DoshaDescriptions.status("A").uppercased(), isDosha ? .red : .green)
        case "R":
            return (DoshaDescriptions.status("R").uppercased(), .orange)
        case "C":
            return (DoshaDescriptions.status("C").uppercased(), .gray)
        default:
            return (status, .gray)
        }
    }
    
    private func strengthGradient(item: YogaItem, isDosha: Bool) -> LinearGradient {
        if isDosha {
            if item.status == "A" {
                return LinearGradient(colors: [.red, .orange], startPoint: .leading, endPoint: .trailing)
            } else if item.status == "R" {
                return LinearGradient(colors: [.orange, .yellow], startPoint: .leading, endPoint: .trailing)
            } else {
                return LinearGradient(colors: [.gray, .gray.opacity(0.5)], startPoint: .leading, endPoint: .trailing)
            }
        } else {
            return LinearGradient(colors: [.purple, .blue], startPoint: .leading, endPoint: .trailing)
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "sparkles")
                .font(.system(size: 48))
                .foregroundColor(.white.opacity(0.3))
            
            Text("No \(filterType.rawValue) found")
                .font(.system(size: 16))
                .foregroundColor(.white.opacity(0.5))
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
