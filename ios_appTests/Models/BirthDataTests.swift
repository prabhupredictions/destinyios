import XCTest
@testable import ios_app

final class BirthDataTests: XCTestCase {
    
    // MARK: - Codable Tests
    
    func testBirthData_Codable_EncodeDecode() throws {
        // Given
        let birthData = MockDataFactory.validBirthData()
        
        // When
        let encoder = JSONEncoder()
        let data = try encoder.encode(birthData)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(BirthData.self, from: data)
        
        // Then
        XCTAssertEqual(decoded.dob, birthData.dob)
        XCTAssertEqual(decoded.time, birthData.time)
        XCTAssertEqual(decoded.latitude, birthData.latitude)
        XCTAssertEqual(decoded.longitude, birthData.longitude)
    }
    
    func testBirthData_CodingKeys_SnakeCase() throws {
        // Given
        let json = """
        {
            "dob": "1994-07-01",
            "time": "00:15",
            "latitude": 18.4386,
            "longitude": 79.1288,
            "city_of_birth": "Karimnagar"
        }
        """.data(using: .utf8)!
        
        // When
        let decoder = JSONDecoder()
        let birthData = try decoder.decode(BirthData.self, from: json)
        
        // Then
        XCTAssertEqual(birthData.cityOfBirth, "Karimnagar")
    }
    
    // MARK: - Validation Tests
    
    func testBirthData_Validation_ValidData() {
        // Given
        let birthData = MockDataFactory.validBirthData()
        
        // When
        let isValid = birthData.isValid()
        
        // Then
        XCTAssertTrue(isValid)
    }
    
    func testBirthData_Validation_InvalidDateFormat() {
        // Given
        var birthData = MockDataFactory.validBirthData()
        birthData.dob = "01-07-1994" // Wrong format
        
        // When
        let isValid = birthData.isValid()
        
        // Then
        XCTAssertFalse(isValid)
    }
    
    func testBirthData_Validation_InvalidLatitude() {
        // Given
        var birthData = MockDataFactory.validBirthData()
        birthData.latitude = 95.0 // > 90
        
        // When
        let isValid = birthData.isValid()
        
        // Then
        XCTAssertFalse(isValid)
    }
    
    func testBirthData_Validation_InvalidLongitude() {
        // Given
        var birthData = MockDataFactory.validBirthData()
        birthData.longitude = -200.0 // < -180
        
        // When
        let isValid = birthData.isValid()
        
        // Then
        XCTAssertFalse(isValid)
    }
}
