#!/bin/bash
# Called from build_all.bat via WSL — builds the .deb without interactive prompts
set -e
VERSION="1.7.5"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

DEB_DIR="/tmp/flowe_deb"
rm -rf "$DEB_DIR"
mkdir -p "$DEB_DIR/DEBIAN" "$DEB_DIR/usr/bin" "$DEB_DIR/usr/lib/flowe" \
  "$DEB_DIR/usr/share/applications" "$DEB_DIR/usr/share/doc/flowe" \
  "$DEB_DIR/usr/share/metainfo"
for sz in 16 32 48 64 128 256 512; do
  mkdir -p "$DEB_DIR/usr/share/icons/hicolor/${sz}x${sz}/apps"
done

cp -r build/linux/x64/release/bundle/* "$DEB_DIR/usr/lib/flowe/"

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
GenericName=Personal Finance Tracker
Comment=Take control of your money — budget, debt snowball, net worth, events
Exec=/usr/bin/flowe
Icon=flowe
Categories=Office;Finance;
Keywords=budget;finance;money;debt;snowball;networth;personal;tracker;
StartupWMClass=flowe
DESK

# Install AppStream metainfo (makes GNOME Software / KDE Discover show full details)
[ -f "com.privacychase.flowe.metainfo.xml" ] && \
  cp "com.privacychase.flowe.metainfo.xml" "$DEB_DIR/usr/share/metainfo/com.privacychase.flowe.metainfo.xml"

INSTALLED_SIZE=$(du -sk "$DEB_DIR/usr" | cut -f1)
cat > "$DEB_DIR/DEBIAN/control" << CTRL
Package: flowe
Version: $VERSION
Section: utils
Priority: optional
Architecture: amd64
Installed-Size: $INSTALLED_SIZE
Conflicts: flo
Replaces: flo
Breaks: flo
Maintainer: PrivacyChase <https://privacychase.com>
Description: Flowe - Personal Finance Tracker
 Take control of your money with Flowe — a privacy-first personal
 finance app with budgeting, debt snowball, net worth tracking,
 event split calculator, and spending journal.
 .
 v1.7.0: Rebuilt Transactions tab, tab restructure (Budget/Snowball/
 Net Worth/Events), split calculator now saves, debt card alignment
 fixes, font size persistence fix, safe area fixes for mobile,
 Linux package renamed from flo to flowe.
Homepage: https://privacychase.com
License: MIT
CTRL

# ── preinst: runs before new files are unpacked ─────────────────────────────
cat > "$DEB_DIR/DEBIAN/preinst" << 'SH'
#!/bin/bash
# Remove old 'flo' package if installed — it owns /usr/bin/flo which would conflict
if dpkg -l flo 2>/dev/null | grep -q '^ii'; then
    echo "Removing old 'flo' package to allow flowe installation..."
    dpkg --remove flo 2>/dev/null || apt-get remove -y flo 2>/dev/null || true
fi
# Kill any running instance
pkill -x flowe 2>/dev/null || true
pkill -x flo 2>/dev/null || true
# Clean up any leftover files from old package
rm -f /usr/bin/flo /usr/share/applications/flo.desktop
true
SH
chmod 755 "$DEB_DIR/DEBIAN/preinst"

# ── postinst: runs after new files are in place ──────────────────────────────
cat > "$DEB_DIR/DEBIAN/postinst" << 'SH'
#!/bin/bash
# Refresh desktop and icon cache
update-desktop-database /usr/share/applications 2>/dev/null || true
gtk-update-icon-cache -f -t /usr/share/icons/hicolor 2>/dev/null || true

# ── Migrate data from old flo installation ────────────────────────────────────
# Only copies if old data exists AND new location doesn't yet have data
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

# Remove OLD flo desktop entry if still present (not flowe!)
rm -f /usr/share/applications/flo.desktop
update-desktop-database /usr/share/applications 2>/dev/null || true
true
SH
chmod 755 "$DEB_DIR/DEBIAN/postinst"

# ── prerm: runs before files are removed (uninstall/upgrade) ─────────────────
# NOTE: intentionally does NOT touch ~/.local/share/flowe — user data is kept.
cat > "$DEB_DIR/DEBIAN/prerm" << 'SH'
#!/bin/bash
# Stop running instance before removal
pkill -x flowe 2>/dev/null || true
# On upgrade dpkg calls prerm with "upgrade <new-version>" — just exit cleanly
true
SH
chmod 755 "$DEB_DIR/DEBIAN/prerm"

# ── postrm: runs after files are removed ─────────────────────────────────────
# Called with "remove", "purge", "upgrade", "failed-upgrade", "abort-install",
# "abort-upgrade", or "disappear".
# We NEVER remove ~/.local/share/flowe in any of these cases.
cat > "$DEB_DIR/DEBIAN/postrm" << 'SH'
#!/bin/bash
ACTION="$1"

# Refresh desktop cache after removal
update-desktop-database /usr/share/applications 2>/dev/null || true
gtk-update-icon-cache -f -t /usr/share/icons/hicolor 2>/dev/null || true

# On purge we STILL do not remove user data — user must do this manually.
# This is intentional: data lives in ~/.local/share/flowe/ which is outside
# the package's file list and should never be wiped by dpkg.
true
SH
chmod 755 "$DEB_DIR/DEBIAN/postrm"

mkdir -p installers
dpkg-deb --build "$DEB_DIR" "installers/flowe_${VERSION}_amd64.deb"
cp "installers/flowe_${VERSION}_amd64.deb" "flowe_${VERSION}_amd64.deb" 2>/dev/null || true
echo "[OK] DEB built: installers/flowe_${VERSION}_amd64.deb"
