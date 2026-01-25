//
//  DestinyTileType.swift
//  ios_app
//
//  Category grouping for premium yoga/dosha UI
//

import SwiftUI

/// Life area tiles for the Destiny Matrix dashboard
enum DestinyTileType: String, CaseIterable, Identifiable {
    case wealth = "Wealth"
    case career = "Career"
    case love = "Love"
    case family = "Family"
    case wisdom = "Wisdom"
    case health = "Health"
    case dosha = "Challenges"
    
    var id: String { rawValue }
    
    /// Display title for the tile
    var displayTitle: String {
        switch self {
        case .wealth: return "Wealth & Assets"
        case .career: return "Career & Power"
        case .love: return "Love & Marriage"
        case .family: return "Family & Home"
        case .wisdom: return "Wisdom & Spirit"
        case .health: return "Health & Support"
        case .dosha: return "Karmic Challenges"
        }
    }
    
    /// Icon for the tile
    var icon: String {
        switch self {
        case .wealth: return "💰"
        case .career: return "🚀"
        case .love: return "❤️"
        case .family: return "🏡"
        case .wisdom: return "🧠"
        case .health: return "🛡️"
        case .dosha: return "⚠️"
        }
    }
    
    /// SF Symbol for the tile
    var systemIcon: String {
        switch self {
        case .wealth: return "dollarsign.circle.fill"
        case .career: return "star.circle.fill"
        case .love: return "heart.circle.fill"
        case .family: return "house.circle.fill"
        case .wisdom: return "brain.head.profile"
        case .health: return "cross.circle.fill"
        case .dosha: return "exclamationmark.triangle.fill"
        }
    }
    
    /// Accent color for the tile
    var accentColor: Color {
        switch self {
        case .wealth: return AppTheme.Colors.gold
        case .career: return .purple
        case .love: return .pink
        case .family: return .orange
        case .wisdom: return .cyan
        case .health: return .green
        case .dosha: return AppTheme.Colors.error
        }
    }
    
    /// Map backend category string to tile type
    /// Backend sends: "Basic Foundation", "Wealth", "Career", "Relationship", "Education", "Health", "Family", "Spiritual", "Special", "Pancha Mahapurusha", "Kendra", "Power", "Planetary", "Personality"
    static func from(category: String?) -> DestinyTileType {
        guard let cat = category?.lowercased().trimmingCharacters(in: .whitespaces) else { 
            return .wealth // Default to wealth if nil
        }
        
        switch cat {
        // Wealth & Assets
        case "wealth", "finance", "basic foundation", "basic_foundation", "planetary":
            return .wealth
        // Career & Power
        case "career", "power", "pancha mahapurusha", "pancha_mahapurusha", "special", "kendra":
            return .career
        // Love & Marriage
        case "relationship", "romance":
            return .love
        // Family & Home
        case "family":
            return .family
        // Wisdom & Spirit
        case "education", "spiritual", "personality":
            return .wisdom
        // Health & Support
        case "health":
            return .health
        default:
            // Print for debug - unknown category
            print("⚠️ DestinyTileType: Unknown category '\(cat)' - defaulting to wealth")
            return .wealth // Default to wealth instead of wisdom
        }
    }
    
    /// All topic tiles (excludes dosha which is status-based)
    static var topicTiles: [DestinyTileType] {
        [.wealth, .career, .love, .family, .wisdom, .health]
    }
}

// MARK: - YogaDoshaData Grouping Extension

extension YogaDoshaData {
    
    /// Group all items by topic tile type
    /// - Parameter includeBlocked: If true, includes cancelled items. If false, only active/reduced.
    func grouped(includeBlocked: Bool = true) -> [DestinyTileType: [YogaItem]] {
        var result: [DestinyTileType: [YogaItem]] = [:]
        
        // Initialize all tiles
        for tile in DestinyTileType.topicTiles {
            result[tile] = []
        }
        result[.dosha] = []
        
        // First, process doshas - they know their identity
        for item in (doshas ?? []) {
            // Skip cancelled if not including blocked
            if !includeBlocked && item.status == "C" {
                continue
            }
            
            // Active doshas go to Challenges tile
            if item.status == "A" {
                result[.dosha, default: []].append(item)
            } else {
                // Inactive/cancelled doshas go to their category tile
                let tile = DestinyTileType.from(category: item.category)
                result[tile, default: []].append(item)
            }
        }
        
        // Then, process yogas - they go to category tiles
        for item in (yogas ?? []) {
            // Skip cancelled if not including blocked
            if !includeBlocked && item.status == "C" {
                continue
            }
            
            // Yogas always go to category tiles
            let tile = DestinyTileType.from(category: item.category)
            result[tile, default: []].append(item)
        }
        
        return result
    }
    
    /// Get items for a specific tile
    func items(for tile: DestinyTileType) -> [YogaItem] {
        return grouped()[tile] ?? []
    }
    
    /// Get active items for a tile (status = A or R)
    func activeItems(for tile: DestinyTileType) -> [YogaItem] {
        return items(for: tile).filter { $0.status != "C" }
    }
    
    /// Get blocked items for a tile (status = C)
    func blockedItems(for tile: DestinyTileType) -> [YogaItem] {
        return items(for: tile).filter { $0.status == "C" }
    }
    
    /// Get summary counts for a tile
    func summaryCounts(for tile: DestinyTileType) -> (active: Int, blocked: Int) {
        let items = self.items(for: tile)
        let active = items.filter { $0.status != "C" }.count
        let blocked = items.filter { $0.status == "C" }.count
        return (active, blocked)
    }
    
    /// Get the signature strength (strongest active yoga from yogas array)
    var signatureStrength: YogaItem? {
        return (yogas ?? [])
            .filter { $0.status == "A" }
            .max(by: { $0.strength < $1.strength })
    }
    
    /// Get active doshas (from doshas array with status A)
    var activeDoshas: [YogaItem] {
        return (doshas ?? []).filter { $0.status == "A" }
    }
}
