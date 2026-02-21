# Progress Log — Archived v0.1.0

> Archived from PROGRESS.md on 2026-02-21 when v0.1.0 shipped.
> This file covers Sessions 1–6 (planning through Phase T+F completion).

---

## 2026-02-21 — Session 6

**Goal:** Begin Phase N nice-to-haves (starting with S9 manual observation or N1 hour-change animation)
**Completed:** — (session just started; sync run, archive triggered)
**Blocked / Skipped:** —
**Next session:** Start at N1 (Hour-change animation)
**Notes:**
- Phase T + F fully complete as of Session 5; 30 tests, 0 failures
- S9 (30-min observation) can be done in parallel with any N task
- Doc files (CLAUDE.md, DECISIONS.md, MAP.md, FUTURE.md) have uncommitted edits — review before committing

---

## 2026-02-21 — Session 5 (v0.2.0 Phase T + Phase F — Sprint)

**Goal:** Ship all Phase T (test suite T1–T6) and Phase F (bug fixes F1–F2) via parallel sprint.

**Completed:**
- (T1) Added ChessClockTests XCTest target to project.pbxproj + shared scheme with test action; TEST_HOST points to app bundle so `@testable import ChessClock` works
- (T2) Refactored `ClockService.makeState(for:)` → `makeState(at date: Date = Date())`; BUILD SUCCEEDED, behavior unchanged
- (T3) BoardPositionTests.swift — 6 cases: king placement, all 12 piece types, nil squares, empty FEN, invalid FEN fallback, sparse endgame
- (T4) GameSchedulerTests.swift — 9 cases: determinism, fenIndex correctness (3 cases), AM/PM game split, consecutive-day advance, pre-epoch safety, wrap-around
- (T5) ClockServiceTests.swift — 8 cases: 3:45 AM, noon, midnight, 23:59, isAM flip, FEN consistency, multi-date stress
- (T6) GameLibraryTests.swift — 6 cases: bundle load, 12-position invariant, non-empty names, year range, JSON round-trip (2 variants)
- (F1) MinuteSquareRingView: ring now starts at top-center (midX, minY); 5-segment clockwise path; minute=15 → right-center, minute=30 → bottom-center
- (F2) GameInfoView: year formatted as `String(game.year)` — no thousands-separator comma in any locale

**Test results:** 30 tests, 0 failures, TEST SUCCEEDED

**MVP Success Criteria:** S2, S3, S4, S5, S6, S7 now verified by automated tests. S1 ✓ manual. S8 ~ partial. S9 pending 30-min observation.

**Blocked / Skipped:**
- T4 agent hit token limit partway through — file was created on disk and committed manually by senior
- GameLibrary.private init prevents creating an empty-library mock; empty-library branch verified by code inspection only

**Next session:** S9 (30-min manual observation), then Phase N nice-to-haves. Recommended starting point: N1 (hour-change animation) or N4 (onboarding tooltip).

**Notes:**
- Sprint used 4 parallel background agents (T3, T4, F1, F2) + senior for T1/T2/T5/T6
- All commits follow Conventional Commits format
- 8 commits this session: T1 (effb426) → T2 (a027147) → F2 (cafca1f) → F1 (83caf15) → T3 (e5c2667) → T4 (0494267) → T5+T6 (076b624)

---

## 2026-02-21 — Session 4 (v0.2.0 Planning)

**Goal:** Plan the v0.2.0 release scope and update planning documents.

**Completed:**
- MAP.md updated: added "Minute ring 12 o'clock start" (bug fix) and "Automated test suite" to NICE TO HAVE v0.2.0 targets
- TODO.md updated: full v0.2.0 backlog added with three phases (T, F, N) and acceptance criteria for each task

**Blocked / Skipped:** None — this was a planning-only session

**Next session:** Verify MVP success criteria S1–S9 manually, then begin T1 (Add XCTest target). Phases T and F can proceed in parallel: test infrastructure + ring fix are independent.

**Notes:**
- v0.2.0 task breakdown: 6 test tasks (T1–T6), 1 bug fix (F1), 5 NICE TO HAVE (N1–N5)
- Key insight for test suite: ClockService needs `makeState(at: Date = Date())` signature (T2) before ClockState tests (T5) can simulate arbitrary times
- Ring fix math: start at `(midX, minY)`, 5 segments clockwise, same total perimeter — no progress formula change
- Recommended sprint order: T1 → T2 → T3+T4+F1 (parallel) → T5 → T6 → verify all green → N tasks

---

## 2026-02-21 — Session 3 (continued — Phase 3)

**Goal:** Complete Phase 3 distribution tasks.

**Completed:**
- (P3-1) App icon: 10 PNG sizes generated from wK.png on dark mahogany background using ImageMagick; AppIcon.appiconset populated; menu bar uses crown.fill SF Symbol; BUILD SUCCEEDED
- (P3-2) scripts/build_dmg.sh: archives Release build, falls back to archive .app when no Developer ID cert, packages with hdiutil → dist/ChessClock-0.1.0.dmg (1.1MB)
- (P3-3) GitHub Release v0.1.0 created with DMG asset and full release notes
- (P3-4) README.md updated: direct download link live, Gatekeeper note added, repo URL corrected

**Blocked / Skipped:**
- Screenshot placeholder in README (requires running the app manually to capture)
- App notarization (requires Apple Developer ID certificate — out of scope for MVP)

**Next session:** All MUST HAVE tasks complete. Potential improvements: add more players to games.json (increase from 588 toward 730), notarize app, add screenshot to README

**Notes:**
- Release: https://github.com/luclacombe/chess-clock/releases/tag/v0.1.0
- DMG is unsigned; users must right-click → Open on first launch

---

## 2026-02-21 — Session 3 (Phase 1 + Phase 2)

**Goal:** Complete Phase 1 (data pipeline) and Phase 2 (full Swift app) in one session via parallel agents.

**Completed:**
- (P1-1) scripts/fetch_games.py — downloads 15 players from PGN Mentor (User-Agent header required)
- (P1-2) scripts/curate_games.py — 588 checkmate games curated into curated_games.pgn
- (P1-3) scripts/build_json.py — 588 × 12 FEN positions → scripts/games.json (531K, all verified)
- (P1-4) games.json copied to ChessClock/ChessClock/Resources/; BUILD SUCCEEDED
- (P2-1) ChessGame.swift + GameLibrary.swift — Codable struct, singleton bundle loader
- (P2-2) GameScheduler.swift — deterministic half-day game selection from epoch 2026-01-01
- (P2-3) ClockService.swift + ClockState.swift — 1s Timer, @Published state, placeholder fallback
- (P2-4) BoardPosition.swift — FEN parser, Piece types, startingPosition constant
- (P2-5) PieceView.swift + BoardView.swift — 8×8 grid, lichess brown colors, piece images
- (P2-6) MinuteSquareRingView.swift — clockwise perimeter ring, 0–59 minute progress
- (P2-7) AMPMView.swift — sun.max.fill/moon.fill SF Symbols, hardcoded colors
- (P2-8) GameInfoView.swift — compact player/ELO/tournament strip, "?" ELO handled
- (P2-9) ClockView.swift — composes BoardView + ring overlay + AMPMView + GameInfoView
- (P2-10) ChessClockApp.swift — MenuBarExtra(.window) + crown.fill icon, no dock icon

**Blocked / Skipped:** P1-2 yielded 588 games (not 730) — strict checkmate filter + available data

**Next session:** Start at P3-1 (App icon — About box icon, menu bar already using crown.fill SF Symbol)

**Notes:**
- 4 agents ran in parallel: data pipeline (bg) + models/services + board rendering + UI components
- All Swift agents reported BUILD SUCCEEDED independently; full integration also BUILD SUCCEEDED
- games.json: 531K well under 10MB limit
- ClockService gracefully falls back to placeholder game when games.json not present
- GameScheduler epoch: 2026-01-01, double-modulo handles pre-epoch dates safely

---

## 2026-02-20 — Session 2

**Goal:** Create GitHub repo (P0-1), then Xcode project (P0-3)
**Completed:**
- (sync) Verified P0-2 and P0-4 criteria — marked done
**Blocked / Skipped:** none yet
**Next session:** TBD
**Notes:** gh CLI not installed; will use git + curl or browser for P0-1

---

## 2026-02-20 — Session 1 (Planning)

**Goal:** Set up all project documentation and scaffolding files so a fresh Claude Code session can begin development immediately.

**Completed:**
- Created `CLAUDE.md` — primary Claude Code context file
- Created `TODO.md` — full task list with acceptance criteria for all MUST HAVE tasks (P0-1 through P3-4)
- Created `PROGRESS.md` (this file)
- Created `DECISIONS.md` — 8 architecture decision records
- Created `MVP.md` — frozen MVP spec with 9 success criteria
- Created `MAP.md` — NICE TO HAVE and NEXT VERSION features
- Created `FUTURE.md` — long-term idea parking lot
- Created `README.md` — public-facing project description
- Created `.claude/settings.json` — PostToolUse activity hook
- Created `.claude/commands/sync.md` — /sync slash command
- Created `scripts/requirements.txt` — python-chess dependency
- Created `.gitignore` — Xcode + project-specific ignores

**Blocked / Skipped:**
- P0-1 (GitHub repo creation) — requires user to create repo manually or approve gh CLI command
- P0-3 (Xcode project) — requires Xcode, deferred to next session

**Next session:**
- Start at: **P0-1** — Create GitHub repo, then **P0-3** — Create Xcode project

**Notes:**
- All documentation is complete. The project directory is ready.
- Fresh chat should open `CLAUDE.md` first, then `TODO.md` to find current task.
- Run `/sync` at the start of the next session to confirm state.
- The Xcode project goes inside `ChessClock/` subfolder (not the repo root).
