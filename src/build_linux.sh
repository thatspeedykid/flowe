#!/usr/bin/env bash
# flo — Linux Build Script
# Usage: bash build_linux.sh

cd "$(dirname "$0")"
REPO_DIR="$(pwd)"

GREEN='\033[0;32m'; RED='\033[0;31m'; NC='\033[0m'

echo ""
echo "========================================"
echo "  flo — simple budget app"
echo "  Linux Build Script"
echo "========================================"
echo ""

# ── System dependencies for pywebview ────────────────────────────────────────
echo -e "${GREEN}[1/3]${NC} Installing system dependencies..."
sudo apt-get install -y \
    python3-gi python3-gi-cairo gir1.2-gtk-3.0 \
    gir1.2-webkit2-4.0 libwebkit2gtk-4.0-dev \
    python3-venv python3-full 2>/dev/null || \
sudo apt-get install -y \
    python3-gi python3-gi-cairo gir1.2-gtk-3.0 \
    gir1.2-webkit2-4.1 libwebkit2gtk-4.1-dev \
    python3-venv python3-full 2>/dev/null || true
echo -e "  ${GREEN}✓${NC} Done"
echo ""

# ── Python deps in venv ───────────────────────────────────────────────────────
echo -e "${GREEN}[2/3]${NC} Installing Python build tools..."
python3 -m venv "$HOME/flo_venv" --clear --system-site-packages
"$HOME/flo_venv/bin/pip" install pyinstaller pywebview pillow --quiet
echo -e "  ${GREEN}✓${NC} Done"
echo ""

# ── Build ─────────────────────────────────────────────────────────────────────
echo -e "${GREEN}[3/3]${NC} Building (1-3 minutes)..."
echo ""

BUILD_DIR="$HOME/flo_build"
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

cp "$REPO_DIR/src/flo_linux.py"   "$BUILD_DIR/"
cp "$REPO_DIR/src/flo_linux.spec" "$BUILD_DIR/"
cp "$REPO_DIR/src/app.html"       "$BUILD_DIR/"

cd "$BUILD_DIR"
"$HOME/flo_venv/bin/python3" -m PyInstaller flo_linux.spec --noconfirm \
    --distpath "$BUILD_DIR/dist" \
    --workpath "$BUILD_DIR/work"

if [ ! -f "$BUILD_DIR/dist/flo" ]; then
    echo -e "${RED}[ERROR]${NC} Build failed — binary not found."
    exit 1
fi

mkdir -p "$REPO_DIR/src/dist"
cp "$BUILD_DIR/dist/flo" "$REPO_DIR/src/dist/flo"
rm -rf "$BUILD_DIR"

SIZE=$(du -sh "$REPO_DIR/src/dist/flo" | cut -f1)
echo ""
echo "========================================"
echo -e "  ${GREEN}DONE${NC} — src/dist/flo ($SIZE)"
echo "========================================"
echo ""
echo "  Now run:  bash build_deb.sh"
echo ""
