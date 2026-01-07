import SwiftUI

/// Premium language selection screen shown on first launch
/// Features: Glassmorphism cards, staggered animations, particle effects
struct LanguageSelectionView: View {
    @Binding var isCompleted: Bool
    
    // UserDefaults to save selection
    @AppStorage("appLanguage") private var appLanguage = "English"
    @AppStorage("appLanguageCode") private var appLanguageCode = "en"
    
    @State private var selectedCode: String?
    @State private var animateContent = false
    @State private var showParticles = false
    @State private var iconRotation: Double = 0
    
    // Supported languages
    private let languages: [LanguageOption] = [
        LanguageOption(code: "en", name: "English", nativeName: "English", symbol: "A"),
        LanguageOption(code: "hi", name: "Hindi", nativeName: "हिन्दी", symbol: "अ"),
        LanguageOption(code: "ta", name: "Tamil", nativeName: "தமிழ்", symbol: "அ"),
        LanguageOption(code: "te", name: "Telugu", nativeName: "తెలుగు", symbol: "అ"),
        LanguageOption(code: "kn", name: "Kannada", nativeName: "ಕನ್ನಡ", symbol: "ಅ"),
        LanguageOption(code: "ml", name: "Malayalam", nativeName: "മലയാളം", symbol: "അ"),
        LanguageOption(code: "es", name: "Spanish", nativeName: "Español", symbol: "Ñ"),
        LanguageOption(code: "pt", name: "Portuguese", nativeName: "Português", symbol: "Ç"),
        LanguageOption(code: "de", name: "German", nativeName: "Deutsch", symbol: "Ö"),
        LanguageOption(code: "fr", name: "French", nativeName: "Français", symbol: "É"),
        LanguageOption(code: "zh-Hans", name: "Chinese", nativeName: "中文", symbol: "中"),
        LanguageOption(code: "ja", name: "Japanese", nativeName: "日本語", symbol: "あ"),
        LanguageOption(code: "ru", name: "Russian", nativeName: "Русский", symbol: "Я")
    ]
    
    private let columns = [
        GridItem(.flexible(), spacing: AppTheme.LanguageSelection.cardSpacing),
        GridItem(.flexible(), spacing: AppTheme.LanguageSelection.cardSpacing),
        GridItem(.flexible(), spacing: AppTheme.LanguageSelection.cardSpacing)
    ]
    
    var body: some View {
        ZStack {
            // Premium cosmic background (same as Onboarding)
            CosmicBackgroundView()
            
            // Main content
            VStack(spacing: 0) {
                // Header with animated celestial icon
                headerSection
                
                // Language Grid
                languageGrid
                
                Spacer(minLength: 8)
                
                // Continue Button (always visible)
                continueButton
            }
            
            // Particle overlay
            if showParticles {
                ParticleBurstView()
                    .allowsHitTesting(false)
            }
        }
        .onAppear {
            startAnimations()
        }
    }
    
    // MARK: - Header
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Animated Celestial Icon
            ZStack {
                // Outer glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [AppTheme.Colors.gold.opacity(0.3), Color.clear],
                            center: .center,
                            startRadius: 10,
                            endRadius: AppTheme.LanguageSelection.iconGlowRadius
                        )
                    )
                    .frame(width: 80, height: 80)
                
                // Rotating orbit ring
                Circle()
                    .stroke(AppTheme.Colors.gold.opacity(0.2), lineWidth: 1)
                    .frame(width: 70, height: 70)
                    .rotationEffect(.degrees(iconRotation))
                
                // Small orbiting dot
                Circle()
                    .fill(AppTheme.Colors.goldLight)
                    .frame(width: 6, height: 6)
                    .offset(x: 35)
                    .rotationEffect(.degrees(iconRotation))
                
                // Main icon
                Image(systemName: "globe.asia.australia.fill")
                    .font(.system(size: AppTheme.LanguageSelection.iconSize, weight: .light))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [AppTheme.Colors.goldLight, AppTheme.Colors.gold],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }
            .padding(.bottom, 8)
            
            Text("Destiny AI Astrology")
                .font(AppTheme.Fonts.display(size: 26))
                .goldGradient()
            
            Text("Your cosmic journey begins in your language")
                .font(AppTheme.Fonts.body(size: 15))
                .foregroundColor(AppTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .padding(.top, 30)
        .padding(.bottom, 16)
        .opacity(animateContent ? 1 : 0)
        .offset(y: animateContent ? 0 : 20)
    }
    
    private var languageGrid: some View {
        LazyVGrid(columns: columns, spacing: AppTheme.LanguageSelection.cardSpacing) {
            ForEach(Array(languages.enumerated()), id: \.element.id) { index, language in
                PremiumLanguageCard(
                    language: language,
                    isSelected: selectedCode == language.code
                ) {
                    selectLanguage(language)
                }
                .opacity(animateContent ? 1 : 0)
                .offset(y: animateContent ? 0 : 30)
                .animation(
                    .easeOut(duration: AppTheme.LanguageSelection.entranceDuration)
                    .delay(Double(index) * AppTheme.LanguageSelection.staggerDelay),
                    value: animateContent
                )
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
    }
    
    // MARK: - Continue Button
    @ViewBuilder
    private var continueButton: some View {
        let isEnabled = selectedCode != nil
        
        Button(action: confirmSelection) {
            HStack(spacing: 10) {
                Text(continueButtonText)
                    .font(AppTheme.Fonts.title(size: 17))
                
                if isEnabled {
                    Image(systemName: "arrow.right")
                        .font(.system(size: 14, weight: .semibold))
                }
            }
            .foregroundColor(isEnabled ? AppTheme.Colors.textOnGold : AppTheme.Colors.textSecondary)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(
                ZStack {
                    if isEnabled {
                        AppTheme.Colors.premiumCardGradient
                        
                        // Top highlight
                        VStack {
                            Rectangle()
                                .fill(Color.white.opacity(0.25))
                                .frame(height: 1)
                            Spacer()
                        }
                    } else {
                        // Disabled state - muted background
                        RoundedRectangle(cornerRadius: 14)
                            .fill(AppTheme.Colors.cardBackground)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(AppTheme.Colors.separator, lineWidth: 1)
                            )
                    }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(color: isEnabled ? AppTheme.Colors.gold.opacity(0.35) : Color.clear, radius: 12, y: 5)
        }
        .disabled(!isEnabled)
        .padding(.horizontal, 32)
        .padding(.bottom, 30)
        .animation(.easeInOut(duration: 0.25), value: isEnabled)
    }
    
    // MARK: - Helpers
    private var continueButtonText: String {
        guard let code = selectedCode else { return "Select a language" }
        switch code {
        case "hi": return "जारी रखें"
        case "es": return "Continuar"
        case "fr": return "Continuer"
        case "de": return "Weiter"
        case "pt": return "Continuar"
        case "ja": return "続ける"
        case "ru": return "Продолжить"
        case "zh-Hans": return "继续"
        default: return "Continue in \(languages.first(where: { $0.code == code })?.name ?? "English")"
        }
    }
    
    private func startAnimations() {
        // Entrance animation
        withAnimation(.easeOut(duration: 0.7).delay(0.15)) {
            animateContent = true
        }
        
        // Continuous icon rotation
        withAnimation(.linear(duration: AppTheme.LanguageSelection.iconRotationDuration).repeatForever(autoreverses: false)) {
            iconRotation = 360
        }
    }
    
    private func selectLanguage(_ language: LanguageOption) {
        withAnimation(AppTheme.LanguageSelection.selectionSpring) {
            selectedCode = language.code
        }
        
        // Trigger particle burst
        showParticles = true
        DispatchQueue.main.asyncAfter(deadline: .now() + AppTheme.LanguageSelection.particleDuration) {
            showParticles = false
        }
        
        appLanguageCode = language.code
        appLanguage = language.name
        
        // Haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
    }
    
    private func confirmSelection() {
        guard let code = selectedCode else { return }
        
        UserDefaults.standard.set([code], forKey: "AppleLanguages")
        UserDefaults.standard.synchronize()
        
        // Success haptic
        let notification = UINotificationFeedbackGenerator()
        notification.notificationOccurred(.success)
        
        withAnimation(.easeInOut(duration: 0.5)) {
            isCompleted = true
        }
    }
}

// MARK: - Language Option Model
struct LanguageOption: Identifiable {
    let id = UUID()
    let code: String
    let name: String
    let nativeName: String
    let symbol: String
}

// MARK: - Premium Language Card
struct PremiumLanguageCard: View {
    let language: LanguageOption
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                // Glassmorphism background
                RoundedRectangle(cornerRadius: AppTheme.LanguageSelection.cardCornerRadius)
                    .fill(.ultraThinMaterial.opacity(AppTheme.LanguageSelection.glassOpacity))
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.LanguageSelection.cardCornerRadius)
                            .fill(
                                isSelected
                                    ? AppTheme.Colors.gold.opacity(AppTheme.LanguageSelection.selectedBackgroundOpacity)
                                    : AppTheme.Colors.cardBackground.opacity(0.6)
                            )
                    )
                
                // Inner gradient (depth effect)
                RoundedRectangle(cornerRadius: AppTheme.LanguageSelection.cardCornerRadius)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(isSelected ? 0.12 : 0.06),
                                Color.clear
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                
                // Selection glow
                if isSelected {
                    RoundedRectangle(cornerRadius: AppTheme.LanguageSelection.cardCornerRadius)
                        .fill(
                            RadialGradient(
                                colors: [AppTheme.Colors.gold.opacity(0.2), Color.clear],
                                center: .center,
                                startRadius: 10,
                                endRadius: 60
                            )
                        )
                }
                
                // Content
                VStack(spacing: 6) {
                    Text(language.nativeName)
                        .font(AppTheme.Fonts.title(size: 17))
                        .foregroundColor(isSelected ? AppTheme.Colors.goldLight : AppTheme.Colors.textPrimary)
                        .minimumScaleFactor(0.7)
                        .lineLimit(1)
                    
                    Text(language.name)
                        .font(AppTheme.Fonts.caption(size: 11))
                        .foregroundColor(isSelected ? AppTheme.Colors.gold : AppTheme.Colors.textSecondary)
                        .lineLimit(1)
                }
                .padding(.horizontal, 6)
            }
            .frame(height: AppTheme.LanguageSelection.cardHeight)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.LanguageSelection.cardCornerRadius)
                    .stroke(
                        isSelected
                            ? AppTheme.Colors.gold
                            : Color.white.opacity(AppTheme.LanguageSelection.glassBorderOpacity),
                        lineWidth: isSelected ? AppTheme.LanguageSelection.selectedBorderWidth : 0.5
                    )
            )
            .shadow(
                color: isSelected ? AppTheme.Colors.gold.opacity(0.25) : Color.clear,
                radius: AppTheme.LanguageSelection.selectedGlowRadius,
                y: 0
            )
        }
        .buttonStyle(PremiumCardButtonStyle())
    }
}

// MARK: - Button Style
struct PremiumCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Particle Burst View
struct ParticleBurstView: View {
    @State private var particles: [Particle] = []
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(particles) { particle in
                    Circle()
                        .fill(AppTheme.Colors.gold)
                        .frame(width: particle.size, height: particle.size)
                        .position(particle.position)
                        .opacity(particle.opacity)
                }
            }
            .onAppear {
                createParticles(in: geo.size)
            }
        }
    }
    
    private func createParticles(in size: CGSize) {
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        
        for i in 0..<AppTheme.LanguageSelection.particleCount {
            let angle = Double(i) * (360.0 / Double(AppTheme.LanguageSelection.particleCount))
            let radius: CGFloat = CGFloat.random(in: 80...150)
            
            let endX = center.x + cos(angle * .pi / 180) * radius
            let endY = center.y + sin(angle * .pi / 180) * radius
            
            var particle = Particle(
                position: center,
                size: CGFloat.random(in: 3...6),
                opacity: 1.0
            )
            
            particles.append(particle)
            
            let index = particles.count - 1
            
            withAnimation(.easeOut(duration: AppTheme.LanguageSelection.particleDuration)) {
                particles[index].position = CGPoint(x: endX, y: endY)
                particles[index].opacity = 0
            }
        }
    }
}

struct Particle: Identifiable {
    let id = UUID()
    var position: CGPoint
    var size: CGFloat
    var opacity: Double
}

#Preview {
    LanguageSelectionView(isCompleted: .constant(false))
}
