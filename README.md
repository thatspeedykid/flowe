<div align="center">

<img src="https://raw.githubusercontent.com/thatspeedykid/flo/main/github/flo_logo.svg" width="80" height="80" alt="flo logo">

# flo

**Take control of your money.**

[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg?style=flat-square)](LICENSE)
[![Open Source](https://img.shields.io/badge/open%20source-yes-brightgreen?style=flat-square)](#)
[![Platform](https://img.shields.io/badge/platform-Windows%20%7C%20Linux%20%7C%20Android-blue?style=flat-square)](#getting-started)
[![Flutter](https://img.shields.io/badge/Flutter-3.x-54C5F8?style=flat-square&logo=flutter)](https://flutter.dev)
[![Version](https://img.shields.io/badge/version-1.4.1-c8f560?style=flat-square)](#changelog)
[![Buy me a coffee](https://img.shields.io/badge/PayPal-Buy%20me%20a%20coffee-7aaa40?style=flat-square&logo=paypal)](https://www.paypal.com/paypalme/speeddevilx)

*Monthly budgets · Debt snowball · Net worth · Event planning · Split costs*
*100% offline · 100% open source · No accounts · No cloud · No ads*

**Current version: v1.4.1 — Flutter Edition**

</div>

---

## Screenshots

| Budget | Debt Snowball |
|:---:|:---:|
| ![Budget](github/screenshots/budget.png) | ![Snowball](github/screenshots/snowball.png) |

| Net Worth | Event Budget |
|:---:|:---:|
| ![Net Worth](github/screenshots/networth.png) | ![Events](github/screenshots/events.png) |

---

## What is flo?

**flo** is a free, open source personal finance app for people who want real control over their money — without handing it to a subscription service.

No accounts. No cloud. No ads. No paywalls. Your data lives in a plain file on your own machine. You own it completely.

Built with **Flutter** — a single codebase that runs natively on Windows, Linux, and Android.

---

## Features

### 💰 Monthly Budget
- Fully customizable income and expense sections
- Tag rows by type: 💳 debt / 🏦 savings / 💰 income / 📦 other
- 6-month income vs expenses chart
- Carry over previous month in one tap
- Export to CSV, swipe to delete

### ❄️ Debt Snowball
- Track credit cards, loans, medical debt
- Import debts directly from budget rows tagged 💳
- Full snowball payoff simulation with projected dates
- Calendar date picker for due dates
- 🔴 red ≤3 days, 🟠 orange ≤7 days alerts

### 📈 Net Worth
- Track assets and liabilities
- Dated snapshots with +/- delta vs previous
- Liabilities auto-linked from snowball

### 🎉 Event Budgets
- Plan vacations, weddings, any event
- Budget cap with progress bar
- Split calculator — people and amounts persist between sessions

### ⚙️ App
- Dark and light theme
- Text size selector (3 sizes)
- Delete confirmations throughout — no accidental data loss
- Import/export backup — compatible with all flo versions (v1.0–v1.4)
- Check for update button

---

## Getting Started

### Build everything from Windows (recommended)

Requires: [Flutter](https://flutter.dev/get-started/install/windows) · [Android Studio](https://developer.android.com/studio) · [NSIS](https://nsis.sourceforge.io) · [WSL](https://learn.microsoft.com/en-us/windows/wsl/install)

```bat
git clone https://github.com/thatspeedykid/flo
cd flo
build_all.bat
```

Produces:
- `flo_setup.exe` — Windows installer
- `flo_1.4.1.apk` — Android APK
- `flo_1.4.1_amd64.deb` — Linux deb (via WSL)

---

### Build on Linux

Requires: [Flutter](https://docs.flutter.dev/get-started/install/linux)

```bash
git clone https://github.com/thatspeedykid/flo
cd flo
bash build_all.sh
```

Produces:
- `flo_1.4.1_amd64.deb` — installs and launches from app menu
- `flo_1.4.1.apk` — Android APK (requires Android SDK)

---

### Upgrading from v1.0–v1.3 (Python/HTML version)

Your existing data migrates automatically on first launch. No manual steps needed.

To import manually: Settings → Import Backup → point to your old `data.json`

---

## Data locations

| Platform | Path |
|---|---|
| Linux | `~/.local/share/flo/flo/data.json` |
| Windows | `%APPDATA%\Roaming\flo\flo\data.json` |
| Android | App private storage |

---

## Project structure

```
flo/
├── lib/
│   ├── main.dart                 ← app shell, navigation, settings
│   ├── models/data.dart          ← all data models + storage
│   └── screens/
│       ├── budget_screen.dart
│       ├── snowball_screen.dart
│       ├── networth_screen.dart
│       └── events_screen.dart
├── assets/                       ← icons (all sizes)
├── build_all.bat                 ← Windows: builds EXE + APK + DEB + installer
├── build_all.sh                  ← Linux: builds DEB + APK
├── flo_setup.nsi                 ← NSIS Windows installer script
├── legacy/                       ← original Python/HTML v1.0–v1.3 source
├── LICENSE                       ← MIT
└── README.md
```

---

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for full history.

---

## Support

[![Buy me a coffee](https://img.shields.io/badge/PayPal-Buy%20me%20a%20coffee-00457C?style=for-the-badge&logo=paypal&logoColor=white)](https://www.paypal.com/paypalme/speeddevilx)

---

## License

MIT — see [LICENSE](LICENSE). Free to use, modify, and distribute.
