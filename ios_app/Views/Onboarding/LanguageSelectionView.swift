import SwiftUI

/// Premium language selection screen shown on first launch
struct LanguageSelectionView: View {
    @Binding var isCompleted: Bool
    
    // UserDefaults to save selection
    @AppStorage("appLanguage") private var appLanguage = "English"
    @AppStorage("appLanguageCode") private var appLanguageCode = "en"
    // AppleLanguages is array [String], not supported by AppStorage directly
    // usage is handled manually in helper functions
    
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
            Color("NavyPrimary").ignoresSafeArea()
            
            // Cosmic background effect
            Circle()
                .fill(Color("PurpleAccent").opacity(0.1))
                .frame(width: 400, height: 400)
                .blur(radius: 60)
                .offset(x: -100, y: -200)
            
            VStack(spacing: 30) {
                Spacer()
                    .frame(height: 20) // Top spacing to prevent truncation
                
                // Header
                VStack(spacing: 12) {
                    // Logo or Icon
                    Image(systemName: "globe")
                        .font(.system(size: 40))
                        .foregroundColor(Color("GoldAccent"))
                        .padding(.bottom, 8)
                        
                    Text("Destiny AI Astrology")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Your cosmic journey begins in your language")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
                .opacity(animateContent ? 1 : 0)
                .offset(y: animateContent ? 0 : 20)
                
                // Language Grid
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
                    .padding(.bottom, 100) // Space for button
                }
                .opacity(animateContent ? 1 : 0)
                .offset(y: animateContent ? 0 : 30)
            }
            
            // Continue Button (Fixed at bottom)
            VStack {
                Spacer()
                if selectedCode != nil {
                    Button(action: confirmSelection) {
                        Text(continueButtonText)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                RoundedRectangle(cornerRadius: 30)
                                    .fill(Color("PurpleAccent")) // Premium purple button
                                    .shadow(color: Color("PurpleAccent").opacity(0.4), radius: 10, y: 4)
                            )
                    }
                    .padding(.horizontal, 40)
                    .padding(.bottom, 40)
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
        // Simple mapping for demonstration, in a real app these would be localized too
        // or fetched from the respective bundle
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
        
        // Save
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
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .minimumScaleFactor(0.8)
                
                Text(language.name)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.6))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 90)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? Color.white.opacity(0.15) : Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isSelected ? Color("GoldAccent") : Color.white.opacity(0.1), lineWidth: isSelected ? 2 : 1)
                    )
            )
            .scaleEffect(isSelected ? 1.05 : 1.0)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// Reuse or define ScaleButtonStyle
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}

#Preview {
    LanguageSelectionView(isCompleted: .constant(false))
}
