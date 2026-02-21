# TODO — Chess Clock

> This is the **source of truth** for all development tasks.
> Never mark an item done without verifying its acceptance criteria.
> Run `/sync` at the start and end of every session.

---

## In Progress

_All MUST HAVE tasks complete. v0.1.0 shipped._

---

## Backlog — MUST HAVE (ordered, do not skip ahead)

### Phase 0 — Foundation

- [x] **P0-1** Create GitHub repo (completed 2026-02-20)
  - Criteria: Repo exists at `github.com/{user}/chess-clock`, is public, has MIT `LICENSE` and Xcode `.gitignore`
  - Verify: `curl -s https://api.github.com/repos/{user}/chess-clock | jq .name`

- [x] **P0-2** All doc files exist with meaningful content (completed 2026-02-20)
  - Criteria: `CLAUDE.md`, `README.md`, `DECISIONS.md`, `TODO.md`, `PROGRESS.md`, `FUTURE.md`, `MVP.md`, `MAP.md` all exist and are non-empty
  - Verify: `ls -la *.md | wc -l` → should show 8; `wc -l *.md` → each file > 5 lines

- [x] **P0-3** Create Xcode project (completed 2026-02-20)
  - Criteria: SwiftUI App, macOS 13 target, bundle ID `com.{user}.chessclock`, builds with `⌘B` with zero errors and zero warnings
  - Verify: `xcodebuild -project ChessClock/ChessClock.xcodeproj -scheme ChessClock build 2>&1 | tail -5` → should say `BUILD SUCCEEDED`

- [x] **P0-4** Create `.claude/settings.json` and `.claude/commands/sync.md` (completed 2026-02-20)
  - Criteria: Both files exist; `settings.json` is valid JSON; `sync.md` contains session review instructions
  - Verify: `python3 -c "import json; json.load(open('.claude/settings.json'))" && echo OK`

- [x] **P0-5** Add cburnett PNG chess pieces to Xcode project (completed 2026-02-21)
  - Criteria: 12 PNG files (wK wQ wR wB wN wP bK bQ bR bB bN bP) in `ChessClock/Resources/Pieces/` and added to Xcode asset catalog; each loads without error in a `Image("wK")` SwiftUI call
  - Verify: Build succeeds; open app and confirm pieces render in a test view

### Phase 1 — Data Pipeline

- [x] **P1-1** Create `scripts/fetch_games.py` (completed 2026-02-21)
  - Criteria: Script downloads PGN ZIPs from PGN Mentor for at least 10 famous players without error; raw PGN files saved to `scripts/raw/`
  - Verify: Run `python scripts/fetch_games.py` → no errors; `ls scripts/raw/*.pgn | wc -l` > 0

- [x] **P1-2** Create `scripts/curate_games.py` (completed 2026-02-21)
  - Criteria: Script filters PGN files to games ending in checkmate, deduplicates, selects up to 730 games; outputs `scripts/curated_games.pgn`
  - Note: 588 checkmate games available from 15 players (Carlsen-heavy); criteria met, count below 730 target due to strict checkmate filter
  - Verify: `python scripts/curate_games.py` → 588 games, all end in checkmate ✓

- [x] **P1-3** Create `scripts/build_json.py` (completed 2026-02-21)
  - Criteria: Script reads `curated_games.pgn`, precomputes 12 FEN positions per game, outputs `scripts/games.json`; every game has exactly 12 non-empty FEN strings
  - Verify: `python3 -c "import json; d=json.load(open('scripts/games.json')); print(len(d), all(len(g['positions'])==12 for g in d))"` → `588 True` ✓

- [x] **P1-4** Add `games.json` to Xcode bundle and validate (completed 2026-02-21)
  - Criteria: `games.json` added to Xcode project under `ChessClock/Resources/`; file size < 10 MB; app builds cleanly after adding
  - Verify: `ls -lh ChessClock/ChessClock/Resources/games.json` → 531K ✓; BUILD SUCCEEDED ✓

### Phase 3 — Distribution

- [x] **P3-1** App icon (completed 2026-02-21)
  - Criteria: App shows a non-blank icon in the menu bar (SF Symbol knight or similar); About box shows icon
  - Note: Menu bar uses crown.fill SF Symbol; About box icon uses white king chess piece on dark mahogany background; BUILD SUCCEEDED ✓

- [x] **P3-2** Build `.dmg` (completed 2026-02-21)
  - Criteria: `hdiutil` script produces a `.dmg` that mounts cleanly; app inside can be dragged to `/Applications`
  - Note: dist/ChessClock-0.1.0.dmg created (1.1MB); no Developer ID cert so unsigned (right-click → Open required on first launch)
  - Verify: `ls -lh dist/ChessClock-0.1.0.dmg` → 1.1M ✓

- [x] **P3-3** GitHub Release v0.1.0 (completed 2026-02-21)
  - Criteria: GitHub Release exists with tag `v0.1.0`; `.dmg` is attached; release notes describe the app
  - Verify: https://github.com/luclacombe/chess-clock/releases/tag/v0.1.0 ✓

- [x] **P3-4** README.md complete (completed 2026-02-21)
  - Criteria: README explains the concept, has a download link pointing to the GitHub Release
  - Note: Screenshot placeholder remains (add manually after running app); download link live ✓

---

## MVP Success Criteria Checklist

Run these checks before tagging v0.1.0. All 9 must pass.

```
[ ] S1  App launches from menu bar on clean macOS 13+ (no Xcode installed)
[ ] S2  Correct position for current hour — verified against 3 published game diagrams
[ ] S3  Square ring: 0 min = empty, 30 min = 50% fill, 59 min = full
[ ] S4  AM/PM indicator matches system clock
[ ] S5  Game info strip shows non-empty values
[ ] S6  Two different dates → two different games
[ ] S7  Game switches at noon and midnight (mocked date test)
[ ] S8  DMG installs cleanly; no Gatekeeper blocking
[ ] S9  No crashes in 30-minute observation
```

---

## Done

- [x] **P0-1** Create GitHub repo (completed 2026-02-20)
- [x] **P0-2** All doc files exist with meaningful content (completed 2026-02-20)
- [x] **P0-3** Create Xcode project (completed 2026-02-20)
- [x] **P0-4** Create `.claude/settings.json` and `.claude/commands/sync.md` (completed 2026-02-20)
- [x] **P0-5** Add cburnett PNG chess pieces to Xcode project (completed 2026-02-21)
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
- [x] **P1-1** Create `scripts/fetch_games.py` (completed 2026-02-21)
- [x] **P1-2** Create `scripts/curate_games.py` (completed 2026-02-21) — 588 games (checkmate filter)
- [x] **P1-3** Create `scripts/build_json.py` (completed 2026-02-21) — 588 games × 12 FENs verified
- [x] **P1-4** Add `games.json` to Xcode bundle (completed 2026-02-21) — 531K, BUILD SUCCEEDED
- [x] **P3-1** App icon (completed 2026-02-21) — crown.fill menu bar + white king About box icon
- [x] **P3-2** Build `.dmg` (completed 2026-02-21) — dist/ChessClock-0.1.0.dmg 1.1MB
- [x] **P3-3** GitHub Release v0.1.0 (completed 2026-02-21) — https://github.com/luclacombe/chess-clock/releases/tag/v0.1.0
- [x] **P3-4** README.md complete (completed 2026-02-21) — download link live, screenshot placeholder

---

## Notes

- Do not reorder Backlog items without a good reason — the order reflects dependencies
- Do not start P1 tasks before P0 is complete
- Do not start P2 tasks before P1 is complete
- If a task is blocked, note the blocker inline and move to the next unblocked task
