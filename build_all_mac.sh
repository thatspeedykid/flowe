#!/bin/bash
VERSION="1.6.0"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

INSTALLERS="$HOME/Documents/flowe-builds"
mkdir -p "$INSTALLERS"

echo "=========================================="
echo "  Flowe v$VERSION - Mac Build"
echo "  macOS App + iOS IPA"
echo "  Output: $INSTALLERS"
echo "=========================================="
echo ""

# ── Always pull latest code first ─────────────────────────────────────────────
if [ -d ".git" ]; then
  echo "[+] Pulling latest code from GitHub..."
  git pull --ff-only 2>/dev/null && echo "  [OK] Up to date" || echo "  [WARN] Could not pull (offline or no remote)"
  echo ""
fi

# ── Checks ────────────────────────────────────────────────────────────────────
if ! command -v flutter &>/dev/null; then
  echo "[ERROR] Flutter not found. brew install --cask flutter"
  exit 1
fi
if ! command -v xcodebuild &>/dev/null; then
  echo "[ERROR] Xcode not found. Install from developer.apple.com"
  exit 1
fi
if ! command -v pod &>/dev/null; then
  echo "[INFO] CocoaPods not found - installing..."
  sudo gem install cocoapods
fi

# ── Step 1: Dependencies ──────────────────────────────────────────────────────
echo "[1/5] Getting dependencies..."
flutter pub get
echo ""

# ── Step 2: Platform setup + icons ───────────────────────────────────────────
echo "[2/5] Setting up platforms and injecting icons..."
flutter create --platforms=macos,ios . >/dev/null 2>&1 || true
# Fix window title in macOS/iOS runner
[ -f "macos/Runner/AppInfo.xcconfig" ] && sed -i '' 's/PRODUCT_NAME = flowe/PRODUCT_NAME = Flowe/g' macos/Runner/AppInfo.xcconfig || true
[ -f "ios/Runner/AppInfo.xcconfig" ] && sed -i '' 's/PRODUCT_NAME = flowe/PRODUCT_NAME = Flowe/g' ios/Runner/AppInfo.xcconfig || true

# Enable Files app visibility on iOS (On My iPhone > Flowe)
if [ -f "ios/Runner/Info.plist" ]; then
  python3 -c "
import plistlib
with open('ios/Runner/Info.plist','rb') as f:
    p = plistlib.load(f)
p['UIFileSharingEnabled'] = True
p['LSSupportsOpeningDocumentsInPlace'] = True
with open('ios/Runner/Info.plist','wb') as f:
    plistlib.dump(p, f)
print('  [OK] iOS file sharing enabled')
"
fi

# Disable Impeller (fixes blank window on VMware macOS)
if [ -f "macos/Runner/Info.plist" ]; then
  python3 -c "
import plistlib
with open('macos/Runner/Info.plist','rb') as f:
    p = plistlib.load(f)
p['FLTEnableImpeller'] = False
with open('macos/Runner/Info.plist','wb') as f:
    plistlib.dump(p, f)
print('  [OK] Impeller disabled')
"
fi

# Entitlements modification flag
if [ -f "macos/Runner.xcodeproj/project.pbxproj" ]; then
  sed -i '' 's/CODE_SIGN_STYLE = Automatic;/CODE_SIGN_STYLE = Automatic;\n\t\t\t\tCODE_SIGN_ALLOW_ENTITLEMENTS_MODIFICATION = YES;/g' \
    macos/Runner.xcodeproj/project.pbxproj 2>/dev/null || true
fi

# Write entitlements before build
for ENT in macos/Runner/Release.entitlements macos/Runner/DebugProfile.entitlements; do
  [ -f "$ENT" ] && cat > "$ENT" << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.app-sandbox</key><true/>
    <key>com.apple.security.cs.allow-jit</key><true/>
    <key>com.apple.security.network.client</key><true/>
    <key>com.apple.security.files.user-selected.read-write</key><true/>
    <key>com.apple.security.files.downloads.read-write</key><true/>
</dict>
</plist>
PLIST
done

bash inject_icons.sh

# iOS icon Contents.json
cat > "ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json" << 'JSON'
{
  "images": [
    {"size":"20x20","idiom":"iphone","filename":"ios_icon_40.png","scale":"2x"},
    {"size":"20x20","idiom":"iphone","filename":"ios_icon_60.png","scale":"3x"},
    {"size":"29x29","idiom":"iphone","filename":"ios_icon_58.png","scale":"2x"},
    {"size":"29x29","idiom":"iphone","filename":"ios_icon_87.png","scale":"3x"},
    {"size":"40x40","idiom":"iphone","filename":"ios_icon_80.png","scale":"2x"},
    {"size":"40x40","idiom":"iphone","filename":"ios_icon_120.png","scale":"3x"},
    {"size":"60x60","idiom":"iphone","filename":"ios_icon_120.png","scale":"2x"},
    {"size":"60x60","idiom":"iphone","filename":"ios_icon_180.png","scale":"3x"},
    {"size":"20x20","idiom":"ipad","filename":"ios_icon_20.png","scale":"1x"},
    {"size":"20x20","idiom":"ipad","filename":"ios_icon_40.png","scale":"2x"},
    {"size":"29x29","idiom":"ipad","filename":"ios_icon_29.png","scale":"1x"},
    {"size":"29x29","idiom":"ipad","filename":"ios_icon_58.png","scale":"2x"},
    {"size":"40x40","idiom":"ipad","filename":"ios_icon_40.png","scale":"1x"},
    {"size":"40x40","idiom":"ipad","filename":"ios_icon_80.png","scale":"2x"},
    {"size":"76x76","idiom":"ipad","filename":"ios_icon_76.png","scale":"1x"},
    {"size":"76x76","idiom":"ipad","filename":"ios_icon_152.png","scale":"2x"},
    {"size":"83.5x83.5","idiom":"ipad","filename":"ios_icon_167.png","scale":"2x"},
    {"size":"1024x1024","idiom":"ios-marketing","filename":"ios_icon_1024.png","scale":"1x"}
  ],
  "info": {"version": 1, "author": "xcode"}
}
JSON

# macOS icon Contents.json
cat > "macos/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json" << 'JSON'
{
  "images": [
    {"size":"16x16","idiom":"mac","filename":"macos_icon_16.png","scale":"1x"},
    {"size":"16x16","idiom":"mac","filename":"macos_icon_32.png","scale":"2x"},
    {"size":"32x32","idiom":"mac","filename":"macos_icon_32.png","scale":"1x"},
    {"size":"32x32","idiom":"mac","filename":"macos_icon_64.png","scale":"2x"},
    {"size":"128x128","idiom":"mac","filename":"macos_icon_128.png","scale":"1x"},
    {"size":"128x128","idiom":"mac","filename":"macos_icon_256.png","scale":"2x"},
    {"size":"256x256","idiom":"mac","filename":"macos_icon_256.png","scale":"1x"},
    {"size":"256x256","idiom":"mac","filename":"macos_icon_512.png","scale":"2x"},
    {"size":"512x512","idiom":"mac","filename":"macos_icon_512.png","scale":"1x"},
    {"size":"512x512","idiom":"mac","filename":"macos_icon_1024.png","scale":"2x"}
  ],
  "info": {"version": 1, "author": "xcode"}
}
JSON

echo "[OK] Icons and platform files ready."
echo ""

# ── Step 3: macOS app ─────────────────────────────────────────────────────────
echo "[3/5] Building macOS app..."
mkdir -p build/native_assets/macos
flutter build macos --release

MACOS_APP="build/macos/Build/Products/Release/flowe.app"
if [ -d "$MACOS_APP" ]; then
  if command -v create-dmg &>/dev/null; then
    create-dmg \
      --volname "Flowe $VERSION" \
      --window-size 600 400 \
      --icon-size 100 \
      --icon "flowe.app" 150 185 \
      --hide-extension "flowe.app" \
      --app-drop-link 450 185 \
      "$INSTALLERS/flowe_${VERSION}.dmg" \
      "$MACOS_APP"
    echo "[OK] macOS DMG: $INSTALLERS/flowe_${VERSION}.dmg"
  else
    cd "build/macos/Build/Products/Release"
    zip -r "$INSTALLERS/flowe_${VERSION}_macos.zip" flowe.app -q
    cd "$SCRIPT_DIR"
    echo "[OK] macOS ZIP: $INSTALLERS/flowe_${VERSION}_macos.zip"
    echo "     Tip: brew install create-dmg for a proper .dmg"
  fi
else
  echo "[WARN] macOS app not found at $MACOS_APP — VMware Metal limitation, skipping DMG"
fi
echo ""

# ── Step 4: iOS IPA ───────────────────────────────────────────────────────────
echo "[4/5] Building iOS release..."
mkdir -p build/native_assets/ios
INSTALLED=$(xcodebuild -showsdks 2>/dev/null | grep iphoneos | tail -1)
if [ -z "$INSTALLED" ]; then
  echo "[INFO] iOS platform not installed - downloading now (~2GB)..."
  xcodebuild -downloadPlatform iOS
fi

flutter build ios --release --no-codesign

IOS_APP="build/ios/iphoneos/Runner.app"
if [ -d "$IOS_APP" ]; then
  rm -rf /tmp/flowe_ipa
  mkdir -p /tmp/flowe_ipa/Payload
  cp -r "$IOS_APP" /tmp/flowe_ipa/Payload/flowe.app
  cd /tmp/flowe_ipa
  zip -r "$INSTALLERS/flowe_${VERSION}.ipa" Payload -q
  cd "$SCRIPT_DIR"
  rm -rf /tmp/flowe_ipa
  echo "[OK] iOS IPA: $INSTALLERS/flowe_${VERSION}.ipa"
else
  echo "[ERROR] iOS build failed"
fi
echo ""

# ── Done ──────────────────────────────────────────────────────────────────────
echo "=========================================="
echo "  Build complete -> $INSTALLERS"
echo "=========================================="
[ -f "$INSTALLERS/flowe_${VERSION}.dmg" ]         && echo "  macOS DMG:  flowe_${VERSION}.dmg"
[ -f "$INSTALLERS/flowe_${VERSION}_macos.zip" ]   && echo "  macOS ZIP:  flowe_${VERSION}_macos.zip"
[ -f "$INSTALLERS/flowe_${VERSION}.ipa" ]         && echo "  iOS IPA:    flowe_${VERSION}.ipa"
echo ""
echo "  Sideload IPA: https://sideloadly.io"
echo "=========================================="
