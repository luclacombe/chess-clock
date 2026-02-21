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

## 2026-02-21 — Session 3 (v0.2.0 Phase N Sprint — final)

**Goal:** Ship N4, N7, N8, N9 in parallel via agentic sprint — completing all Phase N tasks
**Completed:**
- (N4) Onboarding overlay on first launch: `OnboardingService` + `OnboardingOverlayView`; 3 new XCTests
- (N7) Board orientation encodes AM/PM: `isFlipped: Bool` in `ClockState`; `BoardView` reverses ranks in PM; `AMPMView` removed; T5 tests updated
- (N8) Game info layout redesign: `build_json.py` extracts month/round; `ChessGame` gains optional fields; `GameInfoView` redesigned with labeled rows; games.json regenerated (422/588 have month, 472/588 have round); 2 new T6 tests
- (N9) Context menu + floating window: secondary `MenuBarExtra` (ellipsis icon, `.menu` style); `FloatingWindowManager` manages floating `NSPanel`
**Blocked / Skipped:** none — all Phase N tasks complete
**Adaptations:**
- N9: secondary MenuBarExtra (left-click ellipsis icon) instead of true right-click on primary icon; floating panel has independent ClockService instance (same game displayed)
**Next session:**
- Run `/archive` to ship v0.2.0; tag v0.2.0
**Notes:**
- 38 tests, 0 failures (up from 33: +3 OnboardingTests, +2 GameLibraryTests for month/round)
- N4/N7/N8/N9 all require manual verification (launch the app)

---

## 2026-02-21 — Session 2 (v0.2.0 Phase N Sprint)

**Goal:** Ship N3, N5, N6 in parallel via agentic sprint
**Completed:**
- (N3) Global ⌥Space hotkey via Carbon `RegisterEventHotKey`; `HotkeyService.swift` + `ChessClockApp.swift` updated; BUILD SUCCEEDED
- (N3 side-fix) Resolved pre-existing CLAUDE.md resource conflict (`EXCLUDED_SOURCE_FILE_NAMES`); added `.xcodeignore`
- (N5) `.github/workflows/release.yml` — CI DMG build triggered by `v*` tag push; YAML validates cleanly
- (N6) `GameScheduler.resolve` gains optional `seed:` param; `deviceGameSeed` in UserDefaults on first launch; 3 new XCTests; total 33 tests, 0 failures
**Blocked / Skipped:**
- N4, N7, N8, N9 — deferred (N4/N7 share ClockView.swift; N9 shares ChessClockApp.swift with N3)
**Adaptations:**
- N3: `NSStatusBar.system.statusItems` removed in macOS 26 SDK — agent used `NSStatusBarWindow` introspection instead
- N5: yamllint unavailable in background agent; validated with Python `yaml.safe_load` instead
**Next session:**
- Start at: N4 (Onboarding tooltip — first launch only)
**Notes:**
- 33 tests, 0 failures
- N3 requires manual verification (⌥Space from another app → window toggles)

---

## 2026-02-21 — Session 1 (v0.2.0 Phase N)

**Goal:** Archive v0.1.0 docs, reset for v0.2.0 Phase N
**Completed:**
- (/archive) Archived Sessions 1–6 → docs/archive/PROGRESS-v0.1.0.md
- (/archive) Archived Done tasks → docs/archive/TODO-done-v0.1.0.md
- (/archive) Moved MVP.md → docs/archive/MVP-v0.1.0.md
- (/archive) Updated CLAUDE.md File Map, reset TODO.md Done section
**Blocked / Skipped:** —
**Next session:** Start at N3 (Global keyboard shortcut ⌥Space)
**Notes:**
- 30 tests, 0 failures carried forward from Phase T
- S9 (30-min manual observation) still pending — run any time
