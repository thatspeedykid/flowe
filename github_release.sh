#!/bin/bash
# ─────────────────────────────────────────────────────────────────
#  flo — GitHub Release Script
#  - Moves old Python/HTML source to legacy/
#  - Commits and pushes all Flutter source + build scripts
#  - Creates v1.4.1 release with built artifacts attached
#
#  Requirements:
#    git, gh (GitHub CLI) — https://cli.github.com
#    Run from your local flo repo root (where .git lives)
#    Built artifacts must exist before running:
#      flo_1.4.1_amd64.deb  (from Linux: bash build_all.sh)
#      flo_1.4.1.apk        (from build_all.sh or build_all.bat)
#      flowe_setup.exe        (from Windows: build_all.bat)
# ─────────────────────────────────────────────────────────────────
set -e

VERSION="1.7.0"
TAG="v${VERSION}"
REPO="thatspeedykid/flowe"

echo "=========================================="
echo "  Flowe $TAG — GitHub Release Script"
echo "=========================================="
echo ""

# ── Sanity checks ──────────────────────────────────────────────────────────────
if ! command -v git &>/dev/null; then echo "[ERROR] git not found"; exit 1; fi
if ! command -v gh  &>/dev/null; then
  echo "[ERROR] GitHub CLI (gh) not found."
  echo "  Install: https://cli.github.com"
  echo "  Then run: gh auth login"
  exit 1
fi

if [ ! -d ".git" ]; then
  echo "[ERROR] Run this from your flo repo root (where .git is)"
  exit 1
fi

echo "[CHECK] GitHub auth..."
gh auth status || { echo "[ERROR] Not logged in. Run: gh auth login"; exit 1; }
echo ""

# ── Step 1: Move old Python/HTML source to legacy/ ────────────────────────────
echo "[1/6] Moving old source to legacy/..."
mkdir -p legacy

OLD_FILES=(
  "src"
  "flo_setup.iss"
  "build_linux.sh"
  "build_windows.bat"
  "build_installer.bat"
  "linux-package"
  "github"
)

for item in "${OLD_FILES[@]}"; do
  if [ -e "$item" ] && [ "$item" != "legacy" ]; then
    echo "  → legacy/$item"
    git mv "$item" "legacy/$item" 2>/dev/null || mv "$item" "legacy/$item"
  fi
done

# Add a note in legacy folder
cat > legacy/README.md << 'LEGACYMD'
# flo Legacy (Python/HTML)

These are the original flo v1.0–v1.3 source files, built with Python + HTML/CSS/JS.

As of v1.4.0, flo has been rewritten in Flutter. The Flutter source is in the root of this repo.

The Python/HTML version still works — see `src/server.py` to run it directly.

**Data is fully compatible** — flo v1.4+ can import data.json from the old version.
LEGACYMD

echo "[OK] Legacy files moved."
echo ""

# ── Step 2: Copy Flutter source into repo root ────────────────────────────────
echo "[2/6] Copying Flutter source files..."

FLUTTER_SRC="${BASH_SOURCE%/*}"  # directory this script lives in
# If running from repo root already, skip copy
if [ "$FLUTTER_SRC" = "." ] || [ "$FLUTTER_SRC" = "" ]; then
  echo "  Already in repo root, skipping copy."
else
  cp -rf "$FLUTTER_SRC/lib"           ./lib
  cp -rf "$FLUTTER_SRC/assets"        ./assets
  cp -f  "$FLUTTER_SRC/pubspec.yaml"  ./pubspec.yaml
  cp -f  "$FLUTTER_SRC/build_all.sh"  ./build_all.sh
  cp -f  "$FLUTTER_SRC/build_all.bat" ./build_all.bat
  cp -f  "$FLUTTER_SRC/build_deb.sh"  ./build_deb.sh
  cp -f  "$FLUTTER_SRC/build_windows.bat" ./build_windows.bat
  cp -f  "$FLUTTER_SRC/flowe_setup.nsi" ./flowe_setup.nsi
  cp -f  "$FLUTTER_SRC/README.md"     ./README.md
  cp -f  "$FLUTTER_SRC/CHANGELOG.md"  ./CHANGELOG.md
  cp -f  "$FLUTTER_SRC/LICENSE"       ./LICENSE
  echo "  Flutter source copied."
fi
echo "[OK] Source ready."
echo ""

# ── Step 3: Stage and commit ──────────────────────────────────────────────────
echo "[3/6] Staging changes..."
git add -A
git status --short
echo ""
read -p "Commit message [Flutter rewrite v$VERSION — full native app]: " msg
msg="${msg:-Flutter rewrite v$VERSION — full native app}"
git commit -m "$msg"
echo "[OK] Committed."
echo ""

# ── Step 4: Push ──────────────────────────────────────────────────────────────
echo "[4/6] Pushing to GitHub..."
git push origin main
echo "[OK] Pushed."
echo ""

# ── Step 5: Check for built artifacts ────────────────────────────────────────
echo "[5/6] Checking for release artifacts..."
ARTIFACTS=()
MISSING=()

DEB="flowe_${VERSION}_amd64.deb"
APK="flowe_${VERSION}.apk"
EXE="flowe_setup.exe"

[ -f "$DEB" ] && ARTIFACTS+=("$DEB") || MISSING+=("$DEB (build on Linux: bash build_all.sh)")
[ -f "$APK" ] && ARTIFACTS+=("$APK") || MISSING+=("$APK (build via build_all.sh or build_all.bat)")
[ -f "$EXE" ] && ARTIFACTS+=("$EXE") || MISSING+=("$EXE (build on Windows: build_all.bat + NSIS)")

if [ ${#MISSING[@]} -gt 0 ]; then
  echo ""
  echo "  [WARN] Missing artifacts (will create release without them):"
  for m in "${MISSING[@]}"; do echo "    - $m"; done
  echo ""
  echo "  You can upload them later on github.com/thatspeedykid/flowe/releases"
  echo ""
fi

if [ ${#ARTIFACTS[@]} -gt 0 ]; then
  echo "  [OK] Found:"
  for a in "${ARTIFACTS[@]}"; do echo "    + $a ($(du -sh "$a" | cut -f1))"; done
fi
echo ""

# ── Step 6: Create GitHub release ────────────────────────────────────────────
echo "[6/6] Creating GitHub release $TAG..."

RELEASE_NOTES='## Flowe v1.7.0 — PrivacyChase

### New
- 📊 **Track tab** — log real transactions against your budget categories
- 💸 **Spending bars** — see how much of each budget category you'\''ve spent at a glance
- 🔴 **Over-budget alerts** — categories turn red with an OVER badge when exceeded
- 🧾 **Transaction log** — log purchases with category, amount, note, and date; tap to edit or delete
- 🗂️ **Category drill-down** — tap any category to see all its transactions for the month
- 📅 **Events mode** — access the event planner via pill toggle inside the Track tab

### Fixed
- ✅ **Upgrade-safe installs** — all platforms now preserve your data when installing over a previous version
- 🔒 **Android backup** — data.json is included in Google Drive backup and device transfers (Android 6+)
- 🪟 **Windows installer** — upgrade kills running instance before overwriting files; uninstall message clarified
- 🐧 **Linux DEB** — added `prerm`/`postrm` scripts; upgrade and remove never touch `~/.local/share/flowe/`

### Install

**Linux**
```bash
git clone https://github.com/thatspeedykid/flowe
cd flowe && bash build_all.sh
```

**Windows** — run `build_all.bat`

**Upgrade from any previous version:** Your data is kept automatically. No action needed.

---
MIT License · Built by PrivacyChase — privacychase.com'
GH_CMD="gh release create \"$TAG\" --title \"Flowe $TAG\" --notes \"$RELEASE_NOTES\" --repo \"$REPO\""
for a in "${ARTIFACTS[@]}"; do
  GH_CMD="$GH_CMD \"$a\""
done

eval $GH_CMD

echo ""
echo "=========================================="
echo "  [OK] Release $TAG published!"
echo "  https://github.com/$REPO/releases/tag/$TAG"
echo "=========================================="
echo ""

# Offer to upload missing artifacts later
if [ ${#MISSING[@]} -gt 0 ]; then
  echo "To upload missing artifacts later:"
  for m in "${MISSING[@]}"; do
    fname=$(echo "$m" | cut -d' ' -f1)
    echo "  gh release upload $TAG $fname --repo $REPO"
  done
fi
