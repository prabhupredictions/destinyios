# HTML Mockup Transformation Plan

## Overview
Transform `ios_app_mockup.html` to new clean design with navy/white theme.

---

## User Tiers & Quotas

| Tier | Questions | Match | Features |
|------|-----------|-------|----------|
| **Guest** | 3 | 1 | Home view only, no history saved |
| **Free** (signed in) | 10/month | 3/month | History, basic features |
| **Premium** | Unlimited | Unlimited | All features, priority |

### How Quota Works:
1. **Guest tries Ask/Match** → Show sign-up prompt after 3 questions
2. **Free user hits limit** → Show upgrade to Premium modal
3. **Premium user** → No limits

### Quota UI (Home Screen):
```
┌─────────────────────────────────┐
│ 🔮 3/10 questions remaining     │
│ ━━━━━━━━━░░░░░░                 │
│ Renews Jan 21                   │
└─────────────────────────────────┘
```

### Limit Reached Prompt:
```
┌─────────────────────────────────┐
│                                 │
│      You've used all your       │
│      free questions! 🌟         │
│                                 │
│   Upgrade to Premium for        │
│   unlimited cosmic insights.    │
│                                 │
│   [  Upgrade - $4.99/mo  ]      │
│                                 │
│        Maybe later              │
│                                 │
└─────────────────────────────────┘
```

## Screen Flow (All 11 Screens)

### 1. SPLASH SCREEN
```
┌─────────────────────────────────┐
│                                 │
│                                 │
│                                 │
│            D destiny            │
│          ━━━━━━━━━━━           │
│                                 │
│                                 │
│                                 │
│           Loading...            │
│                                 │
└─────────────────────────────────┘
→ Auto-navigate to: Onboarding (first time) / Home (returning)
```

---

### 2. ONBOARDING (4 Slides)

**Slide 1:**
```
┌─────────────────────────────────┐
│                                 │
│            ◎ (GPT logo)         │
│                                 │
│    ChatGPT Store's most loved   │
│    astrology app now on the     │
│           App Store             │
│                                 │
│  ┌─────────────────────────┐    │
│  │ ◎ 300K+ conversations   │    │
│  │ ⭐⭐⭐⭐ 4.0 rating      │    │
│  └─────────────────────────┘    │
│                                 │
│ Skip              ○ ○ ○ ○       │
└─────────────────────────────────┘
```

**Slide 2:**
```
┌─────────────────────────────────┐
│                                 │
│              D>                 │
│                                 │
│     What is Destiny AI          │
│        Astrology?               │
│                                 │
│  Destiny is a personal space    │
│  to understand patterns in      │
│  your life. It combines         │
│  astrology with AI to help      │
│  you reflect, ask better        │
│  questions, and see             │
│  situations more clearly.       │
│                                 │
│ Skip   [Continue >]   ● ○ ○ ○   │
└─────────────────────────────────┘
```

**Slide 3:**
```
┌─────────────────────────────────┐
│                                 │
│             🔭                  │
│                                 │
│      How Destiny delivers       │
│       personal insights         │
│                                 │
│  Astrology is shaped by         │
│  thousands of interacting       │
│  variables. Destiny's system    │
│  analyses these patterns        │
│  together, instead of           │
│  isolating traits - allowing    │
│  it to respond with context,    │
│  nuance, and timing.            │
│                                 │
│ Skip   [Continue >]   ○ ● ○ ○   │
└─────────────────────────────────┘
```

**Slide 4:**
```
┌─────────────────────────────────┐
│                                 │
│   Here's what you can do        │
│                                 │
│ ⚫ Ask Me Anything              │
│   Ask questions about your day  │
│   and get real-time guidance.   │
│                                 │
│ ❤️ Compatibility / Match        │
│   Compare two birth charts.     │
│                                 │
│ 💬 Chat History                 │
│   Revisit past insights.        │
│                                 │
│ ✅ Higher Accuracy              │
│   Context-aware responses.      │
│                                 │
│      [  Get started  ]          │
└─────────────────────────────────┘
→ Navigate to: Auth
```

---

### 3. AUTH SCREEN (Optional - can skip)
```
┌─────────────────────────────────┐
│                                 │
│            D destiny            │
│                                 │
│      Welcome to Destiny         │
│   Your personal astrology       │
│          companion              │
│                                 │
│  ┌─────────────────────────┐    │
│  │  ⍟ Sign in with Apple   │    │
│  └─────────────────────────┘    │
│                                 │
│  ┌─────────────────────────┐    │
│  │  G Sign in with Google  │    │
│  └─────────────────────────┘    │
│                                 │
│  ┌─────────────────────────┐    │
│  │  ✉ Sign in with Email   │    │
│  └─────────────────────────┘    │
│                                 │
│      [Continue as Guest]        │
│                                 │
│     By continuing, you agree    │
│     to our Terms and Privacy    │
│                                 │
└─────────────────────────────────┘
→ Sign in → Birth Data (if new) → Home
→ Continue as Guest → Home (limited features)
```

**Guest Mode Limitations:**
- Can explore Home, view daily insights
- Prompted to sign in when using Ask or Match
- No history saved

---

### 4. BIRTH DATA SCREEN (First-time setup after Auth)
```
┌─────────────────────────────────┐
│ < Back                          │
│                                 │
│      Tell us about yourself     │
│   Enter your birth details so   │
│   we can create your profile.   │
│                                 │
│  📅 Date of birth               │
│  ┌─────────────────────────┐    │
│  │ Select date   April 20, 1996>│
│  └─────────────────────────┘    │
│                                 │
│  🕐 Time of birth               │
│  ┌─────────────────────────┐    │
│  │ Select time       4:45 AM >  │
│  └─────────────────────────┘    │
│                                 │
│  📍 Location of birth           │
│  ┌─────────────────────────┐    │
│  │ Enter...    Los Angeles, CA >│
│  └─────────────────────────┘    │
│                                 │
│  ⊕ Gender                       │
│  ┌─────────────────────────┐    │
│  │ Select gender      Female >  │
│  └─────────────────────────┘    │
│                                 │
│  ┌─────────────────────────┐    │
│  │          Next                │
│  └─────────────────────────┘    │
│  ✨ [Cosmic starry background]  │
└─────────────────────────────────┘
→ Navigate to: Home
```

---

### 5. HOME SCREEN
```
┌─────────────────────────────────┐
│ ☰           D destiny        👤 │
│                                 │
│  Hey Vamshi,                    │
│  Let's look at today.           │
│                                 │
│  ┌─ Quota ─────────────────┐    │
│  │ 🔮 7/10 questions left  │    │
│  │ ━━━━━━━━━░░░  Renews Jan│    │
│  └─────────────────────────┘    │
│                                 │
│  ┌─────────────────────────┐    │
│  │ You're more sensitive   │    │
│  │ to tone than words      │    │
│  │ today.                  │    │
│  └─────────────────────────┘    │
│                                 │
│  ┌─────────────────────────┐    │
│  │ What should I be mindful│    │
│  │ of in conversations?   >│    │
│  └─────────────────────────┘    │
│                                 │
│     ○ ~~~~ ○ ~~~~              │
│    [Golden planets on orbits]   │
│                                 │
├─────────────────────────────────┤
│  🏠      ┌───────┐      ❤️     │
│ Home     │  Ask  │     Match    │
│          └───────┘              │
└─────────────────────────────────┘
☰ → History | 👤 → Profile
```

---

### 6. CHAT SCREEN (via Ask)
```
┌─────────────────────────────────┐
│ < Back      D destiny        👤 │
│                                 │
│  ┌─────────────────────────┐    │
│  │ 🧙 Based on your chart, │    │
│  │ Mercury in the 3rd house│    │
│  │ suggests heightened     │    │
│  │ sensitivity today...    │    │
│  └─────────────────────────┘    │
│                                 │
│         ┌──────────────────┐    │
│         │ What about my    │    │
│         │ career?          │    │
│         └──────────────────┘    │
│                                 │
│                          [+]    │
│  ┌─────────────────────────┐    │
│  │ Type your question... ➤ │    │
│  └─────────────────────────┘    │
├─────────────────────────────────┤
│  🏠      ┌───────┐      ❤️     │
│ Home     │  Ask  │     Match    │
└─────────────────────────────────┘
[+] FAB → Start new chat
```

---

### 7. COMPATIBILITY SCREEN (via Match)
```
┌─────────────────────────────────┐
│       Match Compatibility       │
│                                 │
│     Discover your connection    │
│   Compare birth charts to see   │
│   how your stars align together │
│                                 │
│ ┌──────────────┬──────────────┐ │
│ │ Boy Details  │ Girl Details │ │
│ └──────────────┴──────────────┘ │
│                                 │
│  BOY'S NAME                     │
│  ┌─────────────────────────┐    │
│  │ Vamshi                  │    │
│  └─────────────────────────┘    │
│                                 │
│  DATE OF BIRTH    TIME          │
│  ┌───────────┐ ┌───────────┐    │
│  │ 1994-07-01│ │   00:15   │    │
│  └───────────┘ └───────────┘    │
│                                 │
│  PLACE OF BIRTH                 │
│  ┌─────────────────────────┐    │
│  │ Karimnagar              │    │
│  └─────────────────────────┘    │
│                          [+]    │
│  ┌─────────────────────────┐    │
│  │    Analyze Match ✨      │    │
│  └─────────────────────────┘    │
├─────────────────────────────────┤
│  🏠      ┌───────┐      ❤️     │
│ Home     │  Ask  │     Match    │
└─────────────────────────────────┘
[+] FAB → Start new match
```

**Result View:**
```
┌─────────────────────────────────┐
│ < Back    Match Result          │
│                                 │
│  ┌─────────┐    ┌─────────┐     │
│  │ ♂ Vamshi│ VS │ ♀ Swathi│     │
│  └─────────┘    └─────────┘     │
│                                 │
│        ╭─────────────╮          │
│       ╱      28       ╲         │
│      │   ━━━━━━━━━   │         │
│       ╲   out of 36  ╱          │
│        ╰─────────────╯          │
│                                 │
│  Kuta Grid:                     │
│  Varna 8/8 │ Vashya 5/6         │
│  Tara 3/3  │ Yoni 4/4           │
│                                 │
│  AI Interpretation chat...      │
│                                 │
├─────────────────────────────────┤
│  🏠      ┌───────┐      ❤️     │
│ Home     │  Ask  │     Match    │
└─────────────────────────────────┘
```

---

### 8. HISTORY SCREEN (via ☰)
```
┌─────────────────────────────────┐
│            Chat History         │
│                                 │
│  Today                          │
│  ┌─────────────────────────┐    │
│  │ 🔮 Career guidance 2025 │ 2h │
│  │ Moderate growth...      │    │
│  └─────────────────────────┘    │
│                                 │
│  ┌─────────────────────────┐    │
│  │ 💕 Match: Vamshi&Swathi │ 5h │
│  │ 28/36 - Excellent       │    │
│  └─────────────────────────┘    │
│                                 │
│  Yesterday                      │
│  ┌─────────────────────────┐    │
│  │ 🔮 Marriage prediction  │ 1d │
│  │ Strong 2025 indications │    │
│  └─────────────────────────┘    │
│                                 │
│                                 │
├─────────────────────────────────┤
│  🏠      ┌───────┐      ❤️     │
│ Home     │  Ask  │     Match    │
└─────────────────────────────────┘
```

---

### 9. CHARTS SCREEN
```
┌─────────────────────────────────┐
│ < Back       Birth Chart        │
│                                 │
│  ♋ Cancer Ascendant             │
│                                 │
│  PLANETARY POSITIONS            │
│  ┌─────────────────────────┐    │
│  │ ☉ Sun       Gemini      │    │
│  │ ☽ Moon      Aquarius    │    │
│  │ ☿ Mercury   Gemini      │    │
│  │ ♀ Venus     Cancer      │    │
│  │ ♂ Mars      Taurus      │    │
│  │ ♃ Jupiter   Libra       │    │
│  │ ♄ Saturn    Pisces      │    │
│  │ ☊ Rahu      Libra       │    │
│  │ ☋ Ketu      Aries       │    │
│  └─────────────────────────┘    │
│                                 │
│                                 │
├─────────────────────────────────┤
│  🏠      ┌───────┐      ❤️     │
│ Home     │  Ask  │     Match    │
└─────────────────────────────────┘
```

---

### 10. PROFILE SCREEN (via 👤)
```
┌─────────────────────────────────┐
│ < Back         Profile          │
│                                 │
│          👤 [Crown]             │
│           Vamshi                │
│       vamshi@email.com          │
│                                 │
│  Birth Details                  │
│  ┌─────────────────────────┐    │
│  │ 🎂 Birth Details       >│    │
│  │   01 Jul 1994, 00:15 AM │    │
│  │   Karimnagar            │    │
│  └─────────────────────────┘    │
│                                 │
│  Preferences                    │
│  ┌─────────────────────────┐    │
│  │ 🔔 Astrology System   > │    │
│  │    Vedic                │    │
│  │ 🌐 Language           > │    │
│  │    English              │    │
│  └─────────────────────────┘    │
│                                 │
│  Support                        │
│  ┌─────────────────────────┐    │
│  │ ❓ Help & FAQ          >│    │
│  │ 🚪 Sign Out            >│    │
│  └─────────────────────────┘    │
├─────────────────────────────────┤
│  🏠      ┌───────┐      ❤️     │
│ Home     │  Ask  │     Match    │
└─────────────────────────────────┘
```

---

### 11. SUBSCRIPTION SCREEN
```
┌─────────────────────────────────┐
│ < Back                          │
│                                 │
│             👑                  │
│                                 │
│      Unlock Destiny             │
│        Premium                  │
│                                 │
│  Get unlimited insights and     │
│  deeper cosmic guidance.        │
│                                 │
│  ┌─────────────────────────┐    │
│  │  $4.99 /month           │    │
│  │                         │    │
│  │  ✓ All Premium Horoscopes│   │
│  │  ✓ Unlimited Matches     │   │
│  │  ✓ Advanced Birth Charts │   │
│  │  ✓ Ad-Free Experience    │   │
│  │                         │    │
│  │  [  Subscribe Now  ]     │   │
│  │                         │    │
│  │  Auto-renews. Cancel     │   │
│  │  anytime.                │   │
│  └─────────────────────────┘    │
│                                 │
└─────────────────────────────────┘
```

---

## Navigation Summary

```
App Launch
    ↓
[Splash] → [Onboarding] → [Auth] → [Birth Data]
    ↓                                    ↓
    └──────────────────────────────────→ [Home]
                                          ↓
                    ┌─────────────────────┼─────────────────────┐
                    ↓                     ↓                     ↓
                   ☰                    Tab Bar                👤
                    ↓              ┌──────┼──────┐              ↓
               [History]         [Home][Ask][Match]         [Profile]
                                        ↓      ↓                ↓
                                    [Chat] [Compat]      [Subscription]
```

---

## Execution Order

1. Global CSS (colors, animations)
2. Tab Bar (3 items + Ask pill)
3. Header (☰ | logo | 👤)
4. Splash → Onboarding → Auth → Birth Data
5. Home (insight cards + planets)
6. Chat + FAB
7. Compatibility + FAB
8. History, Charts, Profile, Subscription

---

# iOS App Development Plan - API Integration

> **Base URL:** `https://astroapi-v2-668639087682.asia-south1.run.app/`

---

---

## Development Methodology & Testing Strategy

### Test-Driven Development (TDD) Approach

This project follows **Protocol-Oriented TDD** for maximum testability and CI/CD readiness.

#### Testing Pyramid

```
        /\
       /UI\ ← Few (Critical Paths Only)
      /────\
     /Unit \ ← Many (All Logic)
    /──────\
   /Mocks  \ ← Foundation (Protocols)
  /────────\
```

#### What to Test (Strict TDD)

| Layer | Coverage | Framework | Example |
|-------|----------|-----------|---------|
| **Services** | 100% | XCTest | `PredictionServiceTests`: Mock API, verify data parsing |
| **ViewModels** | 100% | XCTest | `AuthViewModelTests`: Test state transitions, validation |
| **Models** | 100% | XCTest | `BirthDataTests`: Test Codable, validation logic |
| **UI (Critical)** | ~20% | XCUITest | E2E: Splash → Login → Predict → Result |

#### What NOT to Test
- SwiftUI declarative views (use Xcode Previews instead)
- Apple framework internals
- UI layout pixel-perfect assertions (brittle)

---

### Testing Infrastructure

#### 1. Test Target Setup
```swift
// ios_appTests/
├── Mocks/
│   ├── MockPredictionService.swift
│   ├── MockAuthService.swift
│   └── MockChatHistoryService.swift
├── ViewModels/
│   ├── AuthViewModelTests.swift
│   ├── PredictionViewModelTests.swift
│   └── CompatibilityViewModelTests.swift
├── Services/
│   ├── PredictionServiceTests.swift
│   └── NetworkClientTests.swift
└── Models/
    ├── BirthDataTests.swift
    └── PredictionResponseTests.swift
```

#### 2. Protocol-Oriented Design
Every service MUST have a protocol for mockability:

```swift
protocol PredictionServiceProtocol {
    func predict(query: String, birthData: BirthData) async throws -> PredictionResponse
}

// Production
class PredictionService: PredictionServiceProtocol { ... }

// Test Mock
class MockPredictionService: PredictionServiceProtocol {
    var mockResult: Result<PredictionResponse, Error>?
    func predict(...) async throws -> PredictionResponse {
        // Return controlled test data
    }
}
```

#### 3. TDD Red-Green-Refactor Workflow

```
🔴 RED → Write failing test
   ↓
🟢 GREEN → Write minimal code to pass
   ↓
🔵 REFACTOR → Improve code quality
   ↓
   Repeat
```

**Example Session:**
```swift
// 1. RED: Write test first
func testPredictionLoading() {
    let viewModel = PredictionViewModel(service: MockPredictionService())
    XCTAssertFalse(viewModel.isLoading) ❌ FAILS
}

// 2. GREEN: Implement
class PredictionViewModel {
    @Published var isLoading = false
} ✅ PASSES

// 3. REFACTOR: Add real logic
func submitQuery() {
    isLoading = true
    // ...
}
```

---

### CI/CD Setup

#### Git Workflow
```bash
main (protected)
  ↓
develop (integration)
  ↓
feature/auth-screen (your work)
```

**Branch Strategy:**
- `main`: Production-ready (App Store)
- `develop`: Integration branch (TestFlight)
- `feature/*`: Individual features

#### GitHub Actions Pipeline

Create `.github/workflows/ios-ci.yml`:

```yaml
name: iOS CI/CD

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main, develop ]

jobs:
  test:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Select Xcode
        run: sudo xcode-select -s /Applications/Xcode_15.2.app
      
      - name: Build and Test
        run: |
          xcodebuild clean build test \
            -scheme ios_app \
            -destination 'platform=iOS Simulator,name=iPhone 15 Pro,OS=17.2' \
            -resultBundlePath TestResults
      
      - name: Upload Test Results
        if: failure()
        uses: actions/upload-artifact@v3
        with:
          name: test-results
          path: TestResults

  build:
    needs: test
    runs-on: macos-latest
    if: github.ref == 'refs/heads/main'
    steps:
      - uses: actions/checkout@v3
      
      - name: Build Release
        run: |
          xcodebuild archive \
            -scheme ios_app \
            -archivePath build/ios_app.xcarchive
```

#### TestFlight Deployment (Future)
```yaml
- name: Upload to TestFlight
  env:
    APP_STORE_CONNECT_API_KEY: ${{ secrets.ASC_API_KEY }}
  run: |
    xcrun altool --upload-app \
      -f build/ios_app.ipa \
      -t ios \
      --apiKey $APP_STORE_CONNECT_API_KEY
```

---

### Complete CI/CD Setup Guide

#### Step 1: Apple Developer Account Setup

**Prerequisites:**
1. **Apple Developer Program** ($99/year): https://developer.apple.com/programs/
2. **App Store Connect** access: https://appstoreconnect.apple.com/

**Initial Setup:**
```bash
# 1. Create App ID in Apple Developer Portal
Bundle ID: com.destinyai.astrology
Name: Destiny AI Astrology

# 2. Create App in App Store Connect
- App Name: Destiny AI Astrology
- Primary Language: English
- Bundle ID: com.destinyai.astrology
- SKU: DESTINYAI_ASTRO_001
```

#### Step 2: Code Signing & Certificates

**Option A: Automatic Signing (Recommended for Solo Dev)**
```swift
// In Xcode:
// 1. Select your target → Signing & Capabilities
// 2. Check "Automatically manage signing"
// 3. Select your Team
// ✅ Xcode handles certificates automatically
```

**Option B: Manual Signing (For CI/CD)**
```bash
# 1. Create certificates on Apple Developer Portal
- Development Certificate (for local testing)
- Distribution Certificate (for App Store)

# 2. Create Provisioning Profiles
- Development Profile (linked to Dev Certificate)
- App Store Profile (linked to Distribution Certificate)

# 3. Store in GitHub Secrets
CERTIFICATES_P12=<base64 encoded .p12 file>
PROVISIONING_PROFILE=<base64 encoded .mobileprovision>
CERTIFICATE_PASSWORD=<password>
```

**Using Fastlane Match (Best Practice):**
```bash
# Install Fastlane
brew install fastlane

# Initialize Match (stores certs in private Git repo)
fastlane match init

# Generate certificates
fastlane match development  # For testing
fastlane match appstore     # For App Store
```

#### Step 3: Git → App Store Deploy Flow

```
Local Dev (feature/*)
    ↓ git push
GitHub PR
    ↓ merge
develop branch
    ↓ CI: Tests + Build
TestFlight (Beta)
    ↓ QA Pass
main branch + tag
    ↓ CI: Build + Upload
App Store Connect
    ↓ Manual Submit
Apple Review (1-3 days)
    ↓ ✅ Approved
Production (App Store) 🎉
```

#### Step 4: GitHub Secrets Setup

Navigate to: `https://github.com/YOUR_USERNAME/ios_app/settings/secrets/actions`

Add these secrets:
```yaml
CERTIFICATE_BASE64          # Dev/Distribution cert (.p12) as base64
P12_PASSWORD                # Certificate password
PROVISIONING_PROFILE_BASE64 # .mobileprovision as base64
TEAM_ID                     # Apple Developer Team ID
ASC_API_KEY_ID              # App Store Connect API Key ID
ASC_ISSUER_ID               # App Store Connect Issuer ID
ASC_API_KEY                 # App Store Connect API Key (.p8 file content)
SLACK_WEBHOOK               # (Optional) For notifications
```

**How to get base64:**
```bash
base64 -i Certificates.p12 -o cert.txt
base64 -i Profile.mobileprovision -o profile.txt
```

---

### Quality Gates

#### Pre-Commit
- All unit tests pass (`⌘ + U`)
- No build warnings
- Code formatting (SwiftLint optional)

#### Pre-Merge
- CI passes (GitHub Actions)
- Code review approved
- UI tests pass (critical paths)

#### Pre-Release
- Manual QA on TestFlight
- Performance profiling (Instruments)
- Crash-free rate > 99.5%

---

## Prerequisites Checklist

> **IMPORTANT:** Complete ALL items below before starting iOS development to enable seamless end-to-end generation and testing.

### 1. Design Assets Required

| Asset | Format | Description | Status |
|-------|--------|-------------|--------|
| App Icon | 1024x1024 PNG | Main app icon for App Store | ⏳ Needed |
| `logo_s.png` | PNG | Destiny logo from mockup | ✅ Available in `/static/` |
| Splash Background | PNG/Asset | Watercolor texture | ⏳ Export from mockup |
| Onboarding Images | PNG | 4 slide backgrounds (if needed) | ❌ Optional |
| Tab Bar Icons | SF Symbol names | Home, Heart icons | ✅ Use SF Symbols |
| Color Palette | Hex codes | Navy `#1a1a2e`, Gold `#DAA520`, etc. | ✅ From mockup CSS |

**Action Required:**
```
[ ] Export logo_s.png to ios_app/Assets.xcassets/
[ ] Define color set in Assets.xcassets (Navy, Gold, Background)
[ ] Prepare App Icon (1024x1024)
```

### 2. API Configuration ✅ VERIFIED

| Item | Value | Notes |
|------|-------|-------|
| Base URL (Local Dev) | `http://localhost:8000` | ✅ Tested and working |
| Base URL (Production) | `https://astroapi-v2-668639087682.asia-south1.run.app` | Requires valid API key |
| API Version Prefix | None for local, `/api/v1/` for production | |
| Content-Type | `application/json` | Required header |
| Authentication | Disabled for local dev | API key required for production |

**✅ API Health Check PASSED (Dec 23, 2025):**
```json
{
  "prediction_id": "pred_992d082304d3",
  "status": "completed",
  "confidence": 0.5,
  "execution_time_ms": 9559
}
```

**APIConfig.swift Template:**
```swift
struct APIConfig {
    // Use local for development, production for release
    #if DEBUG
    static let baseURL = "http://localhost:8000"
    static let apiVersion = ""
    #else
    static let baseURL = "https://astroapi-v2-668639087682.asia-south1.run.app"
    static let apiVersion = "/api/v1"
    #endif
    
    // Endpoints
    static let predict = "/vedic/api/predict/"
    static let predictStream = "/vedic/api/predict/stream"
    static let compatibility = "/vedic/api/compatibility/analyze"
    static let compatibilityStream = "/vedic/api/compatibility/analyze/stream"
    static let compatibilityFollowUp = "/vedic/api/compatibility/follow-up"
    static let chatHistory = "/chat-history"
    static let feedback = "/feedback/submit"
}
```




### 3. Test Data ✅ READY

**Valid API Key (Development):**
- **Key:** `astro_ios_G5iY3-1Z7ymE46hYwKTbK1bSz2x5Vn4BeymPOvyy3ic`
- **Key ID:** `C-YuKP6ppBPVnhJJuBRTiw`
- **Header:** `X-API-KEY: <key>`
- **Owner:** `prabhukushwaha@gmail.com`

**LLM Configuration (Server-Side):**
- **Provider:** OpenAI (gpt-4o-mini)
- **Status:** ✅ Configured in local database with user-provided key.
- **Verification:** Prediction API tested and working.

**Sample Birth Data for Testing:**
```json
{
  "dob": "1994-07-01",
  "time": "00:15",
  "latitude": 18.4386,
  "longitude": 79.1288,
  "city_of_birth": "Karimnagar",
  "ayanamsa": "lahiri",
  "house_system": "equal"
}
```

**Sample Queries to Test:**
| Query | Expected Area | Use Case |
|-------|---------------|----------|
| "When will I get married?" | marriage | Timing prediction |
| "How is my career in 2025?" | career | Year forecast |
| "Tell me about my health" | health | General question |
| "Am I compatible with this person?" | compatibility | Match test |

**Second Person for Compatibility Testing:**
```json
{
  "dob": "1996-04-20",
  "time": "04:45",
  "lat": 34.0522,
  "lon": -118.2437,
  "name": "Test Partner",
  "place": "Los Angeles"
}
```

### 4. Development Environment

| Requirement | Version | Status |
|-------------|---------|--------|
| Xcode | 15.0+ | ⏳ Verify |
| iOS Target | 17.0+ | ⏳ Set in project |
| Swift | 5.9+ | ✅ Bundled with Xcode |
| macOS | Sonoma 14.0+ | ⏳ Verify |
| Simulator | iPhone 15 Pro | ⏳ Download if needed |

**Xcode Project Settings:**
```
[ ] Set Deployment Target: iOS 17.0
[ ] Set Bundle Identifier: com.destinyai.ios
[ ] Enable SwiftData capability
[ ] Add Apple Sign In capability (later)
```

### 5. Dependencies (None Required for MVP)

The app uses **native Swift/SwiftUI only** for MVP:
- URLSession for networking (no Alamofire)
- SwiftData for local storage (no CoreData/Realm)
- Native SwiftUI animations (no Lottie for MVP)

**Optional (Add Later):**
| Library | Purpose | When to Add |
|---------|---------|-------------|
| EventSource | SSE streaming | If enabling streaming |
| Lottie | Advanced animations | Post-MVP polish |
| KeychainAccess | Secure storage | When adding auth tokens |

### 6. Testing Requirements

**Simulator Testing:**
```
[ ] iPhone 15 Pro simulator available
[ ] Network connectivity to production API
[ ] API returns successful responses (test with curl first)
```

**API Health Check (Run Before Development):**
```bash
# Test Prediction API
curl -X POST "https://astroapi-v2-668639087682.asia-south1.run.app/api/v1/vedic/api/predict/" \
  -H "Content-Type: application/json" \
  -d '{
    "query": "How is my career?",
    "birth_data": {
      "dob": "1994-07-01",
      "time": "00:15",
      "latitude": 18.4386,
      "longitude": 79.1288
    },
    "include_reasoning_trace": false,
    "platform": "ios"
  }'
```

**Expected Response:** JSON with `prediction_id`, `answer`, `confidence`, etc.

### 7. User Defaults Keys (Define Upfront)

| Key | Type | Purpose |
|-----|------|---------|
| `hasSeenOnboarding` | Bool | Skip onboarding for returning users |
| `isLoggedIn` | Bool | Auth state |
| `userEmail` | String | For API calls |
| `savedBirthData` | Data (JSON) | User's birth details |
| `currentSessionId` | String | For follow-up queries |

### 8. SwiftData Models (Define Schema)

```swift
// User.swift - SwiftData @Model
@Model
final class User {
    var email: String
    var name: String?
    var dob: String
    var birthTime: String
    var latitude: Double
    var longitude: Double
    var cityOfBirth: String?
    var createdAt: Date
    
    init(email: String, dob: String, birthTime: String, latitude: Double, longitude: Double) {
        self.email = email
        self.dob = dob
        self.birthTime = birthTime
        self.latitude = latitude
        self.longitude = longitude
        self.createdAt = Date()
    }
}
```

### 9. Files to Create (Initial Setup)

**Before Phase 1 can begin, create these folders:**
```bash
# Run from ios_app/ios_app/
mkdir Models Services ViewModels Views Components
mkdir Views/Splash Views/Onboarding Views/Auth Views/Home
mkdir Views/Chat Views/Compatibility Views/History Views/Profile
```

**Files to create immediately:**
| File | Path | Purpose |
|------|------|---------|
| `APIConfig.swift` | Services/ | API endpoints |
| `BirthData.swift` | Models/ | Birth data Codable |
| `User.swift` | Models/ | SwiftData model |
| `AppRootView.swift` | Views/ | Navigation root |

---

## Pre-Development Verification Checklist

Before starting implementation, confirm:

```
[ ] Xcode 15+ installed and working
[ ] iOS 17 simulator downloaded
[ ] API health check curl command returns valid JSON
[ ] logo_s.png copied to Assets.xcassets
[ ] Color palette defined in Assets.xcassets
[ ] Folder structure created (Models/, Services/, etc.)
[ ] Bundle identifier set in Xcode project
[ ] This implementation plan reviewed and approved
```

Once ALL items above are checked, proceed to **Phase 1: Foundation**.

---

## Complete API Endpoints Reference

> **Base URL:** `https://astroapi-v2-668639087682.asia-south1.run.app`

### Prediction API
| Method | Full URL | Description |
|--------|----------|-------------|
| `POST` | `https://astroapi-v2-668639087682.asia-south1.run.app/api/v1/vedic/api/predict/` | Synchronous JSON (waits for complete response) |
| `POST` | `https://astroapi-v2-668639087682.asia-south1.run.app/api/v1/vedic/api/predict/stream` | SSE streaming (real-time step-by-step updates) |

### Compatibility API
| Method | Full URL | Description |
|--------|----------|-------------|
| `POST` | `https://astroapi-v2-668639087682.asia-south1.run.app/api/v1/vedic/api/compatibility/analyze` | Synchronous analysis |
| `POST` | `https://astroapi-v2-668639087682.asia-south1.run.app/api/v1/vedic/api/compatibility/analyze/stream` | SSE streaming analysis |
| `POST` | `https://astroapi-v2-668639087682.asia-south1.run.app/api/v1/vedic/api/compatibility/follow-up` | Follow-up questions |

### Chat History API
| Method | Full URL | Description |
|--------|----------|-------------|
| `GET` | `.../api/v1/chat-history/threads/{user_id}` | List user's threads |
| `POST` | `.../api/v1/chat-history/threads/{user_id}` | Create new thread |
| `GET` | `.../api/v1/chat-history/threads/{user_id}/{thread_id}` | Get thread with messages |
| `DELETE` | `.../api/v1/chat-history/threads/{user_id}/{thread_id}` | Delete thread |
| `GET` | `.../api/v1/chat-history/search/{user_id}?q=...` | Search history |

### Feedback API
| Method | Full URL | Description |
|--------|----------|-------------|
| `POST` | `https://astroapi-v2-668639087682.asia-south1.run.app/api/v1/feedback/submit` | Submit rating |

---

## Streaming vs Non-Streaming Usage Guide

### Option 1: Non-Streaming (Simpler Implementation)
**Endpoint:** `POST /api/v1/vedic/api/predict/`

**Pros:** Easier to implement, single response
**Cons:** User waits 3-10 seconds with no feedback

```swift
// Non-streaming call
let response = try await predictionService.predict(request)
// Display response.answer directly
```

### Option 2: Streaming (Better UX)
**Endpoint:** `POST /api/v1/vedic/api/predict/stream`

**Pros:** Real-time "thinking" animation, better perceived performance
**Cons:** Requires SSE client implementation

```swift
// Streaming call
for try await event in predictionService.predictStream(request) {
    switch event.type {
    case "thought": showThinkingStep(event.content)
    case "action": showToolCall(event.tool)
    case "final_answer": displayAnswer(event.content)
    }
}
```

> **DECISION POINT:** Start with non-streaming for MVP. Add streaming later for enhanced UX.

---

## Reasoning Trace Toggle

Control whether AI reasoning steps are included in responses:

### With Reasoning Steps (Default)
```json
{
  "query": "When will I get married?",
  "birth_data": {...},
  "include_reasoning_trace": true  // ← Include CoT steps
}
```
**Response includes:** `reasoning_trace` object with step-by-step analysis
**UI:** Show collapsible "How I analyzed this" section

### Without Reasoning Steps (Faster, Smaller Response)
```json
{
  "query": "When will I get married?",
  "birth_data": {...},
  "include_reasoning_trace": false  // ← Skip CoT steps
}
```
**Response:** Only `answer` field, no `reasoning_trace`
**UI:** Just show the answer bubble

> **RECOMMENDATION:** Use `include_reasoning_trace: false` for MVP to reduce response size. Enable later if users want to see AI thinking process.

---

## API 1: Prediction API

### Endpoint Details

| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/api/v1/vedic/api/predict/` | Synchronous JSON prediction |
| `POST` | `/api/v1/vedic/api/predict/stream` | Real-time SSE streaming |
| `GET` | `/api/v1/vedic/api/predict/session/{id}` | Get conversation history |

### Request Schema: `PredictionRequest`

```json
{
  "query": "When will I get married?",
  "birth_data": {
    "dob": "1994-07-01",
    "time": "00:15",
    "latitude": 18.4386,
    "longitude": 79.1288,
    "city_of_birth": "Karimnagar",
    "ayanamsa": "lahiri",
    "house_system": "equal"
  },
  "session_id": "sess_abc123",
  "conversation_id": "conv_xyz789",
  "user_email": "user@example.com",
  "mode": "recommended",
  "include_reasoning_trace": true,
  "include_chart_data": false,
  "language": "en",
  "platform": "ios",
  "architecture": "experts"
}
```

#### Field Descriptions

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `query` | string | ✅ | User's astrology question (3-1000 chars) |
| `birth_data` | object | ✅ (first call) | Birth details for chart calculation |
| `birth_data.dob` | string | ✅ | Date of birth `YYYY-MM-DD` format |
| `birth_data.time` | string | ✅ | Time of birth `HH:MM` format (24hr) |
| `birth_data.latitude` | float | ✅ | Birth place latitude (-90 to 90) |
| `birth_data.longitude` | float | ✅ | Birth place longitude (-180 to 180) |
| `birth_data.city_of_birth` | string | ❌ | City name (optional) |
| `birth_data.ayanamsa` | enum | ❌ | `lahiri` (default), `raman`, `kp` |
| `birth_data.house_system` | enum | ❌ | `equal` (default), `placidus`, `whole_sign` |
| `session_id` | string | ❌ | Session ID for follow-ups (auto-generated if omitted) |
| `conversation_id` | string | ❌ | Conversation thread ID |
| `user_email` | string | ❌ | User email for history tracking |
| `mode` | enum | ❌ | `quick`, `recommended` (default), `deep` |
| `include_reasoning_trace` | bool | ❌ | Include CoT steps (default: true) |
| `platform` | string | ❌ | `ios`, `android`, `web` |
| `architecture` | string | ❌ | `react` (sequential) or `experts` (parallel council) |

### Response Schema: `PredictionResponse`

```json
{
  "prediction_id": "pred_abc123def456",
  "session_id": "sess_abc123",
  "conversation_id": "conv_xyz789",
  "status": "completed",
  "answer": "Based on your 7th house analysis with Venus in Cancer...",
  "answer_summary": "Marriage prospects strong in 2025-2026...",
  "timing": {
    "period": "March 2025 - August 2025",
    "dasha": "Jupiter-Venus",
    "transit": "Jupiter in 7th house",
    "confidence": "HIGH"
  },
  "confidence": 0.78,
  "confidence_label": "HIGH",
  "supporting_factors": [
    "Venus in own sign (Cancer navamsha)",
    "7th lord Moon well-placed in 11th",
    "Jupiter transiting 7th house in 2025"
  ],
  "challenging_factors": [
    "Saturn aspecting 7th from 4th position"
  ],
  "reasoning_trace": {
    "trace_id": "pred_abc123def456",
    "status": "completed",
    "architecture": "react",
    "step_summary": "5 ReAct steps",
    "steps": [
      {
        "type": "thought",
        "step": 1,
        "content": "Analyzing 7th house for marriage timing..."
      },
      {
        "type": "action",
        "step": 2,
        "tool": "analyze_house",
        "args": {"house": 7}
      },
      {
        "type": "observation",
        "step": 3,
        "content": "7th house: Cancer, Lord: Moon in 11th..."
      }
    ]
  },
  "reasoning_summary": "Analyzed 7th house, dasha periods, and transits",
  "advice": "Focus on networking in early 2025",
  "sources": ["BPHS", "Jataka Parijata", "Brihat Parashara Hora Shastra"],
  "query": "When will I get married?",
  "life_area": "marriage",
  "sub_area": "timing",
  "ascendant": "Cancer",
  "planner_used": "experts",
  "execution_time_ms": 3542.5,
  "llm_calls": 3,
  "training_sample_id": null,
  "follow_up_suggestions": [
    "What qualities should I look for in a partner?",
    "Are there any doshas affecting my marriage?",
    "What remedies can improve my marriage prospects?"
  ],
  "created_at": "2024-01-15T10:30:00Z",
  "completed_at": "2024-01-15T10:30:03Z"
}
```

### Streaming Response (SSE Events)

For `/api/v1/vedic/api/predict/stream`:

```javascript
// Event types:
event: started
data: {"prediction_id": "pred_xxx", "session_id": "sess_xxx", "architecture": "react"}

event: thought
data: {"step": 1, "content": "Analyzing 7th house...", "display": "💭 Thinking..."}

event: action
data: {"step": 2, "tool": "analyze_house", "args": {"house": 7}, "display": "🔧 Calling analyze_house..."}

event: observation
data: {"step": 3, "content": "7th house: Cancer...", "char_count": 245, "display": "📊 Received data"}

event: final_answer
data: {"step": 5, "content": "Based on your chart...", "display": "✅ Analysis complete"}

event: done
data: {"prediction_id": "pred_xxx", "execution_time_ms": 3542.5}
```

### iOS Implementation Pattern

```swift
// MARK: - Models
struct BirthData: Codable {
    let dob: String           // "YYYY-MM-DD"
    let time: String          // "HH:MM"
    let latitude: Double
    let longitude: Double
    var cityOfBirth: String?
    var ayanamsa: String = "lahiri"
    var houseSystem: String = "equal"
    
    enum CodingKeys: String, CodingKey {
        case dob, time, latitude, longitude
        case cityOfBirth = "city_of_birth"
        case ayanamsa, houseSystem = "house_system"
    }
}

struct PredictionRequest: Codable {
    let query: String
    let birthData: BirthData
    var sessionId: String?
    var conversationId: String?
    var userEmail: String?
    var includeReasoningTrace: Bool = true
    var platform: String = "ios"
    
    enum CodingKeys: String, CodingKey {
        case query
        case birthData = "birth_data"
        case sessionId = "session_id"
        case conversationId = "conversation_id"
        case userEmail = "user_email"
        case includeReasoningTrace = "include_reasoning_trace"
        case platform
    }
}

struct PredictionResponse: Codable {
    let predictionId: String
    let sessionId: String
    let conversationId: String
    let status: String
    let answer: String
    let answerSummary: String?
    let timing: TimingPrediction?
    let confidence: Double
    let confidenceLabel: String
    let supportingFactors: [String]
    let challengingFactors: [String]
    let reasoningTrace: ReasoningTrace?
    let followUpSuggestions: [String]
    let lifeArea: String
    let executionTimeMs: Double
    
    enum CodingKeys: String, CodingKey {
        case predictionId = "prediction_id"
        case sessionId = "session_id"
        case conversationId = "conversation_id"
        case status, answer
        case answerSummary = "answer_summary"
        case timing, confidence
        case confidenceLabel = "confidence_label"
        case supportingFactors = "supporting_factors"
        case challengingFactors = "challenging_factors"
        case reasoningTrace = "reasoning_trace"
        case followUpSuggestions = "follow_up_suggestions"
        case lifeArea = "life_area"
        case executionTimeMs = "execution_time_ms"
    }
}

// MARK: - Service
class PredictionService {
    private let baseURL = "https://astroapi-v2-668639087682.asia-south1.run.app"
    
    func predict(request: PredictionRequest) async throws -> PredictionResponse {
        let url = URL(string: "\(baseURL)/api/v1/vedic/api/predict/")!
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = try JSONEncoder().encode(request)
        
        let (data, _) = try await URLSession.shared.data(for: urlRequest)
        return try JSONDecoder().decode(PredictionResponse.self, from: data)
    }
    
    func predictStream(request: PredictionRequest) -> AsyncThrowingStream<StreamEvent, Error> {
        // SSE streaming implementation
        AsyncThrowingStream { continuation in
            // EventSource-like implementation
        }
    }
}
```

### Usage Flow (Mockup Integration)

1. **Chat Screen "Send" Button** → Call `POST /api/v1/vedic/api/predict/`
2. **Display "Thinking..." UI** → Use SSE events for real-time updates
3. **Show Response** → Parse `answer` for main bubble, `reasoning_trace` for collapsible section
4. **Store IDs** → Save `session_id` and `conversation_id` for follow-ups
5. **Show Suggestions** → Display `follow_up_suggestions` as quick reply chips

---

## API 2: Compatibility API

### Endpoint Details

| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/api/v1/vedic/api/compatibility/analyze` | Synchronous analysis |
| `POST` | `/api/v1/vedic/api/compatibility/analyze/stream` | Real-time SSE streaming |
| `POST` | `/api/v1/vedic/api/compatibility/follow-up` | Follow-up questions |

### Request Schema: `CompatibilityRequest`

```json
{
  "boy": {
    "dob": "1994-07-01",
    "time": "00:15",
    "lat": 18.4386,
    "lon": 79.1288,
    "name": "Vamshi",
    "place": "Karimnagar"
  },
  "girl": {
    "dob": "1996-04-20",
    "time": "04:45",
    "lat": 34.0522,
    "lon": -118.2437,
    "name": "Swathi",
    "place": "Los Angeles"
  },
  "session_id": "sess_match_abc123",
  "conversation_id": "conv_match_xyz789",
  "user_email": "user@example.com"
}
```

#### Field Descriptions

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `boy` | object | ✅ | Boy's birth details |
| `girl` | object | ✅ | Girl's birth details |
| `boy.dob` / `girl.dob` | string | ✅ | Date of birth `YYYY-MM-DD` |
| `boy.time` / `girl.time` | string | ✅ | Time of birth `HH:MM` (24hr) |
| `boy.lat` / `girl.lat` | float | ✅ | Latitude (-90 to 90) |
| `boy.lon` / `girl.lon` | float | ✅ | Longitude (-180 to 180) |
| `boy.name` / `girl.name` | string | ❌ | Name (default: "Native") |
| `boy.place` / `girl.place` | string | ❌ | Place name (default: "Unknown") |
| `session_id` | string | ❌ | Session ID for caching (5-min TTL) |
| `conversation_id` | string | ❌ | Conversation ID for follow-ups |
| `user_email` | string | ❌ | User email for tracking |

### Response Schema (Expected Structure)

```json
{
  "session_id": "sess_match_abc123",
  "conversation_id": "conv_match_xyz789",
  "status": "completed",
  
  "ashtakoot": {
    "total_score": 28,
    "max_score": 36,
    "percentage": 77.8,
    "verdict": "Excellent Match",
    "kutas": [
      {"name": "Varna", "score": 1, "max": 1, "description": "Social compatibility"},
      {"name": "Vashya", "score": 2, "max": 2, "description": "Mutual attraction"},
      {"name": "Tara", "score": 3, "max": 3, "description": "Destiny compatibility"},
      {"name": "Yoni", "score": 4, "max": 4, "description": "Physical compatibility"},
      {"name": "Graha Maitri", "score": 5, "max": 5, "description": "Mental compatibility"},
      {"name": "Gana", "score": 6, "max": 6, "description": "Temperament"},
      {"name": "Bhakoot", "score": 0, "max": 7, "description": "Family welfare"},
      {"name": "Nadi", "score": 8, "max": 8, "description": "Health of progeny"}
    ]
  },
  
  "mangal_dosha": {
    "boy": {"has_dosha": false, "severity": "none", "houses": []},
    "girl": {"has_dosha": true, "severity": "mild", "houses": [1, 4]},
    "compatibility": "Compatible - Girl's mild dosha cancelled by boy's chart"
  },
  
  "individual_data": {
    "boy": {
      "name": "Vamshi",
      "moon_sign": "Aquarius",
      "ascendant": "Cancer",
      "nakshatra": "Shatabhisha"
    },
    "girl": {
      "name": "Swathi",
      "moon_sign": "Virgo",
      "ascendant": "Pisces",
      "nakshatra": "Hasta"
    }
  },
  
  "ai_interpretation": "Based on the Ashtakoot analysis, this is an excellent match...",
  "recommendations": [
    "Consider performing Nadi dosha parihara if concerned",
    "Favorable muhurta periods: March-May 2025"
  ],
  
  "execution_time_ms": 2845.3
}
```

### Follow-up Request Schema

```json
{
  "query": "Tell me more about Bhakoot dosha",
  "session_id": "sess_match_abc123",
  "user_email": "user@example.com"
}
```

### iOS Implementation Pattern

```swift
struct BirthDetails: Codable {
    let dob: String
    let time: String
    let lat: Double
    let lon: Double
    var name: String = "Native"
    var place: String = "Unknown"
}

struct CompatibilityRequest: Codable {
    let boy: BirthDetails
    let girl: BirthDetails
    var sessionId: String?
    var conversationId: String?
    var userEmail: String?
    
    enum CodingKeys: String, CodingKey {
        case boy, girl
        case sessionId = "session_id"
        case conversationId = "conversation_id"
        case userEmail = "user_email"
    }
}

struct AshtakootResult: Codable {
    let totalScore: Int
    let maxScore: Int
    let percentage: Double
    let verdict: String
    let kutas: [KutaScore]
    
    enum CodingKeys: String, CodingKey {
        case totalScore = "total_score"
        case maxScore = "max_score"
        case percentage, verdict, kutas
    }
}

class CompatibilityService {
    private let baseURL = "https://astroapi-v2-668639087682.asia-south1.run.app"
    
    func analyze(request: CompatibilityRequest) async throws -> CompatibilityResponse {
        let url = URL(string: "\(baseURL)/api/v1/vedic/api/compatibility/analyze")!
        // ... similar to PredictionService
    }
    
    func followUp(query: String, sessionId: String, userEmail: String) async throws -> FollowUpResponse {
        let url = URL(string: "\(baseURL)/api/v1/vedic/api/compatibility/follow-up")!
        // ...
    }
}
```

### Usage Flow (Mockup Integration)

1. **Match Screen "Analyze" Button** → Collect boy/girl birth data → Call `POST /analyze`
2. **Display Score Circle** → Show `ashtakoot.total_score` / `ashtakoot.max_score`
3. **Show Kuta Grid** → Render each kuta with score bar
4. **AI Interpretation** → Display `ai_interpretation` in chat bubble
5. **Follow-up Chat** → User asks questions → Call `POST /follow-up` with saved `session_id`

---

## API 3: Chat History API

### Endpoint Details

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/v1/chat-history/threads/{user_id}` | List user's threads |
| `POST` | `/api/v1/chat-history/threads/{user_id}` | Create new thread |
| `GET` | `/api/v1/chat-history/threads/{user_id}/{thread_id}` | Get thread with messages |
| `PATCH` | `/api/v1/chat-history/threads/{user_id}/{thread_id}` | Update thread (rename, pin) |
| `DELETE` | `/api/v1/chat-history/threads/{user_id}/{thread_id}` | Delete thread |
| `POST` | `/api/v1/chat-history/threads/{user_id}/{thread_id}/messages` | Add message |
| `GET` | `/api/v1/chat-history/search/{user_id}?q=...` | Search history |
| `GET` | `/api/v1/chat-history/settings/{user_id}` | Get settings |
| `PUT` | `/api/v1/chat-history/settings/{user_id}` | Update settings |
| `DELETE` | `/api/v1/chat-history/all/{user_id}` | Delete all (GDPR) |

### List Threads Response

```json
{
  "threads": [...],
  "total_count": 15,
  "today": [
    {
      "id": "thread_abc123",
      "title": "Career guidance 2025",
      "preview": "Based on your 10th house...",
      "primary_area": "career",
      "message_count": 4,
      "is_pinned": false,
      "is_archived": false,
      "created_at": "2024-01-15T10:30:00Z",
      "updated_at": "2024-01-15T12:45:00Z",
      "date_group": "Today"
    }
  ],
  "yesterday": [...],
  "this_week": [...],
  "this_month": [...],
  "older": [...]
}
```

### Thread Detail Response

```json
{
  "id": "thread_abc123",
  "title": "Career guidance 2025",
  "preview": "Based on your 10th house...",
  "primary_area": "career",
  "message_count": 4,
  "is_pinned": false,
  "is_archived": false,
  "created_at": "2024-01-15T10:30:00Z",
  "updated_at": "2024-01-15T12:45:00Z",
  "messages": [
    {
      "id": "msg_001",
      "role": "user",
      "content": "How will my career be in 2025?",
      "area": "career",
      "confidence": null,
      "trace_id": null,
      "tool_calls": null,
      "sources": null,
      "created_at": "2024-01-15T10:30:00Z"
    },
    {
      "id": "msg_002",
      "role": "assistant",
      "content": "Based on your 10th house analysis...",
      "area": "career",
      "confidence": "HIGH",
      "trace_id": "pred_xyz789",
      "sources": ["BPHS", "Jataka Parijata"],
      "created_at": "2024-01-15T10:30:03Z"
    }
  ],
  "areas_discussed": ["career", "finance"],
  "has_birth_data": true
}
```

### Search Response

```json
{
  "query": "marriage",
  "results": [
    {
      "thread_id": "thread_def456",
      "thread_title": "Marriage prediction",
      "message_id": "msg_003",
      "message_preview": "Your 7th house suggests...",
      "role": "assistant",
      "area": "marriage",
      "created_at": "2024-01-14T15:20:00Z",
      "relevance_score": 0.95
    }
  ],
  "count": 3
}
```

### iOS Implementation Pattern

```swift
enum MessageRole: String, Codable {
    case user
    case assistant
    case system
}

struct ChatMessage: Codable, Identifiable {
    let id: String
    let role: MessageRole
    let content: String
    let area: String?
    let confidence: String?
    let traceId: String?
    let sources: [String]?
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id, role, content, area, confidence
        case traceId = "trace_id"
        case sources
        case createdAt = "created_at"
    }
}

struct ChatThread: Codable, Identifiable {
    let id: String
    let title: String?
    let preview: String?
    let primaryArea: String?
    let messageCount: Int
    let isPinned: Bool
    let isArchived: Bool
    let createdAt: Date
    let updatedAt: Date
    var messages: [ChatMessage]?
    
    enum CodingKeys: String, CodingKey {
        case id, title, preview
        case primaryArea = "primary_area"
        case messageCount = "message_count"
        case isPinned = "is_pinned"
        case isArchived = "is_archived"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case messages
    }
}

struct ThreadListResponse: Codable {
    let threads: [ChatThread]
    let totalCount: Int
    let today: [ChatThread]
    let yesterday: [ChatThread]
    let thisWeek: [ChatThread]
    let thisMonth: [ChatThread]
    let older: [ChatThread]
    
    enum CodingKeys: String, CodingKey {
        case threads
        case totalCount = "total_count"
        case today, yesterday
        case thisWeek = "this_week"
        case thisMonth = "this_month"
        case older
    }
}

class ChatHistoryService {
    private let baseURL = "https://astroapi-v2-668639087682.asia-south1.run.app"
    
    func listThreads(userId: String, limit: Int = 50) async throws -> ThreadListResponse {
        let url = URL(string: "\(baseURL)/api/v1/chat-history/threads/\(userId)?limit=\(limit)")!
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode(ThreadListResponse.self, from: data)
    }
    
    func getThread(userId: String, threadId: String) async throws -> ChatThread {
        let url = URL(string: "\(baseURL)/api/v1/chat-history/threads/\(userId)/\(threadId)")!
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode(ChatThread.self, from: data)
    }
    
    func deleteThread(userId: String, threadId: String) async throws {
        let url = URL(string: "\(baseURL)/api/v1/chat-history/threads/\(userId)/\(threadId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        _ = try await URLSession.shared.data(for: request)
    }
    
    func search(userId: String, query: String) async throws -> SearchResponse {
        let url = URL(string: "\(baseURL)/api/v1/chat-history/search/\(userId)?q=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)")!
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode(SearchResponse.self, from: data)
    }
}
```

### Usage Flow (Mockup Integration)

1. **History Screen Load** → Call `GET /threads/{user_id}`
2. **Display Grouped List** → Use `today`, `yesterday`, `this_week` arrays
3. **Tap Thread** → Call `GET /threads/{user_id}/{thread_id}` → Display messages
4. **Search Bar** → Call `GET /search/{user_id}?q=...`
5. **Swipe to Delete** → Call `DELETE /threads/{user_id}/{thread_id}`
6. **Pin Thread** → Call `PATCH /threads/{user_id}/{thread_id}` with `is_pinned: true`

---

## API 4: Feedback API

### Endpoint Details

| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/api/v1/feedback/submit` | Submit prediction feedback |

### Request Schema: `UnifiedFeedbackRequest`

```json
{
  "prediction_id": "pred_abc123",
  "session_id": "sess_xyz789",
  "conversation_id": "conv_def456",
  "user_email": "user@example.com",
  "query": "When will I get married?",
  "prediction_text": "Based on your 7th house analysis...",
  "area": "marriage",
  "sub_area": "timing",
  "ascendant": "Cancer",
  "system": "vedic",
  "rating": 4
}
```

#### Field Descriptions

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `prediction_id` | string | ❌ | Auto-generated if not provided |
| `session_id` | string | ❌ | From prediction response |
| `conversation_id` | string | ❌ | From prediction response |
| `user_email` | string | ❌ | User email |
| `query` | string | ✅ | Original user question |
| `prediction_text` | string | ✅ | Full prediction answer |
| `area` | string | ✅ | Life area (marriage, career, health, etc.) |
| `sub_area` | string | ❌ | Sub-area classification |
| `ascendant` | string | ❌ | User's ascendant sign |
| `system` | string | ❌ | `vedic` (default) |
| `rating` | int | ✅ | 1-5 rating (1=poor, 5=excellent) |

### Response Schema

```json
{
  "success": true,
  "prediction_id": "pred_abc123",
  "message": "Feedback recorded successfully"
}
```

### iOS Implementation Pattern

```swift
struct FeedbackRequest: Codable {
    var predictionId: String?
    var sessionId: String?
    var conversationId: String?
    var userEmail: String?
    let query: String
    let predictionText: String
    let area: String
    var subArea: String?
    var ascendant: String?
    var system: String = "vedic"
    let rating: Int
    
    enum CodingKeys: String, CodingKey {
        case predictionId = "prediction_id"
        case sessionId = "session_id"
        case conversationId = "conversation_id"
        case userEmail = "user_email"
        case query
        case predictionText = "prediction_text"
        case area
        case subArea = "sub_area"
        case ascendant, system, rating
    }
}

class FeedbackService {
    private let baseURL = "https://astroapi-v2-668639087682.asia-south1.run.app"
    
    func submit(feedback: FeedbackRequest) async throws -> FeedbackResponse {
        let url = URL(string: "\(baseURL)/api/v1/feedback/submit")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(feedback)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode(FeedbackResponse.self, from: data)
    }
}
```

### Usage Flow (Mockup Integration)

1. **Show 👍👎 Buttons** → On AI message bubble footer
2. **User Taps Rating** → Show 1-5 star modal (optional)
3. **Submit Feedback** → Call `POST /feedback/submit` with stored prediction data
4. **Show Confirmation** → "Thanks for your feedback!"

---

## Data Flow Summary

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                            iOS App Data Flow                                 │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  1. USER OPENS CHAT                                                          │
│     └─→ Load history: GET /chat-history/threads/{user_id}                   │
│                                                                              │
│  2. USER ASKS QUESTION                                                       │
│     └─→ POST /vedic/api/predict/stream                                      │
│         └─→ Stream SSE events → Update UI in real-time                      │
│         └─→ Store session_id, conversation_id                               │
│                                                                              │
│  3. AI RESPONDS                                                              │
│     └─→ Display answer from response                                        │
│     └─→ Show reasoning_trace in collapsible section                         │
│     └─→ Display follow_up_suggestions as chips                              │
│                                                                              │
│  4. USER RATES RESPONSE                                                      │
│     └─→ POST /feedback/submit with prediction_id + rating                   │
│                                                                              │
│  5. USER DOES MATCH                                                          │
│     └─→ POST /vedic/api/compatibility/analyze                               │
│         └─→ Display ashtakoot scores                                        │
│         └─→ Store session_id for follow-ups                                 │
│                                                                              │
│  6. USER VIEWS HISTORY                                                       │
│     └─→ GET /chat-history/threads/{user_id}                                 │
│     └─→ Tap thread → GET /chat-history/threads/{user_id}/{thread_id}       │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Error Handling

All APIs return standard error format:

```json
{
  "detail": {
    "code": "SECURITY_BLOCKED",
    "message": "Query contains prohibited content",
    "layer": "guard"
  }
}
```

Or simple string:

```json
{
  "detail": "birth_data is required"
}
```

### Common Error Codes

| Code | HTTP Status | Description |
|------|-------------|-------------|
| `SECURITY_BLOCKED` | 400 | Query blocked by security layer |
| `INVALID_BIRTH_DATA` | 400 | Invalid date/time format |
| `SESSION_NOT_FOUND` | 404 | Invalid session_id |
| `RATE_LIMIT_EXCEEDED` | 429 | Too many requests |
| `INTERNAL_ERROR` | 500 | Server error |

---

## iOS Project Structure (Aligned with Existing Xcode Project)

Based on existing project at `/ios_app/`:

```
ios_app/
├── ios_app.xcodeproj/         # Xcode project file
├── ios_app/                   # Main app source
│   ├── ios_appApp.swift       # App entry point (existing)
│   ├── ContentView.swift      # Main view (replace with AppRootView)
│   ├── Item.swift             # SwiftData model (remove/replace)
│   │
│   ├── Models/                # [NEW] Data models
│   │   ├── BirthData.swift
│   │   ├── User.swift
│   │   ├── Prediction.swift
│   │   ├── Compatibility.swift
│   │   ├── ChatThread.swift
│   │   └── ChatMessage.swift
│   │
│   ├── Services/              # [NEW] API services
│   │   ├── APIConfig.swift        # Base URL, headers
│   │   ├── PredictionService.swift
│   │   ├── CompatibilityService.swift
│   │   ├── ChatHistoryService.swift
│   │   └── FeedbackService.swift
│   │
│   ├── ViewModels/            # [NEW] ObservableObjects
│   │   ├── AppState.swift         # Global app state
│   │   ├── AuthViewModel.swift
│   │   ├── ChatViewModel.swift
│   │   ├── CompatibilityViewModel.swift
│   │   └── HistoryViewModel.swift
│   │
│   ├── Views/                 # [NEW] SwiftUI views by screen
│   │   ├── AppRootView.swift      # Navigation root
│   │   ├── Splash/
│   │   │   └── SplashView.swift
│   │   ├── Onboarding/
│   │   │   ├── OnboardingView.swift
│   │   │   └── OnboardingSlide.swift
│   │   ├── Auth/
│   │   │   ├── AuthView.swift
│   │   │   └── BirthDataView.swift
│   │   ├── Home/
│   │   │   └── HomeView.swift
│   │   ├── Chat/
│   │   │   ├── ChatView.swift
│   │   │   └── MessageBubble.swift
│   │   ├── Compatibility/
│   │   │   ├── CompatibilityView.swift
│   │   │   └── AshtakootGrid.swift
│   │   ├── History/
│   │   │   └── HistoryView.swift
│   │   └── Profile/
│   │       └── ProfileView.swift
│   │
│   ├── Components/            # [NEW] Reusable UI
│   │   ├── TabBar.swift
│   │   ├── PrimaryButton.swift
│   │   └── LoadingView.swift
│   │
│   └── Assets.xcassets/       # Images, colors (existing)
│
├── ios_appTests/              # Unit tests (existing)
└── ios_appUITests/            # UI tests (existing)
```

---

## Step-by-Step Implementation Plan (By Screen)

### Phase 1: Foundation (Week 1)

#### Step 1.1: Project Setup
- [ ] Create folder structure (Models/, Services/, ViewModels/, Views/)
- [ ] Add `APIConfig.swift` with base URL constant
- [ ] Remove default `Item.swift` model
- [ ] Replace `ContentView.swift` with `AppRootView.swift`

#### Step 1.2: Create Data Models
- [ ] `BirthData.swift` - User birth details (Codable)
- [ ] `User.swift` - User profile (SwiftData @Model)
- [ ] `Prediction.swift` - API response model
- [ ] Add `CodingKeys` for snake_case ↔ camelCase

#### Step 1.3: Create API Services
- [ ] `PredictionService.swift` - POST to `/predict/`
- [ ] Test with hardcoded birth data

---

### Phase 2: Splash & Onboarding (Week 1-2)

#### Step 2.1: Splash Screen
**Matches Mockup: Screen 1**
- [ ] `SplashView.swift` - Logo + loading animation
- [ ] 2-second timer then auto-navigate
- [ ] Check if returning user → skip to Home

#### Step 2.2: Onboarding Carousel
**Matches Mockup: Screen 2 (4 slides)**
- [ ] `OnboardingView.swift` - TabView with 4 slides
- [ ] Slide 1: ChatGPT Store badge
- [ ] Slide 2: What is Destiny
- [ ] Slide 3: How it works
- [ ] Slide 4: Features list + "Get started" button
- [ ] Skip button on slides 1-3
- [ ] Persist `hasSeenOnboarding` in UserDefaults

---

### Phase 3: Authentication (Week 2)

#### Step 3.1: Auth Screen
**Matches Mockup: Screen 3**
- [ ] `AuthView.swift` - Sign in options
- [ ] Apple Sign In button (AuthenticationServices)
- [ ] Google Sign In button (placeholder)
- [ ] "Continue as Guest" button
- [ ] Terms and Privacy links

#### Step 3.2: Birth Data Screen
**Matches Mockup: Screen 4**
- [ ] `BirthDataView.swift` - Form for birth details
- [ ] Date picker for DOB
- [ ] Time picker for birth time
- [ ] Location search with autocomplete
- [ ] Gender picker
- [ ] Save to SwiftData + UserDefaults

---

### Phase 4: Main Experience (Week 2-3)

#### Step 4.1: Tab Bar
- [ ] `TabBar.swift` - 3 items (Home, Ask pill, Match)
- [ ] Pill-style center "Ask" button
- [ ] Active/inactive states

#### Step 4.2: Home Screen
**Matches Mockup: Screen 5**
- [ ] `HomeView.swift` - Main dashboard
- [ ] Header with menu/profile icons
- [ ] Greeting with user name
- [ ] Quota progress bar (7/10 questions)
- [ ] Daily insight card
- [ ] Clickable prompt card → Chat
- [ ] Animated planet orbits (Lottie or SwiftUI)

#### Step 4.3: Chat Screen
**Matches Mockup: Screen 6**
- [ ] `ChatView.swift` - Conversation interface
- [ ] `ChatViewModel.swift` - Manages messages
- [ ] API call: `POST /predict/` with `include_reasoning_trace: false`
- [ ] User message bubble (right-aligned, gold)
- [ ] AI message bubble (left-aligned, white)
- [ ] Input field with send button
- [ ] Loading state with "Analyzing..." text
- [ ] Follow-up suggestion chips

**API Integration:**
```swift
let request = PredictionRequest(
    query: userInput,
    birthData: savedBirthData,
    sessionId: currentSessionId,
    includeReasoningTrace: false,  // Simpler for MVP
    platform: "ios"
)
let response = try await predictionService.predict(request)
messages.append(Message(role: .assistant, content: response.answer))
```

---

### Phase 5: Compatibility (Week 3)

#### Step 5.1: Compatibility Input
**Matches Mockup: Screen 7**
- [ ] `CompatibilityView.swift` - Two-person form
- [ ] Tab selector: Boy Details / Girl Details
- [ ] Name, DOB, Time, Place fields for each
- [ ] "Analyze Match" button

#### Step 5.2: Compatibility Results
**Matches Mockup: Screen 7 (Result View)**
- [ ] Score circle (28/36)
- [ ] `AshtakootGrid.swift` - 8 kuta scores
- [ ] AI interpretation chat area
- [ ] Follow-up input field

**API Integration:**
```swift
let request = CompatibilityRequest(
    boy: boyDetails,
    girl: girlDetails,
    userEmail: currentUser.email
)
let response = try await compatibilityService.analyze(request)
// Display response.ashtakoot.totalScore
```

---

### Phase 6: History & Profile (Week 4)

#### Step 6.1: History Screen
**Matches Mockup: Screen 8**
- [ ] `HistoryView.swift` - Thread list
- [ ] API call: `GET /chat-history/threads/{userId}`
- [ ] Group by: Today, Yesterday, This Week, Older
- [ ] Thread preview with icon + title + time
- [ ] Swipe to delete
- [ ] Tap to open full conversation

#### Step 6.2: Profile Screen
**Matches Mockup: Screen 10**
- [ ] `ProfileView.swift` - User settings
- [ ] Avatar with crown badge
- [ ] Birth details section (editable)
- [ ] Preferences: Astrology System, Language
- [ ] Support: Help/FAQ, Sign Out

#### Step 6.3: Subscription Screen
**Matches Mockup: Screen 11**
- [ ] `SubscriptionView.swift` - Premium upsell
- [ ] Price card ($4.99/month)
- [ ] Feature checkmarks
- [ ] "Subscribe Now" button
- [ ] StoreKit 2 integration (later)

---

### Phase 7: Feedback & Polish (Week 4)

#### Step 7.1: Feedback Integration
- [ ] Add 👍👎 buttons on AI messages
- [ ] On tap: POST to `/feedback/submit`
- [ ] Show "Thanks!" confirmation

#### Step 7.2: Charts Screen
**Matches Mockup: Screen 9**
- [ ] `ChartsView.swift` - Planetary positions
- [ ] Planet rows with sign + degree + nakshatra

#### Step 7.3: Error Handling
- [ ] Network error alerts
- [ ] Retry buttons
- [ ] Offline mode indicator

---

## Verification Plan

### Automated Tests
- [ ] Unit tests for API request encoding
- [ ] Unit tests for CodingKeys mapping
- [ ] Mock response parsing tests

### Manual Verification
1. **Full Flow:** Splash → Onboarding → Auth → Birth Data → Home
2. **Chat Flow:** Ask question → See response → Rate it
3. **Match Flow:** Enter two people → See Ashtakoot scores
4. **History Flow:** View past threads → Tap to open
