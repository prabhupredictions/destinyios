// AffirmationBuilderTests.swift
import XCTest
@testable import ios_app

final class AffirmationBuilderTests: XCTestCase {

    private func kuta(_ name: String, points: Int, max: Int) -> KutaDetail {
        KutaDetail(name: name, maxPoints: max, points: points, description: "")
    }

    // MARK: - Perfect koota sentence templates

    func test_threePerfectKootas_namesAllThreeInOrder() {
        // Nadi(8/8), Bhakoot(7/7), Gana(6/6) — all perfect, ordered by weight
        let kutas = [
            kuta("Nadi", points: 8, max: 8),
            kuta("Bhakoot", points: 7, max: 7),
            kuta("Gana", points: 6, max: 6),
            kuta("Yoni", points: 2, max: 4),
        ]
        let text = AffirmationBuilder(kutas: kutas, adjustedScore: nil, totalScore: 29).affirmationText()
        XCTAssertTrue(text.contains("Nadi, Bhakoot, and Gana"), "Expected all three names: \(text)")
        XCTAssertTrue(text.contains("all score perfectly"), text)
        XCTAssertTrue(text.contains("health alignment"), text)
        XCTAssertTrue(text.contains("emotional bonding"), text)
        XCTAssertTrue(text.contains("temperament compatibility"), text)
    }

    func test_moreThanThreePerfect_capsAtTopThreeByWeight() {
        // Nadi, Bhakoot, Gana, Maitri all perfect — should mention only top 3
        let kutas = [
            kuta("Nadi", points: 8, max: 8),
            kuta("Bhakoot", points: 7, max: 7),
            kuta("Gana", points: 6, max: 6),
            kuta("Graha Maitri", points: 5, max: 5),
        ]
        let text = AffirmationBuilder(kutas: kutas, adjustedScore: nil, totalScore: 33).affirmationText()
        XCTAssertTrue(text.contains("Nadi, Bhakoot, and Gana"), "Should cap at 3: \(text)")
        XCTAssertFalse(text.contains("Graha Maitri"), "4th should be excluded: \(text)")
    }

    func test_twoPerfectKootas_usesTwoTemplate() {
        let kutas = [
            kuta("Nadi", points: 8, max: 8),
            kuta("Bhakoot", points: 7, max: 7),
            kuta("Gana", points: 3, max: 6),
        ]
        let text = AffirmationBuilder(kutas: kutas, adjustedScore: nil, totalScore: 28).affirmationText()
        XCTAssertTrue(text.contains("Nadi and Bhakoot"), text)
        XCTAssertTrue(text.contains("both score perfectly"), text)
        XCTAssertTrue(text.contains("strong foundations for this match"), text)
    }

    func test_onePerfectKoota_includesScore() {
        let kutas = [
            kuta("Nadi", points: 8, max: 8),
            kuta("Bhakoot", points: 4, max: 7),
        ]
        let text = AffirmationBuilder(kutas: kutas, adjustedScore: nil, totalScore: 24).affirmationText()
        XCTAssertTrue(text.contains("Nadi scores perfectly"), text)
        XCTAssertTrue(text.contains("strong health alignment"), text)
        XCTAssertTrue(text.contains("24/36"), text)
    }

    func test_onePerfectKoota_adjustedScoreUsedOverTotal() {
        let kutas = [kuta("Bhakoot", points: 7, max: 7)]
        let text = AffirmationBuilder(kutas: kutas, adjustedScore: 26, totalScore: 24).affirmationText()
        XCTAssertTrue(text.contains("26/36"), "adjusted score should be used: \(text)")
        XCTAssertFalse(text.contains("24/36"), text)
    }

    // MARK: - Score-tier fallback (0 perfect kootas)

    func test_zeroPerfect_excellentTier() {
        let kutas = [
            kuta("Nadi", points: 6, max: 8),
            kuta("Bhakoot", points: 5, max: 7),
        ]
        let text = AffirmationBuilder(kutas: kutas, adjustedScore: 28, totalScore: 28).affirmationText()
        XCTAssertTrue(text.contains("28/36"), text)
        XCTAssertTrue(text.contains("excellent tier"), text)
    }

    func test_zeroPerfect_goodTier() {
        let kutas = [kuta("Nadi", points: 6, max: 8)]
        let text = AffirmationBuilder(kutas: kutas, adjustedScore: nil, totalScore: 23).affirmationText()
        XCTAssertTrue(text.contains("23/36"), text)
        XCTAssertTrue(text.contains("good match"), text)
    }

    func test_zeroPerfect_minimumTier() {
        let kutas = [kuta("Nadi", points: 4, max: 8)]
        let text = AffirmationBuilder(kutas: kutas, adjustedScore: nil, totalScore: 19).affirmationText()
        XCTAssertTrue(text.contains("19/36"), text)
        XCTAssertTrue(text.contains("minimum threshold"), text)
    }

    func test_nilAdjustedScore_fallsBackToTotalScore() {
        let kutas = [kuta("Nadi", points: 4, max: 8)]
        let text = AffirmationBuilder(kutas: kutas, adjustedScore: nil, totalScore: 21).affirmationText()
        XCTAssertTrue(text.contains("21/36"), text)
    }

    // MARK: - Edge cases

    func test_varnaExcluded_maxOneNotPerfect() {
        // Varna has maxPoints=1 — should never count as a perfect koota
        let kutas = [
            kuta("Varna", points: 1, max: 1),  // max < 3, should be excluded
            kuta("Nadi", points: 4, max: 8),
        ]
        let text = AffirmationBuilder(kutas: kutas, adjustedScore: nil, totalScore: 22).affirmationText()
        XCTAssertFalse(text.contains("Varna scores perfectly"), "Varna should be excluded: \(text)")
        // Falls into 0-perfect path
        XCTAssertTrue(text.contains("22/36"), text)
    }

    func test_prefixMatching_grahaMaitri() {
        // "Graha Maitri" must be matched by key "maitri"
        let kutas = [
            kuta("Graha Maitri", points: 5, max: 5),
            kuta("Nadi", points: 4, max: 8),
        ]
        let text = AffirmationBuilder(kutas: kutas, adjustedScore: nil, totalScore: 26).affirmationText()
        // Should be in 1-perfect path with Graha Maitri as the display name
        XCTAssertTrue(text.contains("Graha Maitri"), "Prefix match should produce display name: \(text)")
        XCTAssertTrue(text.contains("mental friendship"), text)
    }

    func test_perfectWeightOrdering_bhakootBeforeGana() {
        // Bhakoot is heavier than Gana — should appear first
        let kutas = [
            kuta("Gana", points: 6, max: 6),
            kuta("Bhakoot", points: 7, max: 7),
        ]
        let text = AffirmationBuilder(kutas: kutas, adjustedScore: nil, totalScore: 27).affirmationText()
        XCTAssertTrue(text.contains("Bhakoot and Gana"), "Bhakoot should precede Gana: \(text)")
    }
}
