import SwiftUI

/// Individual onboarding slide with premium visuals
struct OnboardingSlideView: View {
    let slide: OnboardingSlide
    var onGetStarted: () -> Void
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 28) {
                Spacer(minLength: 40)
                
                // Icon section
                iconView
                    .frame(height: 120)
                
                // Title section
                VStack(spacing: 12) {
                    Text(slide.title)
                        .font(AppTheme.Fonts.display(size: 26))
                        .foregroundColor(AppTheme.Colors.textPrimary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                    
                    if let subtitle = slide.subtitle {
                        Text(subtitle)
                            .font(AppTheme.Fonts.title(size: 18))
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
                        .font(AppTheme.Fonts.body(size: 16))
                        .foregroundColor(AppTheme.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(6)
                        .padding(.horizontal, 36)
                }
                
                // Features list (last slide)
                if slide.isFeatureSlide {
                    FeaturesListView()
                        .padding(.top, 8)
                    
                    // Get Started button on features slide
                    Button(action: onGetStarted) {
                        HStack(spacing: 10) {
                            Text("get_started".localized)
                                .font(.system(size: 17, weight: .semibold))
                            Image(systemName: "sparkles")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundColor(Color(hex: "0B0F19")) // Dark text on gold
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(AppTheme.Colors.premiumGradient)
                        .cornerRadius(16)
                        .shadow(color: AppTheme.Colors.gold.opacity(0.3), radius: 10, y: 5)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                }
                
                Spacer(minLength: 20)
            }
        }
    }
    
    // MARK: - Icon View
    // iOS HIG standard: Onboarding icons 80-120pt with consistent visual weight
    private let iconContainerSize: CGFloat = 120
    private let iconSize: CGFloat = 88
    
    @ViewBuilder
    private var iconView: some View {
        if slide.icon == "logo" {
            // Destiny logo - larger for better visibility
            Image("logo")
                .resizable()
                .scaledToFit()
                .frame(width: 110, height: 110)
                .frame(width: iconContainerSize, height: iconContainerSize)
        } else if slide.icon == "chatgpt" {
            // ChatGPT logo - centered in container
            Image("chatgpt_logo")
                .resizable()
                .scaledToFit()
                .frame(width: iconSize, height: iconSize)
                .frame(width: iconContainerSize, height: iconContainerSize)
        } else if slide.icon == "telescope_icon" {
            // Telescope icon - centered in container
            Image("telescope_icon")
                .resizable()
                .scaledToFit()
                .frame(width: iconSize, height: iconSize)
                .frame(width: iconContainerSize, height: iconContainerSize)
        } else {
            // SF Symbol icon with background
            ZStack {
                Circle()
                    .fill(AppTheme.Colors.mainBackground.opacity(0.5)) // Adjusted for visibility
                    .frame(width: 100, height: 100)
                
                Image(systemName: slide.icon)
                    .font(.system(size: 44, weight: .medium))
                    .foregroundStyle(AppTheme.Colors.premiumGradient)
            }
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
                        .font(.system(size: 14))
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
                    ForEach(0..<4, id: \.self) { _ in
                        Image(systemName: "star.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(AppTheme.Colors.premiumGradient)
                            .shadow(color: AppTheme.Colors.gold.opacity(0.5), radius: 2, y: 1)
                    }
                }
                Text("4.0 rating")
                    .font(AppTheme.Fonts.caption(size: 12))
                    .foregroundColor(AppTheme.Colors.textTertiary)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.vertical, 20)
        .background(AppTheme.Colors.cardBackground)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(AppTheme.Colors.gold.opacity(0.15), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.2), radius: 10, y: 4)
    }
}

// MARK: - Features List Component
struct FeaturesListView: View {
    let features = OnboardingFeature.features
    
    var body: some View {
        VStack(spacing: 16) {
            ForEach(features) { feature in
                HStack(spacing: 16) {
                    // Icon container
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(AppTheme.Colors.gold.opacity(0.15))
                            .frame(width: 48, height: 48)
                        
                        Image(systemName: feature.icon)
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(AppTheme.Colors.gold)
                    }
                    
                    // Text content
                    VStack(alignment: .leading, spacing: 4) {
                        Text(feature.title)
                            .font(AppTheme.Fonts.title(size: 15))
                            .foregroundColor(AppTheme.Colors.textPrimary)
                        
                        Text(feature.description)
                            .font(AppTheme.Fonts.body(size: 13))
                            .foregroundColor(AppTheme.Colors.textSecondary)
                            .lineLimit(2)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 24)
            }
        }
    }
}

#Preview("Slide 1") {
    OnboardingSlideView(slide: OnboardingSlide.slides[0], onGetStarted: {})
}

#Preview("Features Slide") {
    OnboardingSlideView(slide: OnboardingSlide.slides[3], onGetStarted: {})
}
