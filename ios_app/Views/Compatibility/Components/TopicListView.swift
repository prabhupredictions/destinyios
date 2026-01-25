//
//  TopicListView.swift
//  ios_app
//
//  Content view for a single topic tab showing active and blocked yogas
//

import SwiftUI

/// Displays yogas for a specific topic tile, grouped into Active and Blocked sections
struct TopicListView: View {
    let tile: DestinyTileType
    let items: [YogaItem]
    let personName: String
    
    @State private var expandedItems: Set<String> = []
    
    private var activeItems: [YogaItem] {
        items.filter { $0.status != "C" }
            .sorted { $0.strength > $1.strength }
    }
    
    private var blockedItems: [YogaItem] {
        items.filter { $0.status == "C" }
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16, pinnedViews: [.sectionHeaders]) {
                // Header
                headerSection
                
                // Active Section
                if !activeItems.isEmpty {
                    Section {
                        ForEach(activeItems) { item in
                            ActiveYogaCard(
                                item: item,
                                tile: tile, // Passing tile
                                isExpanded: expandedItems.contains(item.id),
                                onTap: { toggleExpanded(item) }
                            )
                        }
                    } header: {
                        sectionHeader(
                            title: "Active Forces",
                            icon: "sparkles",
                            count: activeItems.count,
                            color: tile.accentColor
                        )
                    }
                }
                
                // Blocked Section
                if !blockedItems.isEmpty {
                    Section {
                        ForEach(blockedItems) { item in
                            BlockedYogaCard(
                                item: item,
                                tile: tile, // Passing tile
                                isExpanded: expandedItems.contains(item.id),
                                onTap: { toggleExpanded(item) }
                            )
                        }
                    } header: {
                        sectionHeader(
                            title: "Blocked Potential",
                            icon: "lock.fill",
                            count: blockedItems.count,
                            color: AppTheme.Colors.textTertiary
                        )
                    }
                }
                
                // Empty state
                if items.isEmpty {
                    emptyState
                }
            }
            .padding()
            .padding(.bottom, 50)
        }
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        VStack(spacing: 4) {
            // Icon with Glow
            Text(tile.icon)
                .font(.system(size: 44))
                .shadow(color: tile.accentColor.opacity(0.6), radius: 20, x: 0, y: 0)
                .padding(.bottom, 8)
            
            // Title - Elegant & Clean
            Text("\(personName)'s \(tile.displayTitle)")
                .font(.system(size: 24, weight: .bold, design: .serif)) // Serif for premium feel
                .foregroundColor(.white)
                .shadow(radius: 2)
            
            // Subtitle/Context (Optional, can be stats)
            HStack(spacing: 12) {
                statusText(label: "Active", count: activeItems.count, color: tile.accentColor)
                
                if !blockedItems.isEmpty {
                    Circle()
                        .fill(Color.white.opacity(0.3))
                        .frame(width: 4, height: 4)
                    
                    statusText(label: "Blocked", count: blockedItems.count, color: AppTheme.Colors.textTertiary)
                }
            }
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        // Removed the boxy background for an open, airy feel
    }
    
    private func statusText(label: String, count: Int, color: Color) -> some View {
        HStack(spacing: 4) {
            Text("\(count)")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(color)
            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(AppTheme.Colors.textSecondary)
        }
    }
    
    // MARK: - Section Header
    
    private func sectionHeader(title: String, icon: String, count: Int, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(color)
            Text(title.uppercased())
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .tracking(1.5) // Premium spacing
                .foregroundColor(AppTheme.Colors.textSecondary)
            Spacer()
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 4)
        .background(
            // subtle blur behind header so content doesn't clash when scrolling
            Rectangle()
                .fill(.ultraThinMaterial)
                .opacity(0.0) // kept fully transparent as requested, or adjust if needed
        )
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Text(tile.icon)
                .font(.system(size: 48))
                .opacity(0.5)
            
            Text("No yogas in this category")
                .font(AppTheme.Fonts.body(size: 16))
                .foregroundColor(AppTheme.Colors.textSecondary)
        }
        .padding(40)
    }
    
    private func toggleExpanded(_ item: YogaItem) {
        withAnimation(.easeInOut(duration: 0.2)) {
            if expandedItems.contains(item.id) {
                expandedItems.remove(item.id)
            } else {
                expandedItems.insert(item.id)
            }
        }
    }
}

// MARK: - Active Yoga Card (Glowing)

struct ActiveYogaCard: View {
    let item: YogaItem
    let tile: DestinyTileType // Added tile
    let isExpanded: Bool
    let onTap: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            Button(action: onTap) {
                HStack(spacing: 12) {
                    // Icon
                    Text("✨")
                        .font(.system(size: 20))
                    
                    // Name & Status
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.displayName)
                            .font(AppTheme.Fonts.body(size: 15).weight(.semibold))
                            .foregroundColor(AppTheme.Colors.textPrimary)
                        
                        if let category = item.category {
                            Text(category)
                                .font(AppTheme.Fonts.caption(size: 11))
                                .foregroundColor(AppTheme.Colors.textTertiary)
                        }
                    }
                    
                    Spacer()
                    
                    // Status Badge
                    statusBadge
                    
                    // Chevron
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(AppTheme.Colors.textTertiary)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
                .padding()
            }
            .buttonStyle(.plain)
            
            // Expanded Content
            if isExpanded {
                expandedContent
            }
        }
        .background(
            ZStack {
                // 1. Transparent Dark Base (No Blur)
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.black.opacity(0.45)) // Darker fill for contrast without blur
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                
                // 2. Subtle Surface Shine
                RoundedRectangle(cornerRadius: 24)
                    .fill(
                        LinearGradient(
                            stops: [
                                .init(color: Color.white.opacity(0.08), location: 0),
                                .init(color: Color.white.opacity(0.0), location: 0.45)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .overlay(
                // 3. Glass Edge Border (Highlights top/left, fades bottom/right)
                RoundedRectangle(cornerRadius: 24)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.4),
                                Color.white.opacity(0.1),
                                Color.white.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            // 4. Inner Glow for Depth
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(tile.accentColor.opacity(0.3), lineWidth: 0) // Hint of color
                    .shadow(color: tile.accentColor.opacity(0.4), radius: 8, x: 0, y: 0)
                    .mask(RoundedRectangle(cornerRadius: 24))
            )
            // 5. Rich Drop Shadow
            .shadow(color: Color.black.opacity(0.4), radius: 15, x: 0, y: 8)
        )
    }
    
    private var statusBadge: some View {
        let (text, color) = statusInfo
        return Text(text)
            .font(AppTheme.Fonts.caption(size: 10).weight(.bold))
            .foregroundColor(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                Capsule()
                    .fill(color.opacity(0.15))
                    .overlay(Capsule().stroke(color.opacity(0.3), lineWidth: 1))
            )
    }
    
    private var statusInfo: (String, Color) {
        switch item.status.uppercased() {
        case "A": return ("ACTIVE", AppTheme.Colors.success)
        case "R": return ("REDUCED", AppTheme.Colors.gold)
        default: return (item.status, AppTheme.Colors.textTertiary)
        }
    }
    
    private var expandedContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            Divider()
                .background(AppTheme.Colors.gold.opacity(0.2))
            
            // Formation (Technical Details)
            if let formation = item.formation, !formation.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Image(systemName: "info.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(AppTheme.Colors.textTertiary)
                        Text("How It's Formed")
                            .font(AppTheme.Fonts.caption(size: 11).weight(.medium))
                            .foregroundColor(AppTheme.Colors.textTertiary)
                    }
                    Text(formation)
                        .font(AppTheme.Fonts.body(size: 13))
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
            }
            
            // Planets & Houses
            HStack {
                if let planets = item.uniquePlanets {
                    detailChip(icon: "sparkle", text: planets, color: AppTheme.Colors.gold)
                }
                if let houses = item.uniqueHouses {
                    detailChip(icon: "house.fill", text: "H\(houses)", color: AppTheme.Colors.goldDim)
                }
            }
            
            // Reason (for Reduced)
            if let reason = item.reason, !reason.isEmpty, item.status == "R" {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(AppTheme.Colors.gold)
                        Text("Why Reduced")
                            .font(AppTheme.Fonts.caption(size: 11).weight(.medium))
                            .foregroundColor(AppTheme.Colors.gold)
                    }
                    Text(reason)
                        .font(AppTheme.Fonts.body(size: 13))
                        .foregroundColor(AppTheme.Colors.gold.opacity(0.8))
                }
            }
        }
        .padding(.horizontal)
        .padding(.bottom)
    }
    
    private func detailChip(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10))
            Text(text)
                .font(AppTheme.Fonts.caption(size: 11).weight(.medium))
        }
        .foregroundColor(color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.1))
        .clipShape(Capsule())
    }
}

// MARK: - Blocked Yoga Card (Matte Gray)

struct BlockedYogaCard: View {
    let item: YogaItem
    let tile: DestinyTileType // Added tile
    let isExpanded: Bool
    let onTap: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            Button(action: onTap) {
                HStack(spacing: 12) {
                    // Locked Icon
                    ZStack {
                        Circle()
                            .fill(AppTheme.Colors.inputBackground)
                            .frame(width: 32, height: 32)
                        Image(systemName: "lock.fill")
                            .font(.system(size: 14))
                            .foregroundColor(AppTheme.Colors.textTertiary)
                    }
                    
                    // Name
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.displayName)
                            .font(AppTheme.Fonts.body(size: 15).weight(.medium))
                            .foregroundColor(AppTheme.Colors.textSecondary)
                        
                        if let category = item.category {
                            Text(category)
                                .font(AppTheme.Fonts.caption(size: 11))
                                .foregroundColor(AppTheme.Colors.textTertiary)
                        }
                    }
                    
                    Spacer()
                    
                    // Blocked Badge
                    Text("BLOCKED")
                        .font(AppTheme.Fonts.caption(size: 10).weight(.bold))
                        .foregroundColor(AppTheme.Colors.textTertiary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            Capsule()
                                .fill(AppTheme.Colors.inputBackground)
                        )
                    
                    // Chevron
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(AppTheme.Colors.textTertiary)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
                .padding()
            }
            .buttonStyle(.plain)
            
            // Expanded - Show Reason
            if isExpanded {
                VStack(alignment: .leading, spacing: 12) {
                    Divider()
                        .background(AppTheme.Colors.textTertiary.opacity(0.2))
                    
                    // REASON - Hero Text
                    if let reason = item.reason, !reason.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 6) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(AppTheme.Colors.error.opacity(0.8))
                                Text("Why Blocked")
                                    .font(AppTheme.Fonts.caption(size: 11).weight(.medium))
                                    .foregroundColor(AppTheme.Colors.error.opacity(0.8))
                            }
                            Text(reason)
                                .font(AppTheme.Fonts.body(size: 14).weight(.medium))
                                .foregroundColor(AppTheme.Colors.error.opacity(0.9))
                        }
                    }
                    
                    // Formation
                    if let formation = item.formation, !formation.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Formation")
                                .font(AppTheme.Fonts.caption(size: 11))
                                .foregroundColor(AppTheme.Colors.textTertiary)
                            Text(formation)
                                .font(AppTheme.Fonts.body(size: 12))
                                .foregroundColor(AppTheme.Colors.textTertiary)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
        }
        .background(
            ZStack {
                // Transparent Dark Base (No Blur)
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.black.opacity(0.5)) // Darker fill for blocked items
                    .clipShape(RoundedRectangle(cornerRadius: 20))
            }
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
        )
        .opacity(0.9)
    }
}
