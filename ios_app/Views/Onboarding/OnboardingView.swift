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
            LinearGradient(
                colors: [
                    Color(red: 0.96, green: 0.95, blue: 0.98),
                    Color(red: 0.94, green: 0.93, blue: 0.97),
                    Color(red: 0.92, green: 0.91, blue: 0.96)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            // Decorative background elements
            GeometryReader { geo in
                Circle()
                    .fill(Color("NavyPrimary").opacity(0.03))
                    .frame(width: 400, height: 400)
                    .offset(x: -100, y: -100)
                
                Circle()
                    .fill(Color("GoldAccent").opacity(0.05))
                    .frame(width: 300, height: 300)
                    .offset(x: geo.size.width - 100, y: geo.size.height - 200)
            }
            
            VStack(spacing: 0) {
                // Top bar with Skip
                HStack {
                    if currentSlide < slides.count - 1 {
                        Button(action: onComplete) {
                            Text("skip".localized)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(Color("TextDark").opacity(0.6))
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
                                .fill(index == currentSlide ? Color("NavyPrimary") : Color("NavyPrimary").opacity(0.2))
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
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                LinearGradient(
                                    colors: [Color("NavyPrimary"), Color("NavyPrimary").opacity(0.9)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(16)
                            .shadow(color: Color("NavyPrimary").opacity(0.3), radius: 10, y: 5)
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
