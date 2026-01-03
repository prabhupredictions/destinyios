import SwiftUI

/// Premium onboarding carousel with smooth animations
struct OnboardingView: View {
    // MARK: - Properties
    @State private var currentSlide = 0
    let slides = OnboardingSlide.slides
    var onComplete: () -> Void
    
    // Animation states
    @State private var dragOffset: CGFloat = 0
    
    var body: some View {
        ZStack {
            // Premium gradient background
            AppTheme.Colors.mainBackground.ignoresSafeArea()
            
            // Decorative background elements
            GeometryReader { geo in
                Circle()
                    .fill(AppTheme.Colors.gold.opacity(0.05))
                    .frame(width: 400, height: 400)
                    .offset(x: -100, y: -100)
                    .blur(radius: 60)
                
                Circle()
                    .fill(Color(hex: "4A148C").opacity(0.1)) // Deep purple accent
                    .frame(width: 300, height: 300)
                    .offset(x: geo.size.width - 100, y: geo.size.height - 200)
                    .blur(radius: 50)
            }
            
            VStack(spacing: 0) {
                // Top bar with Skip
                HStack {
                    if currentSlide < slides.count - 1 {
                        Button(action: onComplete) {
                            Text("skip".localized)
                                .font(AppTheme.Fonts.body(size: 16))
                                .foregroundColor(AppTheme.Colors.textSecondary)
                        }
                    }
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .frame(height: 50)
                
                // Content
                TabView(selection: $currentSlide) {
                    ForEach(Array(slides.enumerated()), id: \.element.id) { index, slide in
                        OnboardingSlideView(
                            slide: slide,
                            onGetStarted: onComplete
                        )
                        .tag(index)
                    }
                }
                #if os(iOS)
                .tabViewStyle(.page(indexDisplayMode: .never))
                #endif
                
                // Bottom section
                VStack(spacing: 24) {
                    // Page indicators
                    HStack(spacing: 10) {
                        ForEach(0..<slides.count, id: \.self) { index in
                            Capsule()
                                .fill(index == currentSlide ? AppTheme.Colors.gold : AppTheme.Colors.textTertiary.opacity(0.3))
                                .frame(width: index == currentSlide ? 24 : 8, height: 8)
                                .animation(.spring(response: 0.3), value: currentSlide)
                        }
                    }
                    
                    // Continue button (not on last slide - last slide has "Get Started")
                    if currentSlide < slides.count - 1 {
                        Button(action: {
                            withAnimation(.spring(response: 0.4)) {
                                currentSlide += 1
                            }
                        }) {
                            HStack(spacing: 8) {
                                Text("continue".localized)
                                    .font(.system(size: 17, weight: .semibold))
                                Image(systemName: "arrow.right")
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
                    }
                }
                .padding(.bottom, 40)
            }
        }
    }
}

#Preview {
    OnboardingView(onComplete: {})
}
