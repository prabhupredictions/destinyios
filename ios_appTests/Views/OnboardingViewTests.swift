import XCTest
@testable import ios_app

final class OnboardingViewTests: XCTestCase {
    
    func testOnboardingSlides_HasFourSlides() {
        // Given/When
        let slides = OnboardingSlide.slides
        
        // Then
        XCTAssertEqual(slides.count, 4)
    }
    
    func testOnboardingSlides_FirstSlideHasStats() {
        // Given
        let firstSlide = OnboardingSlide.slides[0]
        
        // Then
        XCTAssertTrue(firstSlide.showStats)
    }
    
    func testOnboardingSlides_LastSlideIsFeatureSlide() {
        // Given
        let lastSlide = OnboardingSlide.slides[3]
        
        // Then
        XCTAssertTrue(lastSlide.isFeatureSlide)
        XCTAssertEqual(lastSlide.title, "Here's what you can do")
    }
    
    func testOnboardingSlides_AllHaveTitles() {
        // Given
        let slides = OnboardingSlide.slides
        
        // Then
        for slide in slides {
            XCTAssertFalse(slide.title.isEmpty, "Slide should have a title")
        }
    }
    
    func testOnboardingSlides_AllHaveIcons() {
        // Given
        let slides = OnboardingSlide.slides
        
        // Then
        for slide in slides {
            XCTAssertFalse(slide.icon.isEmpty, "Slide should have an icon")
        }
    }
    
    func testOnboardingFeatures_HasFourFeatures() {
        // Given/When
        let features = OnboardingFeature.features
        
        // Then
        XCTAssertEqual(features.count, 4)
    }
    
    func testOnboardingFeatures_AllHaveContent() {
        // Given
        let features = OnboardingFeature.features
        
        // Then
        for feature in features {
            XCTAssertFalse(feature.icon.isEmpty, "Feature should have icon")
            XCTAssertFalse(feature.title.isEmpty, "Feature should have title")
            XCTAssertFalse(feature.description.isEmpty, "Feature should have description")
        }
    }
}
