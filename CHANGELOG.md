# Flowe Changelog

---

## v1.6.0 — March 2026

### New
- **PDF export** — Budget screen exports a formatted PDF (save to Downloads or share)
- **CSV includes snowball** — debt table appended below budget rows in the same export
- **Snowball charts** — balance-over-time curve + principal vs interest cost breakdown bar
- **Export picker on mobile** — tap CSV or PDF to choose Save to Files or Share sheet
- **Copy Backup** — one tap copies a compact encoded backup line to clipboard; paste anywhere (Notes, email, iMessage) to save
- **Paste & Restore** — paste backup line back on any device to restore all data; no file needed
- **Android PDF to Downloads** — PDF saves directly to Downloads folder via native channel (no share sheet required)
- **share_plus** — share sheet on iOS/macOS for all exports

### Fixed
- Backup format upgraded to `FLOWE2:` (gzip+base64) — lines ~65% shorter than before
- Legacy `FLOWE1:` backups still restore correctly
- Restore now shows exact error message instead of generic "failed"
- `objective_c` dependency bumped to `^9.3.0` to fix pub resolution

### Platform status
- ✅ Windows — Stable
- ✅ Linux — Stable
- ✅ Android — Stable
- ✅ iOS — Stable
- 🧪 macOS — Untested

---

## v1.5.0 — February 2026

### New
- **Android export** — CSV saves directly to Downloads folder via MediaStore (no permissions needed on Android 10+)
- **iOS export** — CSV visible in Files app under On My iPhone > Flowe
- **Runtime permissions** — Android 9 and below now properly requests WRITE_EXTERNAL_STORAGE before saving
- **Font size control** — S / M / L selector in settings

### Fixed
- iOS build: `objective_c` dependency added to fix native assets error
- iOS build: Info.plist patched by build script instead of pre-placed (fixes flutter create conflict)
- Android 9: permission denied on first export now shows dialog and retries

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
