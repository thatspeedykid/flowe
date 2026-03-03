<div align="center">

<img src="assets/icon_512.png" width="80" height="80" alt="Flowe logo">

# Flowe

**The file-first budgeting app.**
**No accounts. No subscriptions. Ever.**

[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg?style=flat-square)](LICENSE)
[![Version](https://img.shields.io/badge/version-1.6.0-c8f560?style=flat-square)](#changelog)
[![Flutter](https://img.shields.io/badge/Flutter-3.x-54C5F8?style=flat-square&logo=flutter)](https://flutter.dev)
[![Platform](https://img.shields.io/badge/platform-Windows%20%7C%20Linux%20%7C%20Android%20%7C%20iOS%20%7C%20macOS-blue?style=flat-square)](#getting-started)

*Your data lives on your device. We never touch it.*

</div>

---

## Why Flowe?

Most budget apps want your email, your bank login, and a monthly fee. Flowe doesn't.

Your data lives on your device. Back it up how you want — AirDrop it, email it, drop it in Google Drive, or just leave it where it is. No cloud sync to break. No subscription to cancel. No account to forget the password to.

Flowe is fast, private, and completely offline. Always.

---

## Features

### 💰 Monthly Budget
- Fully customizable income and expense sections
- Tag rows: 💳 debt · 🏦 savings · 💰 income · 📦 other
- 6-month income vs expenses chart
- Carry over previous month in one tap
- Export to **CSV** or **PDF** — save to Downloads or share anywhere

### ❄️ Debt Snowball
- Track credit cards, loans, medical debt — anything
- Import debts directly from budget rows tagged 💳
- Full snowball payoff simulation with projected dates
- **Balance-over-time chart** — visual payoff curve
- **Total cost breakdown** — principal vs interest stacked bar
- Calendar date picker for due dates with 🔴/🟠 urgency badges

### 📈 Net Worth
- Track assets and liabilities
- Dated snapshots with +/- delta vs previous snapshot
- Liabilities auto-linked from snowball debts

### 🎉 Event Budgets
- Plan vacations, weddings, parties — any event
- Per-event budget cap with live progress bar
- Split calculator — people and amounts persist between sessions

### 🔒 Your Data, Your Rules
- All data stored in a single file on your device
- **Copy Backup** — one tap copies a compact encoded line to clipboard
- **Paste & Restore** — paste it back on any device to restore everything
- Export CSV + PDF from Budget screen (save or share)
- Zero telemetry, zero analytics, zero network requests

---

## Download

| Platform | File | Status |
|---|---|---|
| Windows | `flowe_1.6.0_setup.exe` | ✅ Stable |
| Linux | `flowe_1.6.0_amd64.deb` | ✅ Stable |
| Android | `flowe_1.6.0.apk` | ✅ Stable |
| iOS | `flowe_1.6.0.ipa` | ✅ Stable *(sideload via [Sideloadly](https://sideloadly.io))* |
| macOS | `flowe_1.6.0.dmg` | 🧪 Untested |

---

## Build from source

### Windows (builds EXE + APK)
Requires: [Flutter](https://flutter.dev/get-started/install/windows) · [Android Studio](https://developer.android.com/studio) · [NSIS](https://nsis.sourceforge.io)

```bat
git clone https://github.com/thatspeedykid/flowe
cd flowe
build_all.bat
```

### Linux / WSL (builds DEB + APK)
Requires: [Flutter](https://docs.flutter.dev/get-started/install/linux)

```bash
git clone https://github.com/thatspeedykid/flowe
cd flowe
bash build_all.sh
```

### Mac (builds DMG + IPA)
Requires: Flutter · Xcode · CocoaPods · create-dmg

```bash
git clone https://github.com/thatspeedykid/flowe
cd flowe
bash build_all_mac.sh
```

All outputs go to the `installers/` folder.

---

## Upgrading from flo (v1.0–v1.4)

Your data migrates automatically on first launch. No manual steps needed.

---

## Data locations

| Platform | Path |
|---|---|
| Windows | `%APPDATA%\flowe\flowe\data.json` |
| Linux | `~/.local/share/flowe/flowe/data.json` |
| macOS | `~/Library/Application Support/flowe/flowe/data.json` |
| iOS / Android | App private storage (export via share sheet) |

---

## Project structure

```
flowe/
├── lib/
│   ├── main.dart                 ← app shell, navigation, settings, backup
│   ├── models/data.dart          ← all data models + storage + migration
│   └── screens/
│       ├── budget_screen.dart    ← monthly budget + CSV/PDF export
│       ├── snowball_screen.dart  ← debt snowball + charts
│       ├── networth_screen.dart  ← net worth snapshots
│       └── events_screen.dart    ← event budgets + split calculator
├── assets/                       ← icons (all sizes, all platforms)
├── build_all.bat                 ← Windows: EXE + APK + installer
├── build_all.sh                  ← Linux/WSL: DEB + APK
├── build_all_mac.sh              ← Mac: DMG + IPA
├── flowe_setup.nsi               ← NSIS Windows installer script
├── inject_icons.sh / .bat        ← platform icon injection
└── installers/                   ← all build outputs go here
```

---

## License

MIT — free to use, modify, and distribute. See [LICENSE](LICENSE).
