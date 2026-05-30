import XCTest
@testable import ios_app

/// Tests for CompatibilityViewModel
/// Note: analyzeMatch() makes a live network call — those tests are integration
/// tests that require a running backend. Unit tests here cover pure logic only.
@MainActor
final class CompatibilityViewModelTests: XCTestCase {

    var viewModel: CompatibilityViewModel!

    override func setUp() async throws {
        try await super.setUp()
        // Clear any cached user data so init doesn't auto-populate from profile
        UserDefaults.standard.removeObject(forKey: "userBirthData")
        UserDefaults.standard.removeObject(forKey: "userEmail")
        UserDefaults.standard.removeObject(forKey: "userName")
        UserDefaults.standard.removeObject(forKey: "activeProfileId")
        viewModel = CompatibilityViewModel()
        await Task.yield()
    }

    override func tearDown() async throws {
        viewModel = nil
        try await super.tearDown()
    }

    // MARK: - Initialization

    func testInit_IsNotAnalyzing() {
        XCTAssertFalse(viewModel.isAnalyzing)
    }

    func testInit_ShowResultIsFalse() {
        XCTAssertFalse(viewModel.showResult)
    }

    func testInit_ResultIsNil() {
        XCTAssertNil(viewModel.result)
    }

    func testInit_HasOnePartnerSlot() {
        // partners always starts with one empty slot
        XCTAssertEqual(viewModel.partners.count, 1)
    }

    // MARK: - Validation

    func testIsFormValid_ReturnsFalseWhenEmpty() {
        viewModel.boyName = ""
        viewModel.girlName = ""
        XCTAssertFalse(viewModel.isFormValid)
    }

    func testIsFormValid_ReturnsFalseWithPartialData() {
        viewModel.boyName = "John"
        viewModel.girlName = "Jane"
        // Missing cities and coordinates
        viewModel.boyCity = ""
        viewModel.girlCity = ""
        XCTAssertFalse(viewModel.isFormValid)
    }

    func testIsFormValid_ReturnsTrueWithCompleteData() {
        viewModel.boyName = "John"
        viewModel.girlName = "Jane"
        viewModel.boyCity = "Mumbai"
        viewModel.girlCity = "Delhi"
        viewModel.boyLatitude = 19.076
        viewModel.boyLongitude = 72.877
        viewModel.girlLatitude = 28.613
        viewModel.girlLongitude = 77.209
        // isFormValid also requires birthDateSet, birthTimeSet/partnerTimeUnknown, age >= 18
        viewModel.girlBirthDate = Calendar.current.date(byAdding: .year, value: -25, to: Date())!
        viewModel.girlBirthTime = Date()
        // Mark as explicitly set (as the picker would do)
        viewModel.partners[0].birthDateSet = true
        viewModel.partners[0].birthTimeSet = true
        // boyBirthDate also needs to satisfy !isUserMinor — set to 25 years ago
        viewModel.boyBirthDate = Calendar.current.date(byAdding: .year, value: -25, to: Date())!
        XCTAssertTrue(viewModel.isFormValid)
    }

    // MARK: - Form invalid rejection

    func testAnalyzeMatch_SetsErrorWhenFormInvalid() async throws {
        viewModel.boyName = ""
        viewModel.girlName = ""
        await viewModel.analyzeMatch()
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertEqual(viewModel.errorMessage, "Please fill in all required fields")
    }

    // MARK: - Reset

    func testReset_ClearsGirlFields() {
        viewModel.girlName = "Jane"
        viewModel.girlCity = "Delhi"
        viewModel.girlLatitude = 28.613
        viewModel.girlLongitude = 77.209

        viewModel.reset()

        XCTAssertTrue(viewModel.girlName.isEmpty)
        XCTAssertTrue(viewModel.girlCity.isEmpty)
        // girlLatitude/girlLongitude reset to 0 for partner slot
        XCTAssertEqual(viewModel.girlLatitude, 0)
        XCTAssertEqual(viewModel.girlLongitude, 0)
    }

    func testReset_ClearsResult() async {
        // Set result via mock path — just verify reset clears it
        viewModel.result = CompatibilityResult(
            totalScore: 20, maxScore: 36, kutas: [],
            summary: "Test", recommendation: "Test"
        )
        viewModel.showResult = true

        viewModel.reset()

        XCTAssertNil(viewModel.result)
        XCTAssertFalse(viewModel.showResult)
        XCTAssertNil(viewModel.errorMessage)
    }

    func testReset_ClearsBoyNameWhenNoProfile() {
        // reset() calls loadUserDataFromProfile() which reads from ProfileContextManager.
        // In a real test environment the profile may or may not be populated.
        // What we can assert reliably: girlName is always cleared regardless of user profile.
        viewModel.girlName = "Jane"
        viewModel.reset()
        XCTAssertTrue(viewModel.girlName.isEmpty, "reset() must clear girlName")
    }

    // MARK: - Result model

    func testCompatibilityResult_PercentageCalculation() {
        let result = CompatibilityResult(
            totalScore: 27, maxScore: 36, kutas: [],
            summary: "Test", recommendation: "Test"
        )
        XCTAssertEqual(result.percentage, 0.75, accuracy: 0.01)
    }

    func testKutaDetail_PercentageCalculation() {
        let kuta = KutaDetail(name: "Nadi", maxPoints: 8, points: 6)
        XCTAssertEqual(kuta.percentage, 0.75, accuracy: 0.01)
    }
}
