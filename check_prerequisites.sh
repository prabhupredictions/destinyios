#!/bin/bash
# iOS Development Prerequisites Verification Script

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║   iOS Development Prerequisites Check                         ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

FAIL_COUNT=0
PASS_COUNT=0

# Function to check and report
check() {
    local name="$1"
    local command="$2"
    local expected="$3"
    
    echo -n "[$name] "
    result=$(eval "$command" 2>/dev/null)
    
    if echo "$result" | grep -q "$expected"; then
        echo "✅ PASS"
        ((PASS_COUNT++))
    else
        echo "❌ FAIL"
        echo "   Expected: $expected"
        echo "   Got: $result"
        ((FAIL_COUNT++))
    fi
}

# 1. System Requirements
echo "══════════════════════════════════════════"
echo "SECTION 1: SYSTEM REQUIREMENTS"
echo "══════════════════════════════════════════"
check "macOS Version" "sw_vers | grep ProductVersion" "14\."
check "Xcode Installed" "xcodebuild -version | head -1" "Xcode 15"
check "Command Line Tools" "xcode-select -p" "/Applications/Xcode"
check "iOS SDK" "xcodebuild -showsdks | grep iphoneos" "iphoneos17"
echo ""

# 2. Project Setup
echo "══════════════════════════════════════════"
echo "SECTION 2: PROJECT SETUP"
echo "══════════════════════════════════════════"
check "Xcode Project" "ls ios_app.xcodeproj" "xcodeproj"
check "Git Repository" "git rev-parse --git-dir" ".git"
check "Git Remote" "git remote -v | head -1" "origin"
check ".gitignore" "cat .gitignore | head -1" "#"
echo ""

# 3. Backend API
echo "══════════════════════════════════════════"
echo "SECTION 3: BACKEND & API"
echo "══════════════════════════════════════════"
check "API Server Running" "curl -s http://localhost:8000/ | head -c 10" "{"
check "Database Exists" "ls ../astrology_api/astroapi-v2/destinyastroapi.db" "db"

# Test Prediction API
echo -n "[Prediction API] "
response=$(curl -s -X POST "http://localhost:8000/vedic/api/predict/" \
  -H "Content-Type: application/json" \
  -H "X-API-KEY: astro_ios_G5iY3-1Z7ymE46hYwKTbK1bSz2x5Vn4BeymPOvyy3ic" \
  -d '{"query":"test","birth_data":{"dob":"1994-07-01","time":"00:15","latitude":18.4386,"longitude":79.1288},"platform":"ios","include_reasoning_trace":false}' \
  2>/dev/null)

if echo "$response" | grep -q "completed"; then
    echo "✅ PASS (Response received)"
    ((PASS_COUNT++))
else
    echo "❌ FAIL"
    echo "   Response: ${response:0:100}..."
    ((FAIL_COUNT++))
fi
echo ""

# 4. Assets
echo "══════════════════════════════════════════"
echo "SECTION 4: DESIGN ASSETS"
echo "══════════════════════════════════════════"
check "Assets Catalog" "ls ios_app/ios_app/Assets.xcassets" "xcassets"
check "Source Logo" "ls ../astrology_api/astroapi-v2/static/logo_s.png" "png"
echo ""

# Summary
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║   SUMMARY                                                      ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""
echo "✅ Passed: $PASS_COUNT"
echo "❌ Failed: $FAIL_COUNT"
echo ""

if [ $FAIL_COUNT -eq 0 ]; then
    echo "🎉 ALL CHECKS PASSED! Ready to begin Phase 0."
    exit 0
else
    echo "⚠️  $FAIL_COUNT checks failed. Please resolve before starting development."
    echo ""
    echo "Next steps:"
    echo "1. Review failures above"
    echo "2. Fix each issue"
    echo "3. Re-run this script"
    echo "4. Once all pass, begin Phase 0"
    exit 1
fi
