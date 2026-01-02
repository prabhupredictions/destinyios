import Foundation

/// Data model for onboarding carousel slides
struct OnboardingSlide: Identifiable, Sendable {
    let id = UUID()
    let icon: String          // SF Symbol name or "logo" for app logo
    let title: String
    let subtitle: String?
    let description: String
    let showStats: Bool       // Show ratings card on first slide
    let isFeatureSlide: Bool  // Show features list on last slide
    
    /// Pre-defined onboarding slides
    static let slides: [OnboardingSlide] = [
        OnboardingSlide(
            icon: "chatgpt",
            title: "Trusted by 140K+ users",
            subtitle: "on the ChatGPT Store",
            description: "",
            showStats: true,
            isFeatureSlide: false
        ),
        OnboardingSlide(
            icon: "logo",
            title: "Clarity for everyday decisions",
            subtitle: nil,
            description: "Destiny is a personal space to understand patterns in your life. It helps you navigate love, work, and friendships, and think things through in the moment, using astrology as the language to add context.",
            showStats: false,
            isFeatureSlide: false
        ),
        OnboardingSlide(
            icon: "telescope_icon",
            title: "Built for real personalization",
            subtitle: nil,
            description: "With billions of astrological combinations, finding the right insight is like finding one key that fits in a barrel full of keys. Destiny uses a proprietary algorithm, developed over 12+ years and powered by AI, to translate your birth details into clearer, more personal guidance for everyday life.",
            showStats: false,
            isFeatureSlide: false
        ),
        OnboardingSlide(
            icon: "list.bullet.rectangle",
            title: "Here's what you can do",
            subtitle: nil,
            description: "",
            showStats: false,
            isFeatureSlide: true
        )
    ]
}

/// Feature item for the features slide
struct OnboardingFeature: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let description: String
    
    static let features: [OnboardingFeature] = [
        OnboardingFeature(
            icon: "bubble.left.and.bubble.right.fill",
            title: "Ask anything",
            description: "Get real-time astrology insights tailored to your question"
        ),
        OnboardingFeature(
            icon: "checkmark.seal.fill",
            title: "Higher accuracy",
            description: "Get hyper-personalized insights that improve with your feedback"
        ),
        OnboardingFeature(
            icon: "heart.fill",
            title: "Compatibility matching",
            description: "Compare two birth charts (horoscope match) to understand relationship dynamics, and ask anything about the relationship"
        ),
        OnboardingFeature(
            icon: "clock.arrow.circlepath",
            title: "Chat history",
            description: "Revisit past chats anytime and resume where you left off"
        )
    ]
}
