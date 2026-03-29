// KutaTextBuilder.swift
// Pure text-building logic for all 8 Ashtakoot Koota tooltips.
// No SwiftUI dependency — fully unit-testable.

import Foundation

struct KutaTextBuilder {
    let kuta: AshtakootData
    let boyName: String
    let girlName: String

    // MARK: - Public API

    /// Full human-readable description paragraph for the tooltip body.
    func descriptionParagraph() -> String {
        buildDescription()
    }

    /// Prompt text sent to AskDestiny when user taps "See classical analysis →".
    func classicalPrompt() -> String {
        buildPrompt()
    }

    // MARK: - Sanskrit Koota names

    private var kutaName: String {
        let names: [String: String] = [
            "varna": "Varna", "vashya": "Vashya", "tara": "Tara",
            "yoni": "Yoni", "maitri": "Graha Maitri", "gana": "Gana",
            "bhakoot": "Bhakoot", "nadi": "Nadi"
        ]
        return names[kuta.key] ?? kuta.key.capitalized
    }

    private var score: Int { Int(kuta.score) }
    private var maxScore: Int { Int(kuta.maxScore) }
    private var displayScore: String { "\(score) out of \(maxScore)" }

    // MARK: - Sign name expansion

    private func expand(_ value: String) -> String {
        let map: [String: String] = [
            "Ar": "Aries", "Ta": "Taurus", "Ge": "Gemini", "Cn": "Cancer",
            "Le": "Leo", "Vi": "Virgo", "Li": "Libra", "Sc": "Scorpio",
            "Sg": "Sagittarius", "Cp": "Capricorn", "Aq": "Aquarius", "Pi": "Pisces"
        ]
        var result = value
        for (abbr, full) in map {
            result = result.replacingOccurrences(
                of: "\\b\(abbr)\\b", with: full, options: .regularExpression
            )
        }
        return result
    }

    private var bv: String { kuta.boyValue.map { expand($0) } ?? "" }
    private var gv: String { kuta.girlValue.map { expand($0) } ?? "" }
    private var hasValues: Bool { !bv.isEmpty && !gv.isEmpty }

    private var cancellationReason: String {
        expand(kuta.cancellationReason ?? "exemption conditions in your charts")
    }

    /// "Score restored to X/X — this dosha does not count against your match."
    /// Empty string when not cancelled.
    private var adjustedScoreNote: String {
        guard kuta.doshaCancelled else { return "" }
        return "Score restored to \(maxScore)/\(maxScore) — this dosha does not count against your match."
    }

    // MARK: - Description paragraph

    private func buildDescription() -> String {
        var parts: [String] = []

        switch kuta.key {

        case "varna":
            parts.append("\(kuta.label) compatibility is measured by \(kutaName) Koota, which looks at each partner's spiritual and social orientation — Brahmin (wisdom), Kshatriya (leadership), Vaishya (commerce), or Shudra (service/craft).")
            if hasValues {
                parts.append("\(boyName) belongs to the \(bv) Varna and \(girlName) to the \(gv) Varna.")
            }
            let body = kuta.plainEnglishSummary ?? (score == maxScore
                ? "Compatible Varnas indicate natural alignment in how you approach your duties, ambitions, and life purpose."
                : "A mismatch here suggests your fundamental life orientations pull in different directions, which can create friction in shared decisions and long-term goals.")
            parts.append("Their score is \(displayScore). \(body)")

        case "vashya":
            parts.append("\(kuta.label) compatibility is measured by \(kutaName) Koota, which looks at the natural power dynamic and magnetism between partners — based on each moon sign's symbolic animal group (human, four-legged, aquatic, forest, or insect).")
            if hasValues { parts.append("\(boyName) is \(bv) and \(girlName) is \(gv).") }
            let body: String
            if let s = kuta.plainEnglishSummary, !s.isEmpty { body = s }
            else if score == 2 { body = "Mutual Vashya indicates strong natural attraction and a balanced sense of influence between you." }
            else if score == 1 { body = "Partial Vashya — there is a draw between you, but it may feel one-sided at times. Conscious balance prevents resentment." }
            else { body = "No Vashya match — little natural pull between these signs. The relationship requires conscious effort to maintain attraction." }
            parts.append("Their score is \(displayScore). \(body)")

        case "tara":
            parts.append("\(kuta.label) compatibility is measured by \(kutaName) Koota, which counts the distance between each partner's birth Nakshatra (lunar mansion). Even-numbered counts are auspicious; odd are inauspicious — a full score means both directions align well.")
            if let btg = kuta.taraBoyToGirl, let gtb = kuta.taraGirlToBoy {
                parts.append("\(boyName)'s birth star counts \(btg) positions to \(girlName)'s, and the reverse counts \(gtb).")
            }
            let body: String
            if let s = kuta.plainEnglishSummary, !s.isEmpty { body = s }
            else if score == 3 { body = "Your life paths are in harmony and you are likely to bring good fortune to each other rather than draining vitality." }
            else if score >= 1 { body = "Mostly harmonious destinies with some areas of misalignment in how your individual life paths interact." }
            else { body = "Your birth stars indicate life paths that may work against each other's vitality and long-term fortune." }
            parts.append("Their score is \(displayScore). \(body)")

        case "yoni":
            parts.append("\(kuta.label) compatibility is measured by \(kutaName) Koota, which assigns each Nakshatra a symbolic animal. Matching or friendly animals score highly; hostile pairs score low — reflecting depth of physical chemistry and intimate compatibility.")
            if hasValues { parts.append("\(boyName) is \(bv) and \(girlName) is \(gv).") }
            let body: String
            if let s = kuta.plainEnglishSummary, !s.isEmpty { body = s }
            else if score == 4 { body = "An ideal Yoni match — deep physical chemistry and strong intimate compatibility between these two natures." }
            else if score >= 2 { body = "These two natures are partially compatible — decent physical chemistry that can deepen with time and mutual effort." }
            else { body = "A hostile Yoni pairing — physical incompatibility is likely to be a recurring source of friction in this relationship." }
            parts.append("Their score is \(displayScore). \(body)")

        case "maitri":
            parts.append("\(kuta.label) compatibility is measured by \(kutaName) Koota, which compares the ruling planets of each partner's moon sign. Friendly lords score 5; neutral 3; enemies 0 — governing intellectual rapport, mutual respect, and the friendship beneath the romance.")
            if hasValues { parts.append("\(boyName)'s moon sign lord is \(bv) and \(girlName)'s is \(gv).") }
            let body: String
            if let s = kuta.plainEnglishSummary, !s.isEmpty { body = s }
            else if score >= 4 { body = "These planetary lords are friendly — natural intellectual rapport and genuine friendship form the core of this relationship." }
            else if score >= 2 { body = "Neutral lords — the friendship is functional and stable but may lack a deep natural intellectual affinity." }
            else { body = "Enemy lords — intellectual friction and a lack of mutual understanding are likely without deliberate and sustained effort." }
            parts.append("Their score is \(displayScore). \(body)")

        case "gana":
            parts.append("\(kuta.label) compatibility is measured by \(kutaName) Koota, which classifies each partner's fundamental nature as divine (Deva — gentle, idealistic), human (Manushya — balanced, practical), or intense (Rakshasa — ambitious, dominant).")
            if hasValues { parts.append("\(boyName) is \(bv) and \(girlName) is \(gv).") }
            let body: String
            if let s = kuta.plainEnglishSummary, !s.isEmpty { body = s }
            else if score == 6 { body = "Matching Ganas — your temperaments are in natural harmony and you handle conflict and stress in compatible ways." }
            else if score == 5 { body = "Very close Ganas — minor differences in approach but fundamentally compatible temperaments." }
            else { body = "Mixed Ganas — real differences in how you each handle conflict, pressure, and emotional expression." }
            parts.append("Their score is \(displayScore). \(body)")
            if kuta.doshaPresent && !kuta.doshaCancelled {
                let bvLabel = bv.isEmpty ? boyName : bv
                let gvLabel = gv.isEmpty ? girlName : gv
                parts.append("⚠ Active Gana Dosha. When \(bvLabel) and \(gvLabel) natures pair up, the dominant nature tends to overpower the gentler one, creating friction in how you communicate, handle conflict, and show up for each other under stress. No cancellation was found in your charts.")
            } else if kuta.doshaPresent && kuta.doshaCancelled {
                parts.append("The Gana Dosha is cancelled — \(cancellationReason). \(adjustedScoreNote) This softens the temperament clash significantly.")
            }

        case "bhakoot":
            parts.append("\(kuta.label) compatibility is measured by \(kutaName) Koota — the most emotionally significant of all 8 Kootas at 7 points. It looks at the angular distance between moon signs, governing romantic love, emotional bonding, financial prosperity, and prospects for children.")
            if hasValues { parts.append("\(boyName)'s moon is in \(bv) and \(girlName)'s in \(gv).") }
            let body: String
            if let s = kuta.plainEnglishSummary, !s.isEmpty { body = s }
            else if score == 7 { body = "Excellent Bhakoot — a strong emotional bond, aligned financial energies, and favourable prospects for family life." }
            else if !kuta.doshaPresent { body = "This moon-sign pairing scores \(score) but does not form a classical Bhakoot Dosha — the score reflects partial alignment in emotional and financial energies." }
            else { body = "" }
            parts.append(body.isEmpty ? "Their raw score is \(displayScore)." : "Their score is \(displayScore). \(body)")
            if kuta.doshaPresent && !kuta.doshaCancelled {
                let typeNote = kuta.doshaType.map { " (\($0))" } ?? ""
                parts.append("⚠ Active Bhakoot Dosha\(typeNote). Classical texts link this moon-sign pairing with emotional distance and financial hardship. No cancellation was found — this is a significant flag in your match.")
            } else if kuta.doshaPresent && kuta.doshaCancelled {
                parts.append("The Bhakoot Dosha is cancelled — \(cancellationReason). Score restored to \(maxScore)/\(maxScore). The underlying dosha does not count against your compatibility.")
            }

        case "nadi":
            parts.append("\(kuta.label) compatibility is measured by \(kutaName) Koota — the most heavily weighted Koota at 8 points, and classically considered the most critical for long-term compatibility. It looks at the Ayurvedic body-type (Nadi) of each partner: Aadi (Vata), Madhya (Pitta), or Antya (Kapha).")
            if hasValues { parts.append("\(boyName) is \(bv) Nadi and \(girlName) is \(gv) Nadi.") }
            let body: String
            if let s = kuta.plainEnglishSummary, !s.isEmpty { body = s }
            else if score == 8 { body = "Different Nadis — ideal for genetic harmony, health compatibility, and prospects for children." }
            else if !kuta.doshaPresent { body = "Partial Nadi compatibility — mostly harmonious constitutional energies." }
            else { body = "" }
            parts.append(body.isEmpty ? "Their score is \(displayScore)." : "Their score is \(displayScore). \(body)")
            if kuta.doshaPresent && !kuta.doshaCancelled {
                parts.append("⚠ Active Nadi Dosha. Identical Nadis form the most serious dosha in Ashtakoot matching. Classical texts associate same-Nadi couples with health challenges, genetic incompatibility, and difficulties conceiving. No cancellation found — classical remedies are strongly recommended.")
            } else if kuta.doshaPresent && kuta.doshaCancelled {
                parts.append("The Nadi Dosha is cancelled — \(cancellationReason). \(adjustedScoreNote) The genetic and health concerns are considered neutralised.")
            }

        default:
            parts.append("\(kuta.label) compatibility is measured by \(kutaName) Koota.")
            if hasValues { parts.append("\(boyName) is \(bv) and \(girlName) is \(gv).") }
            if let s = kuta.plainEnglishSummary, !s.isEmpty { parts.append(s) }
            parts.append("Their score is \(displayScore).")
            if kuta.doshaPresent && !kuta.doshaCancelled {
                parts.append("⚠ Active \(kutaName) Dosha. No cancellation was found in your charts.")
            } else if kuta.doshaPresent && kuta.doshaCancelled {
                parts.append("The dosha is cancelled — \(cancellationReason). \(adjustedScoreNote)")
            }
        }

        return parts.joined(separator: "\n\n")
    }

    // MARK: - Classical analysis prompt

    private func buildPrompt() -> String {
        let scoreStr = "\(score)/\(maxScore)"
        let valuesLine = hasValues ? "\(boyName) is \(bv) and \(girlName) is \(gv). " : ""
        let opening = "\(boyName) and \(girlName) scored \(scoreStr) on \(kutaName) Koota — the Vedic measure of \(kuta.label.lowercased()) compatibility. \(valuesLine)"

        switch kuta.key {

        case "varna":
            return opening
                + "Can you explain what Varna Koota classically measures, what these two Varnas mean individually, why this pairing scores the way it does, and what it means practically for how this couple will align in their daily work, life purpose, and shared values?"

        case "vashya":
            return opening
                + "Can you explain what Vashya Koota classically measures, what these two types mean, why this pairing scores the way it does, and what it means practically for the power dynamic, magnetism, and sense of influence in this couple's relationship?"

        case "tara":
            let taraLine: String
            if let btg = kuta.taraBoyToGirl, let gtb = kuta.taraGirlToBoy {
                taraLine = "\(boyName)'s birth star counts \(btg) positions to \(girlName)'s; the reverse counts \(gtb). "
            } else { taraLine = "" }
            return "\(boyName) and \(girlName) scored \(scoreStr) on Tara Koota — the Vedic measure of destiny and fortune compatibility. \(taraLine)"
                + "Can you explain what Tara Koota classically measures, how the birth-star counting method works, what these numbers indicate, and what it means in practice — will these two bring good fortune to each other, or is there an astrological drain on vitality and luck?"

        case "yoni":
            return opening
                + "Can you explain what Yoni Koota classically measures, what these two animal symbols mean, whether they are friendly, neutral, or hostile to each other, and what it means practically for the physical chemistry, intimacy, and desire in this couple's relationship?"

        case "maitri":
            return opening
                + "Can you explain what Graha Maitri Koota classically measures, what the classical relationship is between these two planetary lords (friendly, neutral, or enemy), and what this means practically for the intellectual bond, mutual respect, and friendship that underlies this couple's relationship?"

        case "gana":
            if kuta.doshaPresent && !kuta.doshaCancelled {
                return opening
                    + "This mismatch has triggered an active Gana Dosha with no cancellation found in their charts. Can you explain what Gana Koota classically measures, what each Gana type means (Deva, Manushya, Rakshasa), why this pairing forms a dosha, what classical texts say about how this shows up in daily life as a couple, how seriously astrologers weigh this, and what remedies or adjustments the classical tradition recommends?"
            } else if kuta.doshaPresent && kuta.doshaCancelled {
                return opening
                    + "A Gana Dosha was identified but cancelled because: \(cancellationReason). Can you explain what the original dosha meant classically, why this cancellation condition applies and which classical text it comes from, whether a cancelled Gana Dosha carries any residual effect on temperament and daily life, and what this couple should be aware of going forward?"
            } else {
                return opening
                    + "Can you explain what Gana Koota classically measures, what these Gana types mean individually, and what this score means for day-to-day temperament compatibility — how they handle conflict, stress, and emotional expression together?"
            }

        case "bhakoot":
            if kuta.doshaPresent && !kuta.doshaCancelled {
                let typeNote = kuta.doshaType.map { " (\($0))" } ?? ""
                return opening
                    + "This moon-sign pairing forms an active Bhakoot Dosha\(typeNote) with no cancellation found. Can you explain what Bhakoot Koota classically measures, why this particular moon-sign pairing forms a dosha, what classical texts say the consequences are for love, finances, and children, how seriously astrologers weigh this, and what remedies are traditionally prescribed?"
            } else if kuta.doshaPresent && kuta.doshaCancelled {
                return opening
                    + "A Bhakoot Dosha was identified but cancelled because: \(cancellationReason). Score restored to \(maxScore)/\(maxScore). Can you explain what the original Bhakoot Dosha meant classically, why this cancellation condition applies and which classical text it comes from, whether any residual effect remains on love, finances, or children, and what this couple should be aware of?"
            } else {
                return opening
                    + "Can you explain what Bhakoot Koota classically measures, what this moon-sign pairing traditionally indicates for emotional connection, financial alignment, and family prospects — and what this score means for this couple's long-term relationship?"
            }

        case "nadi":
            if kuta.doshaPresent && !kuta.doshaCancelled {
                return opening
                    + "Both partners share the same Nadi, forming an active Nadi Dosha with no cancellation found. Can you explain what Nadi Koota classically measures, what the three Nadis (Aadi, Madhya, Antya) represent in Ayurveda and Vedic astrology, why same-Nadi pairing is considered the most serious dosha in Ashtakoot, what classical texts specifically say about the consequences for health, children, and longevity — and what remedies (puja, gemstones, timing) are traditionally prescribed?"
            } else if kuta.doshaPresent && kuta.doshaCancelled {
                return opening
                    + "A Nadi Dosha was identified but cancelled because: \(cancellationReason). Can you explain what the original Nadi Dosha meant classically, why it is considered the most serious dosha in Ashtakoot, why this cancellation condition applies and which classical text it comes from, whether any residual health or progeny concern remains, and what this couple should know?"
            } else {
                return opening
                    + "Can you explain what Nadi Koota classically measures, what each Nadi type (Aadi/Vata, Madhya/Pitta, Antya/Kapha) means in Ayurveda, why different Nadis are ideal for compatibility, and what this score means for health harmony and prospects for children in this relationship?"
            }

        default:
            return opening
                + "Can you give a classical Vedic analysis of this \(kutaName) Koota result, explaining what it measures, what this score means for this couple, and any classical significance to note?"
        }
    }
}
