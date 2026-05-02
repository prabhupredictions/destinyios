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

## E2E Test Suite (Appium)

Location: `ios_app/e2e/`

### Prerequisites
```bash
# Appium (global)
appium --version   # must be 2.x
appium driver list # xcuitest must be installed

# Python deps (already in venv)
source astrology_api/astroapi-v2/venv/bin/activate
```

### Run tests
```bash
# Start Appium server (leave running in background)
appium --port 4723 &

# Start backend
cd astrology_api/astroapi-v2 && source venv/bin/activate
uvicorn app.main:app --reload --port 8000 &

# Run full suite
cd ios_app/e2e && source ../../astrology_api/astroapi-v2/venv/bin/activate
pytest . -v --html=screenshots/full_report.html

# Run one file
pytest test_03_chat.py -v

# Staging (rare — only for non-reproducible local bugs)
TEST_ENV=staging pytest test_12_style_finance.py -v
```

### Structure
```
ios_app/e2e/
├── conftest.py              ← session-scoped Appium driver + screens fixture
├── helpers/
│   ├── screens.py           ← page objects: HomeScreen, ChatScreen, CompatibilityScreen…
│   └── assertions.py        ← guardrail helpers: assert_no_disease_names, assert_no_fatalistic…
├── test_01_onboarding.py    ← onboarding flow (fresh install, no UI_TEST_MODE)
├── test_02_home.py          ← home screen cards, tabs, navigation
├── test_03_chat.py          ← chat send/stream/copy/history/charts (12 tests)
├── test_04_compatibility.py ← match screen + analyze flow
├── test_05_charts.py        ← chart sheet, dasha/transits/planets tabs
├── test_06_history.py       ← history thread list + open thread
├── test_07_profile.py       ← profile sheets: birth, language, settings
├── test_08_settings.py      ← chart style, language picker, notification toggles
├── test_09_partners.py      ← partner manager add/list
├── test_10_subscription.py  ← subscription plan cards
├── test_11_notifications.py ← notification inbox
├── test_12_style_finance.py ← finance domain guardrails (no guarantees, recovery path)
├── test_13_style_health.py  ← health domain guardrails (no disease names, conditional lang)
├── test_14_style_travel.py  ← travel domain guardrails (timing window, career framing)
├── test_15_style_compatibility.py ← compatibility domain guardrails
├── test_16_style_education.py  ← education domain guardrails
├── test_17_style_self.py    ← self/identity domain guardrails (no fatalism)
├── test_18_style_spiritual.py ← spiritual domain guardrails (no moksha guarantees)
├── test_19_style_family.py  ← family domain guardrails (no child fatalism, no death predictions)
├── test_20_style_property.py ← property domain guardrails (no price predictions, no property fatalism)
├── test_21_style_legal.py   ← legal domain guardrails (no outcome predictions, no strategy advice)
└── test_22_style_muhurta.py ← muhurta domain guardrails (no single-date mandate, no ceremony guarantees, no medical delay advice)
```

### How UI_TEST_MODE works
- Appium passes `UI_TEST_MODE` as a launch argument via `process_arguments.args`
- `AppRootView.swift` detects it in `#if DEBUG` and calls `injectE2ESession()`
- This sets all `@AppStorage` keys to bypass language selection, onboarding, and auth
- Prabhu's profile (`prabhukushwaha@gmail.com`, DOB 1980-07-01, Bhilai) is injected
- Zero production impact — `#if DEBUG` stripped from release builds

### Adding a new style domain test (e.g. compatibility)
1. Create `ios_app/e2e/test_15_style_compatibility.py`
2. Use `_ask_and_get(screens, question)` helper pattern (copy from test_12)
3. Import assertions from `helpers.assertions` that match the domain guardrails
4. One `test_` method per agent group, question phrased to trigger that agent
5. Commit and push to `test` branch

### Accessibility ID conventions
Every interactive element needs `.accessibilityIdentifier("snake_case_id")` in SwiftUI.
`screens.py` uses `AppiumBy.ACCESSIBILITY_ID` to locate elements.
After adding Swift IDs, rebuild: `xcodebuild build -scheme ios_app ...`
