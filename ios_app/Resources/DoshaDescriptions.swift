//
//  DoshaDescriptions.swift
//  ios_app
//
//  Helper for mapping snake_case backend keys to localized user-facing descriptions
//

import Foundation

/// Helper struct to convert backend snake_case keys to localized descriptions
struct DoshaDescriptions {
    
    // MARK: - Exception Descriptions
    
    /// Get localized description for a mangal dosha exception key
    static func exception(_ key: String) -> String {
        return ("exception_" + key).localized
    }
    
    // MARK: - Intensity Factor Descriptions
    
    /// Get localized description for an intensity factor key
    static func intensity(_ key: String) -> String {
        return ("intensity_" + key).localized
    }
    
    // MARK: - Sign Codes
    
    /// Convert 2-letter sign code to full sign name
    static func sign(_ code: String) -> String {
        return ("sign_" + code.lowercased()).localized
    }
    
    // MARK: - Severity Levels
    
    /// Get localized severity label
    static func severity(_ level: String) -> String {
        switch level.lowercased() {
        case "none": return "severity_none".localized
        case "mild": return "severity_mild".localized
        case "moderate": return "severity_moderate".localized
        case "high": return "severity_high".localized
        case "severe": return "severity_severe".localized
        default: return level
        }
    }
    
    // MARK: - Status Badges
    
    /// Get localized status label for yoga/dosha status
    static func status(_ code: String) -> String {
        switch code.uppercased() {
        case "A": return "status_active".localized
        case "R": return "status_reduced".localized
        case "C": return "status_cancelled".localized
        default: return code
        }
    }
    
    // MARK: - Planet Abbreviations
    
    /// Convert planet abbreviation to full name
    static func planet(_ abbr: String) -> String {
        let mapping: [String: String] = [
            "Su": "planet_sun".localized,
            "Mo": "planet_moon".localized,
            "Ma": "planet_mars".localized,
            "Me": "planet_mercury".localized,
            "Ju": "planet_jupiter".localized,
            "Ve": "planet_venus".localized,
            "Sa": "planet_saturn".localized,
            "Ra": "planet_rahu".localized,
            "Ke": "planet_ketu".localized
        ]
        return mapping[abbr] ?? abbr
    }
    
    // MARK: - Yoga Category Icons
    
    /// Get emoji icon for yoga category
    static func categoryIcon(_ category: String) -> String {
        switch category.lowercased() {
        case "wealth", "w": return "💰"
        case "career", "c": return "👔"
        case "relationship", "r": return "💕"
        case "health", "h": return "❤️‍🩹"
        case "spiritual", "s": return "🙏"
        case "fame", "f": return "⭐️"
        case "knowledge", "k": return "📚"
        default: return "✨"
        }
    }
}

// MARK: - Convenience Extensions (only for properties not in main struct)

// MangalDoshaData properties are now defined in DoshaModels.swift

extension KalaSarpaData {
    /// Get planet names as displayable list
    var planetNames: [String] {
        return planetsInvolved?.map { DoshaDescriptions.planet($0) } ?? []
    }
}

extension YogaItem {
    /// Get localized status as display text
    var statusDisplayText: String {
        return DoshaDescriptions.status(status)
    }
    
    /// Get category icon
    var categoryIconEmoji: String {
        return DoshaDescriptions.categoryIcon(category ?? "")
    }
}
