import SwiftUI

/// Premium language selection screen shown on first launch
struct LanguageSelectionView: View {
    @Binding var isCompleted: Bool
    
    // UserDefaults to save selection
    @AppStorage("appLanguage") private var appLanguage = "English"
    @AppStorage("appLanguageCode") private var appLanguageCode = "en"
    
    @State private var selectedCode: String?
    @State private var animateContent = false
    
    // supported languages
    private let languages: [LanguageOption] = [
        LanguageOption(code: "en", name: "English", nativeName: "English"),
        LanguageOption(code: "hi", name: "Hindi", nativeName: "हिन्दी"),
        LanguageOption(code: "ta", name: "Tamil", nativeName: "தமிழ்"),
        LanguageOption(code: "te", name: "Telugu", nativeName: "తెలుగు"),
        LanguageOption(code: "kn", name: "Kannada", nativeName: "ಕನ್ನಡ"),
        LanguageOption(code: "ml", name: "Malayalam", nativeName: "മലയാളം"),
        LanguageOption(code: "es", name: "Spanish", nativeName: "Español"),
        LanguageOption(code: "pt", name: "Portuguese", nativeName: "Português"),
        LanguageOption(code: "de", name: "German", nativeName: "Deutsch"),
        LanguageOption(code: "fr", name: "French", nativeName: "Français"),
        LanguageOption(code: "zh-Hans", name: "Chinese", nativeName: "中文"),
        LanguageOption(code: "ja", name: "Japanese", nativeName: "日本語"),
        LanguageOption(code: "ru", name: "Russian", nativeName: "Русский")
    ]
    
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        ZStack {
            // Background
            AppTheme.Colors.mainBackground.ignoresSafeArea()
            
            // Cosmic background effect
            Circle()
                .fill(AppTheme.Colors.gold.opacity(0.1))
                .frame(width: 400, height: 400)
                .blur(radius: 60)
                .offset(x: -100, y: -200)
            
            // Main content - proper VStack layout (not overlay)
            VStack(spacing: 0) {
                // Header (fixed)
                VStack(spacing: 12) {
                    Image(systemName: "globe")
                        .font(AppTheme.Fonts.display(size: 40))
                        .foregroundColor(AppTheme.Colors.gold)
                        .padding(.bottom, 8)
                        
                    Text("Destiny AI Astrology")
                        .font(AppTheme.Fonts.display(size: 28))
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    
                    Text("Your cosmic journey begins in your language")
                        .font(AppTheme.Fonts.body(size: 16))
                        .foregroundColor(AppTheme.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 40)
                .padding(.bottom, 20)
                .opacity(animateContent ? 1 : 0)
                .offset(y: animateContent ? 0 : 20)
                
                // Language Grid (scrollable, takes remaining space)
                ScrollView(showsIndicators: false) {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(languages) { language in
                            LanguageGridItem(
                                language: language,
                                isSelected: selectedCode == language.code
                            ) {
                                selectLanguage(language)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                }
                .opacity(animateContent ? 1 : 0)
                .offset(y: animateContent ? 0 : 30)
                
                // Continue Button (fixed at bottom, NOT overlaying)
                if selectedCode != nil {
                    Button(action: confirmSelection) {
                        Text(continueButtonText)
                            .font(AppTheme.Fonts.title(size: 18))
                            .foregroundColor(AppTheme.Colors.textOnGold)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(AppTheme.Colors.premiumGradient)
                            .cornerRadius(16)
                            .shadow(color: AppTheme.Colors.gold.opacity(0.3), radius: 10, y: 4)
                    }
                    .padding(.horizontal, 40)
                    .padding(.bottom, 30)
                    .padding(.top, 16)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8).delay(0.2)) {
                animateContent = true
            }
        }
    }
    
    private var continueButtonText: String {
        guard let code = selectedCode else { return "Continue" }
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
    
    private func selectLanguage(_ language: LanguageOption) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            selectedCode = language.code
        }
        
        appLanguageCode = language.code
        appLanguage = language.name
        
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
    }
    
    private func confirmSelection() {
        guard let code = selectedCode else { return }
        
        UserDefaults.standard.set([code], forKey: "AppleLanguages")
        UserDefaults.standard.synchronize()
        
        withAnimation(.easeInOut(duration: 0.5)) {
            isCompleted = true
        }
    }
}

struct LanguageOption: Identifiable {
    let id = UUID()
    let code: String
    let name: String
    let nativeName: String
}

struct LanguageGridItem: View {
    let language: LanguageOption
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(language.nativeName)
                    .font(AppTheme.Fonts.title(size: 18))
                    .foregroundColor(AppTheme.Colors.textPrimary)
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
                
                Text(language.name)
                    .font(AppTheme.Fonts.caption(size: 12))
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .lineLimit(1)
            }
            .padding(.horizontal, 4)
            .frame(maxWidth: .infinity)
            .frame(height: 80) // Slightly smaller cards
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? AppTheme.Colors.gold.opacity(0.15) : AppTheme.Colors.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isSelected ? AppTheme.Colors.gold : AppTheme.Colors.separator, lineWidth: isSelected ? 2 : 1)
                    )
            )
            .animation(.spring(response: 0.3), value: isSelected)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

#Preview {
    LanguageSelectionView(isCompleted: .constant(false))
}
