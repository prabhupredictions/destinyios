// AffirmationBuilder.swift
// Device-computed affirmation text for the Recommended banner.
// Pure Swift — no SwiftUI dependency. Mirrors KutaTextBuilder pattern.

import Foundation

struct AffirmationBuilder {
    let kutas: [KutaDetail]
    let adjustedScore: Int?
    let totalScore: Int

    // MARK: - Public API

    func affirmationText() -> String {
        let score = adjustedScore ?? totalScore
        let perfect = topPerfectKootas()

        switch perfect.count {
        case 3...:
            let top = Array(perfect.prefix(3))
            let names = "\(top[0].displayName), \(top[1].displayName), and \(top[2].displayName)"
            let themes = "\(top[0].theme), \(top[1].theme), and \(top[2].theme)"
            return "\(names) all score perfectly — \(themes) are exceptionally well aligned."

        case 2:
            let names = "\(perfect[0].displayName) and \(perfect[1].displayName)"
            let themes = "\(perfect[0].theme) and \(perfect[1].theme)"
            return "\(names) both score perfectly — \(themes) are strong foundations for this match."

        case 1:
            let k = perfect[0]
            return "\(k.displayName) scores perfectly — strong \(k.theme). Scoring \(score)/36, this is a solid match by Vedic standards."

        default:
            return scoreTierSentence(score: score)
        }
    }

    // MARK: - Private

    /// Ordered weight list (descending). Varna (max=1) is intentionally absent.
    private static let weightOrder = ["nadi", "bhakoot", "gana", "maitri", "yoni", "tara", "vashya"]

    // Sanskrit proper names — same in all languages, not localized
    private var displayNames: [String: String] {
        [
            "nadi": "Nadi", "bhakoot": "Bhakoot", "gana": "Gana",
            "maitri": "Graha Maitri", "yoni": "Yoni", "tara": "Tara",
            "vashya": "Vashya"
        ]
    }

    private var themes: [String: String] {
        [
            "nadi": "kuta_theme_health_progeny".localized,
            "bhakoot": "kuta_theme_love".localized,
            "gana": "kuta_theme_temperament".localized,
            "maitri": "kuta_theme_mental".localized,
            "yoni": "kuta_theme_intimacy".localized,
            "tara": "kuta_theme_destiny".localized,
            "vashya": "kuta_theme_attraction".localized
        ]
    }

    private struct PerfectKoota {
        let displayName: String
        let theme: String
    }

    /// Returns up to 3 perfect kootas in descending weight order.
    /// Perfect = points == maxPoints AND maxPoints >= 3.
    private func topPerfectKootas() -> [PerfectKoota] {
        var result: [PerfectKoota] = []
        for key in Self.weightOrder {
            guard result.count < 3 else { break }
            guard let kuta = kutas.first(where: { $0.name.lowercased().contains(key) }),
                  kuta.maxPoints >= 3,
                  kuta.points == kuta.maxPoints else { continue }
            let displayName = displayNames[key] ?? key.capitalized
            let theme = themes[key] ?? key
            result.append(PerfectKoota(displayName: displayName, theme: theme))
        }
        return result
    }

    private func scoreTierSentence(score: Int) -> String {
        let scoreStr = "\(score)"
        switch score {
        case 28...:
            return String(format: "ashtakoot_tier_excellent".localized, scoreStr)
        case 24...27:
            return String(format: "ashtakoot_tier_very_good".localized, scoreStr)
        case 20...23:
            return String(format: "ashtakoot_tier_good".localized, scoreStr)
        case 16...19:
            return String(format: "ashtakoot_tier_average".localized, scoreStr)
        case 12...15:
            return String(format: "ashtakoot_tier_below_average".localized, scoreStr)
        default:
            return String(format: "ashtakoot_tier_low".localized, scoreStr)
        }
    }
}
