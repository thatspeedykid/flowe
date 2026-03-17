# Flowe v1.7.0 — Release Notes

## Platform Status

| Platform | Status |
|---|---|
| Android APK | ✅ Tested |
| Windows Installer | ✅ Tested |
| Linux .deb | ✅ Tested |
| macOS DMG | ⚠️ Untested — built but not verified on hardware |
| iOS IPA | ⚠️ Untested — built but not verified on device |

---

## What's New

### Tab Restructure
The app layout has been reorganised for clarity. **Budget** now has two sub-tabs — **Budget** and **Transactions** — so your spending lives right next to your planning. **Snowball**, **Net Worth**, and **Events** are each their own top-level tab.

Tab order: Budget · Snowball · Net Worth · Events

### Transactions — Rebuilt from Scratch
The old category-bar view has been replaced with a clean chronological spending journal.
- Month navigator (← March 2026 →) to browse any past month
- Monthly summary card showing total logged vs budgeted with a progress bar and over-budget alert
- Entries grouped by date: Today / Yesterday / Mar 5…
- Swipe left to delete, tap to edit
- Log button always visible at top right

### Split Calculator (Events)
The total amount now **saves** correctly — it no longer resets when you switch events or restart the app. The "↓ From budget" button also persists the pulled value.

### Font Size No Longer Resets
Fixed a bug where changing the font size and then adding or deleting any row would silently reset it back to the default. This affected the Snowball and Net Worth screens.

### Safe Area Fixes (Android & iOS)
The status bar no longer overlaps the top header, and the bottom gesture bar / home indicator no longer overlaps the footer. Switched from `padding` to `viewPadding` for reliable insets across all Android navigation modes and iOS home indicator variants.

### Debt Card Field Alignment (Snowball)
Balance, Min Pay, and APR fields are now properly aligned. The $ prefix sits flush next to the number field. The DUE SOON badge has been moved to the due date row where it belongs.

### Linux Package Rename
The Linux package has been renamed from `flo` to `flowe`. Installing the new `.deb` automatically removes the old `flo` package and migrates your data from `~/.local/share/flo/` to `~/.local/share/flowe/`. No manual steps needed.

---

## Bug Fixes
- Android `backup_rules.xml` lint error fixed (was blocking APK release builds)
- Windows build no longer corrupts `main.cpp` on repeat builds
- Events screen: adding a new event no longer throws a Dart syntax error
- Linux: desktop shortcut (app launcher) now appears correctly after install
- Linux: software centers (GNOME Software, KDE Discover) now show full app details and release notes

---

## Data Safety
Installing over an existing version will never delete your data on any platform.

| Platform | Data Location |
|---|---|
| Windows | `%APPDATA%\flowe\flowe\data.json` |
| Linux | `~/.local/share/flowe/flowe/data.json` |
| Android | App internal storage (backed up via Google Backup) |
| macOS | `~/Library/Application Support/flowe/flowe/data.json` |
| iOS | App container (backed up via iCloud) |

---

## Changelog

### v1.7.0 — March 2026
- feat: Transactions screen rebuilt as spending journal with month nav and summary card
- feat: Budget tab split into Budget + Transactions sub-tabs
- feat: Snowball, Net Worth, Events promoted to top-level tabs
- feat: Split calculator total persists to disk
- feat: AppStream metainfo added for Linux software centers
- fix: Font size no longer resets on row add/delete (Snowball, Net Worth)
- fix: Status bar overlap on Android/iOS (viewPadding.top)
- fix: Gesture bar overlap on Android/iOS (viewPadding.bottom)
- fix: Tablet layout content area now clears status bar
- fix: Debt card Balance/MinPay/APR field alignment
- fix: DUE SOON badge repositioned to due date row
- fix: Split calculator "↓ From budget" now saves correctly
- fix: Linux desktop shortcut deleted by postinst script (flo.desktop vs flowe.desktop typo)
- fix: Linux package rename flo → flowe with preinst conflict removal
- fix: Android backup_rules.xml invalid exclude path lint error
- fix: Windows main.cpp corruption on repeat builds
- fix: Events screen Dart syntax error on new event add
- fix: Windows Runner.rc now includes FileDescription, ProductName, CompanyName, LegalCopyright
- fix: macOS/iOS plist now includes NSHumanReadableCopyright and CFBundleGetInfoString
- chore: Android strings.xml added with app name and description
- chore: fastlane changelog added for Android (build 9)

### v1.6.0
- Events tab with split calculator
- Dark and light mode toggle
- CSV and PDF export
- 6-month budget overview chart

### v1.5.0
- Debt snowball calculator
- Net worth tracker with snapshots
- Settings screen with font size control

---

MIT License · Built by PrivacyChase — privacychase.com
