# TODO — Chess Clock

> This is the **source of truth** for all development tasks.
> Never mark an item done without verifying its acceptance criteria.
> Run `/sync` at the start and end of every session.

---

## In Progress

_Nothing in progress._

---

## Backlog

_No tasks in backlog._

---

## Done

### Sprint 5 — Puzzle Visual Overhaul & Polish ✓

> **Goal:** Fix InfoPanel centering, overhaul puzzle header pills (flash bug, styling, logic), add decorative marble noise ring to puzzle mode with color-transition feedback, and redesign result overlays as compact frosty cards.

- [x] **S5-1: InfoPanelView — True vertical centering** — Changed frame alignment from .top to .center. `c679bcb`
- [x] **S5-2: GoldNoiseShader + GoldNoiseRenderer — Color scheme + tint parameters** — Marble color ramp, colorScheme selection, tintR/G/B/tintStrength blending. `541ea1d`
- [x] **S5-3: DesignTokens — Puzzle polish tokens** — pillBackground, pillBorder, ringTintWrong/Correct, ChessClockTiming enum. `541ea1d`
- [x] **S5-4: PuzzleRingView — Decorative marble noise ring** — NSViewRepresentable with full marble ring, TintPhase state machine (idle/rampUp/holding/rampDown/pulseDip/pulseRecover), board shadow layer. `34d1183`
- [x] **S5-5: GuessMoveView — Header pills complete overhaul** — Flash fix (solid pillBackground), 0.5pt border + shadow, unified hover area, two-line info pill, wrong-answer tries-only pill. `b54c71f`
- [x] **S5-6: ClockView + GuessMoveView — Marble ring integration + feedback wiring** — PuzzleRingView in ClockView, onFeedback callback, removed old red border flash. `c34dfd5`
- [x] **S5-7: GuessMoveView — Result overlay redesign as compact frosty card** — Board blur, .regularMaterial card, .primary/.secondary text, matching capsule buttons, scale+opacity transition. `04764c0`

#### Post-Sprint 5 Polish (visual feedback session)

- [x] **S5-P1: Fix green ring feedback on correct moves** — Moved `onFeedback?(true)` from `.success` to `.correctContinue`; ring now flashes green per-move, not on full solve.
- [x] **S5-P2: Fix pip/tries mutual exclusion** — Pip hides when wrongTriesPill visible; both hide during result overlays.
- [x] **S5-P3: Pip styling — raise, lighten, tighten hover area** — Smaller/lighter pip (10pt, white 0.25/0.50), top-aligned in ZStack. Hover logic split: pip hover reveals pills, pills hover keeps them; no more 280×44 invisible hit zone.
- [x] **S5-P4: Reduce header auto-hide** — headerAutoHide 2.5s → 1.8s.
- [x] **S5-P5: Noise ring color ramp — marble → board browns** — Replaced cool white/gray tones with warm brown 5-tone ramp matching boardLight/boardDark palette.
- [x] **S5-P6: Result card tint + border** — Light green (12%) / light red (12%) fill tint; matching green/red border stroke at 25%.
- [x] **S5-P7: Blurred board edge feedback glow** — 4pt strokeBorder + 6pt blur, 0.75 peak opacity, timing matched to ring (0.15s up, 1.0s hold, 0.20s down). Green on correct, red on wrong.
- [x] **S5-P8: Puzzle ring depth — match clock ring** — Board shadow lineWidth 1→2, alpha 0.25→0.35, radius 3→4; specular 0.15→0.20; shadow strip 0.06→0.08.
- [x] **S5-P9: Back button hit area + tries pill animation** — `.contentShape(Rectangle())` on back button label; wrong tries pill `.transition(.opacity)` moved to container VStack; fade-out slowed to `.easeOut(0.45)`.
- [x] **S5-P10: 3D glass try indicators** — Red: RadialGradient sphere with specular highlight. Gold: AngularGradient stroke ring, transparent center. White: AngularGradient stroke ring, subtle lighting. Reusable `tryIndicator(index:triesUsed:)` helper.
- [x] **S5-P11: Try indicators on result cards** — Replaced "First try"/"Second try" text with 3D circle pips; not-solved card shows 3 red spheres.

### Sprint 4.5 — Polish & Header Redesign ✓

> **Goal:** Fix tick z-order, balance Detail face layout, improve board interaction visibility, implement auto-hide puzzle header pills, and redesign the result overlay as full-board frosted glass.

- [x] **S4.5-1: ClockView — Tick z-order fix** — Moved GoldRingLayerView after boardWithRing in ZStack. `5f5b5d2`
- [x] **S4.5-2: InfoPanelView — Vertical balance fix** — Removed Spacer(), symmetric .padding(.vertical, 12), alignment: .top. `afea009`
- [x] **S4.5-3: DesignTokens — Interaction color opacity updates** — squareSelected 0.30→0.50, legalDot/legalCapture 0.28→0.55. `cad4eb6`
- [x] **S4.5-4: InteractiveBoardView — Legal dot size increase** — sq*0.32→sq*0.38. `cad4eb6`
- [x] **S4.5-5: GuessMoveView — Auto-hide header pills** — Three-pill HStack (back, info, tries) with auto-hide after 2.5s; persistent pip chevron. `6767efb`
- [x] **S4.5-6: GuessMoveView — Wrong move border flash** — 3pt red strokeBorder at 75% opacity, 0.5s fade; pills reappear for 1.8s. `6767efb`
- [x] **S4.5-7: GuessMoveView — Result overlay frosted glass** — Full-board ultraThinMaterial + 10% tint; no icon; 28pt title; Review→ capsule (0.2s delay); Done plain. `6767efb`

### Sprint 4 — Puzzle Face ✓

> **Goal:** Ship the interactive puzzle in a fixed 300×300 square with no text overlays during play.

- [x] **S4-1: DesignTokens — add puzzleBoard radius token and update tick length** — Added `ChessClockRadius.puzzleBoard = 4` and changed `ChessClockSize.tickLength` from 8 to 12. `ef0d488`
- [x] **S4-2: InteractiveBoardView — gold selection color, gold legal-move dots, piece hover lift** — Replaced yellow/black interaction colors with gold tokens; added per-piece hover scale (1.03) and selected scale (1.05). `531b577`
- [x] **S4-3: GoldRingLayerView — extend ticks to 12pt, add board-surface shadow, taper gradient to white 0.20** — `innerEnd` 13→14; board shadow CAShapeLayer per tick; dim gradient tapers 0.45→0.20. `5f59127`
- [x] **S4-4: GuessMoveView — fixed 280×280 board, ZStack layout, 4pt corner radius** — Root body ZStack, board at .frame(280,280), clipShape puzzleBoard (4pt), headerOverlay placeholder. `23cf909`
- [x] **S4-5: GuessMoveView — header overlay: back + last names + "Mate in N" + tries indicator** — 36pt translucent header; last names from PGN; gold/red/outline tries circles. `e164378`
- [x] **S4-6: GuessMoveView — remove statusText, contextLine, and opponent text badge** — Deleted statusText, opponentMoveText state and assignments; isOpponentAnimating retained. `8bbb1a0`
- [x] **S4-7: GuessMoveView + InteractiveBoardView — wrong move: snap-back + red square pulse, no text overlay** — Deleted wrongFlashOverlay; redPulseSquare red flash + snapBackSquare spring in InteractiveBoardView; no 1.2s delay in handleMove(.wrong). `ff240aa`
- [x] **S4-8: GuessMoveView — replace successOverlay and failedOverlay with spec-compliant result cards** — 36pt icon, ChessClockRadius.card (12pt), "Solved"/"Not solved", Review(gold)/Done buttons; deleted statsLine and solutionMoves(). `2e35484`
- [x] **S4-9: PromotionPickerView — column at promotion file, no title, 35×35 pieces, ultraThinMaterial cells** — VStack column at file x-position, ultraThinMaterial cells, 0.30 scrim, no title, badge(4pt) radius. `93c6e40`
- [x] **S4-10: GuessMoveView — opponent auto-play: 0.4s pause, from/to highlight, no text** — Delay 0.8s→0.4s; lastOpponentMove highlight via BoardView + InteractiveBoardView highlightedSquares param; cleared on user's correct move. `1a29734`
- [x] **S4-11: InfoPanelView — CTA pill hover animation (scaleEffect + brightness)** — isHovered state; scaleEffect(1.04) + brightness(0.08); 0.12s easeInOut; all three pill states share isHovered. `61f5d72`

### Sprint 4P — Ring Performance (Zero-Copy IOSurface + Timer Lifecycle) ✓

- [x] **S4P-1: GoldNoiseRenderer — IOSurface zero-copy + async rendering** — Rewrote Metal pipeline with double-buffered IOSurface-backed textures, async GPU completion, eliminated all CPU readback. `30ff743`
- [x] **S4P-2: GoldRingLayerView + ClockView — Timer lifecycle + IOSurface integration** — Added `isActive` parameter, timer pauses when popover closes, adapted to async IOSurface rendering. `5444fc4`
- [x] **S4P-3: ClockService — Lazy timer start** — Removed eager `startTimer()` from init(). `b74d3c7`
- [x] **S4P-4: Docs update** — Updated DESIGN.md and Views/CLAUDE.md with IOSurface architecture.

_Sprint 4 ring tasks archived to docs/archive/TODO-done-sprint-4-ring.md_
_Sprint 3.95 tasks archived to docs/archive/TODO-done-sprint-3.95.md_
_v0.5.1 tasks archived to docs/archive/TODO-done-v0.5.1.md_
_Sprint 1 tasks archived to docs/archive/TODO-done-sprint-1.md_
_Sprint 2 tasks archived to docs/archive/TODO-done-sprint-2.md_
_Sprint 3 tasks archived to docs/archive/TODO-done-sprint-3.md_
_Sprint 3.5 tasks archived to docs/archive/TODO-done-sprint-3.5.md_
_Sprint 3.75 tasks archived to docs/archive/TODO-done-sprint-3.75.md_
_Sprint 3.9 tasks archived to docs/archive/TODO-done-sprint-3.9.md_
_v0.1.0 tasks archived to docs/archive/TODO-done-v0.1.0.md_
_v0.2.0 tasks archived to docs/archive/TODO-done-v0.2.0.md_
_v0.3.0 tasks archived to docs/archive/TODO-done-v0.3.0.md_
_v0.4.0 tasks archived to docs/archive/TODO-done-v0.4.0.md_
_v0.5.0 tasks archived to docs/archive/TODO-done-v0.5.0.md_

---

## Notes

- Do not reorder Backlog items without a good reason — the order reflects dependencies
- Do not mark a task done without verifying its acceptance criteria
- If a task is blocked, note the blocker inline and move to the next unblocked task
