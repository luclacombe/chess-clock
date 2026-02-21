# MAP — Features Beyond MVP

> MAP = features that make the app genuinely delightful beyond MVP.
> v0.1.0 shipped. Active work is on the v0.2.0 Phase N backlog in TODO.md.

---

## NICE TO HAVE — v0.2.0 targets

These improve the experience but do not block the initial release.

### Keyboard shortcut to toggle window
Default: ⌥Space (Option + Space). Configurable later. Shows/hides the floating clock window without clicking the menu bar icon.

### Onboarding tooltip
On first launch only, show a brief tooltip or popover explaining: "The hour = how many moves until this game ended. The ring = minutes." Dismissible, never shown again.

### GitHub Actions automated DMG build
CI workflow that builds and notarizes (or signs) the .dmg on every tagged release. Triggered by pushing a `v*` tag. Attaches the .dmg to the GitHub Release automatically.

### Per-device game variation (N6)
Currently `GameScheduler` is fully deterministic: the same date produces the same game on every device (like Wordle). This is intentional for social sharing but the user experience may feel static. Alternative: generate a device-specific integer seed on first launch (stored in `UserDefaults`) and offset the game index by that seed. Every device gets a unique rotation while still being deterministic on the same device across days. Implementation: `(halfDayIndex + deviceOffset) % library.games.count`. Requires adding a `deviceOffset` property to `GameScheduler` and a one-time seed write on first launch.

### Board POV based on AM/PM — remove explicit indicator (N7)
Replace the AM/PM sun/moon icon and text label with board perspective encoding. AM cycle: board shown from White's point of view (rank 1 at bottom). PM cycle: board shown from Black's point of view (rank 8 at bottom — flip the 8×8 grid). The time-of-day information is still encoded in the display but requires chess knowledge to read, making the clock more puzzle-like. Remove `AMPMView` entirely. Requires flipping `BoardPosition` rank order when `isAM == false`.

### Game info layout: fix formatting and add detail (N8)
Current issues:
- Year displays with a thousands separator ("2,006" instead of "2006") — this is a number formatting bug (use `String(year)` not `"\(year)"` with default locale formatting)
- Missing fields: month of tournament, round number
- Layout: players, ELOs, tournament, date, and round should each be clearly labeled and visually separated
Fix: strip locale from year formatting; expose `month`, `round`, and `event` fields from `games.json` (add to Python pipeline and `ChessGame` model); redesign `GameInfoView` with labeled rows.

### Right-click context menu (N9)
Right-clicking the menu bar icon or the floating window should show a context menu with at minimum:
- "Open as Floating Window" — detaches the clock as a persistent floating NSPanel (always on top)
- "Quit Chess Clock"
Optional future additions: "Copy game info", "Copy board FEN". Implementation: add a `MenuBarExtra` menu block for the icon right-click; for the floating window, use SwiftUI's `.contextMenu` modifier or `NSMenu` on the underlying `NSWindow`.

---

## NEXT VERSION — v1.0.0 and beyond

These are significant features that each deserve their own scoping and planning session.

### UI overhaul + custom app icon + hour-change animation
The current UI is functional MVP. A proper design pass is needed before v1.0.0 — covering typography, spacing, color palette, window chrome, and overall visual polish. Custom app icon (replacing the `crown.fill` SF Symbol) and the hour-change piece-slide animation should ship as part of this overhaul, not independently. Scope to be planned separately.

### "Guess the time" share card
Wordle-style: show the board position, let the user guess the hour and minute, then reveal whether they were right. Generate a shareable text card (like Wordle's emoji grid) that can be copied and shared. This is the viral growth mechanic.

### Settings panel
Accessible from the menu bar menu. Initial settings:
- Toggle: show actual time vs. hide time (advanced mode)
- Future: choose piece theme, board colors

### Hide-the-time mode (advanced player)
Hide the minute ring, AM/PM indicator, and actual time. Only show the board and game info. The challenge: can you tell what time it is from the position? Reveal on click or keyboard shortcut.

### WidgetKit widget
A native macOS widget (for Notification Center / Desktop). Requires the $99 Apple Developer Program membership. Identical visual to the floating window but in widget format.

### Online game database
Replace the bundled `games.json` with live API calls to a backend (or directly to Lichess Broadcasts API). Keeps the game database fresh without app updates. Requires internet. Falls back to bundled games if offline.

### Game-chaining AM↔PM
Instead of fully random rotation, the PM game features one of the same players as the AM game. Creates a thematic through-line for the day. Example: Magnus Carlsen appears in both cycles.

---

## Design Principles for Future Features

- **Additive:** New features should not change the behavior existing users rely on
- **Optional by default:** Settings should default to the current MVP behavior
- **Chess-first:** Visual changes should feel like they belong in chess culture
- **Still compact:** The widget should remain small and non-intrusive
