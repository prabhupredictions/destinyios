// KutaTextBuilderTests.swift
import XCTest
@testable import ios_app

final class KutaTextBuilderTests: XCTestCase {

    // MARK: - Helpers

    private func makeKuta(
        key: String,
        score: Double = 6,
        maxScore: Double = 6,
        boyValue: String? = nil,
        girlValue: String? = nil,
        doshaPresent: Bool = false,
        doshaCancelled: Bool = false,
        cancellationReason: String? = nil,
        doshaType: String? = nil,
        plainEnglishSummary: String? = nil,
        taraBoyToGirl: Int? = nil,
        taraGirlToBoy: Int? = nil
    ) -> AshtakootData {
        AshtakootData(
            key: key,
            label: labelFor(key),
            icon: "circle.fill",
            score: score,
            maxScore: maxScore,
            description: "",
            doshaPresent: doshaPresent,
            doshaCancelled: doshaCancelled,
            cancellationReason: cancellationReason,
            cancellationReasons: nil,
            adjustedScore: nil,
            doshaType: doshaType,
            classicalEffect: nil,
            boyConstitution: nil,
            girlConstitution: nil,
            severity: nil,
            housePositions: nil,
            sadbhakootWarning: nil,
            taraBoyToGirl: taraBoyToGirl,
            taraGirlToBoy: taraGirlToBoy,
            boyVashya: nil,
            girlVashya: nil,
            boyToGirlScore: nil,
            girlToBoyScore: nil,
            boyVarna: nil,
            girlVarna: nil,
            complementarityNote: nil,
            boyValue: boyValue,
            girlValue: girlValue,
            plainEnglishSummary: plainEnglishSummary,
            boyValueDescription: nil,
            girlValueDescription: nil
        )
    }

    private func labelFor(_ key: String) -> String {
        ["varna": "Work", "vashya": "Attraction", "tara": "Destiny",
         "yoni": "Intimacy", "maitri": "Friendship", "gana": "Temperament",
         "bhakoot": "Love", "nadi": "Health"][key] ?? key.capitalized
    }

    private func builder(
        key: String,
        score: Double = 6,
        maxScore: Double = 6,
        boyValue: String? = nil,
        girlValue: String? = nil,
        doshaPresent: Bool = false,
        doshaCancelled: Bool = false,
        cancellationReason: String? = nil,
        doshaType: String? = nil,
        plainEnglishSummary: String? = nil,
        taraBoyToGirl: Int? = nil,
        taraGirlToBoy: Int? = nil
    ) -> KutaTextBuilder {
        KutaTextBuilder(
            kuta: makeKuta(
                key: key, score: score, maxScore: maxScore,
                boyValue: boyValue, girlValue: girlValue,
                doshaPresent: doshaPresent, doshaCancelled: doshaCancelled,
                cancellationReason: cancellationReason, doshaType: doshaType,
                plainEnglishSummary: plainEnglishSummary,
                taraBoyToGirl: taraBoyToGirl, taraGirlToBoy: taraGirlToBoy
            ),
            boyName: "Prabhu",
            girlName: "Smita"
        )
    }

    // MARK: - Description: opening sentence always names the Koota correctly

    func test_description_varna_openingMentionsVarnaKoota() {
        let result = builder(key: "varna").descriptionParagraph()
        XCTAssertTrue(result.contains("Work compatibility"), "Should say 'Work compatibility', got: \(result)")
        XCTAssertTrue(result.contains("Varna Koota"), "Should mention 'Varna Koota', got: \(result)")
    }

    func test_description_gana_openingMentionsGanaKoota() {
        let result = builder(key: "gana", score: 1, maxScore: 6).descriptionParagraph()
        XCTAssertTrue(result.contains("Temperament compatibility"), "got: \(result)")
        XCTAssertTrue(result.contains("Gana Koota"), "got: \(result)")
    }

    func test_description_nadi_openingMentionsNadiKoota() {
        let result = builder(key: "nadi", score: 8, maxScore: 8).descriptionParagraph()
        XCTAssertTrue(result.contains("Health compatibility"), "got: \(result)")
        XCTAssertTrue(result.contains("Nadi Koota"), "got: \(result)")
    }

    // MARK: - Description: partner values injected when available

    func test_description_includesPartnerValues() {
        let result = builder(key: "gana", score: 1, maxScore: 6, boyValue: "Manushya", girlValue: "Rakshasa").descriptionParagraph()
        XCTAssertTrue(result.contains("Prabhu is Manushya"), "got: \(result)")
        XCTAssertTrue(result.contains("Smita is Rakshasa"), "got: \(result)")
    }

    func test_description_omitsPartnerValueSentenceWhenNil() {
        let result = builder(key: "gana", score: 6, maxScore: 6, boyValue: nil, girlValue: nil).descriptionParagraph()
        XCTAssertFalse(result.contains("Prabhu is"), "Should not inject nil values, got: \(result)")
    }

    // MARK: - Description: score sentence always present

    func test_description_alwaysContainsScore() {
        for key in ["varna", "vashya", "tara", "yoni", "maitri", "gana", "bhakoot", "nadi"] {
            let result = builder(key: key, score: 3, maxScore: 6).descriptionParagraph()
            XCTAssertTrue(result.contains("3 out of 6"), "Key \(key): should contain score, got: \(result)")
        }
    }

    // MARK: - Description: active dosha appends warning

    func test_description_ganaActiveDoshaAppendsWarning() {
        let result = builder(key: "gana", score: 1, maxScore: 6,
                             boyValue: "Manushya", girlValue: "Rakshasa",
                             doshaPresent: true, doshaCancelled: false).descriptionParagraph()
        XCTAssertTrue(result.contains("⚠ Active Gana Dosha"), "got: \(result)")
        XCTAssertTrue(result.contains("No cancellation was found"), "got: \(result)")
    }

    func test_description_nadiActiveDoshaAppendsWarning() {
        let result = builder(key: "nadi", score: 0, maxScore: 8,
                             doshaPresent: true, doshaCancelled: false).descriptionParagraph()
        XCTAssertTrue(result.contains("⚠ Active Nadi Dosha"), "got: \(result)")
    }

    // MARK: - Description: cancelled dosha mentions cancellation reason

    func test_description_cancelledDoshaMentionsReason() {
        let result = builder(key: "bhakoot", score: 0, maxScore: 7,
                             doshaPresent: true, doshaCancelled: true,
                             cancellationReason: "both share the same Rashi lord").descriptionParagraph()
        XCTAssertTrue(result.contains("both share the same Rashi lord"), "got: \(result)")
        XCTAssertTrue(result.contains("cancelled"), "got: \(result)")
    }

    // MARK: - Description: backend plainEnglishSummary overrides fallback body

    func test_description_backendSummaryOverridesFallback() {
        let backendText = "This is a custom backend explanation."
        let result = builder(key: "varna", score: 1, maxScore: 1,
                             plainEnglishSummary: backendText).descriptionParagraph()
        XCTAssertTrue(result.contains(backendText), "Should use backend text, got: \(result)")
        XCTAssertFalse(result.contains("Compatible Varnas indicate"), "Should not use fallback, got: \(result)")
    }

    // MARK: - Description: Tara includes star counts when available

    func test_description_taraIncludesStarCounts() {
        let result = builder(key: "tara", score: 2, maxScore: 3,
                             taraBoyToGirl: 5, taraGirlToBoy: 4).descriptionParagraph()
        XCTAssertTrue(result.contains("counts 5 positions"), "got: \(result)")
        XCTAssertTrue(result.contains("reverse counts 4"), "got: \(result)")
    }

    func test_description_taraOmitsCountsWhenNil() {
        let result = builder(key: "tara", score: 2, maxScore: 3).descriptionParagraph()
        XCTAssertFalse(result.contains("positions"), "got: \(result)")
    }

    // MARK: - Description: sign abbreviations expanded

    func test_description_expandsSignAbbreviation() {
        let result = builder(key: "bhakoot", score: 0, maxScore: 7,
                             boyValue: "Cp", girlValue: "Aq").descriptionParagraph()
        XCTAssertTrue(result.contains("Capricorn"), "Should expand Cp → Capricorn, got: \(result)")
        XCTAssertTrue(result.contains("Aquarius"), "Should expand Aq → Aquarius, got: \(result)")
    }

    // MARK: - Prompt: contains partner names and Koota name

    func test_prompt_containsPartnerNamesAndKootaName() {
        let result = builder(key: "gana", score: 1, maxScore: 6,
                             boyValue: "Manushya", girlValue: "Rakshasa",
                             doshaPresent: true, doshaCancelled: false).classicalPrompt()
        XCTAssertTrue(result.contains("Prabhu"), "got: \(result)")
        XCTAssertTrue(result.contains("Smita"), "got: \(result)")
        XCTAssertTrue(result.contains("Gana Koota"), "got: \(result)")
    }

    func test_prompt_ganaActiveDoshaAskForRemedies() {
        let result = builder(key: "gana", score: 1, maxScore: 6,
                             doshaPresent: true, doshaCancelled: false).classicalPrompt()
        XCTAssertTrue(result.contains("remedies"), "Active dosha prompt should ask about remedies, got: \(result)")
        XCTAssertTrue(result.contains("active Gana Dosha"), "got: \(result)")
    }

    func test_prompt_cancelledDoshaAskWhichText() {
        let result = builder(key: "nadi", score: 0, maxScore: 8,
                             doshaPresent: true, doshaCancelled: true,
                             cancellationReason: "same Rashi lord").classicalPrompt()
        XCTAssertTrue(result.contains("same Rashi lord"), "Should include cancellation reason, got: \(result)")
        XCTAssertTrue(result.contains("which classical text"), "Cancelled prompt should ask about text source, got: \(result)")
    }

    func test_prompt_noDoshaAsksPracticalMeaning() {
        let result = builder(key: "varna", score: 1, maxScore: 1,
                             boyValue: "Brahmin", girlValue: "Kshatriya").classicalPrompt()
        XCTAssertTrue(result.contains("work") || result.contains("purpose"), "No-dosha prompt should ask practical meaning, got: \(result)")
    }

    func test_prompt_allKootasProduceNonEmptyString() {
        for key in ["varna", "vashya", "tara", "yoni", "maitri", "gana", "bhakoot", "nadi"] {
            let result = builder(key: key).classicalPrompt()
            XCTAssertFalse(result.isEmpty, "Key \(key): prompt should not be empty")
            XCTAssertTrue(result.contains("Can you"), "Key \(key): should end with a question, got: \(result)")
        }
    }
}
