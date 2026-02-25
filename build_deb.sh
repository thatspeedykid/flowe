#!/bin/bash
set -e

APP="flo"
VERSION="1.4.0"
ARCH="amd64"
DEB_DIR="/tmp/flo_deb"

echo "╔══════════════════════════════════════╗"
echo "║  flo v$VERSION — Build & Install        ║"
echo "╚══════════════════════════════════════╝"
echo ""

# ── 0. Check deps ─────────────────────────────────────────────────────────────
for cmd in flutter dpkg-deb; do
  if ! command -v "$cmd" &>/dev/null; then
    echo "✗ Missing: $cmd"
    [ "$cmd" = "flutter" ] && echo "  → https://docs.flutter.dev/get-started/install/linux"
    exit 1
  fi
done

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

# ── 1. Dependencies ───────────────────────────────────────────────────────────
echo "→ Getting Flutter dependencies..."
flutter pub get --suppress-analytics 2>/dev/null || flutter pub get

# ── 2. Build release ──────────────────────────────────────────────────────────
echo "→ Building release binary..."
flutter build linux --release
echo "✓ Flutter build done"
echo ""

# ── 3. Deb structure ──────────────────────────────────────────────────────────
rm -rf "$DEB_DIR"
mkdir -p "$DEB_DIR/DEBIAN"
mkdir -p "$DEB_DIR/usr/bin"
mkdir -p "$DEB_DIR/usr/lib/flo"
mkdir -p "$DEB_DIR/usr/share/applications"
mkdir -p "$DEB_DIR/usr/share/doc/flo"
mkdir -p "$DEB_DIR/usr/share/icons/hicolor/16x16/apps"
mkdir -p "$DEB_DIR/usr/share/icons/hicolor/32x32/apps"
mkdir -p "$DEB_DIR/usr/share/icons/hicolor/48x48/apps"
mkdir -p "$DEB_DIR/usr/share/icons/hicolor/64x64/apps"
mkdir -p "$DEB_DIR/usr/share/icons/hicolor/128x128/apps"
mkdir -p "$DEB_DIR/usr/share/icons/hicolor/256x256/apps"
mkdir -p "$DEB_DIR/usr/share/icons/hicolor/512x512/apps"

# ── 4. Copy bundle ────────────────────────────────────────────────────────────
cp -r build/linux/x64/release/bundle/* "$DEB_DIR/usr/lib/flo/"

# ── 5. Launcher ───────────────────────────────────────────────────────────────
cat > "$DEB_DIR/usr/bin/flo" << 'LAUNCHER'
#!/bin/bash
cd /usr/lib/flo
exec ./flo "$@"
LAUNCHER
chmod +x "$DEB_DIR/usr/bin/flo"

# ── 6. Icons — all sizes ──────────────────────────────────────────────────────
ASSET_DIR="$SCRIPT_DIR/assets"
for size in 16 32 48 64 128 256 512; do
  icon_file="$ASSET_DIR/icon_${size}.png"
  # Fall back to icon.png (256px) if size-specific file missing
  [ ! -f "$icon_file" ] && icon_file="$ASSET_DIR/icon.png"
  if [ -f "$icon_file" ]; then
    target_dir="$DEB_DIR/usr/share/icons/hicolor/${size}x${size}/apps"
    mkdir -p "$target_dir"
    cp "$icon_file" "$target_dir/flo.png"
  fi
done
echo "✓ Icons installed"

# ── 7. Desktop entry ──────────────────────────────────────────────────────────
cat > "$DEB_DIR/usr/share/applications/flo.desktop" << 'DESKTOP'
[Desktop Entry]
Version=1.0
Type=Application
Name=flo
GenericName=Personal Finance
Comment=Take control of your money — budget, crush debt, track net worth
Exec=/usr/bin/flo
Icon=flo
Categories=Office;Finance;
Keywords=budget;finance;money;debt;snowball;savings;
StartupNotify=true
StartupWMClass=flo
DESKTOP

# ── 8. Copyright / License ────────────────────────────────────────────────────
cp "$SCRIPT_DIR/LICENSE" "$DEB_DIR/usr/share/doc/flo/copyright" 2>/dev/null || cat > "$DEB_DIR/usr/share/doc/flo/copyright" << 'COPYRIGHT'
MIT License — Copyright (c) 2026 speeddevilx
Full license: https://github.com/thatspeedykid/flo/blob/main/LICENSE
COPYRIGHT

# ── 9. Control file ───────────────────────────────────────────────────────────
INSTALLED_SIZE=$(du -sk "$DEB_DIR/usr" | cut -f1)
cat > "$DEB_DIR/DEBIAN/control" << CONTROL
Package: flo
Version: $VERSION
Section: utils
Priority: optional
Architecture: $ARCH
Installed-Size: $INSTALLED_SIZE
Maintainer: speeddevilx <https://github.com/thatspeedykid/flo>
Description: flo - personal finance tracker
 Take control of your money with flo. Track your monthly budget,
 crush debt with the snowball method, monitor net worth over time,
 and plan events — all in one fast, offline app.
 .
 Features: budget with 6-month chart, debt snowball payoff timeline,
 net worth snapshots, event split calculator, dark/light mode,
 CSV export, and full backup/restore compatible with all flo versions.
Homepage: https://github.com/thatspeedykid/flo
License: MIT
CONTROL

# ── 10. Maintainer scripts ────────────────────────────────────────────────────
cat > "$DEB_DIR/DEBIAN/preinst" << 'PREINST'
#!/bin/bash
# Remove stale files from older installs
rm -f /usr/share/applications/flo.desktop
rm -f /usr/bin/flo-launch
update-desktop-database /usr/share/applications 2>/dev/null || true
PREINST
chmod 755 "$DEB_DIR/DEBIAN/preinst"

cat > "$DEB_DIR/DEBIAN/postinst" << 'POSTINST'
#!/bin/bash
update-desktop-database /usr/share/applications 2>/dev/null || true
gtk-update-icon-cache -f -t /usr/share/icons/hicolor 2>/dev/null || true
POSTINST
chmod 755 "$DEB_DIR/DEBIAN/postinst"

cat > "$DEB_DIR/DEBIAN/prerm" << 'PRERM'
#!/bin/bash
true
PRERM
chmod 755 "$DEB_DIR/DEBIAN/prerm"

# ── 11. Build deb ─────────────────────────────────────────────────────────────
DEB_FILE="${APP}_${VERSION}_${ARCH}.deb"
dpkg-deb --build "$DEB_DIR" "$DEB_FILE"
echo "✓ Built: $DEB_FILE ($(du -sh "$DEB_FILE" | cut -f1))"
echo ""

# ── 12. Install ───────────────────────────────────────────────────────────────
echo "→ Installing (sudo required)..."
sudo apt install -y "./$DEB_FILE"
echo ""
echo "╔══════════════════════════════════════╗"
echo "║  ✓ flo v$VERSION installed!             ║"
echo "║  Launch: flo  or from app menu       ║"
echo "║  Uninstall: sudo apt remove flo      ║"
echo "╚══════════════════════════════════════╝"
