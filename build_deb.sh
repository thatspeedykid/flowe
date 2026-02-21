#!/usr/bin/env bash
# flo — Build .deb installer package
# Run after build_linux.sh has produced src/dist/flo
# Usage: chmod +x build_deb.sh && ./build_deb.sh

set -e
cd "$(dirname "$0")"

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
VERSION="1.3"
DEB_NAME="flo_${VERSION}_amd64.deb"

echo ""
echo "========================================"
echo "  flo — Build .deb Installer"
echo "========================================"
echo ""

# ── Check flo binary exists ───────────────────────────────────────────────────
if [ ! -f "src/dist/flo" ]; then
    echo -e "${RED}[ERROR]${NC} src/dist/flo not found."
    echo "  Run ./build_linux.sh first, then run this script."
    echo ""
    exit 1
fi
echo -e "${GREEN}[OK]${NC} flo binary found."
echo ""

# ── Check dpkg-deb is available ───────────────────────────────────────────────
if ! command -v dpkg-deb >/dev/null 2>&1; then
    echo -e "${YELLOW}[!]${NC} dpkg-deb not found. Installing..."
    sudo apt-get install -y dpkg 2>/dev/null || {
        echo -e "${RED}[ERROR]${NC} Could not install dpkg. Install it manually:"
        echo "  sudo apt-get install dpkg"
        exit 1
    }
fi

# ── Copy binary into package structure ───────────────────────────────────────
echo -e "${GREEN}[1/3]${NC} Copying binary..."
cp src/dist/flo linux-package/usr/bin/flo
chmod +x linux-package/usr/bin/flo
chmod +x linux-package/DEBIAN/postinst

# ── Copy icon (use PNG if SVG not renderable by GTK) ─────────────────────────
echo -e "${GREEN}[2/3]${NC} Adding icon..."
if [ -f "github/flo_logo.svg" ]; then
    # Try to convert SVG to PNG for icon cache
    if command -v rsvg-convert >/dev/null 2>&1; then
        rsvg-convert -w 256 -h 256 github/flo_logo.svg \
            -o linux-package/usr/share/icons/hicolor/256x256/apps/flo.png 2>/dev/null \
            && echo "  Converted SVG → PNG icon" \
            || cp github/flo_logo.svg linux-package/usr/share/icons/hicolor/256x256/apps/flo.svg
    elif command -v inkscape >/dev/null 2>&1; then
        inkscape --export-type=png --export-width=256 --export-height=256 \
            github/flo_logo.svg \
            -o linux-package/usr/share/icons/hicolor/256x256/apps/flo.png 2>/dev/null \
            && echo "  Converted SVG → PNG icon" \
            || cp github/flo_logo.svg linux-package/usr/share/icons/hicolor/256x256/apps/flo.svg
    else
        cp github/flo_logo.svg linux-package/usr/share/icons/hicolor/256x256/apps/flo.svg
        echo "  Using SVG icon (install librsvg2-bin to convert to PNG)"
    fi
else
    echo "  No icon found — skipping"
fi

# ── Set correct permissions on DEBIAN files ───────────────────────────────────
chmod 755 linux-package/DEBIAN
chmod 644 linux-package/DEBIAN/control
chmod 755 linux-package/DEBIAN/postinst

# ── Build the .deb ────────────────────────────────────────────────────────────
echo -e "${GREEN}[3/3]${NC} Building .deb package..."
mkdir -p installer
dpkg-deb --build linux-package "installer/${DEB_NAME}"

if [ ! -f "installer/${DEB_NAME}" ]; then
    echo -e "${RED}[ERROR]${NC} Package not created."
    exit 1
fi

SIZE=$(du -sh "installer/${DEB_NAME}" | cut -f1)
echo ""
echo "========================================"
echo -e "  ${GREEN}DONE${NC} — installer/${DEB_NAME} ($SIZE)"
echo "========================================"
echo ""
echo "  Install on any Debian/Ubuntu system:"
echo "    sudo dpkg -i installer/${DEB_NAME}"
echo ""
echo "  Then launch from:"
echo "    - Terminal:      flo"
echo "    - App launcher:  search 'flo'"
echo ""
echo "  Uninstall:"
echo "    sudo apt remove flo"
echo ""
