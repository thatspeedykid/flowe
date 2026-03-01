<div align="center">

<img src="assets/icon_512.png" width="80" height="80" alt="Flowe logo">

# Flowe

**The file-first budgeting app.**
**No accounts. No subscriptions. Ever.**

[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg?style=flat-square)](LICENSE)
[![Version](https://img.shields.io/badge/version-1.5.0-c8f560?style=flat-square)](#changelog)
[![Flutter](https://img.shields.io/badge/Flutter-3.x-54C5F8?style=flat-square&logo=flutter)](https://flutter.dev)
[![Platform](https://img.shields.io/badge/platform-Windows%20%7C%20Linux%20%7C%20Android%20%7C%20iOS%20%7C%20macOS-blue?style=flat-square)](#getting-started)

*Your data lives in a file. You own it. We never touch it.*

</div>

---

## Why Flowe?

Most budget apps want your email, your bank login, and a monthly fee. Flowe doesn't.

Your budget is a file on your device. You back it up how you want — AirDrop it, email it, drop it in Google Drive, or just leave it on your hard drive. No cloud sync to break. No subscription to cancel. No account to forget the password to.

Flowe is fast, private, and completely offline. Always.

---

## Features

### 💰 Monthly Budget
- Fully customizable income and expense sections
- Tag rows: 💳 debt · 🏦 savings · 💰 income · 📦 other
- 6-month income vs expenses chart
- Carry over previous month in one tap
- Export to CSV — saves to your Downloads folder
- Share CSV via AirDrop, Messages, email, or any app

### ❄️ Debt Snowball
- Track credit cards, loans, medical debt — anything
- Import debts directly from budget rows tagged 💳
- Full snowball payoff simulation with projected dates
- Calendar date picker for due dates
- 🔴 red ≤3 days · 🟠 orange ≤7 days payment alerts

### 📈 Net Worth
- Track assets and liabilities
- Dated snapshots with +/- delta vs previous snapshot
- Liabilities auto-linked from snowball

### 🎉 Event Budgets
- Plan vacations, weddings, parties — any event
- Per-event budget cap with live progress bar
- Split calculator — people and amounts persist between sessions

### 🔒 Your Data, Your Rules
- All data stored in a single `data.json` file on your device
- Backup exports to your **Downloads folder** on every platform
- **Native share support** — AirDrop (iOS/macOS), Android share sheet, email, messaging apps, cloud upload — your choice
- Import backup from any previous Flowe or flo installation
- Zero telemetry, zero analytics, zero network requests

---

## Download

| Platform | File |
|---|---|
| Windows | `flowe_1.5.0_setup.exe` |
| Linux | `flowe_1.5.0_amd64.deb` |
| Android | `flowe_1.5.0.apk` |
| macOS | `flowe_1.5.0.dmg` *(alpha)* |
| iOS | `flowe_1.5.0.ipa` *(alpha — sideload via Sideloadly)* |

---

## Build from source

### Windows (builds EXE + APK)
Requires: [Flutter](https://flutter.dev/get-started/install/windows) · [Android Studio](https://developer.android.com/studio) · [NSIS](https://nsis.sourceforge.io) · [WSL](https://learn.microsoft.com/en-us/windows/wsl/install)

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

Your data migrates automatically on first launch. The installer also handles it — no manual steps needed.

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
│       ├── budget_screen.dart    ← monthly budget + CSV export
│       ├── snowball_screen.dart  ← debt snowball
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
