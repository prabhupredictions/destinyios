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
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(Color("NavyPrimary"))
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                    
                    if let subtitle = slide.subtitle {
                        Text(subtitle)
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(Color("TextDark").opacity(0.7))
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
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(Color("TextDark").opacity(0.7))
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
                            Text("Get Started")
                                .font(.system(size: 17, weight: .semibold))
                            Image(systemName: "sparkles")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            LinearGradient(
                                colors: [Color("NavyPrimary"), Color("NavyPrimary").opacity(0.85)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(16)
                        .shadow(color: Color("NavyPrimary").opacity(0.3), radius: 10, y: 5)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                }
                
                Spacer(minLength: 20)
            }
        }
    }
    
    // MARK: - Icon View
    @ViewBuilder
    private var iconView: some View {
        if slide.icon == "logo" {
            // App logo
            ZStack {
                Circle()
                    .fill(Color("GoldAccent").opacity(0.15))
                    .frame(width: 100, height: 100)
                
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color("GoldAccent"), Color("GoldAccent").opacity(0.85)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                    .shadow(color: Color("GoldAccent").opacity(0.3), radius: 10)
                
                Text("D")
                    .font(.system(size: 36, weight: .light, design: .serif))
                    .foregroundColor(Color("NavyPrimary"))
            }
        } else {
            // SF Symbol icon with background
            ZStack {
                Circle()
                    .fill(Color("NavyPrimary").opacity(0.08))
                    .frame(width: 100, height: 100)
                
                Image(systemName: slide.icon)
                    .font(.system(size: 44, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color("GoldAccent"), Color("GoldAccent").opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
        }
    }
}

// MARK: - Stats Card Component
struct StatsCard: View {
    var body: some View {
        HStack(spacing: 0) {
            // Conversations stat
            VStack(spacing: 6) {
                HStack(spacing: 4) {
                    Image(systemName: "bubble.left.and.bubble.right.fill")
                        .font(.system(size: 14))
                        .foregroundColor(Color("GoldAccent"))
                    Text("300K+")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(Color("NavyPrimary"))
                }
                Text("conversations")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color("TextDark").opacity(0.5))
            }
            .frame(maxWidth: .infinity)
            
            // Divider
            Rectangle()
                .fill(Color("NavyPrimary").opacity(0.1))
                .frame(width: 1, height: 50)
            
            // Rating stat
            VStack(spacing: 6) {
                HStack(spacing: 3) {
                    ForEach(0..<4, id: \.self) { _ in
                        Image(systemName: "star.fill")
                            .font(.system(size: 14))
                            .foregroundColor(Color("GoldAccent"))
                    }
                    Image(systemName: "star.leadinghalf.filled")
                        .font(.system(size: 14))
                        .foregroundColor(Color("GoldAccent"))
                }
                Text("4.5 rating")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color("TextDark").opacity(0.5))
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.06), radius: 15, y: 5)
        )
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
                            .fill(Color("NavyPrimary").opacity(0.08))
                            .frame(width: 48, height: 48)
                        
                        Image(systemName: feature.icon)
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(Color("NavyPrimary"))
                    }
                    
                    // Text content
                    VStack(alignment: .leading, spacing: 4) {
                        Text(feature.title)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(Color("NavyPrimary"))
                        
                        Text(feature.description)
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(Color("TextDark").opacity(0.6))
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
