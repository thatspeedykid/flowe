#!/bin/bash
# Called from build_all.bat via WSL — builds the .deb without interactive prompts
set -e
VERSION="1.6.0"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

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
Name=Flowe
GenericName=Personal Finance
Comment=Take control of your money
Exec=/usr/bin/flo
Icon=flo
Categories=Office;Finance;
StartupWMClass=flo
DESK

INSTALLED_SIZE=$(du -sk "$DEB_DIR/usr" | cut -f1)
cat > "$DEB_DIR/DEBIAN/control" << CTRL
Package: flowe
Version: $VERSION
Section: utils
Priority: optional
Architecture: amd64
Installed-Size: $INSTALLED_SIZE
Maintainer: PrivacyChase <https://privacychase.com>
Description: flowe - personal finance tracker
Homepage: https://privacychase.com
License: MIT
CTRL

cat > "$DEB_DIR/DEBIAN/preinst" << 'SH'
#!/bin/bash
rm -f /usr/share/applications/flo.desktop /usr/bin/flo-launch
true
SH
chmod 755 "$DEB_DIR/DEBIAN/preinst"

cat > "$DEB_DIR/DEBIAN/postinst" << 'SH'
#!/bin/bash
update-desktop-database /usr/share/applications 2>/dev/null || true
gtk-update-icon-cache -f -t /usr/share/icons/hicolor 2>/dev/null || true

# ── Migrate data from old flo installation ────────────────────────────────────
for USER_HOME in /home/*; do
  OLD="$USER_HOME/.local/share/flo/flo/data.json"
  NEW_DIR="$USER_HOME/.local/share/flowe/flowe"
  NEW="$NEW_DIR/data.json"
  if [ -f "$OLD" ] && [ ! -f "$NEW" ]; then
    mkdir -p "$NEW_DIR"
    cp "$OLD" "$NEW"
    echo "Migrated flo data for $(basename $USER_HOME)"
  fi
done

# Remove old flo desktop entry if present
rm -f /usr/share/applications/flo.desktop
update-desktop-database /usr/share/applications 2>/dev/null || true
true
SH
chmod 755 "$DEB_DIR/DEBIAN/postinst"

mkdir -p installers
dpkg-deb --build "$DEB_DIR" "installers/flowe_${VERSION}_amd64.deb"
cp "installers/flowe_${VERSION}_amd64.deb" "flowe_${VERSION}_amd64.deb" 2>/dev/null || true
echo "[OK] DEB built: installers/flowe_${VERSION}_amd64.deb"
