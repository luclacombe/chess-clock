# MAP — Features Beyond MVP

> MAP = shipped version summaries and future feature backlog.
> v1.0.0 shipped 2026-03-06.

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

## v0.4.0 — Shipped ✓

Four focused quality-of-life and depth improvements:

1. **No new windows** — Puzzle embedded inline in the MenuBarExtra popover (`ViewMode.puzzle`); `GuessMoveWindowManager` deleted.
2. **Chess-time hover tooltip** — Hovering the clock board shows e.g. "6 PM — 6 Moves to Checkmate". Puzzle header also shows this context.
3. **Multi-move puzzle + retries + stats** — Puzzle now starts at `positions[(hour-1)*2]`, not always positions[0]. Opponent moves auto-play. 3 total tries. `PuzzleEngine` pure struct drives all logic. Stats (wins by try, losses) persisted to UserDefaults.
4. **Auto-open to clock** — `WindowObserver` resets `ViewMode` to `.clock` whenever the MenuBarExtra popover opens.

See `docs/archive/TODO-done-v0.4.0.md` for full task breakdown.

---

## v0.5.0 — Shipped ✓

Info panel refresh and full game replay viewer.

Key changes:
- **Board-as-CTA**: Tapping the board (not a separate button) enters the puzzle or review flow. A bottom overlay bar shows the AM/PM badge, result badge (if played), and a "Play Puzzle" / "Review" label.
- **Game Replay viewer**: `GameReplayView` — step through the complete game from move 1 to checkmate. Coloured zone banner ("Game context" / "Puzzle start" / "Solution") updates as you navigate. Move arrow (amber shaft + arrowhead) shows which move was played at each position.
- **"Review Game" button**: Success and failed puzzle overlays now offer a "Review Game" button (fades in after 0.5 s) alongside "Close". Tapping opens the replay viewer at the puzzle start position.
- **`allMoves` data field**: `games.json` extended with the full UCI move list from game start to checkmate (~84 moves average). The Python pipeline (`build_json.py`) was updated accordingly.
- **Full game navigation**: ⏮=game start, ←=step back, [⦿]=puzzle start, →=step forward, ⏭=checkmate. Keyboard ← / → also work.
- **40 tests**: `GameReplayViewTests.swift` covers zone classification, move labels, position counter, navigation clamping, arrow geometry, zone label text, and `computeAllPositions` correctness.

See `docs/archive/TODO-done-v0.5.0.md` for full task breakdown.

**v0.5.1 (patch):** Fixed replay starting one position too late — `puzzleStartPosIndex` was pointing to the checkmate position instead of the puzzle start (opponent's context move now shown on open). GitHub Latest release badge also corrected.

---

## v1.0.0 — Shipped ✓

Full UI overhaul, open source release, and GitHub distribution.

Key changes:
- Borderless NSPanel with drag, hover close/minimize, system shadow
- Metal-rendered gold noise minute ring with marble texture, minor ticks, semicircle tip
- Hour-change animation: ring sweep→drain (2.5s cubic ease-in) + white flash board swap
- Progressive 6-stage onboarding (welcome → clock tour → info panel → puzzle → replay → puzzle hint)
- Cinematic focus-pull welcome screen with bokeh motes
- Puzzle ring with tint state machine (correct/wrong color feedback)
- Full game replay viewer with zone-colored progress bar, SAN notation, drag-to-scrub
- Info panel with board-as-CTA, player metadata, ELO ratings
- SANFormatter for algebraic notation display
- ReplayBackgroundView with animated marble noise
- All dimensions, colors, and timings centralized in DesignTokens.swift

See sprint archives in `docs/archive/` for full task breakdowns.

---

## Future

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

### Game-chaining Hour to Hour
Instead of fully random rotation, the new game features one of the same players as the previous game. Creates a thematic through-line for the day. Example: Magnus Carlsen appears in both cycles.

---

## Design Principles for Future Features

- **Additive:** New features should not change the behavior existing users rely on
- **Optional by default:** Settings should default to the current MVP behavior
- **Chess-first:** Visual changes should feel like they belong in chess culture
- **Still compact:** The widget should remain small and non-intrusive
