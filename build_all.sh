#!/bin/bash
set -e
VERSION="1.4.1"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

echo "=========================================="
echo "  flo v$VERSION - Build All Platforms"
echo "  Linux DEB + Android APK"
echo "=========================================="
echo ""

# ── Check Flutter ──────────────────────────────────────────────────────────────
if ! command -v flutter &>/dev/null; then
  echo "[ERROR] Flutter not found. https://docs.flutter.dev/get-started/install/linux"
  exit 1
fi

# ── Step 1: Dependencies ───────────────────────────────────────────────────────
echo "[1/4] Getting Flutter dependencies..."
flutter pub get
echo ""

# ── Step 2: Ensure platform folders exist ─────────────────────────────────────
echo "[2/4] Ensuring platform support is configured..."
flutter create --platforms=linux,android . >/dev/null 2>&1 || true
echo "Done."
echo ""

# ── Step 3: Build Linux ────────────────────────────────────────────────────────
echo "[3/4] Building Linux release..."
flutter build linux --release
echo "[OK] Linux build done."
echo ""

# ── Step 4: Build Android APK ─────────────────────────────────────────────────
echo "[4/4] Building Android APK..."
if flutter build apk --release 2>/dev/null; then
  APK="build/app/outputs/flutter-apk/app-release.apk"
  [ -f "$APK" ] && cp "$APK" "flo_${VERSION}.apk" && echo "[OK] Android APK: flo_${VERSION}.apk"
else
  echo "[WARN] Android build failed - is Android SDK installed?"
  echo "       Install: https://developer.android.com/studio"
fi
echo ""

# ── Step 5: Package Linux DEB ─────────────────────────────────────────────────
echo "[+] Packaging Linux .deb..."
DEB_DIR="/tmp/flo_deb"
rm -rf "$DEB_DIR"
mkdir -p "$DEB_DIR/DEBIAN" "$DEB_DIR/usr/bin" "$DEB_DIR/usr/lib/flo" \
  "$DEB_DIR/usr/share/applications" "$DEB_DIR/usr/share/doc/flo"
for sz in 16 32 48 64 128 256 512; do
  mkdir -p "$DEB_DIR/usr/share/icons/hicolor/${sz}x${sz}/apps"
done

cp -r build/linux/x64/release/bundle/* "$DEB_DIR/usr/lib/flo/"
cat > "$DEB_DIR/usr/bin/flo" << 'LAUNCH'
#!/bin/bash
cd /usr/lib/flo && exec ./flo "$@"
LAUNCH
chmod +x "$DEB_DIR/usr/bin/flo"

for sz in 16 32 48 64 128 256 512; do
  src="assets/icon_${sz}.png"
  [ ! -f "$src" ] && src="assets/icon.png"
  [ -f "$src" ] && cp "$src" "$DEB_DIR/usr/share/icons/hicolor/${sz}x${sz}/apps/flo.png"
done

cat > "$DEB_DIR/usr/share/applications/flo.desktop" << 'DESK'
[Desktop Entry]
Version=1.0
Type=Application
Name=flo
GenericName=Personal Finance
Comment=Take control of your money
Exec=/usr/bin/flo
Icon=flo
Categories=Office;Finance;
StartupWMClass=flo
DESK

INSTALLED_SIZE=$(du -sk "$DEB_DIR/usr" | cut -f1)
cat > "$DEB_DIR/DEBIAN/control" << CTRL
Package: flo
Version: $VERSION
Section: utils
Priority: optional
Architecture: amd64
Installed-Size: $INSTALLED_SIZE
Maintainer: speeddevilx <https://github.com/thatspeedykid/flo>
Description: flo - personal finance tracker
Homepage: https://github.com/thatspeedykid/flo
License: MIT
CTRL

for script in preinst postinst; do
cat > "$DEB_DIR/DEBIAN/$script" << SH
#!/bin/bash
$([ "$script" = "preinst" ] && echo "rm -f /usr/share/applications/flo.desktop /usr/bin/flo-launch")
$([ "$script" = "postinst" ] && echo "update-desktop-database /usr/share/applications 2>/dev/null || true")
$([ "$script" = "postinst" ] && echo "gtk-update-icon-cache -f -t /usr/share/icons/hicolor 2>/dev/null || true")
true
SH
chmod 755 "$DEB_DIR/DEBIAN/$script"
done

DEB_FILE="flo_${VERSION}_amd64.deb"
dpkg-deb --build "$DEB_DIR" "$DEB_FILE"
echo "[OK] DEB built: $DEB_FILE ($(du -sh "$DEB_FILE" | cut -f1))"

echo ""
echo "=========================================="
echo "  Build Summary"
echo "=========================================="
[ -f "flo_${VERSION}_amd64.deb" ] && echo "[OK] Linux DEB:  flo_${VERSION}_amd64.deb" || echo "[--] Linux DEB:  failed"
[ -f "flo_${VERSION}.apk"       ] && echo "[OK] Android:    flo_${VERSION}.apk"       || echo "[--] Android:    not built"
echo ""
echo "Note: Windows EXE must be built on Windows - run: build_all.bat"
echo ""
read -p "Install DEB now? [y/N] " ans
if [[ "$ans" =~ ^[Yy]$ ]]; then
  sudo apt install -y "./$DEB_FILE"
  echo "[OK] flo $VERSION installed! Run: flo"
fi
