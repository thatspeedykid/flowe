# Flowe Changelog

---

## v1.4.0 — February 2026 *(Flutter Edition)*

Complete rewrite in Flutter. Same features, now a true native cross-platform app.

### New
- **Flutter rewrite** — native Linux/Windows/Android/iOS from one codebase. No browser, no Python server required
- **Budget row type tags** — tap to cycle: 💳 debt / 🏦 save / 💰 income / 📦 other. Color-coded pills
- **Import from Budget** — snowball tab can pull debt rows tagged 💳 directly as new debt entries
- **Sync min payments** — fuzzy name-matching syncs minimum payments from budget to snowball automatically
- **Swipe to delete** — sections, rows, debts, assets, snapshots, event items — swipe left on everything
- **Snapshot deltas** — net worth snapshots show +/- vs previous snapshot in green/red
- **Payoff timeline** — snowball shows all debts with projected payoff dates and months remaining
- **Due date badges** — 🔴 red ≤3 days, 🟠 orange ≤7 days on debt cards
- **Original balance tracking** — progress bars show how much of each debt has been paid off
- **Import/export backup** — compatible with all Flowe versions including v1.0–v1.3 Python/HTML format
- **Check for update** button in settings → opens GitHub releases
- **MIT license** included in package and about screen
- **App icon** — bar chart icon, installed at all hicolor sizes (16–512px)
- **☕ Buy me a coffee** — bottom bar, desktop only
- **Dark + light mode** — proper Flutter theming, no assertion errors
- **Linux .deb package** — `build_deb.sh` builds and installs in one command, handles upgrades

### Fixed
- Font scaling removed entirely (caused assertion crashes) — system default font used throughout
- Duplicate widget key errors in budget rows
- Settings sheet overflow on small screens
- Theme brightness mismatch on light mode switch
- Debt type filter mismatch (cc vs card)
- Carry over now copies all sections (income + expenses), not just income

---

## v1.3 — February 2026 *(Python/HTML)*

- **Click-and-drag scrolling** — drag anywhere to scroll with momentum
- **Touch-friendly** — native touch scrolling throughout
- **No text selection on drag** — feels like a native app
- **Check for update** — settings panel shows download link if update available
- **Server shuts down on close** — no more ghost processes
- **Proper installer** — `flo_setup.exe` via Inno Setup, user-scoped, no UAC prompts
- **Responsive layout** — fills full window at any resolution
- **Settings gear** — always pinned to far right of save bar

---

## v1.2 — February 2026 *(Python/HTML)*

- **Single-click launch fixed** — opens reliably every time
- **Split calculator redesigned** — independent from event total, per-person custom amounts
- **Settings gear** — dark/light toggle moved to ⚙️ gear
- **Light mode** — completely reworked with warm tones and proper contrast
- **Status bar & theme toggle** — inside tab bar so they don't hide when scrolling

---

## v1.1 — January 2026 *(Python/HTML)*

- Larger fonts and UI elements
- flo logo and Buy me a coffee button in header
- Open source branding
- Linux build support

---

## v1.0 — Initial release *(Python/HTML)*

- Monthly budget with CSV export and carry-over
- Debt snowball tracker with budget auto-sync
- Net worth tracker with snapshots
- Event budget planner with split cost calculator
- Dark/light theme
- Windows & Linux builds
