#!/usr/bin/env bash
# flo — Linux Build Script
# Produces: src/dist/flo
# Usage: chmod +x build_linux.sh && ./build_linux.sh

set -e
cd "$(dirname "$0")"

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'

echo ""
echo "========================================"
echo "  flo — simple budget app"
echo "  Linux Build Script"
echo "========================================"
echo ""

# ── Python deps only — no pywebview needed ────────────────────────────────
echo -e "${GREEN}[1/2]${NC} Installing build tools..."
python3 -m pip install pyinstaller pillow --quiet
echo -e "  ${GREEN}✓${NC} Done"
echo ""

# ── Build ─────────────────────────────────────────────────────────────────
echo -e "${GREEN}[2/2]${NC} Building (1-3 minutes)..."
echo ""
cd src
python3 -m PyInstaller flo_linux.spec --noconfirm

if [ ! -f "dist/flo" ]; then
    echo -e "${RED}[ERROR]${NC} dist/flo not found."
    exit 1
fi

rm -rf build/
cd ..

SIZE=$(du -sh src/dist/flo | cut -f1)
echo ""
echo "========================================"
echo -e "  ${GREEN}DONE${NC} — src/dist/flo ($SIZE)"
echo "========================================"
echo ""
echo "  Run it:          ./src/dist/flo"
echo "  Opens in Chrome/Chromium in app-mode."
echo "  No browser UI, no address bar."
echo ""
echo "  To install system-wide:"
echo "    sudo cp src/dist/flo /usr/local/bin/flo"
echo ""
