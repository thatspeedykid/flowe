#!/bin/bash
set -e
PROJECT="$1"
cd "$PROJECT"

# Strip Windows /mnt/ paths and snap Flutter from PATH
# Snap Flutter bundles an incomplete read-only LLVM-10 that's missing ld.lld
export PATH=$(echo "$PATH" | tr ':' '\n' | grep -v '^/mnt/' | grep -v '^/snap/flutter' | grep -v '^/snap/bin' | tr '\n' ':')
export PATH="$HOME/flutter/bin:$PATH"

echo "[WSL] dir: $(pwd)"
echo "[WSL] flutter: $(which flutter 2>/dev/null || echo NOT FOUND)"

# Detect snap Flutter still being picked up
if which flutter 2>/dev/null | grep -q '/snap/'; then
    echo ""
    echo "[WSL] ERROR: snap Flutter detected. It has a broken LLVM that can't be fixed."
    echo "[WSL] Fix it once with these commands, then re-run:"
    echo ""
    echo "    sudo snap remove flutter"
    echo "    git clone https://github.com/flutter/flutter.git -b stable --depth 1 ~/flutter"
    echo "    echo 'export PATH=\"\$PATH:\$HOME/flutter/bin\"' >> ~/.bashrc"
    echo "    source ~/.bashrc"
    echo "    flutter precache --linux"
    echo ""
    exit 1
fi

if ! command -v flutter &>/dev/null; then
    echo "[WSL] ERROR: Flutter not found."
    echo "[WSL] Run:"
    echo "    git clone https://github.com/flutter/flutter.git -b stable --depth 1 ~/flutter"
    echo "    echo 'export PATH=\"\$PATH:\$HOME/flutter/bin\"' >> ~/.bashrc"
    echo "    source ~/.bashrc"
    echo "    flutter precache --linux"
    exit 1
fi

# Ensure linker is available
if ! command -v ld.lld &>/dev/null && ! command -v ld &>/dev/null; then
    echo "[WSL] Installing missing linker..."
    sudo apt-get install -y lld binutils
fi

flutter create --platforms=linux . 2>&1 | tail -3
echo "[WSL] Building Linux release..."
flutter build linux --release
echo "[WSL] Packaging .deb..."
bash build_deb_wsl.sh
