#!/bin/bash
# Run this once after flutter create --platforms=macos
# Fixes blank window on macOS by setting correct entitlements
cd "$(dirname "$0")"

RELEASE_ENT="macos/Runner/Release.entitlements"
DEBUG_ENT="macos/Runner/DebugProfile.entitlements"

for ENT in "$RELEASE_ENT" "$DEBUG_ENT"; do
  if [ -f "$ENT" ]; then
    cat > "$ENT" << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.app-sandbox</key>
    <true/>
    <key>com.apple.security.cs.allow-jit</key>
    <true/>
    <key>com.apple.security.network.client</key>
    <true/>
    <key>com.apple.security.files.user-selected.read-write</key>
    <true/>
    <key>com.apple.security.files.downloads.read-write</key>
    <true/>
</dict>
</plist>
PLIST
    echo "[OK] Fixed: $ENT"
  fi
done
