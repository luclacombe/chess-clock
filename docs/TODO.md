# TODO — Chess Clock

> This is the **source of truth** for all development tasks.
> Never mark an item done without verifying its acceptance criteria.
> Run `/sync` at the start and end of every session.

---

## In Progress

_Nothing in progress._

---

## Backlog

_Empty — no pending tasks._

---

## Done

### Sprint 7R — Replay & Puzzle UI Polish ✓

> **Goal:** Visual polish pass on the replay face (marble background, spacing, pill fixes, progress bar redesign) and puzzle success indicator (green try pip).

- [x] **S7R-1: DesignTokens — replayBoard 220→206, replay shadow + progress bar tokens** — Smaller board for breathing room; warm shadow colors, thick progress bar dimensions, halftone tokens.
- [x] **S7R-2: ReplayBackgroundView — animated marble noise background** — New NSViewRepresentable using GoldNoiseRenderer (3200×3200, marble colorScheme, 12 FPS, reduce-motion safe). Dark scrim overlay for text readability.
- [x] **S7R-3: GameReplayView — layout, contrast, pill fixes** — Added `isActive` prop for background lifecycle. Spacing tightened (board raised). Fixed-width pills (56/72/flex) to prevent jitter. Text contrast bumped for marble background. Board shadows enlarged.
- [x] **S7R-4: GameReplayView — nav pill split & animation** — Nav pill split into two tap halves (left=back, right=forward). Chevron pulse animation on tap. Hover scale effect.
- [x] **S7R-5: ClockView — pass isActive to GameReplayView** — Wired `isPopoverVisible` to replay background lifecycle.
- [x] **S7R-6: ReplayProgressBar — halftone softened, gold zone redesigned** — Halftone cursor: blur + opacity drop. Gold zone: 7/10+3/10 visual split with soft gradient transition. Fill: soft right edge mask (disabled at checkmate for full green). Drag-to-scrub gesture. Left 1/10 snap-to-zero. Zone fill remapped to visual layout.
- [x] **S7R-7: ReplayZone colors — solution gold, checkmate green** — Solution zone changed from green to brighter gold. Checkmate uses consistent bright green. Zone label "Opening" renamed to "Context".
- [x] **S7R-8: GuessMoveView — green success try indicator** — Added `succeeded` param to `tryIndicator()`. On solved result card, the winning try shows as a green glass sphere instead of gold ring. Green never appears during active puzzle.

### Sprint 6.5 — Replay Face: Board-First Two Overlays Redesign ✓

> **Goal:** Redesign GameReplayView with a minimal "board-first" layout: always-visible back pill with player names (top-left), slim navigation strip with zone + SAN + counter + arrows (bottom), interactive zone-colored progress bar with snap zones and hover glow, and focus/keyboard bug fixes.

- [x] **S6.5-1: Update DESIGN.md — Replay Face redesign spec** — Face 5 rewritten with board-first two overlays design, Copy Guide updated, Cmd+Arrow shortcuts added, Sprint 6.5 in Sprint Plan. `c70c308`
- [x] **S6.5-2: Design tokens for replay progress bar** — progressBarHeight (3pt), progressBarHoverHeight (5pt), progressBarGlowRadius (20pt) added to ChessClockSize. `62f7a95`
- [x] **S6.5-3: ReplayProgressBar — Interactive zone-colored scrubber** — New view with zone-colored fill, puzzle-start marker, click-to-seek with snap zones, hover thickening + radial cursor glow. `ab536b0`
- [x] **S6.5-4: Rewrite GameReplayView — Board-First Two Overlays** — Always-visible back pill, slim nav strip with ReplayProgressBar, focus ring fix, keyboard on hover, Cmd+Arrow jumps. Deleted ~130 lines of auto-hide/pip/5-button nav. `da890bd`
- [x] **S6.5-5: Verify build + all tests pass** — BUILD SUCCEEDED, 150 tests passed (including all 32 GameReplayViewTests), zero warnings.

### Sprint 6 — Replay Face Overhaul + Ring Polish + Settings Placeholder ✓

> **Goal:** Rewrite `GameReplayView` to match the visual language from Sprint 4–5 (ZStack overlay architecture, pill system, design tokens). Build `SANFormatter`. Add minor tick marks and semicircle ring tip to the gold minute ring. Wire the settings gear icon to a placeholder screen.

- [x] **S6-1: SANFormatter** — New service that converts UCI move strings to Standard Algebraic Notation for the replay nav overlay. `b9ed3b8`
- [x] **S6-2: ReplayZone update** — Expand the `ReplayZone` enum with a `.checkmate` case and update labels to match DESIGN.md naming. `fd1571c`
- [x] **S6-3: GameReplayView layout rewrite** — Replace VStack root with ZStack overlay architecture matching GuessMoveView pattern. `fd1571c`
- [x] **S6-4: Replay header pills** — Two-pill HStack overlaid on board top with auto-hide behavior, matching GuessMoveView's exact pill pattern. `fd1571c`
- [x] **S6-5: Nav overlay** — Bottom overlay on board with 5-button navigation, SAN move label, and position counter. `78dca57`
- [x] **S6-6: Keyboard + focus cleanup** — Ensure arrow keys work immediately without tab-focusing, remove all blue focus rings from replay view. `78dca57`
- [x] **S6-7: Minor tick marks on gold ring** — Add 8 intermediate tick marks for a total of 12 evenly spaced marks (every 30°), resembling a traditional watch dial. `3261c37`
- [x] **S6-8: Semicircle ring tip** — Replace the sharp radial leading edge of the progress fill with a smooth semicircle cap for a "snake body" appearance. `3261c37`
- [x] **S6-9: Settings placeholder screen** — Wire the gear icon in InfoPanelView to navigate to a "Coming Soon" placeholder, add `.settings` ViewMode case. `2157ef0`

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

_Sprint 4.5 tasks archived to docs/archive/TODO-done-sprint-4.5.md_
_Sprint 4 tasks archived to docs/archive/TODO-done-sprint-4.md_
_Sprint 4P tasks archived to docs/archive/TODO-done-sprint-4P.md_
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
