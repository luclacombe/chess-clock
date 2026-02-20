# TODO — Chess Clock

> This is the **source of truth** for all development tasks.
> Never mark an item done without verifying its acceptance criteria.
> Run `/sync` at the start and end of every session.

---

## In Progress

_Nothing in progress — start at the top of Backlog._

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

- [ ] **P1-1** Create `scripts/fetch_games.py`
  - Criteria: Script downloads PGN ZIPs from PGN Mentor for at least 10 famous players without error; raw PGN files saved to `scripts/raw/`
  - Verify: Run `python scripts/fetch_games.py` → no errors; `ls scripts/raw/*.pgn | wc -l` > 0

- [ ] **P1-2** Create `scripts/curate_games.py`
  - Criteria: Script filters PGN files to games ending in checkmate, deduplicates, selects 730 games prioritizing World Championship and super-tournaments; outputs `scripts/curated_games.pgn`
  - Verify: `python scripts/curate_games.py` → prints count ≥ 730; sample 5 games manually to confirm they end in checkmate

- [ ] **P1-3** Create `scripts/build_json.py`
  - Criteria: Script reads `curated_games.pgn`, precomputes 12 FEN positions per game, outputs `scripts/games.json`; spot-check 3 known games against published diagrams; every game has exactly 12 non-empty FEN strings
  - Verify: `python -c "import json; d=json.load(open('scripts/games.json')); print(len(d), all(len(g['positions'])==12 for g in d))"` → prints `730+ True`

- [ ] **P1-4** Add `games.json` to Xcode bundle and validate
  - Criteria: `games.json` added to Xcode project under `ChessClock/Resources/`; file size < 10 MB; app builds cleanly after adding
  - Verify: `ls -lh ChessClock/Resources/games.json`; `xcodebuild ... build` succeeds

### Phase 2 — Core App

- [ ] **P2-1** `ChessGame.swift` + `GameLibrary.swift`
  - Criteria: `ChessGame` is `Codable` matching `games.json` schema; `GameLibrary.shared.games` decodes all 730+ games without error at app startup
  - Verify: Add `print(GameLibrary.shared.games.count)` to app init → prints ≥ 730

- [ ] **P2-2** `GameScheduler.swift`
  - Criteria: Given the same `Date`, always returns the same game; AM and PM cycles return different games; incrementing the date by 1 returns the next game pair
  - Verify: Unit test or print statements with 3 mocked dates confirm deterministic, different results

- [ ] **P2-3** `ClockService.swift`
  - Criteria: `@Published var state: ClockState` updates every second; `state.hour` matches system clock 1–12; `state.minute` matches system minute; `state.isAM` matches system AM/PM
  - Verify: Add a debug view that prints `state` every second and observe for 2 minutes

- [ ] **P2-4** `BoardPosition.swift`
  - Criteria: Starting position FEN `rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1` decodes to correct 8×8 array (rank 8 = black pieces, rank 1 = white pieces); one mid-game FEN also verified
  - Verify: Print the decoded array and compare against a known position diagram

- [ ] **P2-5** `PieceView.swift` + `BoardView.swift`
  - Criteria: Board renders in SwiftUI preview showing 8×8 grid; correct piece images for the FEN; alternating light/dark square colors; board is visually square
  - Verify: SwiftUI preview with starting FEN shows standard chess starting position

- [ ] **P2-6** `MinuteSquareRingView.swift`
  - Criteria: At minute 0 → empty border; at minute 30 → exactly half the perimeter filled clockwise from top-left; at minute 59 → fully filled border; ring sits outside the board tiles
  - Verify: SwiftUI preview with hardcoded minutes 0, 15, 30, 45, 59

- [ ] **P2-7** `AMPMView.swift`
  - Criteria: Shows `sun.max.fill` SF Symbol + "AM" text when `isAM = true`; shows `moon.fill` + "PM" when `isAM = false`; not tied to system light/dark mode
  - Verify: SwiftUI preview with both `isAM = true` and `isAM = false`

- [ ] **P2-8** `GameInfoView.swift`
  - Criteria: Displays White player name, Black player name, White ELO, Black ELO, Tournament, Year for a given `ChessGame`; no text truncation or overflow on standard window sizes; historical "?" ELO displays gracefully
  - Verify: SwiftUI preview with a real game from `games.json` and a historical game with `"?"` ELO

- [ ] **P2-9** `ClockView.swift`
  - Criteria: Composes `BoardView` + `MinuteSquareRingView` + `AMPMView` + `GameInfoView`; all components visible; no overlapping or clipped elements; layout works at 300×400pt minimum size
  - Verify: SwiftUI preview shows complete clock layout with real data

- [ ] **P2-10** `ChessClockApp.swift` — MenuBarExtra + floating window
  - Criteria: App launches with no dock icon; menu bar shows a chess-related icon; clicking shows/hides the floating window; window floats above other apps; window persists position between show/hide
  - Verify: Run app, confirm no dock icon, confirm show/hide works, confirm floating behavior

### Phase 3 — Distribution

- [ ] **P3-1** App icon
  - Criteria: App shows a non-blank icon in the menu bar (SF Symbol knight or similar); About box shows icon
  - Verify: Run app, observe menu bar icon; check About box

- [ ] **P3-2** Build `.dmg`
  - Criteria: `hdiutil` script produces a `.dmg` that mounts cleanly; app inside can be dragged to `/Applications`; app launches on macOS 13+ without Xcode installed
  - Verify: Mount DMG, drag to `/Applications`, launch app, observe for 5 minutes

- [ ] **P3-3** GitHub Release v0.1.0
  - Criteria: GitHub Release exists with tag `v0.1.0`; `.dmg` is attached as a release asset; release notes describe what the app is
  - Verify: Download DMG from GitHub Release page and repeat P3-2 verification

- [ ] **P3-4** README.md complete
  - Criteria: README explains the concept, shows at least one screenshot, has a download link pointing to the GitHub Release
  - Verify: View README on GitHub; confirm screenshot renders; confirm download link works

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

---

## Notes

- Do not reorder Backlog items without a good reason — the order reflects dependencies
- Do not start P1 tasks before P0 is complete
- Do not start P2 tasks before P1 is complete
- If a task is blocked, note the blocker inline and move to the next unblocked task
