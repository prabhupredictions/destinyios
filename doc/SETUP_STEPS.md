# Prerequisites Completion Guide - Step by Step

**Goal:** Complete all prerequisites to be 100% ready for Phase 0

---

## STEP 1: Verify Current Project Structure ✅

**Command:**
```bash
cd /Users/i074917/Documents/destiny_ai_astrology/ios_app
ls -la ios_app/
```

**Expected:** See `ContentView.swift`, `ios_appApp.swift`, etc.

**Status:** ⏳ CHECKING...

---

## STEP 2: Create Assets Catalog (If Missing)

**Command:**
```bash
mkdir -p ios_app/ios_app/Assets.xcassets/AppIcon.appiconset
mkdir -p ios_app/ios_app/Assets.xcassets/AccentColor.colorset
```

**Create Contents.json:**
```bash
# Will create proper structure below
```

**Status:** ⏳ PENDING

---

## STEP 3: Add Logo to Assets

**Command:**
```bash
mkdir -p ios_app/ios_app/Assets.xcassets/logo.imageset
cp ../astrology_api/astroapi-v2/static/logo_s.png \
   ios_app/ios_app/Assets.xcassets/logo.imageset/logo.png
```

**Create logo Contents.json:**
```json
{
  "images" : [
    {
      "filename" : "logo.png",
      "idiom" : "universal",
      "scale" : "1x"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
```

**Status:** ⏳ PENDING

---

## STEP 4: Create Color Assets

**Colors needed:**
- NavyPrimary: #1a237e
- GoldAccent: #ffd700
- BackgroundLight: #f5f5f5
- TextDark: #333333

**Will create color set JSONs**

**Status:** ⏳ PENDING

---

## STEP 5: Create Project Folder Structure

**Command:**
```bash
cd ios_app/ios_app/
mkdir -p Models Services ViewModels Views Components
mkdir -p Views/Splash Views/Onboarding Views/Auth Views/Home
mkdir -p Views/Chat Views/Compatibility Views/History Views/Profile
```

**Status:** ⏳ PENDING

---

## STEP 6: Verify Xcode Settings

**Manual steps in Xcode:**
1. Open `ios_app.xcodeproj`
2. Select target "ios_app"
3. General tab:
   - Bundle Identifier: `com.destinyai.astrology`
   - Deployment Target: `iOS 17.0`
4. Signing & Capabilities:
   - Check "Automatically manage signing"
   - Select your Team

**Status:** ⏳ USER VERIFICATION NEEDED

---

## STEP 7: Test Compatibility API

**Command:**
```bash
curl -X POST "http://localhost:8000/vedic/api/compatibility/analyze" \
  -H "Content-Type: application/json" \
  -H "X-API-KEY: astro_ios_G5iY3-1Z7ymE46hYwKTbK1bSz2x5Vn4BeymPOvyy3ic" \
  -d '{
    "boy": {
      "dob": "1994-07-01",
      "time": "00:15",
      "lat": 18.4386,
      "lon": 79.1288,
      "name": "Vamshi"
    },
    "girl": {
      "dob": "1996-04-20",
      "time": "04:45",
      "lat": 34.0522,
      "lon": -118.2437,
      "name": "Swathi"
    }
  }' | jq '.status'
```

**Expected:** `"completed"`

**Status:** ⏳ PENDING

---

## STEP 8: Create README.md

**File:** `ios_app/README.md`

**Content:**
```markdown
# Destiny AI Astrology - iOS App

AI-powered Vedic astrology predictions using SwiftUI and native iOS frameworks.

## Quick Start

1. **Start Local API Server:**
   ```bash
   cd ../astrology_api/astroapi-v2
   source ../astrovenv/bin/activate
   uvicorn app.main:app --reload
   ```

2. **Open in Xcode:**
   ```bash
   open ios_app.xcodeproj
   ```

3. **Run:** Press ⌘+R or Product → Run

## Architecture

- **UI:** SwiftUI (iOS 17+)
- **Architecture:** MVVM
- **Persistence:** SwiftData
- **Networking:** Native URLSession
- **Testing:** XCTest (TDD approach)

## Documentation

- [Complete Implementation Plan](doc/ios_app_implementation_plan.md)
- [Prerequisites Checklist](doc/PREREQUISITES.md)

## Development Phases

- [x] Phase 0: TDD Setup
- [ ] Phase 1: Foundation (Models & Services)
- [ ] Phase 2: Authentication & Onboarding
- [ ] Phase 3: Core Screens
- [ ] Phase 4: Predictions & Compatibility
- [ ] Phase 5: History & Profile
- [ ] Phase 6: Polish & Testing
- [ ] Phase 7: Deployment

## API Configuration

**Local Development:** http://localhost:8000
**API Key:** Configured in APIConfig.swift

## Testing

```bash
# Run all tests
xcodebuild test -scheme ios_app \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro'
```

## License

Proprietary
```

**Status:** ⏳ PENDING

---

## CHECKLIST SUMMARY

- [ ] Step 1: Verify project structure
- [ ] Step 2: Create Assets catalog
- [ ] Step 3: Add logo to assets
- [ ] Step 4: Create color assets
- [ ] Step 5: Create folder structure
- [ ] Step 6: Verify Xcode settings (MANUAL)
- [ ] Step 7: Test compatibility API
- [ ] Step 8: Create README

**After completion:** Run `./check_prerequisites.sh` to verify all passing.

