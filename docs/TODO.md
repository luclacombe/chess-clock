# TODO — Chess Clock

> This is the **source of truth** for all development tasks.
> Never mark an item done without verifying its acceptance criteria.
> Run `/sync` at the start and end of every session.

---

## In Progress

_Next: N4 — Onboarding tooltip (first launch only)_

---

## Backlog — v0.2.0 (ordered, do not skip ahead)

> Phase T (tests) and Phase F (bug fixes) are complete. Phase N tasks are ordered — do not skip ahead.
> N tasks with XCTest criteria must have passing tests before being marked done.
> N tasks marked "manual only" (N3, N9) use BUILD SUCCEEDED + manual verification as the gate.

### Phase T — Test Suite

- [x] **T1** Add XCTest target to Xcode project (completed 2026-02-21)
- [x] **T2** Refactor `ClockService` for time injection (completed 2026-02-21)

- [x] **T3** `BoardPosition` unit tests (completed 2026-02-21)
- [x] **T4** `GameScheduler` unit tests (completed 2026-02-21)
- [x] **T5** `ClockService` + `ClockState` unit tests (completed 2026-02-21)
- [x] **T6** `ChessGame` + `GameLibrary` integration tests (completed 2026-02-21) — 30 total tests, 0 failures

### Phase F — Bug Fixes

- [x] **F1** Fix minute ring start position to 12 o'clock (top-center) (completed 2026-02-21)
- [x] **F2** Fix year number formatting in `GameInfoView` (completed 2026-02-21)

### Phase N — NICE TO HAVE

- [x] **N3** Global keyboard shortcut ⌥Space to toggle window (completed 2026-02-21)
  - Default: Option+Space shows/hides the floating clock window without needing to click the menu bar icon; implemented via `CGEventTap` or a Carbon global hotkey (no third-party packages)
  - Criteria: Pressing ⌥Space from any app toggles the window; shortcut does not conflict with system shortcuts; BUILD SUCCEEDED
  - Tests: No XCTest case — system event tap cannot be unit tested; manual verification is the gate
  - Verify: Launch app, switch to another app, press ⌥Space → window appears

- [ ] **N4** Onboarding tooltip (first launch only)
  - On first launch, show a brief popover or overlay: "The hour = how many moves until this game ended. The ring = minutes elapsed in the hour." with a single Dismiss button; dismissed state persisted in `UserDefaults`; never shown again after first dismissal
  - Criteria: Tooltip appears on first launch; cleared `UserDefaults` triggers it again; after dismiss, second launch shows no tooltip; BUILD SUCCEEDED
  - Tests: XCTest cases — (1) key absent → `shouldShowOnboarding` returns true; (2) key present → returns false; (3) dismiss action writes key; all 3 cases pass
  - Verify: Delete `UserDefaults` key, launch → tooltip shown; dismiss, relaunch → no tooltip

- [x] **N5** GitHub Actions automated DMG build (completed 2026-02-21)
  - `.github/workflows/release.yml` triggered by push of any `v*` tag; builds Release scheme, runs `scripts/build_dmg.sh`, uploads resulting `.dmg` as a GitHub Release asset; uses macOS runner
  - Criteria: Workflow YAML exists and passes `yamllint`; pushing a `v*` tag triggers the build job; `.dmg` appears as a release asset automatically
  - Verify: `yamllint .github/workflows/release.yml` → no errors; push a `v0.2.0` tag and confirm CI runs

- [x] **N6** Per-device game variation (completed 2026-02-21)
  - Current: `GameScheduler` is fully deterministic — same date → same game on every device (like Wordle). User feedback: feels static, all devices show same game.
  - Fix: on first launch, generate a random `Int` seed and store in `UserDefaults` key `"deviceGameSeed"`. `GameScheduler.resolve(date:library:)` offsets `halfDayIndex` by this seed before the modulo: `(halfDayIndex + seed) % library.games.count`. Each device gets a unique rotation but remains deterministic per-device across days.
  - Criteria: Two fresh installs on separate devices with cleared `UserDefaults` produce different games on the same date at least occasionally (probabilistic); single device always returns same game for same date/period; BUILD SUCCEEDED
  - Tests: XCTest cases — (1) same date + seed=0 and seed=1 → different game indices; (2) same date + same seed → identical result across repeated calls; (3) seed is written to `UserDefaults` on first call; all cases pass
  - Verify: Build; reset `UserDefaults` seed key; verify new seed is written on launch; change seed manually and confirm game changes

- [ ] **N7** Board perspective encodes AM/PM — remove explicit indicator
  - Replace `AMPMView` (sun/moon icon + text) with board orientation. AM cycle (12 AM–11 AM): board shown from White's perspective (rank 1 at bottom). PM cycle (12 PM–11 PM): board shown from Black's perspective (rank 8 at bottom, board flipped vertically).
  - Implementation: add `isFlipped: Bool` to `ClockState` (= `!isAM`); pass to `BoardView`; when `isFlipped`, reverse the rank order in the 8×8 grid render. Remove `AMPMView` from `ClockView`. Update T5 tests for the flipped state.
  - Criteria: AM shows board with white pieces at bottom; PM shows board with black pieces at bottom; no sun/moon icon visible; BUILD SUCCEEDED; T5 tests updated and passing
  - Verify: Mock AM and PM times; confirm board flip; visual check

- [ ] **N8** Game info layout improvements
  - Current: single-line or minimally-structured display; missing month and round; `GameInfoView` does not label fields
  - Improvements: (1) fix year comma bug (tracked separately as F2); (2) expose `month` (string, e.g., "January") and `round` (string, e.g., "3") in `games.json` from the Python pipeline; (3) add `month` and `round` fields to `ChessGame` model; (4) redesign `GameInfoView` with labeled rows (White:, Black:, ELO:, Event:, Date:, Round:) in a clean two-column or stacked layout
  - Criteria: `GameInfoView` shows all 6 fields legibly with labels; no comma in year; month and round are non-empty for all games that have the data; BUILD SUCCEEDED
  - Tests: Update T6 `ChessGame`/`GameLibrary` tests — (1) JSON round-trip includes `month` and `round` fields; (2) all games in bundle have non-nil `month` and `round` where data exists; updated T6 still passes (0 failures)
  - Verify: Build + visual check; confirm `python3 scripts/build_json.py` outputs month and round fields in `games.json`

- [ ] **N9** Right-click context menu
  - Right-clicking the menu bar icon should show a menu with at minimum: "Open as Floating Window" and "Quit Chess Clock"
  - "Open as Floating Window": opens an `NSPanel` (floating, always-on-top, no menu bar required) with the same `ClockView` content; useful when user wants the clock visible on desktop without clicking menu bar
  - Implementation: add a secondary `MenuBarExtra` menu block for right-click items; use `NSPanel` with `level = .floating` for the detached window; `ClockService` is shared between both windows
  - Criteria: Right-click on menu bar icon shows the context menu; "Quit" exits cleanly; "Open as Floating Window" shows a resizable floating panel; BUILD SUCCEEDED
  - Tests: No XCTest case — AppKit menu and NSPanel cannot be meaningfully unit tested; manual verification is the gate
  - Verify: Build + manual test of right-click menu and floating window

---

## Done

_v0.1.0 tasks archived to docs/archive/TODO-done-v0.1.0.md_

---

## Notes

- Do not reorder Backlog items without a good reason — the order reflects dependencies
- Do not start P1 tasks before P0 is complete
- Do not start P2 tasks before P1 is complete
- If a task is blocked, note the blocker inline and move to the next unblocked task
