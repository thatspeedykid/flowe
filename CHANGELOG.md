# Flowe Changelog

---

## v1.7.5 — March 2026

### Fixed
- **App icon** — replaced default Flutter icon with Flowe icon on all platforms (Android, iOS, Windows, Linux, macOS)
- **Splash screen** — replaced Flutter default splash with Flowe branded splash on Android and iOS
- **Settings panel** — removed platform list, added privacychase.com link
- **Version bump** — 1.7.0 → 1.7.5

---

## v1.7.0 — March 2026

### New
- **Track tab** — replaces Events in the bottom nav; log real transactions against your budget categories
- **Spending bars** — each expense category shows a progress bar: spent vs budgeted, colour turns red when over
- **Over-budget badge** — categories exceeding their budget get a red OVER pill
- **Transaction log** — per-transaction list with date, category tag, note, and amount; tap any row to edit or delete
- **Category detail sheet** — tap a category card to see all its transactions for the month
- **Events mode pill** — toggle within Track tab to access the Event planner (full Events screen integration coming in v1.8)
- **Transaction model** — new `Transaction` class stored in `data.json`, fully backward-compatible (existing saves load fine)

### Fixed
- **Upgrade-safe installs** — installing a new version over an old one never deletes data on any platform
- **Windows installer** — kills running flowe.exe before overwriting files; uninstall message now tells users where data lives
- **Linux DEB** — added `prerm` (stops running instance) and `postrm` (refreshes desktop cache); neither script ever touches `~/.local/share/flowe/`
- **Android backup** — `allowBackup="true"` + `backup_rules.xml` + `data_extraction_rules.xml` added; data.json is now included in Google Drive backup and device-to-device transfers (Android 6+, Android 12+)
- **Old flo → Flowe data migration** (Windows + Linux) — now checks if new data.json already exists before copying, preventing overwrite on re-install

### Internal
- `Transaction` added to `data.dart` with `toJson`/`fromJson` and safe migration (missing field defaults to empty list)
- All screens updated to pass `transactions` through `FloData` copy constructors
- pubspec bumped to `1.7.0+9`

---

## v1.6.0 — March 2026

### New
- **Debt snowball charts** — balance-over-time area chart + principal vs interest cost breakdown stacked bar
- **PDF export** — full budget report with snowball section, per-debt payoff timeline, and visual progress bars
- **CSV includes full snowball** — payoff months and dates per debt appended below budget rows
- **Mobile export picker (Android)** — choose Save to Downloads or Share when exporting CSV/PDF
- **iOS export** — goes straight to native share sheet (Save to Files is built in)
- **Copy Backup** — encodes entire app state into a single compact clipboard line (gzip + base64, `FLOWE2:` format)
- **Paste & Restore** — paste backup line on any device/platform to restore everything; no file needed
- **Android PDF to Downloads** — PDF saves directly via native `saveBytesToDownloads` channel (no share sheet required)

### Fixed
- **Windows CSV/PDF export crash** — `RangeError: Not in range 0..50: -1` — Windows path separator `\` vs `/` caused `substring(0,-1)` crash. Fixed with platform-aware separator detection
- **Restore error messages** — now shows actual decode error instead of generic "is the backup line complete?"
- **Backup line length** — new `FLOWE2:` format is ~65% shorter than old `FLOWE1:` (gzip compression before base64)
- **Legacy `FLOWE1:` backups** — still restore correctly on new version
- **`objective_c` dependency** — pinned to `^9.3.0` to fix pub resolution failure on iOS/macOS builds
- **Android 9 export permission** — `WRITE_EXTERNAL_STORAGE` runtime dialog now properly requested and save retried after grant
- **Android PDF binary save** — PDFs were falling back to share sheet on "Save" choice; fixed with native `saveBytesToDownloads` MediaStore channel

### Platform status
- ✅ Windows — Stable
- ✅ Linux — Stable
- ✅ Android — Stable
- ✅ iOS — Stable
- 🧪 macOS — Untested (no bare-metal Mac)

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
