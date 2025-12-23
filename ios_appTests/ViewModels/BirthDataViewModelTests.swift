import XCTest
@testable import ios_app

final class BirthDataViewModelTests: XCTestCase {
    
    var viewModel: BirthDataViewModel!
    
    override func setUp() {
        super.setUp()
        // Clear UserDefaults for clean tests
        UserDefaults.standard.removeObject(forKey: "userBirthData")
        UserDefaults.standard.removeObject(forKey: "hasBirthData")
        UserDefaults.standard.removeObject(forKey: "userGender")
        UserDefaults.standard.removeObject(forKey: "birthTimeUnknown")
        
        viewModel = BirthDataViewModel()
    }
    
    override func tearDown() {
        viewModel = nil
        // Clean up
        UserDefaults.standard.removeObject(forKey: "userBirthData")
        UserDefaults.standard.removeObject(forKey: "hasBirthData")
        UserDefaults.standard.removeObject(forKey: "userGender")
        UserDefaults.standard.removeObject(forKey: "birthTimeUnknown")
        super.tearDown()
    }
    
    // MARK: - Initial State Tests
    
    func testInitialState_IsInvalid() {
        XCTAssertFalse(viewModel.isValid)
        XCTAssertTrue(viewModel.cityOfBirth.isEmpty)
        XCTAssertNil(viewModel.errorMessage)
    }
    
    // MARK: - Validation Tests
    
    func testWithCity_IsValid() {
        // When
        viewModel.cityOfBirth = "Los Angeles"
        
        // Then
        XCTAssertTrue(viewModel.isValid)
    }
    
    func testWithEmptyCity_IsInvalid() {
        // When
        viewModel.cityOfBirth = ""
        
        // Then
        XCTAssertFalse(viewModel.isValid)
    }
    
    func testWithWhitespaceCity_IsInvalid() {
        // When
        viewModel.cityOfBirth = "   "
        
        // Then
        XCTAssertFalse(viewModel.isValid)
    }
    
    // MARK: - BirthData Formatting Tests
    
    func testBirthData_FormatsDateCorrectly() {
        // Given
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        viewModel.dateOfBirth = dateFormatter.date(from: "1996-04-20")!
        viewModel.cityOfBirth = "Los Angeles"
        
        // When
        let birthData = viewModel.birthData
        
        // Then
        XCTAssertEqual(birthData.dob, "1996-04-20")
    }
    
    func testBirthData_FormatsTimeCorrectly() {
        // Given
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        viewModel.timeOfBirth = timeFormatter.date(from: "04:45")!
        viewModel.cityOfBirth = "Los Angeles"
        
        // When
        let birthData = viewModel.birthData
        
        // Then
        XCTAssertEqual(birthData.time, "04:45")
    }
    
    func testBirthData_TimeUnknownUsesNoon() {
        // Given
        viewModel.timeUnknown = true
        viewModel.cityOfBirth = "Los Angeles"
        
        // When
        let birthData = viewModel.birthData
        
        // Then
        XCTAssertEqual(birthData.time, "12:00")
    }
    
    func testBirthData_TrimsCity() {
        // Given
        viewModel.cityOfBirth = "  Los Angeles  "
        
        // When
        let birthData = viewModel.birthData
        
        // Then
        XCTAssertEqual(birthData.cityOfBirth, "Los Angeles")
    }
    
    // MARK: - Save Tests
    
    func testSave_WithValidData_ReturnsTrue() {
        // Given
        viewModel.cityOfBirth = "Los Angeles"
        
        // When
        let result = viewModel.save()
        
        // Then
        XCTAssertTrue(result)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertTrue(UserDefaults.standard.bool(forKey: "hasBirthData"))
    }
    
    func testSave_WithInvalidData_ReturnsFalse() {
        // Given - empty city
        viewModel.cityOfBirth = ""
        
        // When
        let result = viewModel.save()
        
        // Then
        XCTAssertFalse(result)
        XCTAssertNotNil(viewModel.errorMessage)
    }
    
    // MARK: - Formatted String Tests
    
    func testFormattedDate_ReturnsLongFormat() {
        // Given
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        viewModel.dateOfBirth = dateFormatter.date(from: "1996-04-20")!
        
        // When
        let formatted = viewModel.formattedDate
        
        // Then
        XCTAssertTrue(formatted.contains("1996"))
        XCTAssertTrue(formatted.contains("20"))
    }
    
    func testFormattedTime_WhenUnknown_ReturnsUnknown() {
        // Given
        viewModel.timeUnknown = true
        
        // When
        let formatted = viewModel.formattedTime
        
        // Then
        XCTAssertEqual(formatted, "Unknown")
    }
}
