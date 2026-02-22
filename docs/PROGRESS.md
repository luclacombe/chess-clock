# Progress Log

> Append a new entry at the start of each development session.
> Run `/sync` to auto-update this file.

---

## Template

```
## YYYY-MM-DD — Session N
**Goal:** [What we set out to do]
**Completed:**
- [Task ID] Description of what was done
**Blocked / Skipped:**
- [Task ID] Reason
**Next session:**
- Start at: [Task ID] [Task name]
**Notes:**
- [Any context to carry forward]
```

---

## 2026-02-21 — Session 1 (Sprint)

**Goal:** Plan and implement v0.4.0: inline puzzle, multi-move engine, 3-try retries, stats, hover tooltip, auto-open-to-clock fix.

**Completed:**
- P0 (`ce8fbdc`) — Added `moveSequence` computation to `build_json.py`; regenerated all 588 games in `games.json`
- P1 (`40446ee`) — Added `moveSequence: [String]` field to `ChessGame` (decodeIfPresent, defaults to [])
- P2 (`40446ee`) — Created `PuzzleEngine.swift` pure struct with `SubmitResult` enum; 14/14 `PuzzleEngineTests` pass
- Senior inline (`85d0040`) — Added 3 new tests to `GameLibraryTests` covering moveSequence length, alignment with finalMove, and JSON round-trip
- P3 (`6ab6b2b`) — Rewrote `GuessService`: new `PuzzleResult`/`PuzzleStats` types, `startPuzzle(game:hour:)` / `submitMove(uci:)` API, UserDefaults persistence; 10/10 `GuessServiceTests` pass
- P4.1 (`f7070e3`) — Deleted `GuessMoveWindowManager.swift` and `MoveResultView.swift`; added `ViewMode` enum to `ClockView`; rewrote `InfoPanelView` with `onGuess` callback
- P4.2 (`f7070e3`) — Rewrote `GuessMoveView` for multi-move inline puzzle: opponent auto-play animation, wrong flash overlay, success/failed inline overlays with stats
- P5.1 (`f7070e3`) — Hover tooltip shows chess-time string; `ClockView.hoverText(hour:isAM:)` static func; 6/6 `HoverTooltipTests` pass
- P5.2 (`f7070e3`) — `WindowObserver` NSViewRepresentable resets `viewMode = .clock` on MenuBarExtra popover open

**Blocked / Skipped:**
- P6 manual smoke test — requires running app; checklist in TODO.md for next session

**Adaptations:**
- python-chess not installed on system; installed with `pip3 install chess --break-system-packages`
- GuessService `init` hoisted `hourKey` to local `let` to satisfy definite initialization order
- GuessServiceTests: services stored as `@MainActor` instance properties (not local vars) to avoid Swift 6 SIGABRT off-actor deallocation on macOS 26
- Backward-compat shim kept in GuessService (`Guess`, `hasGuessed`, `guess`) during P3→P4 transition

**Next session:**
- Start at: P6 — run manual smoke test checklist (11 items) in the app
- After P6 verified: run `/archive` to ship v0.4.0 and reset tracking for v1.0.0

**Notes:**
- Full test suite: **TEST SUCCEEDED** (all suites pass after f7070e3)
- `ClockView.hoverText` is `static` (internal) so `@testable import` can reach it from tests
- `WindowObserver` observes on specific window instance to avoid false triggers from non-activating panels
- `PuzzleEngine` is a pure value-type struct; mutation requires extract-mutate-writeback pattern in `GuessService`

---
