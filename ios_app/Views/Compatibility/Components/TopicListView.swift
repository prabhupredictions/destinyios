//
//  TopicListView.swift
//  ios_app
//
//  Content view for a single topic tab showing active and blocked yogas
//

import SwiftUI

/// Extension to help with variant counting
extension YogaItem {
    /// Base name without variant numbers (e.g., "Daridra Yoga 144" -> "Daridra Yoga")
    var baseName: String {
        // Remove trailing numbers and parentheses
        return name.replacingOccurrences(of: "\\s+[0-9]+\\s*$", with: "", options: .regularExpression)
            .replacingOccurrences(of: "\\s*\\([0-9]+\\)\\s*$", with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespaces)
    }
    
    /// Extract variant number if present (e.g., "Daridra Yoga 144" -> 144)
    var variantNumber: Int? {
        let pattern = "(?:\\s+|\\()([0-9]+)(?:\\s*|\\))$"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []),
              let match = regex.firstMatch(in: name, options: [], range: NSRange(location: 0, length: name.utf16.count)) else {
            return nil
        }
        if let range = Range(match.range(at: 1), in: name) {
            return Int(name[range])
        }
        return nil
    }
}

/// Helper to calculate variant positions for a list of items
struct VariantCounter {
    static func calculatePositions(for items: [YogaItem]) -> [String: (current: Int, total: Int)] {
        // Group by base name
        let grouped = Dictionary(grouping: items) { $0.baseName }
        
        // Calculate positions
        var positions: [String: (current: Int, total: Int)] = [:]
        
        for (baseName, variants) in grouped {
            if variants.count > 1 {
                // Sort by variant number or original index
                let sorted = variants.enumerated().sorted { a, b in
                    let numA = a.element.variantNumber ?? a.offset
                    let numB = b.element.variantNumber ?? b.offset
                    return numA < numB
                }
                
                for (index, (originalIndex, item)) in sorted.enumerated() {
                    let key = item.id
                    positions[key] = (current: index + 1, total: sorted.count)
                }
            }
        }
        
        return positions
    }
}

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
        let activeVariantPositions = VariantCounter.calculatePositions(for: activeItems)
        let blockedVariantPositions = VariantCounter.calculatePositions(for: blockedItems)
        
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
                                tile: tile,
                                isExpanded: expandedItems.contains(item.id),
                                onTap: { toggleExpanded(item) },
                                variantPosition: activeVariantPositions[item.id]
                            )
                        }
                    } header: {
                        sectionHeader(
                            title: "Active factors",
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
                                tile: tile,
                                isExpanded: expandedItems.contains(item.id),
                                onTap: { toggleExpanded(item) },
                                variantPosition: blockedVariantPositions[item.id]
                            )
                        }
                    } header: {
                        sectionHeader(
                            title: "Inactive factors",
                            icon: "circle.slash",
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
        VStack(spacing: 8) {
            // SVG Icon with Glow
            Image(tile.activeIconImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 40, height: 40) // Reduced from 48
                .shadow(color: tile.accentColor.opacity(0.3), radius: 12, x: 0, y: 0) // Reduced shadow
                .padding(.bottom, 2)
            
            // Title
            Text(tile.displayTitle)
                .font(.system(size: 20, weight: .bold, design: .serif)) // Reduced from 22
                .foregroundColor(.white)
            
            // Counts
            HStack(spacing: 8) {
                Text("\(activeItems.count) Active")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(tile.accentColor)
                
                if !blockedItems.isEmpty {
                    Text("•")
                        .foregroundColor(AppTheme.Colors.textTertiary)
                    
                    Text("\(blockedItems.count) Inactive")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12) // Reduced from 16
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
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(color)
            Text(title.uppercased())
                .font(.system(size: 11, weight: .bold))
                .tracking(1)
                .foregroundColor(AppTheme.Colors.textSecondary)
            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
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
    let tile: DestinyTileType
    let isExpanded: Bool
    let onTap: () -> Void
    let variantPosition: (current: Int, total: Int)?  // NEW: Variant counter
    
    /// Clean base name: strip trailing reference numbers/parentheses from localized name
    private var cleanBaseName: String {
        item.localizedName
            .replacingOccurrences(of: "\\s*\\(\\d+\\)\\s*$", with: "", options: .regularExpression)
            .replacingOccurrences(of: "\\s+\\d+\\s*$", with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespaces)
    }
    
    private var displayName: String {
        if let pos = variantPosition {
            return "\(cleanBaseName) (\(pos.current)/\(pos.total))"
        }
        return cleanBaseName
    }
    
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
                        Text(displayName)
                            .font(AppTheme.Fonts.body(size: 15).weight(.semibold))
                            .foregroundColor(AppTheme.Colors.textPrimary)
                        
                        // Only show category if it doesn't match the current tab (redundancy check)
                        if let category = item.category, 
                           !category.localizedCaseInsensitiveContains(tile.rawValue) {
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
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
    }
    
    private var statusBadge: some View {
        let (text, color) = statusInfo
        return Text(text)
            .font(.system(size: 10, weight: .semibold))
            .tracking(0.5)
            .foregroundColor(color)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(color.opacity(0.12))
                    .overlay(Capsule().stroke(color.opacity(0.25), lineWidth: 0.5))
            )
    }
    
    private var statusInfo: (String, Color) {
        switch item.status.uppercased() {
        case "A": return ("Active", AppTheme.Colors.success)
        case "R": return ("REDUCED", AppTheme.Colors.gold)
        default: return (item.status, AppTheme.Colors.textTertiary)
        }
    }
    
    private var expandedContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            Divider()
                .background(Color.white.opacity(0.08))
                .padding(.horizontal, -16)
            
            // Outcome (Professional interpretation)
            if let outcome = item.localizedOutcome, !outcome.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 11))
                            .foregroundColor(tile.accentColor)
                        Text("yoga_outcome_label".localized.uppercased())
                            .font(.system(size: 10, weight: .bold))
                            .tracking(1)
                            .foregroundColor(tile.accentColor)
                    }
                    Text(outcome)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(AppTheme.Colors.textPrimary)
                        .lineSpacing(2)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(tile.accentColor.opacity(0.08))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(tile.accentColor.opacity(0.15), lineWidth: 1)
                        )
                )
            }
            
            // Formation (Technical Details)
            if let formation = item.localizedFormation, !formation.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Image(systemName: "info.circle.fill")
                            .font(.system(size: 11))
                            .foregroundColor(AppTheme.Colors.textTertiary)
                        Text("yoga_formation_label".localized.uppercased())
                            .font(.system(size: 10, weight: .bold))
                            .tracking(1)
                            .foregroundColor(AppTheme.Colors.textTertiary)
                    }
                    Text(formation)
                        .font(.system(size: 13))
                        .foregroundColor(AppTheme.Colors.textSecondary)
                        .lineSpacing(2)
                }
            }
            
            // Planets & Houses
            HStack(spacing: 8) {
                if let planets = item.uniquePlanets {
                    detailChip(icon: "sparkle", text: planets, color: tile.accentColor)
                }
                if let houses = item.uniqueHouses {
                    detailChip(icon: "house.fill", text: "H\(houses)", color: AppTheme.Colors.textSecondary)
                }
            }
            
            // Reason (for Reduced)
            if let reason = item.reason, !reason.isEmpty, item.status == "R" {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 11))
                            .foregroundColor(AppTheme.Colors.warning)
                        Text("yoga_why_reduced".localized.uppercased())
                            .font(.system(size: 10, weight: .bold))
                            .tracking(1)
                            .foregroundColor(AppTheme.Colors.warning)
                    }
                    Text(DoshaDescriptions.localizeExceptionKeys(in: reason))
                        .font(.system(size: 13))
                        .foregroundColor(AppTheme.Colors.warning.opacity(0.9))
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(AppTheme.Colors.warning.opacity(0.08))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(AppTheme.Colors.warning.opacity(0.15), lineWidth: 1)
                        )
                )
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }
    
    private func detailChip(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 9, weight: .medium))
            Text(text)
                .font(.system(size: 11, weight: .medium))
        }
        .foregroundColor(color)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            Capsule()
                .fill(Color.white.opacity(0.05))
                .overlay(Capsule().stroke(Color.white.opacity(0.1), lineWidth: 0.5))
        )
    }
}
// MARK: - Blocked Yoga Card (Matte Gray)

struct BlockedYogaCard: View {
    let item: YogaItem
    let tile: DestinyTileType
    let isExpanded: Bool
    let onTap: () -> Void
    let variantPosition: (current: Int, total: Int)?  // NEW: Variant counter
    
    /// Clean base name: strip trailing reference numbers/parentheses from localized name
    private var cleanBaseName: String {
        item.localizedName
            .replacingOccurrences(of: "\\s*\\(\\d+\\)\\s*$", with: "", options: .regularExpression)
            .replacingOccurrences(of: "\\s+\\d+\\s*$", with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespaces)
    }
    
    private var displayName: String {
        if let pos = variantPosition {
            return "\(cleanBaseName) (\(pos.current)/\(pos.total))"
        }
        return cleanBaseName
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            Button(action: onTap) {
                HStack(spacing: 12) {
                    // Disabled Icon
                    ZStack {
                        Circle()
                            .fill(AppTheme.Colors.inputBackground)
                            .frame(width: 32, height: 32)
                        Image(systemName: "circle.slash")
                            .font(.system(size: 14))
                            .foregroundColor(AppTheme.Colors.textTertiary)
                    }
                    
                    // Name
                    VStack(alignment: .leading, spacing: 4) {
                        Text(displayName)
                            .font(AppTheme.Fonts.body(size: 15).weight(.medium))
                            .foregroundColor(AppTheme.Colors.textSecondary)
                        
                        // Only show category if it doesn't match the current tab (redundancy check)
                        if let category = item.category,
                           !category.localizedCaseInsensitiveContains(tile.rawValue) {
                            Text(category)
                                .font(AppTheme.Fonts.caption(size: 11))
                                .foregroundColor(AppTheme.Colors.textTertiary)
                        }
                    }
                    
                    Spacer()
                    
                    // Inactive Badge
                    Text("Inactive")
                        .font(.system(size: 10, weight: .semibold))
                        .tracking(0.5)
                        .foregroundColor(AppTheme.Colors.textTertiary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(Color.white.opacity(0.05))
                                .overlay(Capsule().stroke(Color.white.opacity(0.1), lineWidth: 0.5))
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
            
            // Expanded - Show Reason + Outcome + Formation
            if isExpanded {
                VStack(alignment: .leading, spacing: 16) {
                    Divider()
                        .background(Color.white.opacity(0.08))
                        .padding(.horizontal, -16)
                    
                    // Outcome (What it means) - Show FIRST for inactive too
                    if let outcome = item.localizedOutcome, !outcome.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 6) {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 11))
                                    .foregroundColor(AppTheme.Colors.textSecondary)
                                Text("yoga_outcome_label".localized.uppercased())
                                    .font(.system(size: 10, weight: .bold))
                                    .tracking(1)
                                    .foregroundColor(AppTheme.Colors.textSecondary)
                            }
                            Text(outcome)
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(AppTheme.Colors.textPrimary)
                                .lineSpacing(2)
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.05))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                )
                        )
                    }
                    
                    // REASON - Why Inactive (Hero section)
                    if let reason = item.reason, !reason.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 6) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 11))
                                    .foregroundColor(AppTheme.Colors.error)
                                Text("yoga_why_inactive".localized.uppercased())
                                    .font(.system(size: 10, weight: .bold))
                                    .tracking(1)
                                    .foregroundColor(AppTheme.Colors.error)
                            }
                            Text(DoshaDescriptions.localizeExceptionKeys(in: reason))
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(AppTheme.Colors.error.opacity(0.9))
                                .lineSpacing(2)
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(AppTheme.Colors.error.opacity(0.08))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(AppTheme.Colors.error.opacity(0.15), lineWidth: 1)
                                )
                        )
                    }
                    
                    // Formation (Technical Details)
                    if let formation = item.localizedFormation, !formation.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 6) {
                                Image(systemName: "info.circle.fill")
                                    .font(.system(size: 11))
                                    .foregroundColor(AppTheme.Colors.textTertiary)
                                Text("yoga_formation_label".localized.uppercased())
                                    .font(.system(size: 10, weight: .bold))
                                    .tracking(1)
                                    .foregroundColor(AppTheme.Colors.textTertiary)
                            }
                            Text(formation)
                                .font(.system(size: 13))
                                .foregroundColor(AppTheme.Colors.textSecondary)
                                .lineSpacing(2)
                        }
                    }
                    
                    // Planets & Houses
                    HStack(spacing: 8) {
                        if let planets = item.uniquePlanets {
                            detailChip(icon: "sparkle", text: planets, color: AppTheme.Colors.textSecondary)
                        }
                        if let houses = item.uniqueHouses {
                            detailChip(icon: "house.fill", text: "H\(houses)", color: AppTheme.Colors.textTertiary)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.02))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                )
        )
        .opacity(0.85)
    }
    
    private func detailChip(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 9, weight: .medium))
            Text(text)
                .font(.system(size: 11, weight: .medium))
        }
        .foregroundColor(color)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            Capsule()
                .fill(Color.white.opacity(0.05))
                .overlay(Capsule().stroke(Color.white.opacity(0.1), lineWidth: 0.5))
        )
    }
}
