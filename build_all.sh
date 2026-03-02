#!/bin/bash
set -e
VERSION="1.5.0"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

echo "=========================================="
echo "  Flowe v$VERSION - Build All Platforms"
echo "  Linux DEB + Android APK"
echo "=========================================="
echo ""

mkdir -p installers

if ! command -v flutter &>/dev/null; then
  echo "[ERROR] Flutter not found."
  echo "  Install: https://docs.flutter.dev/get-started/install/linux"
  exit 1
fi

# ── Step 1: Dependencies ───────────────────────────────────────────────────────
echo "[1/4] Getting dependencies..."
flutter pub get
echo ""

# ── Step 2: Platform setup + icons ────────────────────────────────────────────
echo "[2/4] Setting up platforms and injecting icons..."
flutter create --platforms=linux,android . >/dev/null 2>&1 || true
# Fix window title in Linux runner
[ -f "linux/runner/main.cc" ] && sed -i 's/"flowe"/"Flowe"/g' linux/runner/main.cc
bash inject_icons.sh
bash inject_icons.sh
echo ""

# ── Step 3: Linux build ────────────────────────────────────────────────────────
echo "[3/4] Building Linux release..."

# Fix missing linker — Flutter needs lld or ld, install if missing
if ! command -v ld &>/dev/null && ! command -v ld.lld &>/dev/null; then
  echo "  [FIX] Linker not found — installing..."
  sudo apt install -y binutils lld 2>/dev/null || true
fi
# If llvm-18 is installed but ld not symlinked, fix it
if [ -f "/usr/lib/llvm-18/bin/ld.lld" ] && ! command -v ld.lld &>/dev/null; then
  sudo ln -sf /usr/lib/llvm-18/bin/ld.lld /usr/local/bin/ld.lld 2>/dev/null || true
fi

# Flutter CMake bug — needs this folder to exist before build
mkdir -p build/native_assets/linux

flutter build linux --release
echo "[OK] Linux build done."
echo ""

# ── Step 4: Android APK ───────────────────────────────────────────────────────
echo "[4/4] Building Android APK..."
if flutter build apk --release; then
  APK="build/app/outputs/flutter-apk/app-release.apk"
  [ -f "$APK" ] && cp "$APK" "installers/flowe_${VERSION}.apk" && echo "[OK] Android APK: installers/flowe_${VERSION}.apk"
else
  echo "[WARN] Android build failed - is Android SDK installed?"
fi
echo ""

# ── Package DEB ───────────────────────────────────────────────────────────────
echo "[+] Packaging Linux .deb..."
DEB_DIR="/tmp/flowe_deb"
rm -rf "$DEB_DIR"
mkdir -p "$DEB_DIR/DEBIAN" "$DEB_DIR/usr/bin" "$DEB_DIR/usr/lib/flowe" \
  "$DEB_DIR/usr/share/applications" "$DEB_DIR/usr/share/doc/flowe"
for sz in 16 32 48 64 128 256 512; do
  mkdir -p "$DEB_DIR/usr/share/icons/hicolor/${sz}x${sz}/apps"
done

cp -r build/linux/x64/release/bundle/* "$DEB_DIR/usr/lib/flowe/"

# The Flutter binary may be named 'flo' — rename to 'flowe'
[ -f "$DEB_DIR/usr/lib/flowe/flo" ] && mv "$DEB_DIR/usr/lib/flowe/flo" "$DEB_DIR/usr/lib/flowe/flowe"

cat > "$DEB_DIR/usr/bin/flowe" << 'LAUNCH'
#!/bin/bash
cd /usr/lib/flowe && exec ./flowe "$@"
LAUNCH
chmod +x "$DEB_DIR/usr/bin/flowe"

for sz in 16 32 48 64 128 256 512; do
  src="assets/icon_${sz}.png"
  [ ! -f "$src" ] && src="assets/icon.png"
  [ -f "$src" ] && cp "$src" "$DEB_DIR/usr/share/icons/hicolor/${sz}x${sz}/apps/flowe.png"
done

cat > "$DEB_DIR/usr/share/applications/flowe.desktop" << 'DESK'
[Desktop Entry]
Version=1.0
Type=Application
Name=Flowe
GenericName=Personal Finance
Comment=Take control of your money
Exec=/usr/bin/flowe
Icon=flowe
Categories=Office;Finance;
StartupWMClass=flowe
DESK

INSTALLED_SIZE=$(du -sk "$DEB_DIR/usr" | cut -f1)
cat > "$DEB_DIR/DEBIAN/control" << CTRL
Package: flowe
Version: $VERSION
Section: utils
Priority: optional
Architecture: amd64
Installed-Size: $INSTALLED_SIZE
Maintainer: speeddevilx <https://github.com/thatspeedykid/flowe>
Description: Flowe - personal finance tracker
Homepage: https://github.com/thatspeedykid/flowe
License: MIT
CTRL

for script in preinst postinst; do
cat > "$DEB_DIR/DEBIAN/$script" << SH
#!/bin/bash
$([ "$script" = "preinst" ] && echo "rm -f /usr/share/applications/flowe.desktop /usr/bin/flowe")
$([ "$script" = "postinst" ] && echo "update-desktop-database /usr/share/applications 2>/dev/null || true")
$([ "$script" = "postinst" ] && echo "gtk-update-icon-cache -f -t /usr/share/icons/hicolor 2>/dev/null || true")
true
SH
chmod 755 "$DEB_DIR/DEBIAN/$script"
done

dpkg-deb --build "$DEB_DIR" "installers/flowe_${VERSION}_amd64.deb"
echo "[OK] Linux DEB: installers/flowe_${VERSION}_amd64.deb"

echo ""
echo "=========================================="
echo "  Build Summary  ->  installers/"
echo "=========================================="
[ -f "installers/flowe_${VERSION}_amd64.deb" ] && echo "[OK] Linux DEB:   installers/flowe_${VERSION}_amd64.deb" || echo "[--] Linux DEB:   FAILED"
[ -f "installers/flowe_${VERSION}.apk"       ] && echo "[OK] Android APK: installers/flowe_${VERSION}.apk"       || echo "[--] Android APK: not built"
echo ""
echo "  Windows + iOS/macOS: use build_all_mac.sh on Mac"
echo "=========================================="
echo ""
read -p "Install DEB now? [y/N] " ans
[[ "$ans" =~ ^[Yy]$ ]] && sudo apt install -y "./installers/flowe_${VERSION}_amd64.deb" && echo "[OK] Installed!"
