# iOS App Views & Sheets Reference

> Complete list of user-visible screens and sheets in the Destiny AI Astrology iOS app.

---

## 📱 Main Navigation

| View | File | Description |
|------|------|-------------|
| **App Root** | `AppRootView.swift` | Root container, handles auth state routing |
| **Main Tab View** | `MainTabView.swift` | Bottom tab navigation (Home, Chat, Compatibility, Profile) |
| **Splash** | `SplashView.swift` | Launch animation screen |

---

## 🔐 Authentication & Onboarding

| View | File | Description |
|------|------|-------------|
| **Auth View** | `Auth/AuthView.swift` | Sign in with Google/Apple |
| **Birth Data Entry** | `Auth/BirthDataView.swift` | Initial birth data collection during auth |
| **Onboarding** | `Onboarding/OnboardingView.swift` | Welcome carousel slides |
| **Onboarding Slide** | `Onboarding/OnboardingSlideView.swift` | Individual carousel slide |
| **Language Selection** | `Onboarding/LanguageSelectionView.swift` | Language picker during onboarding |
| **Profile Setup Loading** | `Onboarding/ProfileSetupLoadingView.swift` | Loading state during profile creation |

---

## 🏠 Home

| View | File | Description |
|------|------|-------------|
| **Home View** | `Home/HomeView.swift` | Dashboard with daily insight, quick actions |
| **Life Area Questions Sheet** | `Home/LifeAreaQuestionsSheet.swift` | Pre-built questions by life area |

---

## 💬 Chat

| View | File | Description |
|------|------|-------------|
| **Chat View** | `Chat/ChatView.swift` | AI astrologer chat interface |

### Chat Components
- `ChatInputBar.swift` - Message input field
- `MessageBubble.swift` - Chat message bubbles
- `MarkdownTextView.swift` - Rendered markdown content
- `ThinkingProgressView.swift` - "Analyzing your chart..." animation
- `TypingIndicator.swift` - Typing dots animation
- `MessageRating.swift` - Response rating widget

---

## ❤️ Compatibility

| View | File | Description |
|------|------|-------------|
| **Compatibility View** | `Compatibility/CompatibilityView.swift` | Enter partner details form |
| **Compatibility Result** | `Compatibility/CompatibilityResultView.swift` | Match analysis results + follow-up chat |
| **Streaming View** | `Compatibility/CompatibilityStreamingView.swift` | Live analysis progress |
| **Match History Sheet** | `Compatibility/CompatibilityHistorySheet.swift` | Previous compatibility matches |

### Compatibility Detail Sheets
| Sheet | File | Description |
|-------|------|-------------|
| **Mangal Dosha** | `Sheets/MangalDoshaSheet.swift` | Mars affliction details |
| **Kalsarpa Dosha** | `Sheets/KalsarpaDoshaSheet.swift` | Kalsarpa yoga details |
| **Additional Yogas** | `Sheets/AdditionalYogasSheet.swift` | Extended yoga analysis |

---

## 📊 Charts

| View | File | Description |
|------|------|-------------|
| **North Indian Chart** | `Charts/NorthIndianChartView.swift` | Diamond-style chart |
| **South Indian Chart** | `Charts/SouthIndianChartView.swift` | Square-style chart |
| **Dasha View** | `Charts/DashaView.swift` | Planetary periods timeline |
| **Transits View** | `Charts/TransitsView.swift` | Current transits overlay |
| **Planetary Positions Sheet** | `Charts/PlanetaryPositionsSheet.swift` | Table of planet positions |
| **Chart Comparison Sheet** | `Charts/ChartComparisonSheet.swift` | Side-by-side chart view |

---

## 👤 Profile & Settings

| View | File | Description |
|------|------|-------------|
| **Profile View** | `Profile/ProfileView.swift` | User profile with settings access |
| **Birth Details View** | `Profile/BirthDetailsView.swift` | Edit birth data form |

### Settings Sheets
| Sheet | File | Description |
|-------|------|-------------|
| **Astrology Settings** | `Settings/AstrologySettingsSheet.swift` | Ayanamsa, house system options |
| **Chart Style Picker** | `Settings/ChartStylePickerSheet.swift` | North/South Indian style toggle |
| **Language Settings** | `Settings/LanguageSettingsSheet.swift` | App language selector |

---

## 💳 Subscription

| View | File | Description |
|------|------|-------------|
| **Subscription View** | `Subscription/SubscriptionView.swift` | Paywall with plan selection |
| **Quota Exhausted View** | `Components/QuotaExhaustedView.swift` | Upgrade prompt (bottom sheet) |

---

## 📂 History

| View | File | Description |
|------|------|-------------|
| **History View** | `History/HistoryView.swift` | Chat history sidebar |

---

## 🧩 Shared Components

| Component | File | Description |
|-----------|------|-------------|
| **App Header** | `Components/AppHeader.swift` | Navigation header bar |
| **Cosmic Background** | `Components/CosmicBackground.swift` | Animated stars background |
| **Location Search** | `Components/LocationSearchView.swift` | City/location autocomplete |
| **Insight Card** | `Components/Home/InsightCard.swift` | Daily insight card |
| **Quota Widget** | `Components/Home/QuotaWidget.swift` | Remaining questions indicator |
| **Suggested Questions** | `Components/Home/SuggestedQuestions.swift` | Quick question chips |
| **Score Circle** | `Components/Compatibility/ScoreCircle.swift` | Animated match score |

---

## Summary

| Category | Count |
|----------|-------|
| Main Views | 22 |
| Sheets | 10 |
| Reusable Components | 14 |
| **Total User-Facing Screens** | **46** |
