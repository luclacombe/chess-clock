# Chess Clock — Claude Code Context

## What This App Does

A macOS menu bar app that tells the time using real professional chess game positions.
- **Hour (1–12):** Shows a historical board position N moves before a famous game ended in checkmate
- **Minute (0–59):** A square ring traces the board's outer perimeter clockwise
- **Game info:** Always shows White player, Black player, ELO (both), Tournament, Year
- **AM/PM:** Sun icon (AM) or moon icon (PM) + text label

No chess engine. No network calls at runtime. Pure display app.

---

## Architecture Overview

```
Menu bar icon → floating NSWindow → ClockView
                                        ├── BoardView (8×8 grid from FEN)
                                        ├── MinuteSquareRingView (perimeter arc)
                                        ├── AMPMView (sun/moon + text)
                                        └── GameInfoView (players / ELO / tournament)

ClockService (Timer, 1s) → publishes ClockState
GameScheduler (Date) → picks game from GameLibrary → picks FEN for current hour
GameLibrary → decodes games.json from app bundle (loaded once at startup)
```

**Key architecture decisions:**
- FEN strings are **precomputed** by the Python pipeline — zero chess logic at runtime
- `games.json` is **bundled in the app** — no network, works offline
- `ClockService` drives everything via `@Published var state: ClockState`
- `GameScheduler` is pure/deterministic: same date always returns the same game

---

## Tech Stack

| Layer | Choice |
|---|---|
| Language | Swift 5.9+ |
| UI | SwiftUI |
| Menu bar | `MenuBarExtra` (macOS 13+) |
| Minimum OS | macOS 13 (Ventura) |
| Chess data | Static JSON bundled in app |
| Piece images | cburnett PNG set (public domain) |
| Chess engine | None |
| Distribution | GitHub Releases (.dmg) |

---

## File Map

```
chess-clock/
├── CLAUDE.md                       ← You are here
├── TODO.md                         ← Active task tracker (source of truth)
├── PROGRESS.md                     ← Session-by-session log
├── DECISIONS.md                    ← Architecture decision records
├── MAP.md                          ← NICE TO HAVE + NEXT VERSION features
├── FUTURE.md                       ← Long-term ideas (do not build now)
│
├── .claude/
│   ├── settings.json               ← PostToolUse hook (activity logging)
│   └── commands/sync.md            ← /sync slash command for session review
│
├── ChessClock/
│   ├── ChessClockApp.swift         ← App entry point + MenuBarExtra
│   ├── Views/
│   │   ├── ClockView.swift         ← Root view, composes all sub-views
│   │   ├── BoardView.swift         ← 8×8 LazyVGrid chess board
│   │   ├── PieceView.swift         ← Single chess piece image
│   │   ├── MinuteSquareRingView.swift ← Clockwise square perimeter ring
│   │   ├── GameInfoView.swift      ← Players / ELO / tournament / year
│   │   └── AMPMView.swift          ← Sun or moon + "AM"/"PM" text
│   ├── Models/
│   │   ├── ChessGame.swift         ← Codable struct matching games.json
│   │   ├── BoardPosition.swift     ← FEN string → [[Piece?]] 8×8 array
│   │   └── ClockState.swift        ← Current time state (hour, min, ampm, game, fen)
│   ├── Services/
│   │   ├── GameLibrary.swift       ← Loads games.json from bundle at startup
│   │   ├── GameScheduler.swift     ← Date + AM/PM cycle → game + FEN index
│   │   └── ClockService.swift      ← 1-second Timer, @Published ClockState
│   └── Resources/
│       ├── games.json              ← 730+ games, 12 FEN strings each (~3–5 MB)
│       └── Pieces/                 ← wK wQ wR wB wN wP bK bQ bR bB bN bP (PNG)
│
├── scripts/                        ← Python data pipeline (not shipped in app)
│   ├── requirements.txt
│   ├── fetch_games.py
│   ├── curate_games.py
│   └── build_json.py
│
└── docs/
    ├── architecture.md
    ├── data-pipeline.md
    └── archive/                    ← Archived specs, progress logs, and done tasks by version
```

---

## Build Commands

```bash
# Build the app (from repo root)
xcodebuild -project ChessClock/ChessClock.xcodeproj \
           -scheme ChessClock \
           -configuration Debug \
           build

# Run in Xcode (preferred during development)
open ChessClock/ChessClock.xcodeproj
# Then press ⌘R

# Run Python data pipeline
cd scripts
pip install -r requirements.txt
python fetch_games.py
python curate_games.py
python build_json.py

# Build DMG for distribution
./scripts/build_dmg.sh   # Created in Phase 3
```

---

## Key Decisions

| Decision | What | Why |
|---|---|---|
| Static JSON | Bundle games.json in app | No server costs, works offline, simple |
| FEN precompute | Python pipeline generates FEN at build time | Zero chess logic at runtime |
| cburnett PNG | Public domain piece images | No licensing issues, widely used |
| PGN Mentor | Source for famous games | Free, clean metadata, no API key |
| MenuBarExtra | SwiftUI menu bar integration | Pure SwiftUI, macOS 13+, no AppKit |
| No dependencies | Zero Swift packages | Simpler build, no version conflicts |
| Checkmate filter | Only games that end in checkmate | Makes "N moves before end" meaningful |

---

## Anti-Patterns — Never Do These

- Do NOT add a chess engine or evaluate positions at runtime
- Do NOT make network calls at runtime (no API calls when the clock is showing)
- Do NOT add Swift Package Manager dependencies without strong justification
- Do NOT mark a TODO item complete without verifying its acceptance criteria
- Do NOT modify MVP.md (it is frozen)
- Do NOT use AppKit directly unless MenuBarExtra requires it
- Do NOT skip ahead in the TODO.md task order
- Do NOT carry Done items from a shipped version into the next version — run `/archive` at each version ship

---

## Development Flow

**Every session:**
1. Read TODO.md to find the current task
2. Run `/sync` to review what's been done and confirm current state
3. Work on exactly one task at a time
4. Verify acceptance criteria before marking done
5. Run `/sync` at session end to update PROGRESS.md and TODO.md

**Marking tasks done:**
Only mark a task `[x]` after running its listed verification command and confirming the criteria pass. Move it to the `## Done` section in TODO.md with the completion date.

**At version ship:**
Run `/archive` to compress completed work out of active files. See `.claude/commands/archive.md` for the full checklist. Historical content lives in `docs/archive/`.
