import XCTest
@testable import ios_app

/// Tests for CompatibilityViewModel
@MainActor
final class CompatibilityViewModelTests: XCTestCase {
    
    var viewModel: CompatibilityViewModel!
    
    override func setUp() async throws {
        try await super.setUp()
        viewModel = CompatibilityViewModel()
    }
    
    override func tearDown() async throws {
        viewModel = nil
        try await super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testInit_HasEmptyFields() async throws {
        // Then
        XCTAssertTrue(viewModel.boyName.isEmpty)
        XCTAssertTrue(viewModel.girlName.isEmpty)
        XCTAssertTrue(viewModel.boyCity.isEmpty)
        XCTAssertTrue(viewModel.girlCity.isEmpty)
        XCTAssertFalse(viewModel.isAnalyzing)
        XCTAssertFalse(viewModel.showResult)
        XCTAssertNil(viewModel.result)
    }
    
    // MARK: - Validation Tests
    
    func testIsFormValid_ReturnsFalseWhenEmpty() async throws {
        // Then
        XCTAssertFalse(viewModel.isFormValid)
    }
    
    func testIsFormValid_ReturnsFalseWithPartialData() async throws {
        // Given
        viewModel.boyName = "John"
        viewModel.girlName = "Jane"
        // Missing cities and coordinates
        
        // Then
        XCTAssertFalse(viewModel.isFormValid)
    }
    
    func testIsFormValid_ReturnsTrueWithCompleteData() async throws {
        // Given
        viewModel.boyName = "John"
        viewModel.girlName = "Jane"
        viewModel.boyCity = "Mumbai"
        viewModel.girlCity = "Delhi"
        viewModel.boyLatitude = 19.076
        viewModel.boyLongitude = 72.877
        viewModel.girlLatitude = 28.613
        viewModel.girlLongitude = 77.209
        
        // Then
        XCTAssertTrue(viewModel.isFormValid)
    }
    
    // MARK: - Analysis Tests
    
    func testAnalyzeMatch_SetsErrorWhenFormInvalid() async throws {
        // Given - empty form
        
        // When
        await viewModel.analyzeMatch()
        
        // Then
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertEqual(viewModel.errorMessage, "Please fill in all required fields")
    }
    
    func testAnalyzeMatch_SetsResultWhenFormValid() async throws {
        // Given
        viewModel.boyName = "John"
        viewModel.girlName = "Jane"
        viewModel.boyCity = "Mumbai"
        viewModel.girlCity = "Delhi"
        viewModel.boyLatitude = 19.076
        viewModel.boyLongitude = 72.877
        viewModel.girlLatitude = 28.613
        viewModel.girlLongitude = 77.209
        
        // When
        await viewModel.analyzeMatch()
        
        // Then
        XCTAssertNotNil(viewModel.result)
        XCTAssertTrue(viewModel.showResult)
        XCTAssertNil(viewModel.errorMessage)
    }
    
    func testAnalyzeMatch_ResultHasValidScore() async throws {
        // Given
        viewModel.boyName = "John"
        viewModel.girlName = "Jane"
        viewModel.boyCity = "Mumbai"
        viewModel.girlCity = "Delhi"
        viewModel.boyLatitude = 19.076
        viewModel.boyLongitude = 72.877
        viewModel.girlLatitude = 28.613
        viewModel.girlLongitude = 77.209
        
        // When
        await viewModel.analyzeMatch()
        
        // Then
        guard let result = viewModel.result else {
            XCTFail("Result should not be nil")
            return
        }
        
        XCTAssertGreaterThanOrEqual(result.totalScore, 0)
        XCTAssertLessThanOrEqual(result.totalScore, result.maxScore)
        XCTAssertEqual(result.maxScore, 36)
    }
    
    func testAnalyzeMatch_ResultHasKutas() async throws {
        // Given
        viewModel.boyName = "John"
        viewModel.girlName = "Jane"
        viewModel.boyCity = "Mumbai"
        viewModel.girlCity = "Delhi"
        viewModel.boyLatitude = 19.076
        viewModel.boyLongitude = 72.877
        viewModel.girlLatitude = 28.613
        viewModel.girlLongitude = 77.209
        
        // When
        await viewModel.analyzeMatch()
        
        // Then
        guard let result = viewModel.result else {
            XCTFail("Result should not be nil")
            return
        }
        
        XCTAssertEqual(result.kutas.count, 8) // Ashtakoot has 8 kutas
    }
    
    // MARK: - Reset Tests
    
    func testReset_ClearsAllFields() async throws {
        // Given
        viewModel.boyName = "John"
        viewModel.girlName = "Jane"
        viewModel.boyCity = "Mumbai"
        viewModel.girlCity = "Delhi"
        viewModel.boyLatitude = 19.076
        viewModel.boyLongitude = 72.877
        viewModel.girlLatitude = 28.613
        viewModel.girlLongitude = 77.209
        await viewModel.analyzeMatch()
        
        // When
        viewModel.reset()
        
        // Then
        XCTAssertTrue(viewModel.boyName.isEmpty)
        XCTAssertTrue(viewModel.girlName.isEmpty)
        XCTAssertTrue(viewModel.boyCity.isEmpty)
        XCTAssertTrue(viewModel.girlCity.isEmpty)
        XCTAssertEqual(viewModel.boyLatitude, 0)
        XCTAssertEqual(viewModel.boyLongitude, 0)
        XCTAssertEqual(viewModel.girlLatitude, 0)
        XCTAssertEqual(viewModel.girlLongitude, 0)
        XCTAssertNil(viewModel.result)
        XCTAssertFalse(viewModel.showResult)
        XCTAssertNil(viewModel.errorMessage)
    }
    
    // MARK: - Result Model Tests
    
    func testCompatibilityResult_PercentageCalculation() async throws {
        // Given
        let result = CompatibilityResult(
            totalScore: 27,
            maxScore: 36,
            kutas: [],
            summary: "Test",
            recommendation: "Test"
        )
        
        // Then
        XCTAssertEqual(result.percentage, 0.75, accuracy: 0.01)
    }
    
    func testKutaDetail_PercentageCalculation() async throws {
        // Given
        let kuta = KutaDetail(name: "Nadi", maxPoints: 8, points: 6)
        
        // Then
        XCTAssertEqual(kuta.percentage, 0.75, accuracy: 0.01)
    }
}
