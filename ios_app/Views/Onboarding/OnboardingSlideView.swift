import SwiftUI

/// Individual onboarding slide with premium visuals
/// Features: FloatingIcon, gold gradient text, premium styling
struct OnboardingSlideView: View {
    let slide: OnboardingSlide
    var onGetStarted: () -> Void
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: AppTheme.Onboarding.iconToTitleSpacing) {
                Spacer(minLength: AppTheme.Onboarding.contentTopPadding)
                
                // Floating Icon with glow and 3D tilt
                FloatingIcon {
                    iconContent
                }
                .tilt3D(intensity: 45) // Increased intensity for stronger 3D effect
                .frame(height: AppTheme.Onboarding.iconContainerSize)
                
                // Title section with gold gradient
                VStack(spacing: AppTheme.Onboarding.titleToDescriptionSpacing) {
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
                
                // Stats card (first slide)
                if slide.showStats {
                    StatsCard()
                        .padding(.horizontal, 40)
                        .padding(.top, 8)
                }
                
                // Description
                if !slide.description.isEmpty {
                    Text(slide.description)
                        .font(AppTheme.Fonts.body(size: AppTheme.Onboarding.descriptionSize))
                        .foregroundColor(AppTheme.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(6)
                        .padding(.horizontal, 36)
                }
                
                // Features list (last slide)
                if slide.isFeatureSlide {
                    FeaturesListView()
                        .padding(.top, 8)
                        .padding(.bottom, 20)
                }
                
                Spacer(minLength: 160) // Increased bottom space for feature slide truncation fix
            }
            .premiumInertia(intensity: 15) // Heavy, substantial feel when tilting
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
                .frame(width: AppTheme.Onboarding.iconSize * 0.85, height: AppTheme.Onboarding.iconSize * 0.85)
        } else if slide.icon.hasPrefix("onboarding_") {
            // Custom onboarding icons from assets
            // Personalization icon needs to be larger
            let pScale: CGFloat = slide.icon.contains("personalization") ? 1.15 : 1.0
            
            Image(slide.icon)
                .resizable()
                .scaledToFit()
                .frame(width: AppTheme.Onboarding.iconSize * pScale, height: AppTheme.Onboarding.iconSize * pScale)
        } else if slide.icon == "logo" {
            // Destiny logo
            Image("logo")
                .resizable()
                .scaledToFit()
                .frame(width: AppTheme.Onboarding.iconSize + 10, height: AppTheme.Onboarding.iconSize + 10)
        } else {
            // SF Symbol icon with gradient
            Image(systemName: slide.icon)
                .font(.system(size: 50, weight: .light))
                .foregroundStyle(AppTheme.Colors.premiumGradient)
        }
    }
}

// MARK: - Stats Card Component
struct StatsCard: View {
    var body: some View {
        HStack(spacing: 0) {
            // Questions stat
            VStack(spacing: 6) {
                HStack(spacing: 4) {
                    Image(systemName: "bubble.left.and.bubble.right.fill")
                        .font(AppTheme.Fonts.body(size: 14))
                        .foregroundStyle(AppTheme.Colors.premiumGradient)
                        .shadow(color: AppTheme.Colors.gold.opacity(0.5), radius: 2, y: 1)
                    Text("2.2M+")
                        .font(AppTheme.Fonts.title(size: 22))
                        .foregroundColor(AppTheme.Colors.textPrimary)
                }
                Text("questions_asked".localized)
                    .font(AppTheme.Fonts.caption(size: 12))
                    .foregroundColor(AppTheme.Colors.textTertiary)
            }
            .frame(maxWidth: .infinity)
            
            // Divider
            Rectangle()
                .fill(AppTheme.Colors.separator)
                .frame(width: 1, height: 50)
            
            // Rating stat
            VStack(spacing: 6) {
                HStack(spacing: 3) {
                    // 4 filled stars
                    ForEach(0..<4, id: \.self) { _ in
                        Image(systemName: "star.fill")
                            .font(AppTheme.Fonts.body(size: 14))
                            .foregroundStyle(AppTheme.Colors.premiumGradient)
                            .shadow(color: AppTheme.Colors.gold.opacity(0.5), radius: 2, y: 1)
                    }
                    // 1 empty star
                    Image(systemName: "star")
                        .font(AppTheme.Fonts.body(size: 14))
                        .foregroundStyle(AppTheme.Colors.gold.opacity(0.4))
                }
                Text("4/5 rating")
                    .font(AppTheme.Fonts.caption(size: 12))
                    .foregroundColor(AppTheme.Colors.textTertiary)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppTheme.Colors.cardBackground.opacity(0.8))
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial.opacity(0.3))
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(AppTheme.Colors.gold.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: AppTheme.Colors.gold.opacity(0.1), radius: 15, y: 5)
    }
}

// MARK: - Features List Component
struct FeaturesListView: View {
    let features = OnboardingFeature.features
    
    var body: some View {
        VStack(spacing: 12) {
            ForEach(features) { feature in
                HStack(spacing: 16) {
                    // Icon container
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(AppTheme.Colors.gold.opacity(0.1))
                            .frame(width: 40, height: 40)
                        
                        Image(systemName: feature.icon)
                            .font(AppTheme.Fonts.title(size: 16))
                            .foregroundStyle(AppTheme.Colors.premiumGradient)
                    }
                    
                    // Text content
                    VStack(alignment: .leading, spacing: 4) {
                        Text(feature.title)
                            .font(AppTheme.Fonts.title(size: 15))
                            .foregroundColor(AppTheme.Colors.textPrimary)
                        
                        Text(feature.description)
                            .font(AppTheme.Fonts.caption(size: 13))
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                    
                    Spacer()
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(AppTheme.Colors.cardBackground.opacity(0.3))
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(.ultraThinMaterial.opacity(0.2))
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    AppTheme.Colors.gold.opacity(0.3),
                                    AppTheme.Colors.gold.opacity(0.05)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .padding(.horizontal, 24)
            }
        }
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
