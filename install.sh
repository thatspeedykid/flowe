#!/bin/bash
set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "=== flo v1.4.1 — Installing source files ==="
mkdir -p ~/flo_flutter/lib/models ~/flo_flutter/lib/screens ~/flo_flutter/assets

cp -fv "$SCRIPT_DIR/lib/main.dart"                     ~/flo_flutter/lib/main.dart
cp -fv "$SCRIPT_DIR/lib/models/data.dart"              ~/flo_flutter/lib/models/data.dart
cp -fv "$SCRIPT_DIR/lib/screens/budget_screen.dart"    ~/flo_flutter/lib/screens/budget_screen.dart
cp -fv "$SCRIPT_DIR/lib/screens/snowball_screen.dart"  ~/flo_flutter/lib/screens/snowball_screen.dart
cp -fv "$SCRIPT_DIR/lib/screens/networth_screen.dart"  ~/flo_flutter/lib/screens/networth_screen.dart
cp -fv "$SCRIPT_DIR/lib/screens/events_screen.dart"    ~/flo_flutter/lib/screens/events_screen.dart
cp -fv "$SCRIPT_DIR/pubspec.yaml"                      ~/flo_flutter/pubspec.yaml
cp -fv "$SCRIPT_DIR/build_deb.sh"                      ~/flo_flutter/build_deb.sh
cp -fv "$SCRIPT_DIR/build_all.sh"                      ~/flo_flutter/build_all.sh
cp -fv "$SCRIPT_DIR/assets/"*.png                      ~/flo_flutter/assets/
cp -fv "$SCRIPT_DIR/assets/"*.ico                      ~/flo_flutter/assets/ 2>/dev/null || true
chmod +x ~/flo_flutter/build_deb.sh ~/flo_flutter/build_all.sh

echo ""
echo "✓ All files installed"
echo ""
echo "  Quick build:    cd ~/flo_flutter && bash build_deb.sh"
echo "  All platforms:  cd ~/flo_flutter && bash build_all.sh"
echo "  Preview only:   cd ~/flo_flutter && flutter run -d linux"
echo ""
read -p "Build and install now? [y/N] " ans
if [[ "$ans" =~ ^[Yy]$ ]]; then
  cd ~/flo_flutter
  bash build_deb.sh
fi
