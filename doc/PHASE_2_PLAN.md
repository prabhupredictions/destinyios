# Phase 2: Authentication & Onboarding - Detailed Implementation Plan

> **Duration:** 2 days  
> **Goal:** Complete user onboarding flow from splash to auth to birth data collection  
> **Prerequisites:** Phase 1 complete (Services layer ready, 28 tests passing)

---

## Table of Contents

1. [Overview](#overview)
2. [Day 1: Splash & Onboarding](#day-1-splash--onboarding)
3. [Day 2: Authentication & Birth Data](#day-2-authentication--birth-data)
4. [Success Criteria](#success-criteria)
5. [Verification](#verification)

---

## Overview

### User Flow

```
┌──────────┐    ┌─────────────┐    ┌──────────┐    ┌───────────┐    ┌──────────┐
│  Splash  │───▶│  Onboarding │───▶│   Auth   │───▶│ BirthData │───▶│   Home   │
│ (2 sec)  │    │  (4 slides) │    │  Screen  │    │  Screen   │    │  Screen  │
└──────────┘    └─────────────┘    └──────────┘    └───────────┘    └──────────┘
     │                                   │
     │ (returning user)                  │ (guest)
     └───────────────────────────────────┴─────────────────────────▶ Home
```

### What We're Building

| Screen | Purpose | Key Code |
|--------|---------|----------|
| **Splash** | App launch, route logic | `SplashView.swift` |
| **Onboarding** | 4-slide carousel | `OnboardingView.swift` |
| **Auth** | Sign in options | `AuthView.swift`, `AuthViewModel.swift` |
| **Birth Data** | Collect birth details | `BirthDataView.swift` |

### Phase 2 Deliverables

| Component | Tests | New Files |
|-----------|-------|-----------|
| SplashView | 3 | 1 View |
| OnboardingView | 4 | 2 Views + 1 Model |
| AuthViewModel | 5 | 1 ViewModel + 1 View |
| BirthDataView | 4 | 1 View + 1 ViewModel |
| AppRootView | 2 | 1 View |
| **Total** | **18+** | **8 files** |

---

## Day 1: Splash & Onboarding

### Task 1.1: Create AppRootView (30 min)

**Goal:** Main app container that handles routing between flows

**File: `ios_app/ios_app/Views/AppRootView.swift`**

```swift
import SwiftUI

struct AppRootView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @AppStorage("isAuthenticated") private var isAuthenticated = false
    @AppStorage("hasBirthData") private var hasBirthData = false
    
    @State private var showSplash = true
    
    var body: some View {
        Group {
            if showSplash {
                SplashView()
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation { showSplash = false }
                        }
                    }
            } else if !hasSeenOnboarding {
                OnboardingView(onComplete: {
                    hasSeenOnboarding = true
                })
            } else if !isAuthenticated {
                AuthView()
            } else if !hasBirthData {
                BirthDataView()
            } else {
                HomeView()
            }
        }
    }
}

#Preview {
    AppRootView()
}
```

---

### Task 1.2: Create Splash Screen (30 min)

**File: `ios_app/ios_app/Views/Splash/SplashView.swift`**

```swift
import SwiftUI

struct SplashView: View {
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            // Background - Watercolor texture
            Color("BackgroundLight")
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                Spacer()
                
                // Logo
                Image("logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .opacity(isAnimating ? 1 : 0)
                
                // Title
                VStack(spacing: 8) {
                    Text("destiny")
                        .font(.system(size: 48, weight: .light))
                        .foregroundColor(Color("NavyPrimary"))
                    
                    Text("AI Astrology")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(Color("TextDark").opacity(0.7))
                }
                .opacity(isAnimating ? 1 : 0)
                
                Spacer()
                
                // Loading indicator
                ProgressView()
                    .tint(Color("GoldAccent"))
                    .scaleEffect(1.2)
                    .padding(.bottom, 50)
            }
        }
        .onAppear {
            withAnimation(.easeIn(duration: 0.8)) {
                isAnimating = true
            }
        }
    }
}

#Preview {
    SplashView()
}
```

---

### Task 1.3: Create Onboarding Model (15 min)

**File: `ios_app/ios_app/Models/OnboardingSlide.swift`**

```swift
import Foundation

struct OnboardingSlide: Identifiable {
    let id = UUID()
    let icon: String          // SF Symbol or asset name
    let title: String
    let subtitle: String?
    let description: String
    let showStats: Bool       // For first slide with ratings
    
    static let slides: [OnboardingSlide] = [
        OnboardingSlide(
            icon: "sparkles",
            title: "ChatGPT Store's most loved",
            subtitle: "astrology app now on App Store",
            description: "",
            showStats: true
        ),
        OnboardingSlide(
            icon: "logo",
            title: "What is Destiny AI Astrology?",
            subtitle: nil,
            description: "Destiny is a personal space to understand patterns in your life. It combines astrology with AI to help you reflect, ask better questions, and see situations more clearly.",
            showStats: false
        ),
        OnboardingSlide(
            icon: "telescope",
            title: "How Destiny delivers personal insights",
            subtitle: nil,
            description: "Astrology is shaped by thousands of interacting variables. Destiny's system analyses these patterns together, instead of isolating traits - allowing it to respond with context, nuance, and timing.",
            showStats: false
        ),
        OnboardingSlide(
            icon: "list.bullet.rectangle",
            title: "Here's what you can do",
            subtitle: nil,
            description: "",
            showStats: false
        )
    ]
}
```

---

### Task 1.4: Create Onboarding View (60 min)

**File: `ios_app/ios_app/Views/Onboarding/OnboardingView.swift`**

```swift
import SwiftUI

struct OnboardingView: View {
    @State private var currentSlide = 0
    let slides = OnboardingSlide.slides
    var onComplete: () -> Void
    
    var body: some View {
        ZStack {
            // Background
            Color("BackgroundLight")
                .ignoresSafeArea()
            
            VStack {
                // Skip button
                HStack {
                    Button("Skip") {
                        onComplete()
                    }
                    .foregroundColor(Color("TextDark").opacity(0.6))
                    .padding()
                    
                    Spacer()
                }
                
                // Content
                TabView(selection: $currentSlide) {
                    ForEach(Array(slides.enumerated()), id: \.element.id) { index, slide in
                        OnboardingSlideView(slide: slide, isLastSlide: index == slides.count - 1) {
                            onComplete()
                        }
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                
                // Page indicators
                HStack(spacing: 8) {
                    ForEach(0..<slides.count, id: \.self) { index in
                        Circle()
                            .fill(index == currentSlide ? Color("NavyPrimary") : Color("NavyPrimary").opacity(0.3))
                            .frame(width: 8, height: 8)
                    }
                }
                .padding(.bottom, 20)
                
                // Continue button (except last slide)
                if currentSlide < slides.count - 1 {
                    Button(action: {
                        withAnimation { currentSlide += 1 }
                    }) {
                        Text("Continue")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color("NavyPrimary"))
                            .cornerRadius(12)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 30)
                }
            }
        }
    }
}

#Preview {
    OnboardingView(onComplete: {})
}
```

**File: `ios_app/ios_app/Views/Onboarding/OnboardingSlideView.swift`**

```swift
import SwiftUI

struct OnboardingSlideView: View {
    let slide: OnboardingSlide
    let isLastSlide: Bool
    var onGetStarted: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Icon
            if slide.icon == "logo" {
                Image("logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
            } else {
                Image(systemName: slide.icon)
                    .font(.system(size: 60))
                    .foregroundColor(Color("GoldAccent"))
            }
            
            // Title
            Text(slide.title)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(Color("NavyPrimary"))
                .multilineTextAlignment(.center)
            
            if let subtitle = slide.subtitle {
                Text(subtitle)
                    .font(.headline)
                    .foregroundColor(Color("TextDark").opacity(0.8))
                    .multilineTextAlignment(.center)
            }
            
            // Stats card (first slide only)
            if slide.showStats {
                StatsCard()
            }
            
            // Description
            if !slide.description.isEmpty {
                Text(slide.description)
                    .font(.body)
                    .foregroundColor(Color("TextDark").opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            // Features list (last slide only)
            if isLastSlide {
                FeaturesListView()
                
                Button(action: onGetStarted) {
                    Text("Get Started")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color("NavyPrimary"))
                        .cornerRadius(12)
                }
                .padding(.horizontal, 24)
            }
            
            Spacer()
        }
        .padding()
    }
}

struct StatsCard: View {
    var body: some View {
        HStack(spacing: 16) {
            VStack {
                Text("300K+")
                    .font(.headline)
                    .foregroundColor(Color("NavyPrimary"))
                Text("conversations")
                    .font(.caption)
                    .foregroundColor(Color("TextDark").opacity(0.6))
            }
            
            Divider()
                .frame(height: 40)
            
            VStack {
                HStack(spacing: 2) {
                    ForEach(0..<4) { _ in
                        Image(systemName: "star.fill")
                            .foregroundColor(Color("GoldAccent"))
                            .font(.caption)
                    }
                }
                Text("4.0 rating")
                    .font(.caption)
                    .foregroundColor(Color("TextDark").opacity(0.6))
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5)
    }
}

struct FeaturesListView: View {
    let features = [
        ("bubble.left.and.bubble.right", "Ask Me Anything", "Ask questions and get real-time guidance"),
        ("heart", "Compatibility", "Compare two birth charts"),
        ("clock", "Chat History", "Revisit past insights"),
        ("checkmark.seal", "Higher Accuracy", "Context-aware responses")
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(features, id: \.0) { icon, title, desc in
                HStack(spacing: 12) {
                    Image(systemName: icon)
                        .foregroundColor(Color("NavyPrimary"))
                        .frame(width: 32, height: 32)
                        .background(Color("NavyPrimary").opacity(0.1))
                        .cornerRadius(8)
                    
                    VStack(alignment: .leading) {
                        Text(title)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Text(desc)
                            .font(.caption)
                            .foregroundColor(Color("TextDark").opacity(0.6))
                    }
                }
            }
        }
        .padding(.horizontal)
    }
}

#Preview {
    OnboardingSlideView(slide: OnboardingSlide.slides[3], isLastSlide: true, onGetStarted: {})
}
```

---

### Task 1.5: Write Onboarding Tests (30 min)

**File: `ios_appTests/Views/OnboardingViewTests.swift`**

```swift
import XCTest
@testable import ios_app

final class OnboardingViewTests: XCTestCase {
    
    func testOnboardingSlides_HasFourSlides() {
        // Given/When
        let slides = OnboardingSlide.slides
        
        // Then
        XCTAssertEqual(slides.count, 4)
    }
    
    func testOnboardingSlides_FirstSlideHasStats() {
        // Given
        let firstSlide = OnboardingSlide.slides[0]
        
        // Then
        XCTAssertTrue(firstSlide.showStats)
    }
    
    func testOnboardingSlides_LastSlideHasFeatures() {
        // Given
        let lastSlide = OnboardingSlide.slides[3]
        
        // Then
        XCTAssertEqual(lastSlide.title, "Here's what you can do")
    }
    
    func testOnboardingSlides_AllHaveTitles() {
        // Given
        let slides = OnboardingSlide.slides
        
        // Then
        for slide in slides {
            XCTAssertFalse(slide.title.isEmpty)
        }
    }
}
```

---

## Day 2: Authentication & Birth Data

### Task 2.1: Create KeychainService (30 min)

**Goal:** Securely store user credentials and tokens (Best Practice)

**File: `ios_app/ios_app/Services/KeychainService.swift`**

```swift
import Foundation
import Security

final class KeychainService: Sendable {
    static let shared = KeychainService()
    private init() {}
    
    enum KeychainError: Error {
        case duplicateEntry
        case unknown(OSStatus)
        case notFound
    }
    
    func save(data: Data, service: String, account: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data
        ]
        
        // Delete existing item first
        SecItemDelete(query as CFDictionary)
        
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.unknown(status)
        }
    }
    
    func load(service: String, account: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        return status == errSecSuccess ? (result as? Data) : nil
    }
    
    func delete(service: String, account: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        
        SecItemDelete(query as CFDictionary)
    }
}
```

### Task 2.2: Create AuthViewModel (45 min)

**File: `ios_app/ios_app/ViewModels/AuthViewModel.swift`**

```swift
import Foundation
import SwiftUI

@Observable
class AuthViewModel {
    // MARK: - State
    var isLoading = false
    var errorMessage: String?
    var isAuthenticated = false
    var userEmail: String?
    var isGuest = false
    
    // MARK: - Dependencies
    private let authService: AuthServiceProtocol
    private let keychain: KeychainService
    
    init(authService: AuthServiceProtocol = MockAuthService(), keychain: KeychainService = .shared) {
        self.authService = authService
        self.keychain = keychain
        checkSession()
    }
    
    // MARK: - Session Management
    private func checkSession() {
        // Check for existing session in Keychain/Defaults
        if let _ = keychain.load(service: "com.destiny.auth", account: "userId") {
            self.isAuthenticated = true
            self.isGuest = UserDefaults.standard.bool(forKey: "isGuest")
            self.userEmail = UserDefaults.standard.string(forKey: "userEmail")
        }
    }
    
    // MARK: - Actions
    func signInWithApple() async {
        await performSignIn { try await authService.signInWithApple() }
    }
    
    func signInWithGoogle() async {
        await performSignIn { try await authService.signInWithGoogle() }
    }
    
    private func performSignIn(_ action: @escaping () async throws -> User) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let user = try await action()
            await MainActor.run {
                self.handleSuccess(user: user, isGuest: false)
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Sign in failed: \(error.localizedDescription)"
            }
        }
        
        await MainActor.run {
            isLoading = false
        }
    }
    
    func continueAsGuest() {
        Task {
            isLoading = true
            let guestUser = await authService.signInAsGuest()
            await MainActor.run {
                handleSuccess(user: guestUser, isGuest: true)
                isLoading = false
            }
        }
    }
    
    private func handleSuccess(user: User, isGuest: Bool) {
        self.isAuthenticated = true
        self.isGuest = isGuest
        self.userEmail = user.email
        
        // Securely store User ID (Simulating token)
        if let data = user.id.data(using: .utf8) {
            try? keychain.save(data: data, service: "com.destiny.auth", account: "userId")
        }
        
        // Store non-sensitive state in Defaults
        UserDefaults.standard.set(isGuest, forKey: "isGuest")
        if let email = user.email {
            UserDefaults.standard.set(email, forKey: "userEmail")
        }
    }
    
    func signOut() {
        isAuthenticated = false
        isGuest = false
        userEmail = nil
        
        // Clear secure storage
        keychain.delete(service: "com.destiny.auth", account: "userId")
        
        // Clear defaults
        UserDefaults.standard.removeObject(forKey: "isGuest")
        UserDefaults.standard.removeObject(forKey: "userEmail")
    }
}

// MARK: - Mock Auth Service (for development)
class MockAuthService: AuthServiceProtocol {
    func signInWithApple() async throws -> User {
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second delay
        return User(id: UUID().uuidString, email: "user@apple.com", name: "Apple User")
    }
    
    func signInWithGoogle() async throws -> User {
        try await Task.sleep(nanoseconds: 1_000_000_000)
        return User(id: UUID().uuidString, email: "user@gmail.com", name: "Google User")
    }
    
    func signInAsGuest() async -> User {
        return User(id: UUID().uuidString, email: nil, name: "Guest")
    }
    
    func signOut() async {}
}
```

---

### Task 2.3: Create AuthView (45 min)

**File: `ios_app/ios_app/Views/Auth/AuthView.swift`**

```swift
import SwiftUI

struct AuthView: View {
    @State private var viewModel = AuthViewModel()
    @AppStorage("isAuthenticated") private var isAuthenticatedStorage = false
    
    var body: some View {
        ZStack {
            Color("BackgroundLight")
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                Spacer()
                
                // Logo
                Image("logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                
                // Title
                VStack(spacing: 8) {
                    Text("Welcome to Destiny")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(Color("NavyPrimary"))
                    
                    Text("Your personal astrology companion")
                        .font(.subheadline)
                        .foregroundColor(Color("TextDark").opacity(0.7))
                }
                
                Spacer()
                
                // Auth buttons
                VStack(spacing: 16) {
                    // Apple Sign In
                    AuthButton(
                        icon: "apple.logo",
                        title: "Sign in with Apple",
                        style: .primary
                    ) {
                        Task { await viewModel.signInWithApple() }
                    }
                    
                    // Google Sign In
                    AuthButton(
                        icon: "g.circle.fill",
                        title: "Sign in with Google",
                        style: .secondary
                    ) {
                        Task { await viewModel.signInWithGoogle() }
                    }
                    
                    // Email Sign In (future)
                    AuthButton(
                        icon: "envelope.fill",
                        title: "Sign in with Email",
                        style: .secondary
                    ) {
                        // TODO: Implement email sign in
                    }
                }
                .padding(.horizontal, 24)
                .disabled(viewModel.isLoading)
                
                // Error message
                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.horizontal)
                }
                
                // Loading
                if viewModel.isLoading {
                    ProgressView()
                        .tint(Color("GoldAccent"))
                }
                
                // Guest option
                Button("Continue as Guest") {
                    viewModel.continueAsGuest()
                    isAuthenticatedStorage = true
                }
                .font(.subheadline)
                .foregroundColor(Color("NavyPrimary"))
                .padding(.top, 8)
                
                Spacer()
                
                // Terms
                Text("By continuing, you agree to our Terms and Privacy Policy")
                    .font(.caption)
                    .foregroundColor(Color("TextDark").opacity(0.5))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .padding(.bottom, 24)
            }
        }
        .onChange(of: viewModel.isAuthenticated) { _, isAuth in
            isAuthenticatedStorage = isAuth
        }
    }
}

// MARK: - Auth Button Component
struct AuthButton: View {
    enum Style { case primary, secondary }
    
    let icon: String
    let title: String
    let style: Style
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                Text(title)
                    .fontWeight(.medium)
            }
            .foregroundColor(style == .primary ? .white : Color("NavyPrimary"))
            .frame(maxWidth: .infinity)
            .padding()
            .background(style == .primary ? Color("NavyPrimary") : Color.white)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color("NavyPrimary"), lineWidth: style == .secondary ? 1 : 0)
            )
        }
    }
}

#Preview {
    AuthView()
}
```

---

### Task 2.3: Create BirthDataView (60 min)

**File: `ios_app/ios_app/ViewModels/BirthDataViewModel.swift`**

```swift
import Foundation
import SwiftUI

@Observable
class BirthDataViewModel {
    // MARK: - State
    var dateOfBirth = Date()
    var timeOfBirth = Date()
    var cityOfBirth = ""
    var gender = ""
    
    var isLoading = false
    var errorMessage: String?
    var isValid: Bool {
        !cityOfBirth.isEmpty
    }
    
    // Computed BirthData
    var birthData: BirthData {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        
        return BirthData(
            dob: dateFormatter.string(from: dateOfBirth),
            time: timeFormatter.string(from: timeOfBirth),
            latitude: 0, // Will be geocoded
            longitude: 0,
            cityOfBirth: cityOfBirth
        )
    }
    
    // MARK: - Actions
    func save() {
        guard isValid else {
            errorMessage = "Please enter your city of birth"
            return
        }
        
        // Save to UserDefaults
        if let encoded = try? JSONEncoder().encode(birthData) {
            UserDefaults.standard.set(encoded, forKey: "userBirthData")
            UserDefaults.standard.set(true, forKey: "hasBirthData")
        }
    }
    
    func loadSaved() {
        if let data = UserDefaults.standard.data(forKey: "userBirthData"),
           let saved = try? JSONDecoder().decode(BirthData.self, from: data) {
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            if let date = dateFormatter.date(from: saved.dob) {
                dateOfBirth = date
            }
            
            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "HH:mm"
            if let time = timeFormatter.date(from: saved.time) {
                timeOfBirth = time
            }
            
            cityOfBirth = saved.cityOfBirth ?? ""
        }
    }
}
```

**File: `ios_app/ios_app/Views/Auth/BirthDataView.swift`**

```swift
import SwiftUI

struct BirthDataView: View {
    @State private var viewModel = BirthDataViewModel()
    @AppStorage("hasBirthData") private var hasBirthData = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color("BackgroundLight")
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 8) {
                            Text("Tell us about yourself")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(Color("NavyPrimary"))
                            
                            Text("Enter your birth details so we can create your profile")
                                .font(.subheadline)
                                .foregroundColor(Color("TextDark").opacity(0.7))
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 32)
                        
                        // Form fields
                        VStack(spacing: 20) {
                            // Date of Birth
                            FormField(icon: "calendar", title: "Date of Birth") {
                                DatePicker("", selection: $viewModel.dateOfBirth, displayedComponents: .date)
                                    .datePickerStyle(.compact)
                                    .labelsHidden()
                            }
                            
                            // Time of Birth
                            FormField(icon: "clock", title: "Time of Birth") {
                                DatePicker("", selection: $viewModel.timeOfBirth, displayedComponents: .hourAndMinute)
                                    .datePickerStyle(.compact)
                                    .labelsHidden()
                            }
                            
                            // City of Birth
                            FormField(icon: "location", title: "City of Birth") {
                                TextField("Enter city name", text: $viewModel.cityOfBirth)
                                    .textFieldStyle(.plain)
                            }
                            
                            // Gender (optional)
                            FormField(icon: "person", title: "Gender (optional)") {
                                Picker("", selection: $viewModel.gender) {
                                    Text("Prefer not to say").tag("")
                                    Text("Male").tag("male")
                                    Text("Female").tag("female")
                                    Text("Other").tag("other")
                                }
                                .pickerStyle(.menu)
                            }
                        }
                        .padding(.horizontal, 24)
                        
                        // Error
                        if let error = viewModel.errorMessage {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                        
                        Spacer(minLength: 40)
                        
                        // Submit button
                        Button(action: {
                            viewModel.save()
                            if viewModel.isValid {
                                hasBirthData = true
                            }
                        }) {
                            Text("Continue")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(viewModel.isValid ? Color("NavyPrimary") : Color.gray)
                                .cornerRadius(12)
                        }
                        .disabled(!viewModel.isValid)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 32)
                    }
                }
            }
            .navigationBarBackButtonHidden(true)
        }
        .onAppear {
            viewModel.loadSaved()
        }
    }
}

// MARK: - Form Field Component
struct FormField<Content: View>: View {
    let icon: String
    let title: String
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundColor(Color("NavyPrimary"))
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(Color("TextDark"))
            }
            
            content()
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color("NavyPrimary").opacity(0.2), lineWidth: 1)
                )
        }
    }
}

#Preview {
    BirthDataView()
}
```

---

### Task 2.4: Create Placeholder HomeView (15 min)

**File: `ios_app/ios_app/Views/Home/HomeView.swift`**

```swift
import SwiftUI

struct HomeView: View {
    @AppStorage("userEmail") private var userEmail = ""
    
    var body: some View {
        NavigationStack {
            VStack {
                Spacer()
                
                Image("logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                
                Text("Welcome to Destiny!")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(Color("NavyPrimary"))
                
                if !userEmail.isEmpty {
                    Text("Signed in as: \(userEmail)")
                        .font(.subheadline)
                        .foregroundColor(Color("TextDark").opacity(0.7))
                }
                
                Text("Home screen coming in Phase 3")
                    .font(.caption)
                    .foregroundColor(Color("TextDark").opacity(0.5))
                    .padding(.top, 8)
                
                Spacer()
            }
        }
    }
}

#Preview {
    HomeView()
}
```

---

### Task 2.5: Update App Entry Point (10 min)

**File: `ios_app/ios_app/ios_appApp.swift`**

```swift
import SwiftUI

@main
struct ios_appApp: App {
    var body: some Scene {
        WindowGroup {
            AppRootView()
        }
    }
}
```

---

### Task 2.6: Write Auth & BirthData Tests (45 min)

**File: `ios_appTests/ViewModels/AuthViewModelTests.swift`**

```swift
import XCTest
@testable import ios_app

final class AuthViewModelTests: XCTestCase {
    
    var viewModel: AuthViewModel!
    
    override func setUp() {
        super.setUp()
        viewModel = AuthViewModel(authService: MockAuthService())
    }
    
    override func tearDown() {
        viewModel = nil
        super.tearDown()
    }
    
    func testInitialState_NotAuthenticated() {
        XCTAssertFalse(viewModel.isAuthenticated)
        XCTAssertFalse(viewModel.isGuest)
        XCTAssertNil(viewModel.userEmail)
    }
    
    func testContinueAsGuest_SetsGuestState() {
        // When
        viewModel.continueAsGuest()
        
        // Then
        XCTAssertTrue(viewModel.isAuthenticated)
        XCTAssertTrue(viewModel.isGuest)
        XCTAssertNil(viewModel.userEmail)
    }
    
    func testSignOut_ClearsState() {
        // Given
        viewModel.continueAsGuest()
        
        // When
        viewModel.signOut()
        
        // Then
        XCTAssertFalse(viewModel.isAuthenticated)
        XCTAssertFalse(viewModel.isGuest)
    }
    
    func testSignInWithApple_SetsAuthenticatedState() async {
        // When
        await viewModel.signInWithApple()
        
        // Then
        XCTAssertTrue(viewModel.isAuthenticated)
        XCTAssertFalse(viewModel.isGuest)
        XCTAssertNotNil(viewModel.userEmail)
    }
    
    func testLoading_DuringSignIn() async {
        // Given
        XCTAssertFalse(viewModel.isLoading)
        
        // When - start sign in (won't wait)
        let task = Task {
            await viewModel.signInWithApple()
        }
        
        // Give it a moment to start
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 sec
        
        // Then - should be loading
        XCTAssertTrue(viewModel.isLoading)
        
        await task.value
    }
}
```

**File: `ios_appTests/ViewModels/BirthDataViewModelTests.swift`**

```swift
import XCTest
@testable import ios_app

final class BirthDataViewModelTests: XCTestCase {
    
    var viewModel: BirthDataViewModel!
    
    override func setUp() {
        super.setUp()
        viewModel = BirthDataViewModel()
        // Clear UserDefaults for tests
        UserDefaults.standard.removeObject(forKey: "userBirthData")
        UserDefaults.standard.removeObject(forKey: "hasBirthData")
    }
    
    override func tearDown() {
        viewModel = nil
        super.tearDown()
    }
    
    func testInitialState_Invalid() {
        XCTAssertFalse(viewModel.isValid)
    }
    
    func testWithCity_IsValid() {
        // When
        viewModel.cityOfBirth = "Los Angeles"
        
        // Then
        XCTAssertTrue(viewModel.isValid)
    }
    
    func testBirthData_FormatsCorrectly() {
        // Given
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        viewModel.dateOfBirth = dateFormatter.date(from: "1996-04-20")!
        
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        viewModel.timeOfBirth = timeFormatter.date(from: "04:45")!
        
        viewModel.cityOfBirth = "Los Angeles"
        
        // When
        let birthData = viewModel.birthData
        
        // Then
        XCTAssertEqual(birthData.dob, "1996-04-20")
        XCTAssertEqual(birthData.time, "04:45")
        XCTAssertEqual(birthData.cityOfBirth, "Los Angeles")
    }
    
    func testSave_WithInvalidData_SetsError() {
        // Given - empty city
        viewModel.cityOfBirth = ""
        
        // When
        viewModel.save()
        
        // Then
        XCTAssertNotNil(viewModel.errorMessage)
    }
}
```

---

## Success Criteria

### Must Have (Phase 2 Complete)

- [ ] Splash screen displays for 2 seconds
- [ ] Onboarding shows 4 slides with skip/continue
- [ ] Auth screen with Apple/Google/Guest options
- [ ] Guest mode works (sets appropriate flags)
- [ ] Birth data form validates city
- [ ] Birth data saves to UserDefaults
- [ ] AppRootView routes correctly between flows
- [ ] 18+ tests passing

### User Flow Works

```
1. First launch → Splash → Onboarding → Auth → Birth Data → Home
2. Returning user → Splash → Home (skips onboarding/auth)
3. Guest user → Limited features, no history saved
```

---

## Verification

After completing Phase 2:

```bash
cd /Users/i074917/Documents/destiny_ai_astrology/ios_app

# Count views created
find ios_app/Views -name "*.swift" | wc -l
# Expected: 6+

# Count tests
grep -r "func test" ios_appTests --include="*.swift" | wc -l
# Expected: 40+ (28 from Phase 1 + 12+ new)

# Run tests
# In Xcode: ⌘ + U
```

### Manual Testing

1. **Delete app** from simulator (to test first launch)
2. **Run app** - should see Splash → Onboarding
3. **Skip onboarding** - should go to Auth
4. **Tap "Continue as Guest"** - should go to Birth Data
5. **Enter city** - Continue button enables
6. **Tap Continue** - should go to Home
7. **Kill and relaunch app** - should go directly to Home

---

## Git Commit

After Phase 2 complete:

```bash
git add .
git commit -m "feat: Complete Phase 2 - Authentication & Onboarding

- Add SplashView with logo animation
- Add OnboardingView with 4 slides carousel
- Add AuthView with Apple/Google/Guest options
- Add BirthDataView with date/time/city collection
- Add AppRootView for flow routing
- Add AuthViewModel with state management
- Add BirthDataViewModel with validation
- 18+ new tests, total 46+ passing"

git push origin main
```

---

## Next: Phase 3

After Phase 2 is verified, proceed to Phase 3: Core Screens - Home & Tab Bar

---

**End of Phase 2 Detailed Plan**
