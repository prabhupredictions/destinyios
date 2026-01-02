import SwiftUI

/// Language settings sheet for selecting app language
struct LanguageSettingsSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    // Current language stored in UserDefaults
    @AppStorage("appLanguage") private var appLanguage = "English"
    @AppStorage("appLanguageCode") private var appLanguageCode = "en"
    
    // Available languages
    private let languages: [(code: String, name: String, nativeName: String)] = [
        ("en", "English", "English"),
        ("hi", "Hindi", "हिंदी"),
        ("ta", "Tamil", "தமிழ்"),
        ("te", "Telugu", "తెలుగు"),
        ("kn", "Kannada", "ಕನ್ನಡ"),
        ("ml", "Malayalam", "മലയാളം"),
        ("es", "Spanish", "Español"),
        ("pt", "Portuguese", "Português"),
        ("de", "German", "Deutsch"),
        ("fr", "French", "Français"),
        ("zh-Hans", "Chinese", "中文"),
        ("ja", "Japanese", "日本語"),
        ("ru", "Russian", "Русский")
    ]
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(languages, id: \.code) { language in
                        Button {
                            selectLanguage(language)
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(language.nativeName)
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(Color("NavyPrimary"))
                                    
                                    if language.name != language.nativeName {
                                        Text(language.name)
                                            .font(.system(size: 13))
                                            .foregroundColor(Color("TextDark").opacity(0.5))
                                    }
                                }
                                
                                Spacer()
                                
                                if appLanguageCode == language.code {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(Color("GoldAccent"))
                                        .font(.system(size: 14, weight: .semibold))
                                }
                            }
                        }
                    }
                } header: {
                    Text("select_language".localized)
                } footer: {
                    Text("language_note".localized)
                        .font(.caption)
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("language".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("done".localized) {
                        dismiss()
                    }
                    .foregroundColor(Color("NavyPrimary"))
                }
            }
        }
    }
    
    private func selectLanguage(_ language: (code: String, name: String, nativeName: String)) {
        appLanguageCode = language.code
        appLanguage = language.nativeName
        
        // Update the app's locale
        UserDefaults.standard.set([language.code], forKey: "AppleLanguages")
        UserDefaults.standard.synchronize()
        
        // Haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
    }
}

// MARK: - Localization Helper
/// Helper to get localized strings with custom bundle
struct LocalizedString {
    static func get(_ key: String) -> String {
        // Check if user has a preferred language
        let languageCode = UserDefaults.standard.string(forKey: "appLanguageCode") ?? "en"
        
        // Try to load from the selected language bundle
        if let path = Bundle.main.path(forResource: languageCode, ofType: "lproj"),
           let bundle = Bundle(path: path) {
            return NSLocalizedString(key, bundle: bundle, comment: "")
        }
        
        // Fallback to main bundle
        return NSLocalizedString(key, comment: "")
    }
}

// MARK: - String Extension for Easy Localization
extension String {
    var localized: String {
        return LocalizedString.get(self)
    }
}

#Preview {
    LanguageSettingsSheet()
}
