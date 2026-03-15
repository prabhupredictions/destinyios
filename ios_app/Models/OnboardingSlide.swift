import Foundation

/// Data model for onboarding carousel slides
struct OnboardingSlide: Identifiable, Sendable {
    let id = UUID()
    let icon: String          // SF Symbol name or "logo" for app logo
    let titleKey: String      // Localization key for title
    let subtitleKey: String?  // Localization key for subtitle
    let descriptionKey: String // Localization key for description
    let showStats: Bool       // Show ratings card on first slide
    let isFeatureSlide: Bool  // Show features list on last slide
    
    /// Computed property to get localized title
    var title: String {
        titleKey.localized
    }
    
    /// Computed property to get localized subtitle
    var subtitle: String? {
        subtitleKey?.localized
    }
    
    /// Computed property to get localized description
    var description: String {
        descriptionKey.localized
    }
    
    /// Pre-defined onboarding slides
    static let slides: [OnboardingSlide] = [
        OnboardingSlide(
            icon: "chatgpt",
            titleKey: "onboarding_slide1_title",
            subtitleKey: "onboarding_slide1_subtitle",
            descriptionKey: "",
            showStats: true,
            isFeatureSlide: false
        ),
        OnboardingSlide(
            icon: "onboarding_clarity",
            titleKey: "onboarding_slide2_title",
            subtitleKey: nil,
            descriptionKey: "onboarding_slide2_description",
            showStats: false,
            isFeatureSlide: false
        ),
        OnboardingSlide(
            icon: "onboarding_personalization",
            titleKey: "onboarding_slide3_title",
            subtitleKey: nil,
            descriptionKey: "onboarding_slide3_description",
            showStats: false,
            isFeatureSlide: false
        ),
        OnboardingSlide(
            icon: "onboarding_features",
            titleKey: "onboarding_slide4_title",
            subtitleKey: nil,
            descriptionKey: "",
            showStats: false,
            isFeatureSlide: true
        )
    ]
}

/// Feature item for the features slide
struct OnboardingFeature: Identifiable {
    let id = UUID()
    let icon: String
    let titleKey: String      // Localization key for title
    let descriptionKey: String  // Localization key for description
    
    /// Computed property to get localized title
    var title: String {
        titleKey.localized
    }
    
    /// Computed property to get localized description
    var description: String {
        descriptionKey.localized
    }
    
    static let features: [OnboardingFeature] = [
        OnboardingFeature(
            icon: "bubble.left.and.bubble.right.fill",
            titleKey: "onboarding_feature1_title",
            descriptionKey: "onboarding_feature1_desc"
        ),
        OnboardingFeature(
            icon: "checkmark.seal.fill",
            titleKey: "onboarding_feature2_title",
            descriptionKey: "onboarding_feature2_desc"
        ),
        OnboardingFeature(
            icon: "heart.fill",
            titleKey: "onboarding_feature3_title",
            descriptionKey: "onboarding_feature3_desc"
        ),
        OnboardingFeature(
            icon: "clock.arrow.circlepath",
            titleKey: "onboarding_feature4_title",
            descriptionKey: "onboarding_feature4_desc"
        ),
        OnboardingFeature(
            icon: "bell.fill",
            titleKey: "onboarding_feature5_title",
            descriptionKey: "onboarding_feature5_desc"
        )
    ]
}
