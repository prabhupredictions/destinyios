import SwiftUI

/// Individual onboarding slide with premium visuals
/// Features: FloatingIcon, gold gradient text, premium styling
struct OnboardingSlideView: View {
    let slide: OnboardingSlide
    var onGetStarted: () -> Void
    
    var body: some View {
        if slide.isFeatureSlide {
            // Features slide: No scroll, fills available space
            VStack(spacing: 12) {
                Spacer(minLength: 16)
                
                // Icon - balanced size for features slide
                FloatingIcon {
                    iconContent
                }
                .tilt3D(intensity: 45)
                .frame(height: 100)
                
                // Title
                Text(slide.title)
                    .font(AppTheme.Fonts.premiumDisplay(size: AppTheme.Onboarding.titleSize))
                    .goldGradient()
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                
                // Features list - fills remaining space
                FeaturesListView()
                    .padding(.top, 8)
                
                Spacer(minLength: 8)
            }
            .premiumInertia(intensity: 15)
        } else if slide.showStats {
            // First slide with stats: No scroll, fills available space
            VStack(spacing: 8) {
                Spacer(minLength: 30)
                
                // Icon
                FloatingIcon {
                    iconContent
                }
                .tilt3D(intensity: 45)
                .frame(height: AppTheme.Onboarding.iconContainerSize)
                
                // Title section
                VStack(spacing: AppTheme.Onboarding.titleToSubtitleSpacing) {
                    Text(slide.title)
                        .font(AppTheme.Fonts.premiumDisplay(size: AppTheme.Onboarding.titleSize))
                        .goldGradient()
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                    
                    if let subtitle = slide.subtitle {
                        Text(subtitle)
                            .font(AppTheme.Fonts.title(size: AppTheme.Onboarding.subtitleSize))
                            .foregroundColor(AppTheme.Colors.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.horizontal, 32)
                
                // Stats card
                StatsCard()
                    .padding(.horizontal, 32)
                    .padding(.top, 12)
                
                Spacer(minLength: 16)
            }
            .premiumInertia(intensity: 15)
        } else {
            // Other slides: Scrollable content
            ScrollView(showsIndicators: false) {
                VStack(spacing: 8) {
                    Spacer(minLength: AppTheme.Onboarding.contentTopPadding)
                    
                    // Floating Icon with glow and 3D tilt
                    FloatingIcon {
                        iconContent
                    }
                    .tilt3D(intensity: 45)
                    .frame(height: AppTheme.Onboarding.iconContainerSize)
                    
                    // Title section with gold gradient
                    VStack(spacing: AppTheme.Onboarding.titleToSubtitleSpacing) {
                        Text(slide.title)
                            .font(AppTheme.Fonts.premiumDisplay(size: AppTheme.Onboarding.titleSize))
                            .goldGradient()
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                        
                        if let subtitle = slide.subtitle {
                            Text(subtitle)
                                .font(AppTheme.Fonts.title(size: AppTheme.Onboarding.subtitleSize))
                                .foregroundColor(AppTheme.Colors.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(.horizontal, 32)
                    
                    // Description
                    if !slide.description.isEmpty {
                        Text(slide.description)
                            .font(AppTheme.Fonts.body(size: AppTheme.Onboarding.descriptionSize))
                            .foregroundColor(AppTheme.Colors.textSecondary)
                            .multilineTextAlignment(.center)
                            .lineSpacing(8)
                            .padding(.horizontal, 36)
                            .padding(.top, AppTheme.Onboarding.titleToBodySpacing)
                    }
                    
                    Spacer(minLength: 60)
                }
                .premiumInertia(intensity: 15)
            }
        }
    }
    
    // MARK: - Icon Content
    @ViewBuilder
    private var iconContent: some View {
        if slide.icon == "chatgpt" {
            // ChatGPT logo
            Image("chatgpt_logo")
                .resizable()
                .scaledToFit()
                .frame(width: AppTheme.Onboarding.iconSize, height: AppTheme.Onboarding.iconSize)
        } else if slide.icon == "onboarding_personalization" {
            // Constellation icon - needs larger size due to sparse visual structure
            let scaledSize = AppTheme.Onboarding.iconSize * AppTheme.Onboarding.personalizationIconScale
            Image(slide.icon)
                .resizable()
                .scaledToFit()
                .frame(width: scaledSize, height: scaledSize)
        } else if slide.icon.hasPrefix("onboarding_") {
            // Other onboarding icons
            Image(slide.icon)
                .resizable()
                .scaledToFit()
                .frame(width: AppTheme.Onboarding.iconSize, height: AppTheme.Onboarding.iconSize)
        } else if slide.icon == "logo" {
            // Destiny logo
            Image("logo")
                .resizable()
                .scaledToFit()
                .frame(width: AppTheme.Onboarding.iconSize, height: AppTheme.Onboarding.iconSize)
        } else {
            // SF Symbol icon with gradient
            Image(systemName: slide.icon)
                .font(.system(size: AppTheme.Onboarding.iconSize * 0.5, weight: .light))
                .foregroundStyle(AppTheme.Colors.premiumGradient)
        }
    }
}

// MARK: - Stats Card Component
struct StatsCard: View {
    var body: some View {
        VStack(spacing: 16) {
            // Main stat: 2.2M+ questions
            VStack(spacing: 4) {
                HStack(spacing: 8) {
                    Image(systemName: "bubble.left.and.bubble.right.fill")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(AppTheme.Colors.premiumGradient)
                    
                    Text("2.2M+")
                        .font(AppTheme.Fonts.premiumDisplay(size: 40))
                        .foregroundColor(AppTheme.Colors.textPrimary)
                }
                
                Text("questions_asked".localized)
                    .font(AppTheme.Fonts.body(size: 14))
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
            
            // Divider
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            AppTheme.Colors.gold.opacity(0),
                            AppTheme.Colors.gold.opacity(0.3),
                            AppTheme.Colors.gold.opacity(0)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1)
                .padding(.horizontal, 20)
            
            // Rating section
            HStack(spacing: 12) {
                // Stars
                HStack(spacing: 4) {
                    ForEach(0..<4, id: \.self) { _ in
                        Image(systemName: "star.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(AppTheme.Colors.premiumGradient)
                    }
                    Image(systemName: "star")
                        .font(.system(size: 18))
                        .foregroundStyle(AppTheme.Colors.gold.opacity(0.3))
                }
                
                Text("4/5")
                    .font(AppTheme.Fonts.title(size: 18))
                    .foregroundColor(AppTheme.Colors.textPrimary)
                
                Text("rating")
                    .font(AppTheme.Fonts.body(size: 14))
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
        }
        .padding(.vertical, 24)
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity)
        .background(
            ZStack {
                // Base blur material for glass effect
                RoundedRectangle(cornerRadius: 24)
                    .fill(.ultraThinMaterial)
                    .opacity(0.7)
                
                // Dark tint to match cosmic background
                RoundedRectangle(cornerRadius: 24)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(white: 0.15).opacity(0.9),
                                Color(white: 0.08).opacity(0.9)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                
                // Glossy shine at top edge
                RoundedRectangle(cornerRadius: 24)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.15),
                                Color.white.opacity(0.05),
                                Color.clear
                            ],
                            startPoint: .top,
                            endPoint: .center
                        )
                    )
                
                // Inner glow
                RoundedRectangle(cornerRadius: 24)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.2),
                                Color.white.opacity(0.05),
                                Color.clear
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1.5
                    )
                    .padding(1)
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(
                    LinearGradient(
                        colors: [
                            AppTheme.Colors.gold.opacity(0.5),
                            AppTheme.Colors.gold.opacity(0.2),
                            AppTheme.Colors.gold.opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: Color.black.opacity(0.3), radius: 20, y: 10)
        .shadow(color: AppTheme.Colors.gold.opacity(0.08), radius: 30, y: 5)
    }
}

// MARK: - Features List Component
struct FeaturesListView: View {
    let features = OnboardingFeature.features
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(features) { feature in
                HStack(alignment: .top, spacing: 14) {
                    // Icon with accent background
                    ZStack {
                        Circle()
                            .fill(AppTheme.Colors.gold.opacity(0.15))
                            .frame(width: 32, height: 32)
                        
                        Image(systemName: feature.icon)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(AppTheme.Colors.premiumGradient)
                    }
                    
                    // Full text content
                    VStack(alignment: .leading, spacing: 2) {
                        Text(feature.title)
                            .font(AppTheme.Fonts.title(size: 16))
                            .foregroundColor(AppTheme.Colors.textPrimary)
                        
                        Text(feature.description)
                            .font(AppTheme.Fonts.body(size: 14))
                            .foregroundColor(AppTheme.Colors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    Spacer(minLength: 0)
                }
            }
        }
        .padding(.horizontal, 28)
    }
}

#Preview("Slide 1") {
    ZStack {
        CosmicBackgroundView()
        OnboardingSlideView(slide: OnboardingSlide.slides[0], onGetStarted: {})
    }
}

#Preview("Features Slide") {
    ZStack {
        CosmicBackgroundView()
        OnboardingSlideView(slide: OnboardingSlide.slides[3], onGetStarted: {})
    }
}
