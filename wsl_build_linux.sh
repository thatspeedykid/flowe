#!/bin/bash
set -e
PROJECT="$1"
cd "$PROJECT"

# Use Linux Flutter only — strip Windows /mnt/ paths
export PATH=$(echo "$PATH" | tr ':' '\n' | grep -v '^/mnt/' | tr '\n' ':')
export PATH="$HOME/flutter/bin:$PATH"

echo "[WSL] dir: $(pwd)"
echo "[WSL] flutter: $(which flutter 2>/dev/null || echo NOT FOUND)"

if ! command -v flutter &>/dev/null; then
    echo "[WSL] ERROR: Flutter not found. Run setup_wsl_flutter.bat first."
    exit 1
fi

# Check for lld linker — must be pre-installed via setup_wsl_flutter.bat
if ! command -v ld.lld &>/dev/null; then
    echo "[WSL] ERROR: lld linker not found."
    echo "[WSL] Open WSL and run: sudo apt-get install -y lld clang cmake ninja-build pkg-config libgtk-3-dev"
    exit 1
fi

flutter create --platforms=linux . 2>&1 | tail -3
echo "[WSL] Building Linux release..."
flutter build linux --release
echo "[WSL] Packaging .deb..."
bash build_deb_wsl.sh
