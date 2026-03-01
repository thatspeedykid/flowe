#!/bin/bash
set -e
VERSION="1.5.0"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

echo "=========================================="
echo "  Flowe v$VERSION - Mac Build"
echo "  macOS App + iOS IPA"
echo "=========================================="
echo ""

mkdir -p "$HOME/Documents/flo-builds"
INSTALLERS="$HOME/Documents/flo-builds"
echo "[+] Output folder: $HOME/Documents/flo-builds/"

# ── Checks ────────────────────────────────────────────────────────────────────
if ! command -v flutter &>/dev/null; then
  echo "[ERROR] Flutter not found."
  echo "  brew install --cask flutter"
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

# ── Step 1: Dependencies ───────────────────────────────────────────────────────
echo "[1/5] Getting dependencies..."
flutter pub get
echo ""

# ── Step 2: Platform setup + icons ────────────────────────────────────────────
echo "[2/5] Setting up platforms and injecting icons..."
flutter create --platforms=macos,ios . >/dev/null 2>&1 || true

# Disable Impeller (fixes blank window on VMware/VirtualBox macOS)
if [ -f "macos/Runner/Info.plist" ]; then
  python3 -c "
import plistlib
with open('macos/Runner/Info.plist','rb') as f:
    p = plistlib.load(f)
p['FLTEnableImpeller'] = False
with open('macos/Runner/Info.plist','wb') as f:
    plistlib.dump(p, f)
print('[OK] Impeller disabled in Info.plist')
"
fi

# Allow entitlements modification in Xcode project settings
if [ -f "macos/Runner.xcodeproj/project.pbxproj" ]; then
  sed -i '' 's/CODE_SIGN_STYLE = Automatic;/CODE_SIGN_STYLE = Automatic;
				CODE_SIGN_ALLOW_ENTITLEMENTS_MODIFICATION = YES;/g' macos/Runner.xcodeproj/project.pbxproj 2>/dev/null || true
fi

# Write entitlements BEFORE build (must be done before pod install)
for ENT in macos/Runner/Release.entitlements macos/Runner/DebugProfile.entitlements; do
  [ -f "$ENT" ] && cat > "$ENT" << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.app-sandbox</key>
    <true/>
    <key>com.apple.security.cs.allow-jit</key>
    <true/>
    <key>com.apple.security.network.client</key>
    <true/>
    <key>com.apple.security.files.user-selected.read-write</key>
    <true/>
    <key>com.apple.security.files.downloads.read-write</key>
    <true/>
</dict>
</plist>
PLIST
  echo "  [OK] Entitlements: $ENT"
done

bash inject_icons.sh

# iOS icon Contents.json — tells Xcode what each icon file is
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
# Allow entitlements modification during build
export XCODE_XCCONFIG_FILE=""
flutter build macos --release
if [ -d "build/macos/Build/Products/Release/flo.app" ]; then
  # Package as .dmg if create-dmg is available, otherwise zip
  if command -v create-dmg &>/dev/null; then
    create-dmg \
      --volname "flo $VERSION" \
      --window-size 600 400 \
      --icon-size 100 \
      --icon "flo.app" 150 185 \
      --hide-extension "flo.app" \
      --app-drop-link 450 185 \
      "$INSTALLERS/flowe_${VERSION}.dmg" \
      "build/macos/Build/Products/Release/flo.app"
    echo "[OK] macOS DMG: $INSTALLERS/flowe_${VERSION}.dmg"
  else
    cd build/macos/Build/Products/Release
    zip -r "$SCRIPT_DIR/$INSTALLERS/flowe_${VERSION}_macos.zip" flo.app -q
    cd "$SCRIPT_DIR"
    echo "[OK] macOS ZIP: $INSTALLERS/flowe_${VERSION}_macos.zip"
    echo "     Tip: brew install create-dmg for a proper .dmg next time"
  fi
else
  echo "[ERROR] macOS build failed"
fi
echo ""

# ── Step 4: iOS IPA ───────────────────────────────────────────────────────────
echo "[4/5] Building iOS release..."

# Check iOS platform is installed
INSTALLED=$(xcodebuild -showsdks 2>/dev/null | grep iphoneos | tail -1)
if [ -z "$INSTALLED" ]; then
  echo "[INFO] iOS platform not installed - downloading now (~2GB)..."
  xcodebuild -downloadPlatform iOS
fi
flutter build ios --release --no-codesign
if [ -d "build/ios/iphoneos/Runner.app" ]; then
  # Package as IPA manually
  mkdir -p /tmp/flo_ipa/Payload
  cp -r build/ios/iphoneos/Runner.app /tmp/flo_ipa/Payload/flo.app
  cd /tmp/flo_ipa
  zip -r "$SCRIPT_DIR/$INSTALLERS/flowe_${VERSION}.ipa" Payload -q
  cd "$SCRIPT_DIR"
  rm -rf /tmp/flo_ipa
  echo "[OK] iOS IPA: $INSTALLERS/flowe_${VERSION}.ipa"
  echo "     Install: AltStore or Sideloadly (no developer account needed)"
else
  echo "[ERROR] iOS build failed"
fi
echo ""

# ── Step 5: Pod install check ─────────────────────────────────────────────────
echo "[5/5] Done."
echo ""
echo "=========================================="
echo "  Build Summary  ->  installers/"
echo "=========================================="
[ -f "$INSTALLERS/flowe_${VERSION}.dmg"          ] && echo "[OK] macOS DMG:   $INSTALLERS/flowe_${VERSION}.dmg"
[ -f "$INSTALLERS/flowe_${VERSION}_macos.zip"    ] && echo "[OK] macOS ZIP:   $INSTALLERS/flowe_${VERSION}_macos.zip"
[ -f "$INSTALLERS/flowe_${VERSION}.ipa"          ] && echo "[OK] iOS IPA:     $INSTALLERS/flowe_${VERSION}.ipa"
echo ""
echo ""
echo "  Files saved to: ~/Documents/flo-builds/"
echo ""
echo "  To install IPA without Apple account:"
echo "  → AltStore:   https://altstore.io"
echo "  → Sideloadly: https://sideloadly.io"
echo "=========================================="
