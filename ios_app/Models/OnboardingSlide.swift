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
            icon: "sparkles",
            title: "ChatGPT Store's most loved",
            subtitle: "astrology app now on App Store",
            description: "",
            showStats: true,
            isFeatureSlide: false
        ),
        OnboardingSlide(
            icon: "logo",
            title: "What is Destiny AI Astrology?",
            subtitle: nil,
            description: "Destiny is a personal space to understand patterns in your life. It combines astrology with AI to help you reflect, ask better questions, and see situations more clearly.",
            showStats: false,
            isFeatureSlide: false
        ),
        OnboardingSlide(
            icon: "telescope",
            title: "How Destiny delivers personal insights",
            subtitle: nil,
            description: "Astrology is shaped by thousands of interacting variables. Destiny's system analyses these patterns together, instead of isolating traits - allowing it to respond with context, nuance, and timing.",
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
            title: "Ask Me Anything",
            description: "Ask questions about your day and get real-time guidance"
        ),
        OnboardingFeature(
            icon: "heart.fill",
            title: "Compatibility / Match",
            description: "Compare two birth charts for relationship insights"
        ),
        OnboardingFeature(
            icon: "clock.arrow.circlepath",
            title: "Chat History",
            description: "Revisit past insights and track your journey"
        ),
        OnboardingFeature(
            icon: "checkmark.seal.fill",
            title: "Higher Accuracy",
            description: "Context-aware responses personalized to you"
        )
    ]
}
