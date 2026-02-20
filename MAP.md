# MAP — Features Beyond MVP

> MAP = features that make the app genuinely delightful at first public release.
> Do not build these until all 9 MVP success criteria pass and v0.1.0 is tagged.

---

## NICE TO HAVE — v0.2.0 targets

These improve the experience but do not block the initial release.

### Hour-change animation
When the hour ticks over, animate the move: the piece that was just played slides from its source square to its destination square. Duration ~1 second. No animation between hours (only on tick).

### Polished custom app icon
Replace the SF Symbol placeholder with a custom icon: a chess clock face with a knight piece motif. Should look good at 16×16 (menu bar) and 512×512 (App Store ready).

### Keyboard shortcut to toggle window
Default: ⌥Space (Option + Space). Configurable later. Shows/hides the floating clock window without clicking the menu bar icon.

### Onboarding tooltip
On first launch only, show a brief tooltip or popover explaining: "The hour = how many moves until this game ended. The ring = minutes." Dismissible, never shown again.

### GitHub Actions automated DMG build
CI workflow that builds and notarizes (or signs) the .dmg on every tagged release. Triggered by pushing a `v*` tag. Attaches the .dmg to the GitHub Release automatically.

---

## NEXT VERSION — v1.0.0 and beyond

These are significant features that each deserve their own scoping and planning session.

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
