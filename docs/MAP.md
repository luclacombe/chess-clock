# MAP — Features Beyond MVP

> MAP = features that make the app genuinely delightful beyond MVP.
> v0.3.0 shipped. Next version: v1.0.0. See backlog below.

---

## v0.2.0 — Shipped ✓

All Phase T (tests), Phase F (bug fixes), and Phase N (nice-to-have) tasks complete.
See `docs/archive/TODO-done-v0.2.0.md` for full task list.

---

## v0.3.0 — Shipped ✓

Simplified UI, hourly game rotation, and interactive "Guess Move" feature.
See `docs/archive/TODO-done-v0.3.0.md` for full task list.

Key changes:
- Board + ring only by default; tap opens info panel with game metadata
- New game every hour (`hourlyIndex = daysSinceEpoch * 24 + hour24`)
- `fenIndex = hour12 - 1`: hour N shows position N moves before checkmate
- Full chess rules engine (ChessRules.swift) powering interactive puzzle
- Floating NSPanel with drag/click board, promotion picker, result overlay

---

## NEXT VERSION — v1.0.0 and beyond

These are significant features that each deserve their own scoping and planning session.

### UI overhaul + custom app icon + hour-change animation
The current UI is functional MVP. A proper design pass is needed before v1.0.0 — covering typography, spacing, color palette, window chrome, and overall visual polish. Custom app icon (replacing the `crown.fill` SF Symbol) and the hour-change piece-slide animation should ship as part of this overhaul, not independently. Board resolution improved, minute ring given great visual polish. Scope to be planned separately.

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

### Game-chaining Hour to Hour
Instead of fully random rotation, the new game features one of the same players as the previous game. Creates a thematic through-line for the day. Example: Magnus Carlsen appears in both cycles.

---

## Design Principles for Future Features

- **Additive:** New features should not change the behavior existing users rely on
- **Optional by default:** Settings should default to the current MVP behavior
- **Chess-first:** Visual changes should feel like they belong in chess culture
- **Still compact:** The widget should remain small and non-intrusive
