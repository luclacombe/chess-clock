# Progress Log

> Append a new entry at the start of each development session.
> Run `/sync` to auto-update this file.

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

---

## 2026-02-25 — Sprint 4.5: Polish & Header Redesign
**Goal:** Fix tick z-order, balance Detail face, increase interaction visibility, auto-hide header pills, frosted glass result overlay
**Completed:**
- S4.5-1 ClockView — GoldRingLayerView z-order above board (tick marks visible)
- S4.5-2 InfoPanelView — symmetric 12pt vertical margins, alignment: .top
- S4.5-3 DesignTokens — squareSelected 0.30→0.50, legalDot/legalCapture 0.28→0.55
- S4.5-4 InteractiveBoardView — legal dot diameter sq*0.32→sq*0.38
- S4.5-5 GuessMoveView — three auto-hide pills (back, info, tries) + persistent pip chevron
- S4.5-6 GuessMoveView — 3pt red strokeBorder flash (0.5s) + pills reappear 1.8s on wrong move
- S4.5-7 GuessMoveView — full-board ultraThinMaterial frosted glass overlays, no icons, 28pt title
**Blocked / Skipped:** None
**Agents deployed:** 4 (A: S4.5-1, B: S4.5-2, C: S4.5-3+S4.5-4, D: S4.5-5+S4.5-6+S4.5-7)
**Next session:** Run app and verify visually. Run `/plan-sprint` for Sprint 5 (Replay Face).
**Notes:**
- All 4 agents ran in parallel — no dependency conflicts
- Full build verified after all commits merged
- Zero adaptations needed; plan executed exactly as designed

---

## 2026-02-25 — Sprint 4.5 Planning: Polish & Header Redesign
**Goal:** Plan Sprint 4.5 based on visual feedback from Sprint 4 results
**Completed:**
- Identified 7 issues from user screenshots: tick z-order, Detail face balance, selection highlight, legal dot size, wrong move feedback, puzzle header, result overlay
- Conducted full design Q&A session with user — all design decisions approved
- Updated DESIGN.md: Face 4 header spec (auto-hide pills), result overlay (frosted glass), token opacities, Sprint 4.5 sprint plan section
- Wrote 7 Sprint 4.5 tasks to TODO.md with acceptance criteria, dependency graph
**Next session:** Run `/sprint` to execute Sprint 4.5 (Wave 1: 4 parallel agents for S4.5-1..4; Wave 2: 1 agent for S4.5-5..7 sequential).
**Notes:**
- S4.5-1 (tick z-order): root cause confirmed — GoldRingLayerView at z=0, boardWithRing at z=1 in ClockView ZStack; ticks hidden beneath 280×280 board
- S4.5-2 (InfoPanel): Spacer() absorbs 35-40pt at bottom vs 12pt at top; fix: remove Spacer, symmetric padding, top alignment
- S4.5-5 (header pills): down-chevron pip must not block piece dragging — small 24×20 target at top-center edge
- S4.5-7 (result overlay): user confirmed "board visible through" → ultraThinMaterial is correct choice

---

## 2026-02-25 — Sprint 4: Puzzle Face
**Goal:** Ship the interactive puzzle in a fixed 280×280 square with no text overlays during play
**Completed:**
- S4-1 DesignTokens — ChessClockRadius.puzzleBoard=4, tickLength 8→12
- S4-2 InteractiveBoardView — gold selection/legal-dot colors, hover scale 1.03/1.05
- S4-3 GoldRingLayerView — ticks extended to 12pt, board shadow layer, taper gradient 0.45→0.20
- S4-4 GuessMoveView — ZStack root, fixed 280×280 board, 4pt clip, headerOverlay placeholder
- S4-5 GuessMoveView — header overlay: back chevron, last names, Mate in N, gold/red/outline tries
- S4-6 GuessMoveView — removed statusText, opponentMoveText, contextLine
- S4-7 GuessMoveView + InteractiveBoardView — wrongFlashOverlay gone; redPulseSquare + snapBackSquare in IBV
- S4-8 GuessMoveView — spec-compliant result cards (36pt icon, 12pt radius, Review/Done buttons)
- S4-9 PromotionPickerView — column at file x-position, ultraThinMaterial cells, no title
- S4-10 GuessMoveView + BoardView + InteractiveBoardView — 0.4s delay, lastOpponentMove highlight
- S4-11 InfoPanelView — CTA pill hover: scaleEffect(1.04) + brightness(0.08), 0.12s easeInOut
**Blocked / Skipped:**
- None
**Agents deployed:** 6 (A: S4-1, B: S4-11, C: S4-3, D: S4-2+S4-9, E: S4-4+S4-5+S4-6+S4-7+S4-8, F: S4-10)
**Next session:** Run app and verify puzzle face visually. Run `/plan-sprint` for Sprint 5 (Replay Face).
**Notes:**
- UnevenRoundedRectangle skipped for macOS 13 compat — used RoundedRectangle for header corners
- All 11 tasks verified BUILD SUCCEEDED individually and final full build passes
- SourceKit IDE diagnostics are noise (scope resolution without full context) — ignore them

---

## 2026-02-24 — Sprint 4P: Ring Performance (Zero-Copy IOSurface + Timer Lifecycle)
**Goal:** Eliminate 3-4% CPU when popover is closed and reduce open-state CPU from 4-5% to <0.5%
**Completed:**
- S4P-1 GoldNoiseRenderer rewrite — double-buffered IOSurface-backed MTLTextures, async GPU completion via addCompletedHandler, eliminated CGImage readback pipeline (getBytes, CGContext, waitUntilCompleted)
- S4P-2 GoldRingLayerView + ClockView — added `isActive: Bool` parameter driven by WindowObserver popover visibility; timer invalidates when popover closes (zero CPU/GPU when invisible), restarts on reopen; adapted to async IOSurface rendering
- S4P-3 ClockService lazy timer — removed startTimer() from init(); timer only starts on first resume() call
- S4P-4 Docs update — DESIGN.md performance architecture, Views/CLAUDE.md file descriptions
**Blocked / Skipped:**
- None
**Agents deployed:** 3 (Wave 1: S4P-1 + S4P-3 in parallel; Wave 2: S4P-2 sequential after S4P-1)
**Next session:** Run app and verify CPU with Activity Monitor. Run `/plan-sprint` for Sprint 4 (Puzzle Face).
**Notes:**
- Root cause of 3-4% idle CPU: noise Timer (10 FPS) never stopped when popover closed — Metal compute + synchronous readback ran continuously while invisible
- Root cause of 4-5% open CPU: per-frame texture allocation, synchronous waitUntilCompleted(), CPU pixel readback (getBytes + CGContext + CGImage)
- IOSurface zero-copy: GPU writes directly to IOSurface memory, CALayer.contents accepts IOSurface natively — no CPU involved in the display path
- All 116 tests pass, build succeeds

---

## 2026-02-24 — Sprint 4N: Perlin Noise Ring
**Goal:** Replace CAGradientLayer + locations drift with GPU-rendered animated simplex noise mapped to gold colors
**Completed:**
- S4N-1 Metal compute shader — 3D simplex noise (Gustavson/McEwan), 2-octave FBM, 5-tone gold color ramp via smoothstep segments
- S4N-2 GoldNoiseRenderer — Metal pipeline manager (MTLDevice, MTLCommandQueue, MTLComputePipelineState), renders at half resolution (150×150), texture-to-CGImage readback
- S4N-3 GoldRingLayerView integration — replaced CAGradientLayer + color drift animation with plain CALayer receiving noise texture at 5 FPS via Timer
**Blocked / Skipped:**
- None
**Agents deployed:** 1 (foreground, S4N-1/S4N-2/S4N-3 sequential)
**Next session:** Run app and verify ring visuals + CPU. Tune noise parameters (scale, speed) if needed. Run `/plan-sprint` for Sprint 4 (Puzzle Face).
**Notes:**
- Metal Toolchain component had to be downloaded first (704.6 MB)
- Architecture: Metal compute kernel → MTLTexture → CGImage → CALayer.contents, 5 FPS timer, half-res rendering
- Reduce motion: single static frame rendered at init, no timer
- All existing ring structure preserved: track, progress mask, specular/shadow strips, tick marks

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
