# Chess Clock — Claude Code Context

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
Timer (1s) → ClockService → ClockState → ClockView
                                ├── BoardView + MinuteSquareRingView   (clock mode)
                                └── InfoPanelView                      (tap mode)
                                      └── GuessMoveWindowManager → NSPanel → GuessMoveView
GameScheduler(Date) → game from GameLibrary(games.json) → FEN string + fenIndex
ChessRules (runtime) → legal moves for the interactive Guess Move puzzle only
```

FEN strings are precomputed by the Python pipeline. ChessRules is used only for the
interactive puzzle window — the clock display itself involves no chess logic at runtime.
`ClockService` drives everything via `@Published var state: ClockState`.

---

## Build Commands

```bash
# Build
xcodebuild -project ChessClock/ChessClock.xcodeproj \
           -scheme ChessClock -configuration Debug build

# Open in Xcode (preferred during development)
open ChessClock/ChessClock.xcodeproj

# Run tests
xcodebuild test -project ChessClock/ChessClock.xcodeproj \
           -scheme ChessClock -destination 'platform=macOS'

# Build DMG for distribution
./scripts/build_dmg.sh
```

---

## Anti-Patterns — Never Do These

- Do NOT add a chess engine or evaluate positions at runtime
- Do NOT make network calls at runtime
- Do NOT add Swift Package Manager dependencies without strong justification
- Do NOT mark a task done without verifying its acceptance criteria
- Do NOT use AppKit directly unless MenuBarExtra requires it
- Do NOT skip ahead in the `docs/TODO.md` task order
- Do NOT carry Done items across versions without running `/archive`

---

## Session Checklist

1. Read `docs/TODO.md` — find the current task
2. Run `/sync` — verify state, update `docs/PROGRESS.md`
3. Work on one task at a time
4. Verify acceptance criteria before marking done
5. Run `/sync` at session end

**At version ship:** Run `/archive`. Historical content lives in `docs/archive/`.
