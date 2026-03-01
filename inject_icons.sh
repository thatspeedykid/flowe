#!/bin/bash
# Injects flo icons into all platform runner folders
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"
ASSETS="$SCRIPT_DIR/assets"

echo "→ Injecting platform icons..."

# ── Android ───────────────────────────────────────────────────────────────────
if [ -d "android/app/src/main/res" ]; then
  for folder in mipmap-mdpi mipmap-hdpi mipmap-xhdpi mipmap-xxhdpi mipmap-xxxhdpi; do
    src="$ASSETS/android_${folder}.png"
    dst="android/app/src/main/res/$folder/ic_launcher.png"
    mkdir -p "android/app/src/main/res/$folder"
    [ -f "$src" ] && cp "$src" "$dst" && echo "  [OK] Android $folder"
  done
fi

# ── iOS ───────────────────────────────────────────────────────────────────────
if [ -d "ios/Runner/Assets.xcassets/AppIcon.appiconset" ]; then
  for size in 20 29 40 58 60 76 80 87 120 152 167 180 1024; do
    src="$ASSETS/ios_icon_${size}.png"
    [ -f "$src" ] && cp "$src" "ios/Runner/Assets.xcassets/AppIcon.appiconset/ios_icon_${size}.png"
  done
  echo "  [OK] iOS icons"
fi

# ── macOS ─────────────────────────────────────────────────────────────────────
if [ -d "macos/Runner/Assets.xcassets/AppIcon.appiconset" ]; then
  for size in 16 32 64 128 256 512 1024; do
    src="$ASSETS/macos_icon_${size}.png"
    [ -f "$src" ] && cp "$src" "macos/Runner/Assets.xcassets/AppIcon.appiconset/macos_icon_${size}.png"
  done
  echo "  [OK] macOS icons"
fi

# ── Linux ─────────────────────────────────────────────────────────────────────
if [ -d "linux/runner" ]; then
  [ -f "$ASSETS/icon_512.png" ] && cp "$ASSETS/icon_512.png" "linux/runner/my_application_icon.png"
  # Also copy sized icons for desktop integration
  for size in 16 32 48 64 128 256 512; do
    src="$ASSETS/icon_${size}.png"
    [ -f "$src" ] && cp "$src" "linux/runner/icon_${size}.png"
  done
  echo "  [OK] Linux icons"
fi

echo "→ Icons done."
