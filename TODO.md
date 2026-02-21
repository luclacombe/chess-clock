# TODO — Chess Clock

> This is the **source of truth** for all development tasks.
> Never mark an item done without verifying its acceptance criteria.
> Run `/sync` at the start and end of every session.

---

## In Progress

_Next: N1 — Hour-change animation_

---

## MVP Success Criteria Checklist

> **Phase T and Phase F complete as of 2026-02-21.** All automated criteria verified.
> S8 is a known partial pass: Gatekeeper blocks the unsigned .dmg; right-click → Open
> works around it. Full fix requires a $99 Developer ID cert (deferred).
> S9 requires a manual 30-minute observation run.

```
Manual — verified with v0.1.0 DMG:
[x] S1  App launches from menu bar on clean macOS 13+ (no Xcode installed)    [manual ✓]
[x] S2  Correct position for current hour                                      [test: T3+T5 ✓ 2026-02-21]
[x] S3  Square ring: 0 min = empty, 30 min ≈ 50%, 59 min = full               [F1 fixed + visual ✓ 2026-02-21]
[~] S8  DMG installs cleanly; no Gatekeeper blocking                           [manual ~, Gatekeeper blocked — right-click open works; full fix = Developer ID cert]

Verified by Phase T test suite:
[x] S4  AM/PM indicator matches system clock                                   [test: T5 ✓ 2026-02-21]
[x] S5  Game info strip shows non-empty values                                 [test: T6 ✓ 2026-02-21]
[x] S6  Two different dates → two different games                              [test: T4 ✓ 2026-02-21]
[x] S7  Game switches at noon and midnight (mocked date test)                  [test: T5 ✓ 2026-02-21]

Manual — requires observation after tests pass:
[ ] S9  No crashes in 30-minute observation                                    [manual — run after Phase T]
```

---

## Backlog — v0.2.0 (ordered, do not skip ahead)

> S4, S5, S6, S7 are verified by completing Phase T — the test suite IS the verification mechanism.
> S1 ✓ and S8 ~ were manually confirmed with v0.1.0. S9 requires a 30-min observation after tests pass.
> Phase T must complete before Phase N begins — tests give confidence for refactors.
> F1 (ring fix) and F2 (year formatting) can run in parallel with Phase T.

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

- [ ] **N1** Hour-change animation
  - When `ClockState.hour` increments, animate the most recent move: the piece that was just played slides from its source square to its destination square over ~1 second (ease-in-out); no animation at other ticks
  - Criteria: Animation is visible when the hour changes; board is static between hour changes; BUILD SUCCEEDED
  - Verify: Mock a rapid hour change in a preview or simulator; observe slide animation

- [ ] **N2** Polished custom app icon
  - Replace `crown.fill` SF Symbol placeholder with a custom icon: chess clock face with a knight piece motif; must look sharp at 16×16 (menu bar) and 512×512 (App Store ready); all required `AppIcon.appiconset` sizes populated
  - Criteria: New icon renders in menu bar and About box; no blank or pixelated sizes; BUILD SUCCEEDED
  - Verify: Build + visual inspection at 16px and 512px

- [ ] **N3** Global keyboard shortcut ⌥Space to toggle window
  - Default: Option+Space shows/hides the floating clock window without needing to click the menu bar icon; implemented via `CGEventTap` or a Carbon global hotkey (no third-party packages)
  - Criteria: Pressing ⌥Space from any app toggles the window; shortcut does not conflict with system shortcuts; BUILD SUCCEEDED
  - Verify: Launch app, switch to another app, press ⌥Space → window appears

- [ ] **N4** Onboarding tooltip (first launch only)
  - On first launch, show a brief popover or overlay: "The hour = how many moves until this game ended. The ring = minutes elapsed in the hour." with a single Dismiss button; dismissed state persisted in `UserDefaults`; never shown again after first dismissal
  - Criteria: Tooltip appears on first launch; cleared `UserDefaults` triggers it again; after dismiss, second launch shows no tooltip; BUILD SUCCEEDED
  - Verify: Delete `UserDefaults` key, launch → tooltip shown; dismiss, relaunch → no tooltip

- [ ] **N5** GitHub Actions automated DMG build
  - `.github/workflows/release.yml` triggered by push of any `v*` tag; builds Release scheme, runs `scripts/build_dmg.sh`, uploads resulting `.dmg` as a GitHub Release asset; uses macOS runner
  - Criteria: Workflow YAML exists and passes `yamllint`; pushing a `v*` tag triggers the build job; `.dmg` appears as a release asset automatically
  - Verify: `yamllint .github/workflows/release.yml` → no errors; push a `v0.2.0` tag and confirm CI runs

- [ ] **N6** Per-device game variation
  - Current: `GameScheduler` is fully deterministic — same date → same game on every device (like Wordle). User feedback: feels static, all devices show same game.
  - Fix: on first launch, generate a random `Int` seed and store in `UserDefaults` key `"deviceGameSeed"`. `GameScheduler.resolve(date:library:)` offsets `halfDayIndex` by this seed before the modulo: `(halfDayIndex + seed) % library.games.count`. Each device gets a unique rotation but remains deterministic per-device across days.
  - Criteria: Two fresh installs on separate devices with cleared `UserDefaults` produce different games on the same date at least occasionally (probabilistic); single device always returns same game for same date/period; BUILD SUCCEEDED
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
  - Verify: Build + visual check; confirm `python3 scripts/build_json.py` outputs month and round fields in `games.json`

- [ ] **N9** Right-click context menu
  - Right-clicking the menu bar icon should show a menu with at minimum: "Open as Floating Window" and "Quit Chess Clock"
  - "Open as Floating Window": opens an `NSPanel` (floating, always-on-top, no menu bar required) with the same `ClockView` content; useful when user wants the clock visible on desktop without clicking menu bar
  - Implementation: add a secondary `MenuBarExtra` menu block for right-click items; use `NSPanel` with `level = .floating` for the detached window; `ClockService` is shared between both windows
  - Criteria: Right-click on menu bar icon shows the context menu; "Quit" exits cleanly; "Open as Floating Window" shows a resizable floating panel; BUILD SUCCEEDED
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
