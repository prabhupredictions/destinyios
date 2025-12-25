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
    
    func testWithCityAndCoords_IsValid() {
        // When - need both city and coordinates
        viewModel.cityOfBirth = "Los Angeles"
        viewModel.latitude = 34.0522
        viewModel.longitude = -118.2437
        
        // Then
        XCTAssertTrue(viewModel.isValid)
    }
    
    func testWithCityButNoCoords_IsInvalid() {
        // When - city without coordinates
        viewModel.cityOfBirth = "Los Angeles"
        viewModel.latitude = 0
        viewModel.longitude = 0
        
        // Then
        XCTAssertFalse(viewModel.isValid)
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
    
    // MARK: - Formatted Date/Time Tests
    
    func testFormattedDOB_FormatsDateCorrectly() {
        // Given
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        viewModel.dateOfBirth = dateFormatter.date(from: "1996-04-20")!
        
        // Then
        XCTAssertEqual(viewModel.formattedDOB, "1996-04-20")
    }
    
    func testFormattedTOB_FormatsTimeCorrectly() {
        // Given
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        viewModel.timeOfBirth = timeFormatter.date(from: "04:45")!
        
        // Then
        XCTAssertEqual(viewModel.formattedTOB, "04:45")
    }
    
    func testFormattedTOB_TimeUnknownUsesNoon() {
        // Given
        viewModel.timeUnknown = true
        
        // Then
        XCTAssertEqual(viewModel.formattedTOB, "12:00")
    }
    
    // MARK: - Save Tests
    
    func testSave_WithValidData_ReturnsTrue() {
        // Given
        viewModel.cityOfBirth = "Los Angeles"
        viewModel.latitude = 34.0522
        viewModel.longitude = -118.2437
        
        // When
        let result = viewModel.save()
        
        // Then
        XCTAssertTrue(result)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertTrue(UserDefaults.standard.bool(forKey: "hasBirthData"))
    }
    
    func testSave_WithoutCity_ReturnsFalse() {
        // Given - empty city
        viewModel.cityOfBirth = ""
        
        // When
        let result = viewModel.save()
        
        // Then
        XCTAssertFalse(result)
        XCTAssertNotNil(viewModel.errorMessage)
    }
    
    func testSave_WithoutCoords_ReturnsFalse() {
        // Given - city without coordinates
        viewModel.cityOfBirth = "Los Angeles"
        viewModel.latitude = 0
        viewModel.longitude = 0
        
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
    
    // MARK: - Location Selection Tests
    
    func testSetLocation_UpdatesAllFields() {
        // When
        viewModel.setLocation(city: "Mumbai", lat: 19.076, lng: 72.877, id: "place123")
        
        // Then
        XCTAssertEqual(viewModel.cityOfBirth, "Mumbai")
        XCTAssertEqual(viewModel.latitude, 19.076, accuracy: 0.001)
        XCTAssertEqual(viewModel.longitude, 72.877, accuracy: 0.001)
        XCTAssertEqual(viewModel.placeId, "place123")
    }
}

