#!/bin/bash
# Xcode Project Settings Verification Script

PROJECT_DIR="/Users/i074917/Documents/destiny_ai_astrology/ios_app"
PROJECT_FILE="$PROJECT_DIR/ios_app.xcodeproj/project.pbxproj"
INFO_PLIST="$PROJECT_DIR/ios_app/Info.plist"

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║        Xcode Project Settings Verification                   ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

PASS=0
FAIL=0

# Function to check settings
check_setting() {
    local name="$1"
    local search_pattern="$2"
    local expected="$3"
    
    echo -n "[$name] "
    
    if grep -q "$search_pattern" "$PROJECT_FILE"; then
        actual=$(grep "$search_pattern" "$PROJECT_FILE" | head -1 | sed 's/.*= \(.*\);/\1/' | tr -d ' ')
        if [[ "$actual" == *"$expected"* ]]; then
            echo "✅ $actual"
            ((PASS++))
        else
            echo "⚠️  Found: $actual (Expected: $expected)"
            ((FAIL++))
        fi
    else
        echo "❌ Not found in project file"
        ((FAIL++))
    fi
}

echo "══════════════════════════════════════════════════════════════"
echo "CHECKING PROJECT SETTINGS"
echo "══════════════════════════════════════════════════════════════"
echo ""

# 1. Bundle Identifier
check_setting "Bundle Identifier" "PRODUCT_BUNDLE_IDENTIFIER" "com.destinyai.astrology"

# 2. Deployment Target
check_setting "iOS Deployment Target" "IPHONEOS_DEPLOYMENT_TARGET" "17.0"

# 3. Product Name
check_setting "Product Name" "PRODUCT_NAME" "ios_app"

# 4. Swift Version
check_setting "Swift Version" "SWIFT_VERSION" "5"

echo ""
echo "══════════════════════════════════════════════════════════════"
echo "CHECKING INFO.PLIST (if exists)"
echo "══════════════════════════════════════════════════════════════"
echo ""

if [ -f "$INFO_PLIST" ]; then
    echo "[Info.plist] ✅ Exists"
    
    # Check bundle identifier in Info.plist
    if /usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" "$INFO_PLIST" 2>/dev/null | grep -q "com.destinyai"; then
        echo "[CFBundleIdentifier] ✅ Configured"
        ((PASS++))
    else
        echo "[CFBundleIdentifier] ⚠️  May need update"
        ((FAIL++))
    fi
else
    echo "[Info.plist] ⚠️  Not found (may be auto-generated)"
fi

echo ""
echo "══════════════════════════════════════════════════════════════"
echo "CHECKING SIGNING"
echo "══════════════════════════════════════════════════════════════"
echo ""

# Check for automatic signing
if grep -q "CODE_SIGN_STYLE = Automatic" "$PROJECT_FILE"; then
    echo "[Code Signing Style] ✅ Automatic"
    ((PASS++))
else
    echo "[Code Signing Style] ⚠️  Manual or not set"
    echo "   Recommendation: Enable 'Automatically manage signing' in Xcode"
    ((FAIL++))
fi

# Check for development team
if grep -q "DEVELOPMENT_TEAM = " "$PROJECT_FILE"; then
    team=$(grep "DEVELOPMENT_TEAM = " "$PROJECT_FILE" | head -1 | sed 's/.*= \(.*\);/\1/' | tr -d ' "')
    if [ -n "$team" ] && [ "$team" != '""' ]; then
        echo "[Development Team] ✅ Set: $team"
        ((PASS++))
    else
        echo "[Development Team] ⚠️  Not configured"
        echo "   Action: Sign in to Xcode with your Apple ID"
        ((FAIL++))
    fi
else
    echo "[Development Team] ⚠️  Not found in project"
    ((FAIL++))
fi

echo ""
echo "══════════════════════════════════════════════════════════════"
echo "SUMMARY"
echo "══════════════════════════════════════════════════════════════"
echo ""
echo "✅ Passed: $PASS"
echo "⚠️  Warnings/Failures: $FAIL"
echo ""

if [ $FAIL -eq 0 ]; then
    echo "🎉 All Xcode settings verified! Ready for Phase 0."
    exit 0
else
    echo "⚠️  Some settings need attention."
    echo ""
    echo "Options:"
    echo "1. Run './configure_xcode.sh' to auto-configure (recommended)"
    echo "2. Manually configure in Xcode (see below)"
    echo ""
    echo "Manual Configuration Steps:"
    echo "  • Open: open ios_app.xcodeproj"
    echo "  • Select target 'ios_app'"
    echo "  • General tab:"
    echo "    - Bundle Identifier: com.destinyai.astrology"
    echo "    - Minimum Deployments: iOS 17.0"
    echo "  • Signing & Capabilities tab:"
    echo "    - Check 'Automatically manage signing'"
    echo "    - Select your Team"
    exit 1
fi
