<div align="center">

<img src="assets/icon_512.png" width="80" height="80" alt="Flowe logo">

# Flowe

**The file-first budgeting app.**  
**No accounts. No subscriptions. Ever.**

[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg?style=flat-square)](LICENSE)
[![Version](https://img.shields.io/badge/version-1.7.0-c8f560?style=flat-square)](#changelog)
[![Flutter](https://img.shields.io/badge/Flutter-3.x-54C5F8?style=flat-square&logo=flutter)](https://flutter.dev)
[![Platform](https://img.shields.io/badge/platform-Windows%20%7C%20Linux%20%7C%20Android%20%7C%20iOS-blue?style=flat-square)](#download)

*Your data lives on your device. We never touch it.*

</div>

---

## Why Flowe?

Most budget apps want your email, your bank login, and a monthly fee. Flowe doesn't.

Your data lives in a file on your device. Back it up how you want — copy a single line to your notes app, AirDrop it, email it, drop it in Google Drive. No cloud sync to break. No subscription to cancel. No account to forget the password to.

Flowe is fast, private, and completely offline. Always.

---

> **Note:** Flowe is transitioning to **PrivacyChase** as its official studio name in preparation for App Store and Google Play launches. Package IDs are moving from `com.example.flowe` to `com.privacychase.flowe`. See the [Upgrading](#upgrading-from-an-older-version) section for data migration details.

## Features

### 💰 Monthly Budget
- Fully customizable income and expense sections
- Tag rows: 💳 debt · 🏦 savings · 💰 income · 📦 other
- 6-month income vs expenses overview chart
- Carry over previous month's budget in one tap
- Export to **CSV** or **PDF** — save to Downloads or share anywhere
- CSV includes full debt snowball with payoff dates per debt
- PDF includes budget summary + full snowball section with timeline bars

### ❄️ Debt Snowball
- Track credit cards, loans, medical debt — anything with a balance
- Import debts directly from budget rows tagged 💳
- Full snowball payoff simulation with projected payoff dates
- **Balance-over-time chart** — visual payoff curve showing your debt melting away
- **Total cost breakdown** — stacked bar showing principal vs total interest paid
- Calendar date picker for due dates
- 🔴 red ≤3 days · 🟠 orange ≤7 days urgency badges

### 📈 Net Worth
- Track assets and liabilities side by side
- Dated snapshots with +/- delta vs previous snapshot
- Liabilities auto-populated from your snowball debts

### 🎉 Event Budgets
- Plan vacations, weddings, parties — any one-time spend
- Per-event budget cap with live progress bar
- Split calculator — people and amounts persist between sessions

### 🔒 Your Data, Your Rules
- All data stored in a single file on your device — nothing leaves without you
- **Copy Backup** — one tap encodes your entire budget into a single compact line and copies it to clipboard. Paste it anywhere: Notes, iMessage, email, Notion
- **Paste & Restore** — paste the line back on any device, any platform, to restore everything instantly. No files, no cloud, no account
- Zero telemetry. Zero analytics. Zero network requests. Ever.

---

## Download

| Platform | File | Status |
|---|---|---|
| Windows | `flowe_1.7.0_setup.exe` | ✅ Stable |
| Linux | `flowe_1.7.0_amd64.deb` | ✅ Stable |
| Android | `flowe_1.7.0.apk` | ✅ Stable |
| iOS | `flowe_1.7.0.ipa` | ✅ Stable — sideload via [Sideloadly](https://sideloadly.io) |
| macOS | `flowe_1.7.0.dmg` | ⚠️ Untested — not verified on hardware |

### ⚠️ About signing & SmartScreen warnings

Flowe releases are currently **unsigned**. This means:

- **Windows** will show a SmartScreen warning ("Windows protected your PC") when you run the installer. Click **More info → Run anyway** to proceed. This is normal for unsigned indie software.
- **Android** will warn about installing from unknown sources. Enable it once in your security settings.
- **iOS** requires sideloading via [Sideloadly](https://sideloadly.io) since there's no App Store listing yet.

Code signing certificates cost $200–400/year for Windows and $99/year for Apple. As a solo indie project, I'm holding off on that until there's more of a reason to spend it. The source code is fully open — you're welcome to build it yourself and verify nothing sketchy is happening.

---

## Build from source

See **[BUILDING.md](BUILDING.md)** for the full step-by-step guide covering every platform — including all dependencies (Flutter, Android Studio, Java, NSIS, Xcode, CocoaPods), exact install commands, and a troubleshooting section for every known error.

Quick start:

**Windows** (builds EXE + APK):
```bat
git clone https://github.com/thatspeedykid/flowe
cd flowe
build_all.bat
```

**Linux** (builds DEB):
```bash
git clone https://github.com/thatspeedykid/flowe
cd flowe
flutter build linux --release && bash build_deb_wsl.sh
```

**macOS** (builds DMG + IPA — requires Mac + Xcode):
```bash
git clone https://github.com/thatspeedykid/flowe
cd flowe
bash build_all_mac.sh
```

All outputs land in the `installers/` folder.

---

## Upgrading from an older version

**Desktop (Windows / Linux):** Just install over the top. Your data migrates automatically.

**Android:** Install the new APK over the existing one without uninstalling. The app will automatically detect and migrate your data from the old `com.example.flowe` package location on first launch. As a precaution, tap **Copy Backup** before upgrading — it takes one second and gives you a full restore point.

**iOS:** iOS ties app data to the bundle ID via a UUID container — there is no automatic path migration possible. **Before upgrading, tap Copy Backup and paste the line somewhere safe (Notes, iMessage, email).** After installing the new IPA, tap Paste & Restore and paste the line back. Everything comes back instantly.

**From flo (v1.0–v1.4):** Your old data migrates automatically on first launch on desktop. On mobile, use Copy Backup first.

---

## Data locations

| Platform | Path |
|---|---|
| Windows | `%APPDATA%\flowe\flowe\data.json` |
| Linux | `~/.local/share/flowe/flowe/data.json` |
| macOS | `~/Library/Application Support/flowe/flowe/data.json` |
| iOS / Android | App private storage — use Copy Backup to move data |

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
│       ├── track_screen.dart     ← spending journal + monthly summary
│       └── events_screen.dart    ← event budgets + split calculator
├── assets/                       ← icons for all platforms and sizes
├── build_all.bat                 ← Windows: EXE + APK + NSIS installer
├── build_all.sh                  ← Linux/WSL: DEB + APK
├── build_all_mac.sh              ← macOS: DMG + IPA
├── flowe_setup.nsi               ← NSIS Windows installer script
├── inject_icons.sh / .bat        ← platform icon injection helpers
└── installers/                   ← all build outputs land here
```

---

## License

MIT — free to use, modify, and distribute. See [LICENSE](LICENSE).

---

<div align="center">
  <sub>Built by <strong>PrivacyChase</strong> — software that respects you.<br>
  <a href="https://privacychase.com">privacychase.com</a></sub>
</div>
