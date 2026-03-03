# Flowe Roadmap — toward v2.0

> Slow releases, each one solid. Building toward a full offline personal finance system
> where budget, spending, debt, and net worth all talk to each other.
> Target: v2.0 = App Store + Play Store launch with signed binaries.

---

## v1.7 — Track Tab (Transaction Logging)

The biggest missing piece. Rework the Events tab into a general **Track** tab with two modes.

### Track tab — Transaction mode (default)
- Log individual purchases against budget categories
- Tap a category → enter amount → done
- Running total per category updates live
- Over-budget rows turn red automatically
- Monthly spending history per category stored automatically

### Track tab — Event mode
- Existing Events screen lives here as a mode
- Simple pill/toggle switcher at top of tab
- Events optionally pull from a budget category so they don't blow up monthly numbers
- Split calculator stays exactly as-is

### Budget tab sync
- Budget rows show "spent $340 of $500" pulling live from Track
- Spending pace indicator — "20 days in, 80% through your food budget"
- Over-budget rows highlighted automatically
- Rollover unspent amounts to next month or redirect to debt payoff

---

## v1.8 — Recurring Expenses + Budget Templates

### Recurring expenses
- Mark any budget row as recurring with a frequency (weekly, biweekly, monthly, annual)
- Auto-fills each new month — no rebuilding from scratch
- Recurring transactions auto-logged in Track when due date hits

### Budget templates
- Save current month layout as a named template
- Multiple templates: "lean month", "holiday month", "normal"
- Apply a template to any new month in one tap

---

## v1.9 — Snowball + Net Worth intelligence

### Snowball gets smarter
- Logging a debt payment in Track automatically reduces the balance in Snowball
- No more manually updating debt balances — it just tracks
- Snowball feels alive, not static

### What-if extra payment slider
- Already half-built — the calc runs live
- Expose a slider: "what if I put an extra $X/month?"
- Debt-free date and total interest update in real time
- No competitor does this visually

### Net Worth chart
- Connect existing dated snapshots into a line chart
- Auto-snapshot option — take snapshot at end of each month automatically
- Liabilities update automatically from Snowball balances

### Budget health score
- Simple 0–100 score based on: savings rate, debt ratio, remaining budget, spending pace
- Gives users something to chase month over month

---

## v1.10 — Due Date Notifications

- Local push notifications for debt due dates (no server, fully on-device)
- Configurable reminder windows: 1 day, 3 days, 7 days before due
- Notification taps open directly to the relevant debt card
- Works on: Android, iOS, Windows, Linux, macOS
- Bill reminders — notify when a recurring budget row is coming up
- Notification history / snooze

---

## v2.0 — Launch

The full picture. Budget planning, spending reality, debt payoff, and net worth
all connected and talking to each other. No other offline app does all four.

### Feature complete
- All v1.7–v1.10 features solid and tested
- Transaction logging fully synced with Budget, Snowball, and Net Worth
- Notifications working on all platforms

### Polish pass
- UI consistency audit across all screens
- Onboarding flow for new users (what is each tab, how do they connect)
- Empty state improvements — new users shouldn't see blank screens

### Signing + store prep
- Windows: OV code signing certificate — removes SmartScreen warning
- Android: Keystore finalized, Play Store listing prepared
- iOS: Apple Developer account ($99/yr), App Store listing prepared
- macOS: Tested on bare-metal hardware, notarized

### Studio name
- ✅ **PrivacyChase** — locked in, domain purchased March 2026 (privacychase.com)
- ✅ Package IDs migrated to `com.privacychase.*`
- App Store / Play Store developer account registration pending
- Windows OV signing certificate pending

### Pricing
- Target: $7.99 one-time on App Store + Play Store
- Undercuts BYB ($29.99 one-time / $4.99/mo) significantly
- Windows + Linux remain free and open source

---

## The 2.0 story (for the store listing)

> Most budget apps want your email, your bank login, and a monthly fee.
> Flowe is the only app that shows you your full financial picture —
> what you planned, what you actually spent, what you owe, and what you're worth —
> all on your device, all offline, all yours. One payment. Forever.

---

## Ideas backlog (unscheduled)

- Dark/light mode scheduled auto-switch
- CSV import (import transactions from bank export)
- Widget support (iOS/Android home screen budget remaining widget)
- Apple Watch / Wear OS glance (remaining budget at a glance)
- iCloud / local network sync between devices (no cloud server — peer to peer only)
- Multiple budget profiles (personal + business)
- Custom currency symbols and number formatting
- Biometric lock (Face ID / fingerprint to open app)

