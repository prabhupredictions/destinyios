import XCTest
@testable import ios_app

final class EmailGeneratorTests: XCTestCase {
    
    // MARK: - Format Tests
    
    func testGenerateFromComponents_BasicCase() {
        let email = EmailGenerator.generateFromComponents(
            dateOfBirth: "1990-07-15",
            timeOfBirth: "14:30",
            cityOfBirth: "Karimnagar",
            latitude: 17.385,
            longitude: 78.4867
        )
        
        XCTAssertEqual(email, "19900715_1430_Kar_17_78@daa.com")
    }
    
    func testGenerateFromComponents_RemovesSeparators() {
        let email = EmailGenerator.generateFromComponents(
            dateOfBirth: "2000-12-25",
            timeOfBirth: "08:45",
            cityOfBirth: "Delhi",
            latitude: 28.6139,
            longitude: 77.209
        )
        
        // Date separators removed: 2000-12-25 -> 20001225
        // Time separators removed: 08:45 -> 0845
        XCTAssertTrue(email.hasPrefix("20001225_0845_"))
    }
    
    func testGenerateFromComponents_CityPrefix3Letters() {
        let email = EmailGenerator.generateFromComponents(
            dateOfBirth: "1985-03-10",
            timeOfBirth: "10:00",
            cityOfBirth: "Hyderabad",
            latitude: 17.385,
            longitude: 78.4867
        )
        
        // City prefix should be first 3 letters
        XCTAssertTrue(email.contains("_Hyd_"))
    }
    
    func testGenerateFromComponents_ShortCityName() {
        let email = EmailGenerator.generateFromComponents(
            dateOfBirth: "1995-06-20",
            timeOfBirth: "12:00",
            cityOfBirth: "Goa",
            latitude: 15.2993,
            longitude: 74.124
        )
        
        // Short city name should use full name
        XCTAssertTrue(email.contains("_Goa_"))
    }
    
    func testGenerateFromComponents_EmptyCity() {
        let email = EmailGenerator.generateFromComponents(
            dateOfBirth: "1980-01-01",
            timeOfBirth: "00:00",
            cityOfBirth: "",
            latitude: 0,
            longitude: 0
        )
        
        // Empty city should use "Unk"
        XCTAssertTrue(email.contains("_Unk_"))
    }
    
    func testGenerateFromComponents_NegativeCoordinates() {
        let email = EmailGenerator.generateFromComponents(
            dateOfBirth: "1992-08-15",
            timeOfBirth: "16:30",
            cityOfBirth: "Sydney",
            latitude: -33.8688,
            longitude: 151.2093
        )
        
        // Negative lat should be converted to positive integer
        XCTAssertTrue(email.contains("_33_151@"))
    }
    
    func testGenerateFromComponents_Domain() {
        let email = EmailGenerator.generateFromComponents(
            dateOfBirth: "1990-01-01",
            timeOfBirth: "12:00",
            cityOfBirth: "Test",
            latitude: 0,
            longitude: 0
        )
        
        // Should use @daa.com domain
        XCTAssertTrue(email.hasSuffix("@daa.com"))
    }
    
    // MARK: - Validation Tests
    
    func testIsGeneratedEmail_GeneratedEmail() {
        let email = "19900715_1430_Kar_17_78@daa.com"
        XCTAssertTrue(EmailGenerator.isGeneratedEmail(email))
    }
    
    func testIsGeneratedEmail_RegularEmail() {
        let email = "user@gmail.com"
        XCTAssertFalse(EmailGenerator.isGeneratedEmail(email))
    }
    
    func testIsGeneratedEmail_OtherDomain() {
        let email = "test@das.com"
        XCTAssertFalse(EmailGenerator.isGeneratedEmail(email))
    }
}
