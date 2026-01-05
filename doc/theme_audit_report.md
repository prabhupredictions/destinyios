# Theme Consistency Audit Report

> Analysis of centralized theme usage across all iOS views and components.

---

## 📊 Summary

| Category | Status | Details |
|----------|--------|---------|
| **AppTheme Definition** | ✅ Well-structured | Colors, Fonts, Styles centralized |
| **Components Folder** | ✅ Consistent | No hardcoded colors found |
| **Views Folder** | ⚠️ Violations Found | 31+ hardcoded hex colors |

---

## ✅ What's Working Well

### AppTheme.swift
- **Colors**: `mainBackground`, `cardBackground`, `gold`, `textPrimary`, `textSecondary`, etc.
- **Fonts**: `display()`, `title()`, `body()`, `caption()` with size parameter
- **Styles**: `cornerRadius`, `inputHeight`, `cardShadow`, `goldBorder`

### Files Using AppTheme Correctly (46+ files)
All files in `/Components/` directory use `AppTheme.Colors.*` and `AppTheme.Fonts.*` consistently.

---

## ⚠️ Violations Found

### Files with Hardcoded Hex Colors

| File | Violations | Issue |
|------|------------|-------|
| `MainTabView.swift` | 11 | Tab bar styling with direct hex codes |
| `HomeView.swift` | 10 | Gradient stops, premium card colors |
| `SubscriptionView.swift` | 4 | Dark text on gold button |
| `OnboardingView.swift` | 2 | Purple accent, dark text |
| `OnboardingSlideView.swift` | 1 | Dark text on gold |
| `LanguageSelectionView.swift` | 1 | Dark text on gold |
| `AuthView.swift` | 1 | Purple accent |
| `PlanetaryPositionsSheet.swift` | 2 | Custom gradients |

### Common Hardcoded Values

| Hex Code | Should Use | Occurrences |
|----------|------------|-------------|
| `0B0F19` | `AppTheme.Colors.mainBackground` | 6 |
| `D4AF37` | `AppTheme.Colors.gold` | 8 |
| `4A148C` | Add `purpleAccent` to AppTheme | 3 |
| `1A1E3C`, `1A2138` | Add `darkNavyContrast` to AppTheme | 4 |

---

## 🔧 Recommendations

### 1. Add Missing Colors to AppTheme

```swift
// Add to AppTheme.Colors
static let purpleAccent = Color(hex: "4A148C")
static let darkNavyContrast = Color(hex: "1A1E3C")
static let darkTextOnGold = Color(hex: "0B0F19")  // Already mainBackground
```

### 2. Create Premium Gradients in AppTheme

```swift
// Add to AppTheme.Colors
static let homeCardGradient = LinearGradient(
    stops: [
        .init(color: Color(hex: "FFFDE7"), location: 0.0),
        .init(color: Color(hex: "D4AF37"), location: 0.6),
        .init(color: Color(hex: "8B7226"), location: 1.0)
    ],
    startPoint: .topLeading,
    endPoint: .bottomTrailing
)
```

### 3. Fix Priority Order

1. **High**: `MainTabView.swift` - Most visible, 11 violations
2. **High**: `HomeView.swift` - User sees first, 10 violations
3. **Medium**: `SubscriptionView.swift` - Paywall, 4 violations
4. **Low**: Onboarding views - Seen once

---

## 📋 Action Items

- [ ] Add missing color constants to `AppTheme.Colors`
- [ ] Add gradient presets for premium cards
- [ ] Refactor `MainTabView.swift` to use AppTheme
- [ ] Refactor `HomeView.swift` to use AppTheme
- [ ] Refactor `SubscriptionView.swift` to use AppTheme
- [ ] Refactor onboarding views to use AppTheme
- [ ] Verify all `.font(.system(...))` calls use `AppTheme.Fonts`

---

## ✅ Files Already Compliant

- All 14 `/Components/*` files
- `ChatView.swift`
- `CompatibilityView.swift`
- `CompatibilityResultView.swift`
- `ProfileView.swift`
- `BirthDetailsView.swift`
- `SplashView.swift`
- `HistoryView.swift`
- All chart views (except PlanetaryPositionsSheet)
- All settings sheets
