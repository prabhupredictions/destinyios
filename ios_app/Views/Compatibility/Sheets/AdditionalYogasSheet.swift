//
//  AdditionalYogasSheet.swift
//  ios_app
//
//  Premium Yogas & Doshas sheet with Magic Floating Tabs
//

import SwiftUI

struct AdditionalYogasSheet: View {
    let boyData: YogaDoshaData?
    let girlData: YogaDoshaData?
    let boyName: String
    let girlName: String
    
    @State private var selectedPartner: Int = 0
    @State private var selectedTile: DestinyTileType = .wealth
    @Environment(\.dismiss) private var dismiss
    
    private var currentData: YogaDoshaData? {
        selectedPartner == 0 ? boyData : girlData
    }
    
    private var currentName: String {
        selectedPartner == 0 ? boyName : girlName
    }
    
    /// Get counts for each tile based on current partner's data
    private var tileCounts: [DestinyTileType: Int] {
        guard let data = currentData else { return [:] }
        var counts: [DestinyTileType: Int] = [:]
        for tile in DestinyTileType.topicTiles {
            counts[tile] = data.items(for: tile).count
        }
        // Dosha count (active only)
        counts[.dosha] = data.activeDoshas.count
        return counts
    }
    
    var body: some View {
        ZStack {
            // Background
            CosmicBackgroundView()
                .ignoresSafeArea()
            
            VStack(spacing: 4) {
                // Tier 1: Magic Tabs (Now on Top)
                MagicTabbar(
                    selectedTab: $selectedTile,
                    tiles: DestinyTileType.topicTiles + [.dosha],
                    counts: tileCounts
                )
                
                // Tier 2: Profile Switcher (Now Below)
                ProfileSwitcher(
                    selectedIndex: $selectedPartner,
                    names: [boyName, girlName]
                )
                .padding(.horizontal, 16)
                
                // Content Area
                if let data = currentData {
                    contentView(data)
                } else {
                    emptyDataView
                }
            }
        }
        .navigationTitle("yogas_analysis".localized)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbarBackground(.hidden, for: .navigationBar)
    }
    
    // MARK: - Content View
    
    @ViewBuilder
    private func contentView(_ data: YogaDoshaData) -> some View {
        TopicListView(
            tile: selectedTile,
            items: itemsForCurrentTile(data),
            personName: currentName
        )
        .id("\(selectedPartner)-\(selectedTile.id)") // Force refresh on change
        .transition(.opacity.combined(with: .move(edge: .trailing)))
    }
    
    private func itemsForCurrentTile(_ data: YogaDoshaData) -> [YogaItem] {
        if selectedTile == .dosha {
            // Show all doshas (active and cancelled)
            return data.allItems.filter { $0.isDosha ?? false }
        } else {
            return data.items(for: selectedTile)
        }
    }
    
    // MARK: - Empty State
    
    private var emptyDataView: some View {
        VStack(spacing: 16) {
            Image(systemName: "sparkles")
                .font(.system(size: 48))
                .foregroundColor(AppTheme.Colors.textTertiary)
            
            Text("No yoga data available")
                .font(AppTheme.Fonts.body(size: 16))
                .foregroundColor(AppTheme.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        AdditionalYogasSheet(
            boyData: nil,
            girlData: nil,
            boyName: "Prabhu",
            girlName: "Smita"
        )
    }
}
