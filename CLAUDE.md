# iOS App — Swift/SwiftUI

## Architecture: MVVM + SwiftData (zero external deps)
```
ios_app/ios_app/
├── Models/       → Codable structs (API response shapes)
├── Services/     → URLSession async/await services (protocols for testing)
├── ViewModels/   → @MainActor ObservableObject (business logic)
├── Views/        → SwiftUI screens per feature
│   ├── Splash/ Auth/ Onboarding/
│   ├── Home/ Chat/ Compatibility/ Charts/
│   ├── History/ Profile/ Partners/
│   ├── Notifications/ Subscription/ Settings/
│   └── AppRootView.swift / MainTabView.swift
└── Resources/    → Localizable.strings (13 languages)
```

## Config Files (actual values)
- Local dev: `Local.xcconfig` → API_BASE_URL=http://127.0.0.1:8000
- TestFlight: `Test.xcconfig` → API_BASE_URL=https://astroapi-test-dsqvza5jza-ul.a.run.app
- Production: `Production.xcconfig` → API_BASE_URL=https://astroapi-prod-dsqvza5jza-ul.a.run.app
- Note: TestFlight uses a SEPARATE test Cloud Run URL (not prod)

## API Endpoints
- POST /vedic/api/predict/ → predictions
- POST /vedic/api/compatibility/analyze → compatibility
- GET /chat-history/threads/{user_id} → history
- POST /feedback/submit → ratings

## Patterns
- @StateObject for ViewModel lifecycle
- async/await everywhere (no Combine, no callbacks)
- DestinyError enum for all error types
- NSLocalizedString for every user-facing string
- Every Service has a protocol + mock for testing

## Settings Screens
- AstrologySettingsSheet.swift
- LanguageSettingsSheet.swift
- NotificationPreferencesSheet.swift
- ChartStylePickerSheet.swift

## Build: Cmd+R | Test: Cmd+U
## Simulator: ALWAYS use "iPhone 17 Pro" for xcodebuild commands
## APNS: server-side APNS_SANDBOX=false for TestFlight+prod
