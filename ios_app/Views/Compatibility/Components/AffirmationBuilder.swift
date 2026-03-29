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

    private static let displayNames: [String: String] = [
        "nadi": "Nadi", "bhakoot": "Bhakoot", "gana": "Gana",
        "maitri": "Graha Maitri", "yoni": "Yoni", "tara": "Tara", "vashya": "Vashya"
    ]

    private static let themes: [String: String] = [
        "nadi": "health alignment", "bhakoot": "emotional bonding",
        "gana": "temperament compatibility", "maitri": "mental friendship",
        "yoni": "physical compatibility", "tara": "shared fortune",
        "vashya": "natural attraction"
    ]

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
            let displayName = Self.displayNames[key] ?? key.capitalized
            let theme = Self.themes[key] ?? key
            result.append(PerfectKoota(displayName: displayName, theme: theme))
        }
        return result
    }

    private func scoreTierSentence(score: Int) -> String {
        switch score {
        case 26...:
            return "Scoring \(score)/36 puts this match in the excellent tier — above the 26-point threshold for a strong Vedic match."
        case 22...25:
            return "Scoring \(score)/36 is a good match. No critical doshas are active — a solid foundation."
        default:
            return "Scoring \(score)/36 meets the minimum threshold. No critical doshas are blocking this match."
        }
    }
}
