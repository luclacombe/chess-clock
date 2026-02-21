# TODO Done — Archived v0.1.0

> Archived from TODO.md on 2026-02-21 when v0.1.0 shipped.
> Covers all completed tasks through Phase T (test suite) and Phase F (bug fixes).

---

## Phase P0 — Project Setup

- [x] **P0-1** Create GitHub repo (completed 2026-02-20)
- [x] **P0-2** All doc files exist with meaningful content (completed 2026-02-20)
- [x] **P0-3** Create Xcode project (completed 2026-02-20)
- [x] **P0-4** Create `.claude/settings.json` and `.claude/commands/sync.md` (completed 2026-02-20)

## Phase P1 — Data Pipeline

- [x] **P0-5** Add cburnett PNG chess pieces to Xcode project (completed 2026-02-21)
- [x] **P1-1** Create `scripts/fetch_games.py` (completed 2026-02-21)
- [x] **P1-2** Create `scripts/curate_games.py` (completed 2026-02-21) — 588 games (checkmate filter)
- [x] **P1-3** Create `scripts/build_json.py` (completed 2026-02-21) — 588 games × 12 FENs verified
- [x] **P1-4** Add `games.json` to Xcode bundle (completed 2026-02-21) — 531K, BUILD SUCCEEDED

## Phase P2 — Swift App

- [x] **P2-1** `ChessGame.swift` + `GameLibrary.swift` (completed 2026-02-21)
- [x] **P2-2** `GameScheduler.swift` (completed 2026-02-21)
- [x] **P2-3** `ClockService.swift` (completed 2026-02-21)
- [x] **P2-4** `BoardPosition.swift` (completed 2026-02-21)
- [x] **P2-5** `PieceView.swift` + `BoardView.swift` (completed 2026-02-21)
- [x] **P2-6** `MinuteSquareRingView.swift` (completed 2026-02-21)
- [x] **P2-7** `AMPMView.swift` (completed 2026-02-21)
- [x] **P2-8** `GameInfoView.swift` (completed 2026-02-21)
- [x] **P2-9** `ClockView.swift` (completed 2026-02-21)
- [x] **P2-10** `ChessClockApp.swift` — MenuBarExtra + no dock icon (completed 2026-02-21)

## Phase P3 — Distribution

- [x] **P3-1** App icon (completed 2026-02-21) — crown.fill menu bar + white king About box icon
- [x] **P3-2** Build `.dmg` (completed 2026-02-21) — dist/ChessClock-0.1.0.dmg 1.1MB
- [x] **P3-3** GitHub Release v0.1.0 (completed 2026-02-21) — https://github.com/luclacombe/chess-clock/releases/tag/v0.1.0
- [x] **P3-4** README.md complete (completed 2026-02-21) — download link live, screenshot placeholder

## Phase T — Test Suite (v0.2.0)

- [x] **T1** Add XCTest target to Xcode project (completed 2026-02-21) — ChessClockTests target, TEST_HOST pointing to app, scheme with test action
- [x] **T2** Refactor `ClockService` for time injection (completed 2026-02-21) — `makeState(at date: Date = Date())`, BUILD SUCCEEDED
- [x] **T3** `BoardPosition` unit tests (completed 2026-02-21) — 6 cases, 0 failures
- [x] **T4** `GameScheduler` unit tests (completed 2026-02-21) — 9 cases, 0 failures
- [x] **T5** `ClockService` + `ClockState` unit tests (completed 2026-02-21) — 8 cases, 0 failures
- [x] **T6** `ChessGame` + `GameLibrary` integration tests (completed 2026-02-21) — 6 cases, 0 failures; total 30 tests across all files

## Phase F — Bug Fixes (v0.2.0)

- [x] **F1** Fix minute ring start position to 12 o'clock (completed 2026-02-21) — 5-segment clockwise path from top-center
- [x] **F2** Fix year formatting in `GameInfoView` (completed 2026-02-21) — `String(game.year)` prevents locale comma
