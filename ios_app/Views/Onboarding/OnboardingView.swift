import SwiftUI

/// Premium onboarding carousel with cosmic effects
/// Features: ScrollView with paging, parallax transitions, motion effects
struct OnboardingView: View {
    // MARK: - Properties
    @State private var currentSlideIndex = 0
    @State private var scrolledSlideID: UUID?
    let slides = OnboardingSlide.slides
    var onComplete: () -> Void
    
    var body: some View {
        ZStack {
            // Cosmic background with tilt parallax
            CosmicBackgroundView()
            
            VStack(spacing: 0) {
                // Top bar with Skip
                topBar
                
                // Paging ScrollView with parallax transitions
                slideContent
                
                // Bottom section
                bottomSection
            }
        }
        .onAppear {
            // Initialize with first slide
            scrolledSlideID = slides.first?.id
        }
        .onChange(of: scrolledSlideID) { _, newValue in
            // Update index when user scrolls
            if let newID = newValue,
               let index = slides.firstIndex(where: { $0.id == newID }) {
                currentSlideIndex = index
            }
        }
    }
    
    // MARK: - Top Bar
    private var topBar: some View {
        HStack {
            if currentSlideIndex < slides.count - 1 {
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
    }
    
    // MARK: - Slide Content
    private var slideContent: some View {
        GeometryReader { geo in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 0) {
                    ForEach(slides) { slide in
                        OnboardingSlideView(
                            slide: slide,
                            onGetStarted: onComplete
                        )
                        .frame(width: geo.size.width)
                        .id(slide.id)
                        .scrollTransition(.interactive) { content, phase in
                            content
                                .opacity(phase.isIdentity ? 1 : 0.5)
                                .scaleEffect(phase.isIdentity ? 1 : 0.92)
                                .blur(radius: phase.isIdentity ? 0 : 2)
                        }
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.paging)
            .scrollPosition(id: $scrolledSlideID)
        }
    }
    
    // MARK: - Bottom Section
    private var bottomSection: some View {
        VStack(spacing: 24) {
            // Page indicators
            HStack(spacing: 10) {
                ForEach(0..<slides.count, id: \.self) { index in
                    Capsule()
                        .fill(index == currentSlideIndex ? AppTheme.Colors.gold : AppTheme.Colors.textTertiary.opacity(0.3))
                        .frame(width: index == currentSlideIndex ? 24 : 8, height: 8)
                        .animation(.spring(response: 0.3), value: currentSlideIndex)
                }
            }
            
            // Action button - Continue or Get Started
            if currentSlideIndex < slides.count - 1 {
                // Continue button for slides 1-3
                ShimmerButton(title: "continue".localized, icon: "arrow.right") {
                    goToNextSlide()
                }
                .padding(.horizontal, 24)
            } else {
                // Get Started button on last slide
                ShimmerButton(title: "get_started".localized, icon: "sparkles") {
                    onComplete()
                }
                .padding(.horizontal, 24)
            }
        }
        .padding(.bottom, 40)
    }
    
    // MARK: - Navigation
    private func goToNextSlide() {
        let nextIndex = currentSlideIndex + 1
        guard nextIndex < slides.count else { return }
        
        withAnimation(.spring(response: 0.4)) {
            scrolledSlideID = slides[nextIndex].id
        }
    }
}

#Preview {
    OnboardingView(onComplete: {})
}
