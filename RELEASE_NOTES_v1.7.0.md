# Flowe v1.7.0 — Release Notes

## What's New

### Tab Restructure
- **Budget** tab now has two sub-tabs: **Budget** and **Transactions** — spending lives alongside planning
- **Snowball** is its own top-level tab (no longer nested under Track)
- **Events** restored as its own top-level tab
- Tab order: Budget · Snowball · Net Worth · Events

### Transactions — Rebuilt from Scratch
- Clean chronological spending journal replacing the old category-bar view
- Month navigator (← March 2026 →) — browse any past month
- Monthly summary card: total logged vs budgeted, progress bar, over-budget alert
- Transactions grouped by date: Today / Yesterday / Mar 5…
- Swipe left to delete, tap to edit
- Log button always visible at top right

### Debt Card Fixes (Snowball)
- Balance / Min Pay / APR fields now properly aligned — $ prefix sits tight next to number
- DUE SOON badge moved to the due date row where it makes contextual sense
- LAST 4 digits and card type dropdown moved to top-right of card header

### Split Calculator (Events)
- Total amount now **saves** — no longer resets when switching events or restarting
- "↓ From budget" button correctly persists the pulled value

### Font Size No Longer Resets
- Fixed a bug where changing font size then adding/deleting any row would reset it back to default
- Affected Snowball and Net Worth screens — now fixed across all screens

### Safe Area Fixes (Android & iOS)
- Status bar no longer overlaps the top header
- Bottom gesture bar / home indicator no longer overlaps the settings bar
- Uses `viewPadding` instead of `padding` for reliable insets on all Android nav modes

### Debt Cards — Last 4 Digits
- Add the last 4 digits of each card in the Snowball debt card header
- Payoff timeline shows `···8709` format
- Transactions can be tagged to a card via the Log dialog

### Linux Package
- Package renamed from `flo` to `flowe`
- Installing `flowe` automatically removes the old `flo` package
- User data migrated automatically from `~/.local/share/flo/` to `~/.local/share/flowe/`

---

## Bug Fixes
- Android backup_rules.xml lint error fixed (was blocking APK release builds)
- Windows build no longer corrupts `main.cpp` on repeat builds
- Events screen: adding a new event no longer throws a Dart syntax error

---

## Upgrading
Just install the new version over the old one — your data is safe on all platforms.

---

MIT License · Built by PrivacyChase — privacychase.com
