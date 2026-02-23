#!/usr/bin/env bash
# flo — Build .deb Installer
# Usage: bash build_deb.sh

cd "$(dirname "$0")"
REPO_DIR="$(pwd)"

GREEN='\033[0;32m'; RED='\033[0;31m'; NC='\033[0m'
VERSION="1.3"
DEB_NAME="flo_${VERSION}_amd64.deb"

echo ""
echo "========================================"
echo "  flo — Build .deb Installer"
echo "========================================"
echo ""

# ── Check flo binary exists ───────────────────────────────────────────────────
if [ ! -f "$REPO_DIR/src/dist/flo" ]; then
    echo -e "${RED}[ERROR]${NC} src/dist/flo not found."
    echo "  Run: bash build_linux.sh first"
    echo ""
    exit 1
fi
echo -e "${GREEN}[OK]${NC} flo binary found."
echo ""

# ── Check dpkg-deb ────────────────────────────────────────────────────────────
if ! command -v dpkg-deb >/dev/null 2>&1; then
    echo "Installing dpkg..."
    sudo apt-get install -y dpkg
fi

# ── Build entirely in Linux home dir (avoids /mnt/c chmod issues) ────────────
PKG_TMP="$HOME/flo_deb_tmp"
rm -rf "$PKG_TMP"

# Copy package structure to Linux filesystem
cp -r "$REPO_DIR/linux-package" "$PKG_TMP"

# Copy binary and set permissions (works on Linux fs)
mkdir -p "$PKG_TMP/usr/lib/flo"
cp "$REPO_DIR/src/dist/flo" "$PKG_TMP/usr/lib/flo/flo"
chmod 755 "$PKG_TMP/usr/lib/flo/flo"
chmod 755 "$PKG_TMP/usr/bin/flo-launch"
chmod 755 "$PKG_TMP/DEBIAN/postinst"
chmod 644 "$PKG_TMP/DEBIAN/control"
find "$PKG_TMP/usr/share" -type f -exec chmod 644 {} \;

# Copy icon if available
if [ -f "$REPO_DIR/github/flo_logo.svg" ]; then
    cp "$REPO_DIR/github/flo_logo.svg" "$PKG_TMP/usr/share/icons/hicolor/256x256/apps/flo.svg"
fi

# ── Build .deb ────────────────────────────────────────────────────────────────
echo -e "${GREEN}[1/1]${NC} Building .deb..."
mkdir -p "$HOME/flo_installer_out"
dpkg-deb --build "$PKG_TMP" "$HOME/flo_installer_out/${DEB_NAME}"

if [ ! -f "$HOME/flo_installer_out/${DEB_NAME}" ]; then
    echo -e "${RED}[ERROR]${NC} Package not created."
    exit 1
fi

# Copy .deb back to repo
mkdir -p "$REPO_DIR/installer"
cp "$HOME/flo_installer_out/${DEB_NAME}" "$REPO_DIR/installer/${DEB_NAME}"
rm -rf "$PKG_TMP" "$HOME/flo_installer_out"

SIZE=$(du -sh "$REPO_DIR/installer/${DEB_NAME}" | cut -f1)
echo ""
echo "========================================"
echo -e "  ${GREEN}DONE${NC} — installer/${DEB_NAME} ($SIZE)"
echo "========================================"
echo ""
echo "  Install:   sudo dpkg -i installer/${DEB_NAME}"
echo "  Uninstall: sudo apt remove flo"
echo ""
