# Flowe v1.6.0

> The biggest update since the Flutter rewrite. Better exports, smarter backups, and your first look at real debt payoff charts.

---

## ⚠️ A note on signing

These binaries are **unsigned**. Windows will show a SmartScreen warning — click **More info → Run anyway**. Android needs "Install from unknown sources" enabled once. iOS requires sideloading via [Sideloadly](https://sideloadly.io).

Signing costs $200–400/yr for Windows and $99/yr for Apple. As a solo project I'm not spending that yet. The full source is here — build it yourself and see exactly what's in it.

---

## Platform status

| Platform | Status |
|---|---|
| ✅ Windows | Stable |
| ✅ Linux | Stable |
| ✅ Android | Stable |
| ✅ iOS | Stable (sideload via Sideloadly) |
| 🧪 macOS | Untested — no bare-metal Mac to test on |

---

## 🆕 What's new

### Debt Snowball Charts
The snowball tab now shows you the full picture visually, not just numbers.

**Balance over time** — a filled area chart that shows your total debt balance from today down to zero. Watch the curve. That's your financial future bending in the right direction.

**Total cost breakdown** — a stacked bar splitting every dollar you'll spend: what's principal (money you actually borrowed) vs what's interest (money the lender takes). Seeing that number in context hits different than just reading it.

### Completely reworked backup system
The old backup created a `.flowe` file and made you deal with saving it somewhere. The new system doesn't touch the filesystem at all.

**Copy Backup** — one tap. Your entire budget, all debts, all snapshots, every event, compressed and encoded into a single line, copied to your clipboard. Paste it into Notes, iMessage, email, anywhere. It looks like gibberish — that's intentional.

**Paste & Restore** — open Flowe on any device, any platform, tap Paste & Restore, paste the line, done. Everything comes back exactly as it was.

The new format (`FLOWE2:`) uses gzip compression before encoding. Lines are **~65% shorter** than the old `FLOWE1:` format. Old backups still restore fine.

### PDF export — actually useful now
The PDF was a plain text dump before. Now it's a real document:

- Full budget with section subtotals and separators
- Complete snowball section with total debt, total interest paid, total cost, debt-free date
- A visual cost breakdown bar: `[################........]` — principal on the left, interest on the right
- Per-debt payoff timeline with balance, months to payoff, projected date, and a progress bar for each one

### CSV export — snowball data included
CSV now exports the full picture in one file. Budget rows up top, then a full snowball section below with per-debt payoff months and dates. Open it in Excel or Google Sheets and your entire financial snapshot is there.

### Mobile export picker (Android)
Android now shows a bottom sheet when you tap CSV or PDF:
- **Save to Downloads** — goes directly to your Downloads folder, no share sheet
- **Share…** — opens the native share sheet for AirDrop, Gmail, Drive, etc.

iOS skips the picker entirely and goes straight to the native share sheet, which already has Save to Files built in.

---

## 🐛 Bug fixes

- **Windows CSV/PDF export crash** — `RangeError: Invalid value: Not in inclusive range 0..50: -1` — Windows uses `\` as a path separator, not `/`. The export was trying to split the save path on `/`, getting -1, then crashing on `substring(0, -1)`. Fixed.
- **Restore showing generic error** — "Restore failed — is the backup line complete?" told you nothing. Now shows the actual decode error so you know what went wrong.
- **Missing `objective_c` dependency** — iOS/macOS builds failed with `NativeAssetsManifest.json references objective_c`. Pinned to `^9.3.0`.
- **Android 9 permission denied on export** — Android 9 and below requires a runtime permission dialog for `WRITE_EXTERNAL_STORAGE`. The app now requests it properly and retries the save after it's granted.
- **PDF binary save on Android** — PDFs were falling back to the share sheet even when "Save to Downloads" was chosen. Added a `saveBytesToDownloads` native channel method that handles binary files directly via MediaStore.

---

## 📦 Installing / upgrading

**Fresh install:** Download and run the installer for your platform.

**Upgrading:**
- Windows: Run the new installer over the existing one. Data is untouched.
- Linux: `sudo apt install ./flowe_1.6.0_amd64.deb` — dpkg handles the upgrade.
- Android: Install the APK over the existing install without uninstalling.
- iOS: Sideload the new IPA over the existing app.

**Coming from flo (v1.0–v1.4):** Data migrates automatically on first launch.

---

## Downloads

| File | Platform |
|---|---|
| `flowe_1.6.0_setup.exe` | Windows |
| `flowe_1.6.0_amd64.deb` | Linux |
| `flowe_1.6.0.apk` | Android |
| `flowe_1.6.0.ipa` | iOS (sideload) |
| `flowe_1.6.0.dmg` | macOS (untested) |
