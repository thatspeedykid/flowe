<div align="center">

# flo

**Simple budget app and tracking.**

[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg?style=flat-square)](LICENSE)
[![Open Source](https://img.shields.io/badge/open%20source-yes-brightgreen?style=flat-square)](#)
[![Platform](https://img.shields.io/badge/platform-Windows%20%7C%20Linux-blue?style=flat-square)](#getting-started)
[![Python](https://img.shields.io/badge/python-3.8%2B-yellow?style=flat-square)](https://python.org)
[![Buy me a coffee](https://img.shields.io/badge/PayPal-Buy%20me%20a%20coffee-7aaa40?style=flat-square&logo=paypal)](https://www.paypal.com/paypalme/speeddevilx)

*Monthly budgets · Debt snowball · Net worth · Event planning — 100% offline, 100% open source.*

</div>

---

## What is flo?

**flo** is a free, open source personal finance app built for people who want real control over their money without handing it to a subscription service.

No accounts. No cloud. No ads. No paywalls. Your data is a plain file sitting on your own machine — you own it completely.

It runs as a native-feeling desktop window using Edge or Chrome's app mode, so there's no address bar, no browser tabs, just the app. Under the hood it's a lightweight Python server and a single HTML file — the entire codebase is small enough to read in an afternoon. Fork it, modify it, make it yours.

Whether you're trying to get out of debt, track your net worth over time, or plan a big event without blowing your budget, flo gives you the tools without the bloat.

---

## Screenshots

| Budget | Debt Snowball |
|:---:|:---:|
| ![Budget](github/screenshots/budget.png) | ![Snowball](github/screenshots/snowball.png) |

| Net Worth | Event Budget |
|:---:|:---:|
| ![Net Worth](github/screenshots/networth.png) | ![Events](github/screenshots/events.png) |

> Replace placeholder images in `github/screenshots/` with real screenshots after running the app.

---

## Features

**Monthly Budget**
- Fully customizable income and expense sections
- 6-month income vs expenses bar chart
- Carry over last month as a starting point
- Export to CSV and copy to clipboard
- Auto-saves 2.5 seconds after any change

**Debt Snowball**
- Track credit cards, loans, and any other debt
- Minimum payments auto-sync from your budget tab by name matching
- Full snowball payoff simulation with months-to-freedom
- Due date alerts — orange within 7 days, red within 3
- Progress bars showing how much of each debt is paid off
- 15% suggestion card splits leftover income across debts

**Net Worth**
- Track assets: checking, savings, investments, anything
- Liabilities auto-pull from your debt balances — no double entry
- Save dated snapshots and see +/- delta between each one

**Event Budgets**
- Plan vacations, weddings, holidays, any one-time event
- Budget cap with real-time progress bar
- Mark individual items as paid
- Split cost calculator across any number of people

**Other**
- Dark and light theme, saved across sessions
- Keyboard friendly
- Works on 768px+ screens

---

## Getting Started

### Run from source (any platform)

```bash
git clone https://github.com/yourusername/flo
cd flo/src
python server.py
```

Then open `http://127.0.0.1:5757/app.html` in your browser.

No dependencies. Pure Python stdlib. Works on Python 3.8+.

---

### Build a standalone executable

**Windows**

Requirements: Python 3.8–3.12 on PATH.

Just double-click `build_windows.bat`. It installs pyinstaller, generates the icon, and produces `src/dist/flo.exe`.

Double-click `flo.exe` to run. Opens in Edge app-mode — no browser UI, no address bar.

> Use Python 3.8–3.12. Python 3.13+ may have issues with some PyInstaller hooks.

**Linux**

```bash
chmod +x build_linux.sh && ./build_linux.sh
# Output: src/dist/flo
```

Opens in Chrome or Chromium app-mode. To install system-wide:

```bash
sudo cp src/dist/flo /usr/local/bin/flo
```

---

## How it works

| Layer | Details |
|---|---|
| Frontend | Single HTML file — no framework, no build step |
| Backend | Python `http.server` (stdlib only) |
| Window | Edge or Chrome launched in `--app=` mode |
| Data | Plain JSON file in your user data folder |

**Data locations:**

| Platform | Path |
|---|---|
| Windows | `%APPDATA%\flo\data.json` |
| Linux | `~/.local/share/flo/data.json` |

Data is never stored inside the app folder. Upgrading just means replacing the exe — your data is untouched.

---

## Project structure

```
flo/
├── src/
│   ├── app.html            <- entire frontend (HTML + CSS + JS)
│   ├── server.py           <- Python HTTP server + data storage
│   ├── flo_win.py          <- Windows launcher
│   ├── flo_linux.py        <- Linux launcher
│   ├── flo_win.spec        <- PyInstaller Windows spec
│   ├── flo_linux.spec      <- PyInstaller Linux spec
│   └── generate_icon.py    <- Generates flo.ico before build
├── github/
│   └── screenshots/
├── build_windows.bat
├── build_linux.sh
├── .gitignore
├── LICENSE
└── README.md
```

---

## Support

[![Buy me a coffee](https://img.shields.io/badge/PayPal-Buy%20me%20a%20coffee-00457C?style=for-the-badge&logo=paypal&logoColor=white)](https://www.paypal.com/paypalme/speeddevilx)

---

## License

MIT — see [LICENSE](LICENSE).
