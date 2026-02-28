# Progress Log

> Append a new entry at the start of each development session.
> Run `/sync` to auto-update this file.

---

## 2026-02-27 — Onboarding Sprint: Progressive Discovery in 4 Stages
**Goal:** Replace single-modal onboarding with a progressive 4-stage system that teaches concepts at the moment the user encounters them.
**Completed:**
- OB-1 OnboardingService expanded with 4 stage flags (A/B/C/D), backward-compat aliases, resetAll()
- OB-2 OnboardingCalloutView (new) — reusable glass callout pill with icon, text, subtext, progress dots, dismiss x. ultraThinMaterial + top-edge gradient + dual shadows.
- OB-3 OnboardingOverlayView rewritten — 3-step Stage A tour (position, ring, tap-to-explore). Board dim on step 2, board pulse on step 3. onBoardTap callback navigates directly to info.
- OB-4 InfoPanelView — highlightMetadata and highlightCTA params with gold glow overlays (blurred strokeBorder)
- OB-5 GameReplayView — highlightProgressBar param with gold glow overlay on progress bar
- OB-6 ClockView orchestration — Stage B triggered on first .info visit (0.6s delay, 2-step callout). Stage C triggered after first puzzle completion (replay nudge with dismiss x). Stage D triggered on first .replay visit (0.8s delay, 5s auto-dismiss). WindowObserver clears all overlays on popover reopen.
**Blocked / Skipped:** None
**Next session:** S7-4 (Face transition audit), S7-5 (Performance audit), S7-6 (Accessibility + reduced motion).
**Notes:**
- 1 new file (OnboardingCalloutView.swift), 5 modified files
- BUILD SUCCEEDED, zero warnings
- Stage triggers use DispatchQueue.main.asyncAfter to let view transitions complete before showing callouts
- UserDefaults keys: onboardingDismissed (A), infoPanelOnboardingSeen (B), replayNudgeSeen (C), replayOnboardingSeen (D)

---

## 2026-02-28 — Sprint 7 (partial): Chrome — BorderlessPanel, Onboarding, Hour-Change Animation
**Goal:** Implement S7-1 through S7-3: borderless floating window, onboarding refresh, and hour-change animation.
**Completed:**
- S7-1 BorderlessPanel — `BorderlessPanel` NSPanel subclass (borderless, 300×300, draggable, `.floating`, system shadow, `.canJoinAllSpaces`). `FloatingWindowContent` wrapper with hover-visible close (`xmark`) + minimize (`minus`) buttons (dark circle bg, white bold icon, drop shadow).
- S7-2 Onboarding refresh — Title "Chess Clock", 4 Copy Guide body lines, "Continue" gold capsule, 12pt card radius, "Don't show again" checkbox (only persists when checked).
- S7-3 Hour-change animation — Ring sweep to full (0.3s) → clockwise drain (2.5s, 60fps Timer, even-odd CAShapeLayer masking, cubic ease-in acceleration) → white flash (0.1s in, 0.2s out) hides board swap to new hour. Board frozen via snapshotFen/snapshotFlipped during drain. Total ~3.1s.
**Blocked / Skipped:** S7-4, S7-5, S7-6 remain in backlog.
**Next session:** S7-4 (Face transition audit), S7-5 (Performance audit), S7-6 (Accessibility + reduced motion).
**Notes:**
- 4 files modified: FloatingWindowManager.swift, OnboardingOverlayView.swift, ClockView.swift, GoldRingLayerView.swift
- Ring drain uses frame-by-frame even-odd masking (growing wedgePath subtracted from full rect) — CA path interpolation doesn't work across different path structures
- BUILD SUCCEEDED, all 150 tests pass

---

## 2026-02-26 — Sprint 6.5 Post: Replay & Puzzle UI Polish
**Goal:** Visual polish pass on replay face and puzzle success indicator.
**Completed:**
- S7R-1 DesignTokens — replayBoard 220→206, replay shadow colors, thick progress bar + halftone tokens
- S7R-2 ReplayBackgroundView (new) — NSViewRepresentable marble noise bg (3200×3200, 12 FPS, scrim 0.56)
- S7R-3 GameReplayView — isActive prop, board raised, fixed-width pills, contrast bumps, marble background
- S7R-4 GameReplayView — nav pill split into two tap halves with pulse animation + hover scale
- S7R-5 ClockView — isPopoverVisible wired to replay background
- S7R-6 ReplayProgressBar — halftone softened, 7/10+3/10 zone split, drag-to-scrub, fill soft edge, checkmate full green, left 1/10 snap-to-zero
- S7R-7 ReplayZone — solution=brighter gold, checkmate=consistent green, "Opening"→"Context"
- S7R-8 GuessMoveView — green glass sphere on success try in result card
- GameReplayViewTests — zone label updated "Opening"→"Context"
**Blocked / Skipped:** None
**Next session:** Run `/plan-sprint` for next sprint.
**Notes:**
- Interactive polish session — iterative tuning of background (colorScheme, scale, speed, resolution, scrim), spacing, progress bar layout
- 6 files modified, 1 new file, 1 test updated. BUILD SUCCEEDED, 150 tests pass.

---

## 2026-02-26 — Sprint 6.5: Replay Face — Board-First Two Overlays Redesign
**Goal:** Redesign GameReplayView with minimal "board-first" layout: always-visible back pill, slim nav strip with progress bar, focus/keyboard fixes.
**Completed:**
- S6.5-1 Update DESIGN.md — Face 5 rewritten with board-first two overlays, Copy Guide updated, Cmd+Arrow shortcuts, Sprint 6.5 in Sprint Plan
- S6.5-2 Design tokens — progressBarHeight (3pt), progressBarHoverHeight (5pt), progressBarGlowRadius (20pt) in ChessClockSize
- S6.5-3 ReplayProgressBar — new SwiftUI view: zone-colored fill, puzzle-start marker, click-to-seek snap zones, hover thickening + radial cursor glow
- S6.5-4 GameReplayView rewrite — always-visible back pill (top-left, player names), slim nav strip (zone + SAN + N/M + arrows + progress bar), deleted ~130 lines (auto-hide pills, pip, 5-button nav, state machine). Focus ring fix, keyboard on hover, Cmd+Arrow jumps (macOS 14+).
- S6.5-5 Full verification — BUILD SUCCEEDED, 150 tests passed (all 32 GameReplayViewTests unchanged), zero warnings
**Blocked / Skipped:** None
**Agents deployed:** 4 (A: S6.5-1, B: S6.5-2, C: S6.5-3, D: S6.5-4)
**Next session:** Run `/plan-sprint` for Sprint 7 (Chrome + Polish).
**Notes:**
- 4-wave execution: Wave 1 (A+B parallel), Wave 2 (C after B), Wave 3 (D after C), Wave 4 (senior verify)
- Zero adaptations — all tasks completed exactly as planned
- 4 agent commits: c70c308, 62f7a95, ab536b0, da890bd
- No integration fixes needed — interface contracts held perfectly across all agents

---

## 2026-02-25 — Sprint 6: Replay Face Overhaul + Ring Polish + Settings Placeholder
**Goal:** Rewrite GameReplayView to match Sprint 4–5 visual language, build SANFormatter, add minor ticks + semicircle ring tip, wire settings placeholder.
**Completed:**
- S6-1 SANFormatter — pure static `format(uci:in:)` with disambiguation, castling, promotion, check/checkmate, en passant; 18 unit tests
- S6-2 ReplayZone update — added `.checkmate` case, renamed labels (Opening, Puzzle, Solution, Checkmate), updated `classify()` with `totalMoves` param
- S6-3 GameReplayView layout — VStack → ZStack overlay architecture (280×280), board highlight squares wired
- S6-4 Replay header pills — back pill + info pill with zone capsule, auto-hide system with pip, spring animations
- S6-5 Nav overlay — 5-button nav, SAN move label via SANFormatter, position counter "N of M", dark scrim background
- S6-6 Keyboard + focus cleanup — `.focusable(true)` on root only, all nav buttons `.focusable(false)`
- S6-7 Minor tick marks — 8 minor ticks at 30° intervals, `ChessClockSize.minorTickLength`/`minorTickWidth` tokens
- S6-8 Semicircle ring tip — `ringCenterlinePoint(at:in:)` helper, wedge path ends with tangent-aligned semicircle cap
- S6-9 Settings placeholder — `.settings` ViewMode, `onSettings` param on InfoPanelView, SettingsPlaceholderView
- Integration fix: GameReplayViewTests updated for classify() API change + renamed zone labels
**Blocked / Skipped:** None
**Agents deployed:** 5 (A: S6-1, B: S6-7+S6-8, C: S6-2+S6-3+S6-4, D: S6-9, E: S6-5+S6-6)
**Next session:** Run `/plan-sprint` for Sprint 7 (Chrome + Polish).
**Notes:**
- 2-wave execution: Wave 1 (4 parallel agents: A, B, C, D), Wave 2 (Agent E after Wave 1)
- Agent C combined S6-2+S6-3+S6-4 sequentially (same file: GameReplayView.swift)
- Agent B combined S6-7+S6-8 sequentially (same file: GoldRingLayerView.swift)
- Agent A's test target build exposed cross-agent breakage (S6-2 changed classify API) — fixed by senior during integration
- All 9 tasks + integration fix verified: BUILD SUCCEEDED, all tests passed (0 failures)
- 6 commits total: 2157ef0, 3261c37, fd1571c, b9ed3b8, 78dca57, ab6748c

---

## 2026-03-28 — Post-Sprint 5 Polish: Visual Feedback & 3D Indicators
**Goal:** Fix bugs and refine visuals from Sprint 5 based on user testing feedback
**Completed:**
- S5-P1 Fix green ring feedback — onFeedback moved to .correctContinue (per-move, not full solve)
- S5-P2 Pip/tries mutual exclusion — pip hides when tries pill visible; both hide during results
- S5-P3 Pip raised, lightened, hover scoped to pip/pills only (no more 280×44 invisible zone)
- S5-P4 Header auto-hide reduced 2.5s → 1.8s
- S5-P5 Noise ring color ramp — marble whites replaced with board-matching brown 5-tone ramp
- S5-P6 Result cards tinted light green/red (12%) with matching border strokes
- S5-P7 Blurred board edge glow — 4pt strokeBorder + 6pt blur, synced to ring feedback timing
- S5-P8 Puzzle ring depth matched to clock ring — specular 0.15→0.20, shadow 0.06→0.08, board shadow stronger
- S5-P9 Back button full-pill clickable + tries pill smooth fade-out (easeOut 0.45s)
- S5-P10 3D glass try indicators — red RadialGradient spheres, gold/white AngularGradient rings
- S5-P11 Try indicator pips replace text on result cards (solved + not solved)
**Blocked / Skipped:** None
**Next session:** Run `/plan-sprint` for Sprint 6 (Replay Face).
**Notes:**
- 11 fixes across 4 source files (GuessMoveView, DesignTokens, GoldNoiseShader, PuzzleRingView)
- All changes verified BUILD SUCCEEDED
- Files: GuessMoveView.swift (bulk of changes), DesignTokens.swift (timing), GoldNoiseShader.metal (color ramp), PuzzleRingView.swift (depth)

---

## 2026-02-25 — Sprint 5: Puzzle Visual Overhaul & Polish
**Goal:** Fix InfoPanel centering, overhaul puzzle header pills, add decorative marble noise ring with color-transition feedback, redesign result overlays as compact frosty cards
**Completed:**
- S5-1 InfoPanelView — frame alignment .top → .center for true vertical centering
- S5-2 GoldNoiseShader + GoldNoiseRenderer — marble color ramp, colorScheme param, tintR/G/B/tintStrength blending
- S5-3 DesignTokens — pillBackground, pillBorder, ringTintWrong/Correct, ChessClockTiming enum
- S5-4 PuzzleRingView — NSViewRepresentable marble noise ring with TintPhase state machine (6 phases, 10 transitions)
- S5-5 GuessMoveView — header pills: flash fix (solid bg), border+shadow, unified hover area, two-line layout, wrong-answer tries-only pill
- S5-6 ClockView + GuessMoveView — PuzzleRingView wired into ClockView, onFeedback callback, old red border flash removed
- S5-7 GuessMoveView — result overlays replaced with compact .regularMaterial card, board blur, matching capsule buttons
**Blocked / Skipped:** None
**Agents deployed:** 4 (A: S5-2, B: S5-3, C: S5-4, D: S5-5); Senior: S5-1, S5-6, S5-7
**Next session:** Run app and verify puzzle visuals. Run `/plan-sprint` for Sprint 6 (Replay Face).
**Notes:**
- Wave 1 (S5-1+S5-2+S5-3) and Wave 2 (S5-4+S5-5) ran in parallel successfully
- S5-2 and S5-3 were committed together by the S5-3 agent (same commit 541ea1d)
- S5-6 and S5-7 done as senior integration work (touching files from multiple agents)
- All 7 tasks verified BUILD SUCCEEDED, zero adaptations needed

_Sprint 4N through Sprint 4.5 sessions archived to docs/archive/PROGRESS-sprint-4-to-4.5.md_
_Sprint ring evolution archived to docs/archive/PROGRESS-sprint-ring-evolution.md_
_v0.5.1 and earlier sessions archived to docs/archive/_

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
