# iOS Development Prerequisites - Complete Checklist

> **CRITICAL:** All items must be ✅ before Phase 0 begins. This ensures smooth, unblocked development.

---

## SECTION 1: SYSTEM REQUIREMENTS

### 1.1 macOS & Xcode

```bash
# Verify macOS version
sw_vers
# Required: macOS Sonoma 14.0 or later
```

- [ ] **macOS Version:** Sonoma 14.0+ 
  - **Check:** `sw_vers | grep ProductVersion`
  - **Expected:** `14.x.x`

- [ ] **Xcode Installed:** Version 15.2+
  - **Check:** `xcodebuild -version`
  - **Expected:** `Xcode 15.2` or higher
  - **Install:** Mac App Store → Search "Xcode"

- [ ] **Xcode Command Line Tools**
  - **Check:** `xcode-select -p`
  - **Expected:** `/Applications/Xcode.app/Contents/Developer`
  - **Install:** `xcode-select --install`

- [ ] **iOS SDK:** iOS 17.2+
  - **Check:** `xcodebuild -showsdks | grep iOS`
  - **Expected:** `iOS 17.2` or higher

- [ ] **iPhone Simulator Downloaded**
  - **Check:** Xcode → Window → Devices and Simulators → Simulators
  - **Required:** iPhone 15 Pro (iOS 17.2+)
  - **Download:** Xcode → Settings → Platforms → iOS → Download

### 1.2 Development Tools

- [ ] **Git Installed**
  - **Check:** `git --version`
  - **Expected:** `git version 2.x`

- [ ] **Homebrew** (Optional but recommended)
  - **Check:** `brew --version`
  - **Install:** `/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"`

---

## SECTION 2: PROJECT SETUP

### 2.1 Xcode Project

- [✅] **Xcode Project Exists:** `ios_app.xcodeproj`
  - **Location:** `/Users/i074917/Documents/destiny_ai_astrology/ios_app/ios_app.xcodeproj`
  - **Verified:** ✅ Exists

- [ ] **Project Opens Without Errors**
  - **Check:** Open `ios_app.xcodeproj` in Xcode
  - **Expected:** No build errors, warnings acceptable

- [ ] **Bundle Identifier Set**
  - **Location:** Target → General → Identity → Bundle Identifier
  - **Recommended:** `com.destinyai.astrology`
  - **Check:** Should not be default `com.example.*`

- [ ] **Deployment Target Set**
  - **Location:** Target → General → Minimum Deployments
  - **Required:** iOS 17.0
  - **Check:** Value should be `17.0`

- [ ] **Team & Signing Configured**
  - **Location:** Target → Signing & Capabilities
  - **For Local Dev:** Select "Automatically manage signing" + Your Team
  - **Check:** No signing errors shown

### 2.2 Git Repository

- [✅] **Git Repository Initialized**
  - **Check:** `cd ios_app && git status`
  - **Expected:** Shows branch name (not "not a git repository")

- [✅] **Remote Repository Connected**
  - **Check:** `git remote -v`
  - **Expected:** Shows `origin` with GitHub URL
  - **Verified:** `https://github.com/prabhupredictions/destinyios.git`

- [✅] **Git Ignore Configured**
  - **Check:** `cat .gitignore | grep -E "(xcuserdata|build)"`
  - **Expected:** Should exclude Xcode build artifacts
  - **File:** `/Users/i074917/Documents/destiny_ai_astrology/ios_app/.gitignore` ✅

- [ ] **Clean Git Status** (before starting)
  - **Check:** `git status`
  - **Expected:** "working tree clean" or only doc/ untracked
  - **Action:** Commit any pending changes before Phase 0

### 2.3 Project Structure

- [ ] **Source Folder Exists:** `ios_app/ios_app/`
  - **Check:** `ls ios_app/ios_app/`
  - **Expected:** Contains `ContentView.swift`, `Assets.xcassets`, etc.

- [ ] **Assets Catalog Exists:** `ios_app/ios_app/Assets.xcassets`
  - **Check:** Folder exists
  - **Expected:** ✅ Should be present

- [ ] **Initial Folders Created**
  ```bash
  cd ios_app/ios_app/
  mkdir -p Models Services ViewModels Views Components
  mkdir -p Views/{Splash,Onboarding,Auth,Home,Chat,Compatibility,History,Profile}
  ```
  - **Verify:** All folders exist
  - **Check:** `ls -d Models Services ViewModels Views Components`

---

## SECTION 3: BACKEND & API

### 3.1 Local API Server

- [✅] **API Server Code Exists**
  - **Location:** `/Users/i074917/Documents/destiny_ai_astrology/astrology_api/astroapi-v2`

- [✅] **Python Virtual Environment**
  - **Location:** `astrology_api/astrovenv/`
  - **Check:** `ls astrology_api/astrovenv/bin/python`

- [✅] **Local API Server Running**
  - **Start:** 
    ```bash
    cd /Users/i074917/Documents/destiny_ai_astrology/astrology_api/astroapi-v2
    /Users/i074917/Documents/destiny_ai_astrology/astrology_api/astrovenv/bin/python -m uvicorn app.main:app --host 0.0.0.0 --port 8000
    ```
  - **Check:** `curl http://localhost:8000/`
  - **Expected:** JSON response (not "Connection refused")
  - **Status:** ✅ Currently running

- [✅] **Database Seeded**
  - **Check:** 
    ```bash
    sqlite3 astrology_api/astroapi-v2/destinyastroapi.db \
      "SELECT COUNT(*) FROM llm_model_variants;"
    ```
  - **Expected:** > 0 (at least one LLM model)
  - **Verified:** ✅ 1 model (gpt-4o-mini)

- [✅] **API Key Configured**
  - **Key:** `astro_ios_G5iY3-1Z7ymE46hYwKTbK1bSz2x5Vn4BeymPOvyy3ic`
  - **Owner:** `prabhukushwaha@gmail.com`
  - **Check:** 
    ```bash
    sqlite3 astrology_api/astroapi-v2/destinyastroapi.db \
      "SELECT key_id FROM api_keys WHERE consumer_email='prabhukushwaha@gmail.com';"
    ```
  - **Expected:** Shows key_id
  - **Verified:** ✅ `C-YuKP6ppBPVnhJJuBRTiw`

### 3.2 API Health Checks

- [✅] **Prediction API Works**
  ```bash
  curl -s -X POST "http://localhost:8000/vedic/api/predict/" \
    -H "Content-Type: application/json" \
    -H "X-API-KEY: astro_ios_G5iY3-1Z7ymE46hYwKTbK1bSz2x5Vn4BeymPOvyy3ic" \
    -d '{
      "query": "How is my career?",
      "birth_data": {
        "dob": "1994-07-01",
        "time": "00:15",
        "latitude": 18.4386,
        "longitude": 79.1288
      },
      "platform": "ios",
      "include_reasoning_trace": false
    }' | jq '.status'
  ```
  - **Expected:** `"completed"`
  - **Verified:** ✅ Working (Dec 23, 2025)

- [ ] **Compatibility API Works**
  ```bash
  curl -s -X POST "http://localhost:8000/vedic/api/compatibility/analyze" \
    -H "Content-Type: application/json" \
    -H "X-API-KEY: astro_ios_G5iY3-1Z7ymE46hYwKTbK1bSz2x5Vn4BeymPOvyy3ic" \
    -d '{
      "boy": {"dob": "1994-07-01", "time": "00:15", "lat": 18.4386, "lon": 79.1288},
      "girl": {"dob": "1996-04-20", "time": "04:45", "lat": 34.0522, "lon": -118.2437}
    }' | jq '.status'
  ```
  - **Expected:** `"completed"`
  - **Action:** Test before starting Phase 4

- [ ] **Response Time Acceptable**
  - **Test:** Time the above prediction request
  - **Expected:** < 15 seconds
  - **Check:** `time curl ...` (look at `real` time)

---

## SECTION 4: DESIGN ASSETS

### 4.1 App Icon

- [ ] **App Icon Created:** 1024x1024 PNG
  - **Tool:** Can use Figma, Canva, or SF Symbols App
  - **Temporary:** Use placeholder from SF Symbols for MVP
  - **Location:** Add to `Assets.xcassets/AppIcon.appiconset/`

### 4.2 Logo & Branding

- [✅] **Logo File Available**
  - **Source:** `astrology_api/astroapi-v2/static/logo_s.png`
  - **Action:** Copy to `ios_app/ios_app/Assets.xcassets/`
  ```bash
  cp astrology_api/astroapi-v2/static/logo_s.png \
     ios_app/ios_app/Assets.xcassets/logo.imageset/logo.png
  ```

- [ ] **Logo Added to Assets Catalog**
  - **Xcode:** Assets.xcassets → + → Image Set → Name: "logo"
  - **Verify:** Can preview in Xcode

### 4.3 Color Palette

- [ ] **Colors Defined in Assets**
  - **Create Color Sets in Xcode:**
    1. Assets.xcassets → + → Color Set
    2. Create these colors:
       - `NavyPrimary`: #1a237e
       - `GoldAccent`: #ffd700
       - `BackgroundLight`: #f5f5f5
       - `TextDark`: #333333
  - **Verify:** Can use `Color("NavyPrimary")` in SwiftUI

### 4.4 SF Symbols

- [ ] **Verify SF Symbols Available**
  - **Icons Needed:**
    - `house` (Home tab)
    - `message.fill` (Chat tab)
    - `heart` (Compatibility tab)
    - `line.3.horizontal` (Menu)
    - `person.circle` (Profile)
  - **Check:** SF Symbols app or https://developer.apple.com/sf-symbols/
  - **All Available:** Yes (built into iOS 17)

---

## SECTION 5: DEPENDENCIES & CONFIGURATION

### 5.1 Swift Package Dependencies

- [✅] **No External Dependencies Required for MVP**
  - SwiftUI (built-in)
  - SwiftData (built-in)
  - URLSession (built-in)

### 5.2 Configuration Files

- [ ] **APIConfig.swift Created**
  ```bash
  # Will be created in Phase 1
  # For now, just verify structure exists
  ls -la ios_app/ios_app/Services/ 2>/dev/null || echo "Will create in Phase 1"
  ```

- [ ] **Development vs Production Switching**
  - **#if DEBUG** macro will handle local vs production URLs
  - **Documented:** ✅ In implementation plan

---

## SECTION 6: TESTING INFRASTRUCTURE

### 6.1 Test Target

- [ ] **Unit Test Target Exists**
  - **Check:** Xcode → Project Navigator → Show ios_appTests
  - **If Missing:** File → New → Target → Unit Testing Bundle
  - **Name:** `ios_appTests`

- [ ] **UI Test Target Exists** (Optional for Phase 0)
  - **Check:**ios_appUITests target exists
  - **Can Add Later:** Not blocker for Phase 0

### 6.2 Test Data

- [✅] **Sample Birth Data Documented**
  - **Location:** Implementation Plan, Appendix B
  - **Vamshi:** DOB 1994-07-01, Time 00:15, Karimnagar
  - **Swathi:** DOB 1996-04-20, Time 04:45, Los Angeles

- [✅] **Sample Queries Documented**
  - "When will I get married?"
  - "How is my career in 2025?"
  - "Tell me about my health"

---

## SECTION 7: DOCUMENTATION

### 7.1 Implementation Plan

- [✅] **Implementation Plan Exists**
  - **File:** `ios_app/doc/ios_app_implementation_plan.md`
  - **Size:** 2,529 lines
  - **Comprehensive:** ✅ All 11 screens, API specs, TDD strategy

### 7.2 README (Optional but Recommended)

- [ ] **README.md Created**
  ```markdown
  # Destiny AI Astrology - iOS App
  
  AI-powered Vedic astrology predictions.
  
  ## Quick Start
  1. Open `ios_app.xcodeproj` in Xcode
  2. Start local API: `cd ../astrology_api/astroapi-v2 && uvicorn app.main:app`
  3. Run app in simulator: Cmd+R
  
  ## Documentation
  See `doc/ios_app_implementation_plan.md`
  ```

---

## SECTION 8: CI/CD (Optional for MVP)

### 8.1 GitHub Actions

- [ ] **CI Workflow File**
  - **File:** `.github/workflows/ios-ci.yml`
  - **Status:** Not required for Phase 0
  - **Can Add:** In Phase 6 (Testing)

---

## VERIFICATION SCRIPT

Run this script to verify all prerequisites:

```bash
#!/bin/bash
# prerequisites_check.sh

echo "=== iOS Development Prerequisites Check ==="
echo ""

# 1. macOS Version
echo "✓ Check: macOS Version"
sw_vers | grep ProductVersion
echo ""

# 2. Xcode
echo "✓ Check: Xcode"
xcodebuild -version | head -1
echo ""

# 3. Xcode Project
echo "✓ Check: Xcode Project"
ls -la ios_app.xcodeproj && echo "  ✅ EXISTS" || echo "  ❌ MISSING"
echo ""

# 4. Git Repository
echo "✓ Check: Git Repository"
git remote -v | head -1 && echo "  ✅ CONNECTED" || echo "  ❌ NOT CONFIGURED"
echo ""

# 5. Local API
echo "✓ Check: Local API Server"
curl -s http://localhost:8000/ > /dev/null && echo "  ✅ RUNNING" || echo "  ❌ NOT RUNNING"
echo ""

# 6. API Health
echo "✓ Check: Prediction API"
curl -s -X POST "http://localhost:8000/vedic/api/predict/" \
  -H "Content-Type: application/json" \
  -H "X-API-KEY: astro_ios_G5iY3-1Z7ymE46hYwKTbK1bSz2x5Vn4BeymPOvyy3ic" \
  -d '{"query":"test","birth_data":{"dob":"1994-07-01","time":"00:15",
      "latitude":18.4386,"longitude":79.1288},"platform":"ios",
      "include_reasoning_trace":false}' | jq -r '.status' 2>/dev/null \
  && echo "  ✅ WORKING" || echo "  ❌ FAILED"
echo ""

# 7. Folder Structure
echo "✓ Check: Required Folders"
[ -d "ios_app/ios_app/Models" ] && echo "  ✅ Models/" || echo "  ⏳ Models/ (will create)"
[ -d "ios_app/ios_app/Services" ] && echo "  ✅ Services/" || echo "  ⏳ Services/ (will create)"
echo ""

echo "=== END OF CHECK ==="
echo ""
echo "Next Step: Review failures above and resolve before Phase 0"
```

---

## SUMMARY CHECKLIST

**Before starting Phase 0, confirm:**

### MUST HAVE (Blockers)
- [ ] macOS Sonoma 14.0+
- [ ] Xcode 15.2+
- [ ] iPhone 15 Pro Simulator downloaded
- [ ] ios_app.xcodeproj opens without errors
- [ ] Bundle ID set (not default)
- [ ] Git repository connected
- [ ] Local API server running
- [ ] Prediction API health check passes
- [ ] Implementation plan reviewed

### NICE TO HAVE (Can add later)
- [ ] App Icon (1024x1024)
- [ ] Logo in Assets catalog
- [ ] Color palette in Assets
- [ ] README.md created
- [ ] CI/CD workflow

### VERIFIED ✅
- [✅] API Configuration documented
- [✅] API Key created and tested
- [✅] Test data prepared
- [✅] Database seeded
- [✅] .gitignore configured
- [✅] Implementation plan complete (2,529 lines)

---

**STATUS:** 
- **Blockers:** Need to verify Xcode settings (Bundle ID, Team, Deployment Target)
- **Next:** Run verification script, fix any failures
- **Then:** Begin Phase 0 (TDD Setup)

