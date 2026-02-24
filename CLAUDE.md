# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

A macOS menu bar app that displays the current time using real professional chess positions.
No chess engine. No network calls at runtime.

- **Hour (1–12):** Board position N moves before a famous game ended in checkmate
- **Minute (0–59):** Square ring traces the board perimeter clockwise
- **AM/PM:** Board perspective — White's POV for AM (rank 1 at bottom), Black's POV for PM (board flipped)

---

## Where to Find Things

| What | Where |
|---|---|
| Current tasks | `docs/TODO.md` ← start here every session |
| Session log | `docs/PROGRESS.md` |
| v1.0 design spec | `docs/DESIGN.md` ← source of truth for current sprint |
| Architecture decisions | `docs/DECISIONS.md` |
| Feature roadmap | `docs/MAP.md` |
| Long-term ideas | `docs/FUTURE.md` |
| App source overview | `ChessClock/ChessClock/CLAUDE.md` |
| Views / Models / Services | Each subfolder has its own `CLAUDE.md` |
| Python data pipeline | `scripts/CLAUDE.md` |
| Archived versions | `docs/archive/` |

---

## Architecture

```
Timer (1s) → ClockService → ClockState → ClockView (ViewMode: clock | info | puzzle | replay)
                                ├── [clock]  BoardView + MinuteSquareRingView
                                ├── [info]   InfoPanelView → onGuess → puzzle mode
                                ├── [puzzle] GuessMoveView (inline, no separate window)
                                └── [replay] GameReplayView
GameScheduler(Date, seed) → game from GameLibrary(games.json) → FEN string + fenIndex
ChessRules (runtime) → legal moves for the interactive Guess Move puzzle only
```

FEN strings are precomputed by the Python pipeline. `ChessRules` is used only for the interactive puzzle window — the clock display itself involves no chess logic at runtime. `ClockService` drives everything via `@Published var state: ClockState`.

`ClockView` resets to `.clock` mode whenever the MenuBarExtra popover reopens (via `WindowObserver`, an `NSViewRepresentable` that observes `NSWindow.didBecomeKeyNotification`).

### Key Data Flow

- `ClockService.makeState(at:)` is **static** — pass any `Date` to test arbitrary times without a live timer.
- `GameScheduler.resolve(date:library:seed:)` is deterministic per device: epoch `2026-01-01`, hourly rotation, double-modulo game index, AM pulls `mateBy == "white"` games, PM pulls `mateBy == "black"` games. A per-device seed is stored in `UserDefaults` on first launch (`"deviceGameSeed"`).
- `fenIndex = hour - 1`. `positions[0]` = 1 move before checkmate (shown at hour 1, mate-in-1); `positions[11]` = 12 moves before checkmate (shown at hour 12).
- `positions` has **23 entries** — odd indices interleave puzzle-start positions (mating side to move). `positions[2*(N-1)]` = puzzle start for hour N.
- `BoardPosition.squares[rankIndex][fileIndex]`: rankIndex 0 = rank 8 (top). Matches FEN order directly.

### ChessGame Schema

Fields in `games.json` (all fields decoded by `ChessGame.Codable`):

| Field | Type | Notes |
|---|---|---|
| `white`, `black` | `String` | PGN format: `"Kasparov,G"` |
| `whiteElo`, `blackElo` | `String` | `"2851"` or `"?"` for historical/unknown |
| `tournament` | `String` | |
| `year` | `Int` | |
| `month` | `String?` | e.g. `"January"`, optional |
| `round` | `String?` | optional |
| `mateBy` | `String` | `"white"` or `"black"` |
| `finalMove` | `String` | UCI of checkmate move |
| `positions` | `[String]` | 23 FENs (see indexing above) |
| `moveSequence` | `[String]` | 23 UCIs; `moveSequence[i]` = move from `positions[i]`; `moveSequence[0]` = `finalMove` |
| `allMoves` | `[String]` | Full game UCI list from move 1 to checkmate (used by GameReplayView) |

---

## Build Commands

```bash
# Build
xcodebuild -project ChessClock/ChessClock.xcodeproj \
           -scheme ChessClock -configuration Debug build

# Open in Xcode (preferred during development)
open ChessClock/ChessClock.xcodeproj

# Run all tests
xcodebuild test -project ChessClock/ChessClock.xcodeproj \
           -scheme ChessClock -destination 'platform=macOS'

# Run tests (suppress signing noise)
xcodebuild test -project ChessClock/ChessClock.xcodeproj \
           -scheme ChessClock -destination 'platform=macOS' \
           CODE_SIGN_IDENTITY="" 2>&1 | grep -E "Test Suite|passed|failed"

# Build DMG for distribution (VERSION hardcoded at top of script — update before release)
./scripts/build_dmg.sh
```

### Data Pipeline (run when updating games.json)

```bash
cd scripts
pip install -r requirements.txt
python fetch_games.py      # downloads PGNs to scripts/raw/
python curate_games.py     # filters to checkmate games → curated_games.pgn
python build_json.py       # extracts 23 FENs per game → games.json
cp games.json ../ChessClock/ChessClock/Resources/games.json
```

---

## Anti-Patterns — Never Do These

- Do NOT add a chess engine or evaluate positions at runtime
- Do NOT make network calls at runtime
- Do NOT add Swift Package Manager dependencies without strong justification
- Do NOT mark a task done without verifying its acceptance criteria
- Do NOT use AppKit directly unless `MenuBarExtra` / `NSPanel` requires it
- Do NOT skip ahead in the `docs/TODO.md` task order
- Do NOT carry Done items across versions without running `/archive`
- Do NOT use `TimelineView` for animation — use `.animation(.linear, value:)` with `Animatable` shapes
- Do NOT leave expensive views (blur, material, TimelineView) in tree at `opacity(0)` — use conditional `if` rendering
- Do NOT create multiple `ClockService` instances — share the single instance via dependency injection
- Do NOT call `GameScheduler.resolve()` every second — result is hourly-stable, cache it
- Do NOT apply `.blur()` to views with many subviews without `.drawingGroup()` first

---

## Session Checklist

1. Read `docs/TODO.md` — find the current task
2. Run `/sync` — verify state, update `docs/PROGRESS.md`
3. Work on one task at a time
4. Verify acceptance criteria before marking done
5. Run `/sync` at session end

**At version ship:** Run `/archive`. Historical content lives in `docs/archive/`.
