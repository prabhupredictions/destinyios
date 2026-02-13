# Destiny AI Astrology - iOS App

AI-powered Vedic astrology predictions using SwiftUI and native iOS frameworks.

## Quick Start

### 1. Start Local API Server
```bash
cd ../astrology_api/astroapi-v2
source ../astrovenv/bin/activate
uvicorn app.main:app --host 0.0.0.0 --port 8000
```

### 2. Open in Xcode
```bash
open ios_app.xcodeproj
```

### 3. Run
Press `⌘+R` or **Product → Run**

---

## Architecture

| Component | Technology |
|-----------|------------|
| **UI** | SwiftUI (iOS 17+) |
| **Architecture** | MVVM (Model-View-ViewModel) |
| **Persistence** | SwiftData |
| **Networking** | Native URLSession (No Alamofire) |
| **Testing** | XCTest (TDD approach) |
| **Dependencies** | Zero external (100% native) |

---

## Project Structure

```
ios_app/
├── ios_app/
│   ├── Models/              # Codable data models
│   ├── Services/            # API & network layer
│   ├── ViewModels/          # Business logic
│   ├── Views/               # SwiftUI screens
│   │   ├── Splash/
│   │   ├── Onboarding/
│   │   ├── Auth/
│   │   ├── Home/
│   │   ├── Chat/
│   │   ├── Compatibility/
│   │   ├── History/
│   │   └── Profile/
│   ├── Components/          # Reusable UI components
│   └── Assets.xcassets/     # Images, colors, icons
├── ios_appTests/            # Unit tests
└── doc/                     # Documentation
    ├── ios_app_implementation_plan.md  # Complete dev bible
    └── PREREQUISITES.md                # Setup checklist
```

---

## Documentation

- **[Complete Implementation Plan](doc/ios_app_implementation_plan.md)** - 2,500+ line development bible
- **[Prerequisites Checklist](doc/PREREQUISITES.md)** - Pre-development requirements
- **[Setup Steps](doc/SETUP_STEPS.md)** - Step-by-step prerequisite completion

---

## Development Phases

- [x] **Prerequisites** - API, Git, Assets configured
- [ ] **Phase 0:** TDD Setup (2 days)
- [ ] **Phase 1:** Foundation - Models & Services (3 days)
- [ ] **Phase 2:** Authentication & Onboarding (2 days)
- [ ] **Phase 3:** Core Screens - Home & Tab Bar (4 days)
- [ ] **Phase 4:** Predictions & Compatibility (5 days)
- [ ] **Phase 5:** History & Profile (3 days)
- [ ] **Phase 6:** Polish & Testing (3 days)
- [ ] **Phase 7:** Deployment to App Store (2 days)

**Total:** ~24 days (1 month sprint)

---

## API Configuration

| Environment | Base URL |
|-------------|----------|
| **Local Development** | `http://localhost:8000` |
| **Production** | `https://astroapi-v2-668639087682.asia-south1.run.app` |

**API Key:** Configured in `APIConfig.swift` (see implementation plan)

### Available Endpoints

- `POST /vedic/api/predict/` - Astrological predictions
- `POST /vedic/api/compatibility/analyze` - Match compatibility (Ashtakoot)
- `GET /chat-history/threads/{user_id}` - Chat history
- `POST /feedback/submit` - Submit ratings

---

## Testing

### Run All Tests
```bash
xcodebuild test -scheme ios_app \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro'
```

### Run Specific Test
```bash
xcodebuild test -scheme ios_app \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
  -only-testing:ios_appTests/BirthDataTests
```

### Test Coverage Goal
- **Models:** 100%
- **Services:** 100%
- **ViewModels:** 100%
- **UI (Critical Paths):** ~20%

---

## Git Workflow

```
main (protected) → Production (App Store)
  ↓
develop → TestFlight
  ↓
feature/your-feature → Your work
```

### Commit Convention
```
feat: Add chat screen UI
fix: Resolve API timeout issue
test: Add prediction service tests
docs: Update README
```

---

## Verification

Run prerequisite checker:
```bash
./check_prerequisites.sh
```

Expected: **All checks passing** ✅

---

## Tech Stack Highlights

✅ **SwiftUI** - Modern declarative UI  
✅ **SwiftData** - Native iOS 17 ORM  
✅ **Async/Await** - Clean concurrency  
✅ **Protocol-Oriented** - Maximum testability  
✅ **Zero Dependencies** - Faster builds, smaller app  

---

## License

Proprietary - All Rights Reserved

---

## Contact

**Email:** prabhukushwaha@gmail.com  
**GitHub:** https://github.com/prabhupredictions/destinyios

---

**Ready to start development?** See `doc/ios_app_implementation_plan.md` Phase 0.

Dummy change for trigger Fri Feb 13 14:08:57 IST 2026
