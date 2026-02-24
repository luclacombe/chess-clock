# Progress Log — v0.5.1

> Archived 2026-02-24

---

## 2026-02-23 — Sprint 3.9: Visual Refinement
**Goal:** Refine ring animation (traveling pulses), ring base appearance (glass tube), info panel composition, and tick mark styling.
**Completed:**
- S3.9-1 DesignTokens — ChessClockPulse, ChessClockTube, ChessClockCTADetail enums; boardDetail 176→164; shimmerMinOpacity + anim.shimmer removed
- S3.9-2 MinuteBezelView — FilledRingTrack parameterized; three glass tube overlay layers; tick marks simplified to gradient bars
- S3.9-3 MinuteBezelView — RingCenterlinePath shape; TimelineView-driven dual traveling pulses with layered glow
- S3.9-4 InfoPanelView — flanking icons, 164pt board, glassy player indicators, split name/ELO, CTA with detail tokens
- S3.9-5 DESIGN.md — Face 1 ticks, Face 3 layout, token tables updated
- S3.9-6 Glass audit — GlassPillView specular highlight + stroke 0.30; CTA pill inner stroke
**Blocked / Skipped:** None
**Agents deployed:** 3 (Agent A: S3.9-2 + S3.9-3, Agent B: S3.9-4, Agent C: S3.9-5) + Senior: S3.9-1, S3.9-6
**Next session:** Run `/plan-sprint` to set up Sprint 4 (Puzzle Face)
**Notes:**
- 6 commits: c044af5 (tokens), 24fc694 (tube+ticks), a12d36a (pulses), 9f05dca (info panel), 326adc8 (docs), 96fe5d1 (glass audit)
- Agent A ran S3.9-2 and S3.9-3 sequentially; Agent B (S3.9-4) and Agent C (S3.9-5) ran in parallel
- BUILD SUCCEEDED after all commits integrated

---

## 2026-02-23 — Sprint 3.9 Planning
**Goal:** Plan Sprint 3.9 (Visual Refinement) — polish sprint before Sprint 4 (Puzzle Face)
**Completed:**
- Ran `/plan-sprint 3.9` — decomposed into 6 tasks (S3.9-1 through S3.9-6)
- Researched Liquid Glass techniques, traveling pulse animations, glass tube effects
- Added Sprint 3.9 section to DESIGN.md with full spec (ring pulses, glass tube, info panel layout, tick marks, glass audit)
- Updated TODO.md with 6 tasks, dependency graph, and acceptance criteria
**Blocked / Skipped:** None
**Next session:** Run `/sprint` to execute Sprint 3.9
**Notes:**
- Sprint 3.9 addresses: flat ring shimmer → traveling pulses, flat gold bar → glass tube, crowded info panel → flanking icons + player indicators, inconsistent ticks → gradient bars, glass coherence audit
- Dependency chain: S3.9-1 → (S3.9-2 + S3.9-4 + S3.9-5 parallel) → S3.9-3 → S3.9-6
- 3 agents recommended for parallel execution

---

## 2026-02-23 — Sprint 3.75: Ring Geometry + Detail Face Fix
**Goal:** Fix ring rendering artifacts (lineCap bleed, corner gaps, flat appearance, weak shimmer) and repair Detail face layout (clipped buttons, overflowing text, visible ring).
**Completed:**
- S3.75-1 DesignTokens — accentGoldLight/accentGoldDeep, ringGradient, shimmer 1.8s/0.50↔1.0, boardDetail 196→176, ringOuterEdge/ringInnerEdge/shimmerMinOpacity
- S3.75-2 MinuteBezelView — complete rewrite: FilledRingTrack (even-odd fill) + ProgressWedge mask, gold gradient, .butt lineCap ticks at ring edges
- S3.75-3 BoardView — 0.5pt dark strokeBorder overlay for ring-board definition
- S3.75-4 InfoPanelView — 8pt top padding, 20pt header padding, 2pt board spacing, 6pt CTA spacing, reads 176pt token
- S3.75-5 ClockView — ring opacity 0.0 for .info mode, removed blur
- S3.75-6 DESIGN.md — all spec changes documented, Sprint 3.75 added to Sprint Plan
**Blocked / Skipped:** None
**Agents deployed:** 4 (Agent A: S3.75-2, Agent B: S3.75-3 + S3.75-5, Agent C: S3.75-4) + Senior: S3.75-1, S3.75-6
**Next session:** Run `/plan-sprint` to set up Sprint 4 (Puzzle Face)
**Notes:**
- 5 commits: cc54fff (tokens), 16995a7 (board bevel), 1eb003c (hide ring), a65333b (ring rewrite), 390bb0d (info panel)
- Phase 1 agents (S3.75-3, S3.75-5) ran in parallel with S3.75-1; Phase 2 agents (S3.75-2, S3.75-4) launched after S3.75-1 committed
- BUILD SUCCEEDED after all agent commits integrated

---

## 2026-02-23 — Sprint 3: Detail Face
**Goal:** Ship the info panel with proper information hierarchy, equalized bezel gaps, and always-visible tick marks.
**Completed:**
- S3-1 DesignTokens — ringInset 4→5, bezelGap 2→1, ring radius 10→9, tickLength 4→6, tickWidth 1.5→2
- S3-2 MinuteBezelView — all 4 cardinal ticks now .white, removed conditional gold/gray logic
- S3-3 ClockView — MinuteBezelView persistent background layer, ring opacity per face (1.0/0.30/0.0/0.0), animated transitions, InfoPanelView gains onReplay
- S3-4 InfoPanelView — complete rewrite: 28pt header (chevron + gear), 196×196 board with CTA overlay, PlayerNameFormatter names, abbreviated event line, removed Round/AM-PM/labels/Divider
**Blocked / Skipped:** None
**Agents deployed:** 3 (Agent A: S3-2, Agent B: S3-3, Agent C: S3-4) + Senior: S3-1
**Next session:** Run `/plan-sprint` to set up Sprint 4 (Puzzle Face)
**Notes:**
- All 107 tests pass, zero regressions
- 4 commits: c481cd1 (tokens), b73ff73 (ticks), 6251f69 (ClockView+ring), d31b00a (InfoPanel)
- S3-2 and S3-3 ran in parallel after S3-1; S3-4 ran sequentially after S3-3

---

## 2026-02-23 — Sprint 3 Planning
**Goal:** Plan Sprint 3 (Detail Face) from DESIGN.md
**Completed:**
- Ran `/plan-sprint` — decomposed Sprint 3 into 4 tasks (S3-1 through S3-4)
- Verified DESIGN.md coverage: all 10 Sprint 3 line items mapped to tasks
- Solved bezel asymmetry: ringInset 4→5 equalizes outer/inner gaps to 1pt each (board stays 280)
- Identified S3-1 (tokens) as blocker for S3-2/S3-3; S3-3 blocks S3-4; S3-2 is independent after S3-1
**Blocked / Skipped:** None
**Next session:** Run `/sprint` to execute Sprint 3
**Notes:**
- Interface contract: InfoPanelView gains `onReplay` callback (S3-3 adds signature, S3-4 uses it)
- GameInfoView.swift may be dead code — not used by InfoPanelView. Defer cleanup.

---

## 2026-02-23 — Sprint 2: Clock + Glance
**Goal:** Ship the primary surface — what users see 95% of the time.
**Completed:**
- S2-1 DesignTokens — concentric radius system (outer=14, ring=10, board=4), ring dimensions (stroke=8, inset=4, gap=2)
- S2-2 MinuteBezelView — RingShape corner radius from ChessClockRadius.ring token
- S2-3 BoardView — token-based clip radius and color references, removed inline constants
- S2-4 GlassPillView — new reusable .ultraThinMaterial container
- S2-5 ClockView — 14pt outer clip, Glance face (blurred board + GlassPillView), deleted old hover text + 6 tests
**Blocked / Skipped:** None
**Agents deployed:** 2 (Agent A: S2-1/S2-2/S2-3, Agent B: S2-4) + Senior: S2-5
**Next session:** Run `/plan-sprint` to set up Sprint 3 (Detail Face)
**Notes:**
- All 113 tests pass (6 HoverTooltipTests removed, 107 remain + 6 new-equivalent coverage)
- 3 commits: bdeb036 (tokens+bezel+board), b5ad8ac (glass pill), b0addec (glance+clip)
- InteractiveBoardView has independent color constants — no breakage from BoardView cleanup

---

## 2026-02-23 — Sprint 2 Planning
**Goal:** Plan Sprint 2 (Clock + Glance) from DESIGN.md
**Completed:**
- Ran `/plan-sprint` — decomposed Sprint 2 into 5 tasks (S2-1 through S2-5)
- Verified DESIGN.md coverage: all 11 Sprint 2 line items mapped to tasks
- Identified S2-1 (tokens) as the blocker for S2-2/S2-3/S2-5; S2-4 is independent
- Noted HoverTooltipTests.swift (6 tests) must be deleted with old hover text in S2-5
**Blocked / Skipped:** None
**Next session:** Run `/sprint` to execute Sprint 2
**Notes:**
- `ChessClockRadius.system` is unreferenced — safe rename to `outer`
- Codesign workaround still needed: `CODE_SIGN_IDENTITY=""`

---

## 2026-02-23 — Sprint 1: Foundation
**Goal:** Ship the visual atoms that everything else builds on.
**Completed:**
- S1-1 DesignTokens.swift — all color, type, spacing, radius, dimension, animation constants
- S1-2 Merida SVGs — 12 SVGs from Lichess replace cburnett PNGs
- S1-3 BoardView 6pt corner radius
- S1-4 MinuteBezelView — custom RingShape, gold fill, gray track, 4 tick marks, animated
- S1-5 PlayerNameFormatter — PGN name inversion, initial handling, ELO formatting
- S1-6 ClockView locked to 300×300, MinuteBezelView wired in, padding removed
- S1-7 ContentView.swift deleted (legacy)
- S1-8 MoveArrowView.swift deleted, GameReplayView cleaned, 8 arrow tests removed
**Blocked / Skipped:** None
**Agents deployed:** 5 (Agent A: S1-1, Agent B: S1-2 partial, Agent C: S1-3/5/7, Agent D: S1-8, Agent E: S1-4)
**Next session:** Run `/plan-sprint` to set up Sprint 2 (Clock + Glance)
**Notes:**
- Agents B/C/D had Bash permission denied for curl/verification/commit; Senior handled those steps
- All tests pass (32 GameReplayView + others), BUILD SUCCEEDED
- 6 commits: 050ed42, c2f9f69, 43cf99d, 3c8c260, bd1979f, 4d8163d

---

## 2026-02-23 — Session (v0.5.1 patch)
**Goal:** Fix replay start position bug + GitHub Latest release badge
**Completed:**
- Fixed `puzzleStartPosIndex` formula: `positions.count - 1` → `positions.count - 2`
- Updated `testComputeAllPositions_puzzleStartMapsCorrectly` to match corrected formula (psi=9, not 10)
- All 40 tests pass (CODE_SIGN_IDENTITY="" workaround for transient keychain lock)
- Tagged v0.5.1 and pushed; created `gh release create v0.5.1 --latest` → GitHub now shows v0.5.1 Latest
- Updated README download link, TODO Done section, MAP.md patch note
**Next session:**
- Start at: v0.6.0 planning
**Notes:**
- The psi bug was subtle: for hour 1, psi=N pointed to checkmate (after your move); correct is N-1 (before your move, showing opponent's context arrow)
- Codesign intermittently fails in xcodebuild test; use CODE_SIGN_IDENTITY="" workaround if it recurs
