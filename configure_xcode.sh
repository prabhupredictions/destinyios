#!/bin/bash
# Xcode Project Auto-Configuration Script
# This script modifies project.pbxproj to set Bundle ID and Deployment Target

PROJECT_DIR="/Users/i074917/Documents/destiny_ai_astrology/ios_app"
PROJECT_FILE="$PROJECT_DIR/ios_app.xcodeproj/project.pbxproj"
BACKUP_FILE="$PROJECT_FILE.backup_$(date +%Y%m%d_%H%M%S)"

# Configuration values
BUNDLE_ID="com.destinyai.astrology"
DEPLOYMENT_TARGET="17.0"

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║        Xcode Project Auto-Configuration                     ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "⚠️  WARNING: This will modify your Xcode project file!"
echo ""
echo "Configuration:"
echo "  • Bundle Identifier: $BUNDLE_ID"
echo "  • iOS Deployment Target: $DEPLOYMENT_TARGET"
echo "  • Signing: Automatic (recommended)"
echo ""
read -p "Continue? (y/N): " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 1
fi

echo ""
echo "Creating backup: $BACKUP_FILE"
cp "$PROJECT_FILE" "$BACKUP_FILE"

echo ""
echo "══════════════════════════════════════════════════════════════"
echo "APPLYING CONFIGURATIONS"
echo "══════════════════════════════════════════════════════════════"
echo ""

# 1. Set Bundle Identifier
echo "[1/3] Setting Bundle Identifier to $BUNDLE_ID..."
if grep -q "PRODUCT_BUNDLE_IDENTIFIER = " "$PROJECT_FILE"; then
    # Replace existing
    sed -i '' "s/PRODUCT_BUNDLE_IDENTIFIER = .*/PRODUCT_BUNDLE_IDENTIFIER = $BUNDLE_ID;/" "$PROJECT_FILE"
    echo "     ✅ Updated"
else
    echo "     ⚠️  PRODUCT_BUNDLE_IDENTIFIER not found (may need manual config)"
fi

# 2. Set iOS Deployment Target
echo "[2/3] Setting iOS Deployment Target to $DEPLOYMENT_TARGET..."
if grep -q "IPHONEOS_DEPLOYMENT_TARGET = " "$PROJECT_FILE"; then
    # Replace existing
    sed -i '' "s/IPHONEOS_DEPLOYMENT_TARGET = [^;]*/IPHONEOS_DEPLOYMENT_TARGET = $DEPLOYMENT_TARGET/" "$PROJECT_FILE"
    echo "     ✅ Updated"
else
    echo "     ⚠️  IPHONEOS_DEPLOYMENT_TARGET not found"
fi

# 3. Enable Automatic Signing
echo "[3/3] Enabling Automatic Code Signing..."
if grep -q "CODE_SIGN_STYLE = " "$PROJECT_FILE"; then
    sed -i '' "s/CODE_SIGN_STYLE = Manual/CODE_SIGN_STYLE = Automatic/" "$PROJECT_FILE"
    echo "     ✅ Set to Automatic"
else
    # Add if not exists (after buildSettings)
    echo "     ⚠️  CODE_SIGN_STYLE not found (configure manually in Xcode)"
fi

echo ""
echo "══════════════════════════════════════════════════════════════"
echo "VERIFICATION"
echo "══════════════════════════════════════════════════════════════"
echo ""

# Verify changes
echo "Verifying changes..."
echo ""

bundle_id_check=$(grep "PRODUCT_BUNDLE_IDENTIFIER" "$PROJECT_FILE" | head -1)
deployment_check=$(grep "IPHONEOS_DEPLOYMENT_TARGET" "$PROJECT_FILE" | head -1)
signing_check=$(grep "CODE_SIGN_STYLE" "$PROJECT_FILE" | head -1)

echo "Bundle ID:          $bundle_id_check"
echo "Deployment Target:  $deployment_check"
echo "Code Sign Style:    $signing_check"

echo ""
echo "══════════════════════════════════════════════════════════════"
echo "NEXT STEPS"
echo "══════════════════════════════════════════════════════════════"
echo ""
echo "1. Open Xcode to verify:"
echo "   open $PROJECT_DIR/ios_app.xcodeproj"
echo ""
echo "2. In Xcode, check:"
echo "   • Target → General → Bundle Identifier"
echo "   • Target → Signing & Capabilities"
echo "     - If needed, sign in with your Apple ID"
echo "     - Select your Team"
echo ""
echo "3. Build the project (⌘+B) to confirm"
echo ""
echo "4. Run verification:"
echo "   ./verify_xcode_settings.sh"
echo ""
echo "Backup saved at:"
echo "  $BACKUP_FILE"
echo ""
echo "To restore backup (if needed):"
echo "  cp '$BACKUP_FILE' '$PROJECT_FILE'"
echo ""
echo "✅ Configuration complete!"
