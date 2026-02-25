#!/bin/bash
set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "=== flo — Installing source files ==="
mkdir -p ~/flo_flutter/lib/models ~/flo_flutter/lib/screens ~/flo_flutter/assets

cp -fv "$SCRIPT_DIR/lib/main.dart"                     ~/flo_flutter/lib/main.dart
cp -fv "$SCRIPT_DIR/lib/models/data.dart"              ~/flo_flutter/lib/models/data.dart
cp -fv "$SCRIPT_DIR/lib/screens/budget_screen.dart"    ~/flo_flutter/lib/screens/budget_screen.dart
cp -fv "$SCRIPT_DIR/lib/screens/snowball_screen.dart"  ~/flo_flutter/lib/screens/snowball_screen.dart
cp -fv "$SCRIPT_DIR/lib/screens/networth_screen.dart"  ~/flo_flutter/lib/screens/networth_screen.dart
cp -fv "$SCRIPT_DIR/lib/screens/events_screen.dart"    ~/flo_flutter/lib/screens/events_screen.dart
cp -fv "$SCRIPT_DIR/pubspec.yaml"                      ~/flo_flutter/pubspec.yaml
cp -fv "$SCRIPT_DIR/build_deb.sh"                      ~/flo_flutter/build_deb.sh
cp -fv "$SCRIPT_DIR/assets/"*.png                      ~/flo_flutter/assets/
cp -fv "$SCRIPT_DIR/assets/"*.ico                      ~/flo_flutter/assets/ 2>/dev/null || true
chmod +x ~/flo_flutter/build_deb.sh

echo ""
echo "✓ All files installed (including assets)"
echo ""
echo "Options:"
echo "  Preview:        cd ~/flo_flutter && flutter run -d linux"
echo "  Build & install: cd ~/flo_flutter && bash build_deb.sh"
echo ""

read -p "Build and install the deb now? [y/N] " ans
if [[ "$ans" =~ ^[Yy]$ ]]; then
  cd ~/flo_flutter
  bash build_deb.sh
fi
