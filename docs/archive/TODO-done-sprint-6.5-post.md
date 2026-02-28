### Sprint 6.5 (POST) — Replay & Puzzle UI Polish ✓

> **Goal:** Visual polish pass on the replay face (marble background, spacing, pill fixes, progress bar redesign) and puzzle success indicator (green try pip).

- [x] **S7R-1: DesignTokens — replayBoard 220→206, replay shadow + progress bar tokens** — Smaller board for breathing room; warm shadow colors, thick progress bar dimensions, halftone tokens.
- [x] **S7R-2: ReplayBackgroundView — animated marble noise background** — New NSViewRepresentable using GoldNoiseRenderer (3200×3200, marble colorScheme, 12 FPS, reduce-motion safe). Dark scrim overlay for text readability.
- [x] **S7R-3: GameReplayView — layout, contrast, pill fixes** — Added `isActive` prop for background lifecycle. Spacing tightened (board raised). Fixed-width pills (56/72/flex) to prevent jitter. Text contrast bumped for marble background. Board shadows enlarged.
- [x] **S7R-4: GameReplayView — nav pill split & animation** — Nav pill split into two tap halves (left=back, right=forward). Chevron pulse animation on tap. Hover scale effect.
- [x] **S7R-5: ClockView — pass isActive to GameReplayView** — Wired `isPopoverVisible` to replay background lifecycle.
- [x] **S7R-6: ReplayProgressBar — halftone softened, gold zone redesigned** — Halftone cursor: blur + opacity drop. Gold zone: 7/10+3/10 visual split with soft gradient transition. Fill: soft right edge mask (disabled at checkmate for full green). Drag-to-scrub gesture. Left 1/10 snap-to-zero. Zone fill remapped to visual layout.
- [x] **S7R-7: ReplayZone colors — solution gold, checkmate green** — Solution zone changed from green to brighter gold. Checkmate uses consistent bright green. Zone label "Opening" renamed to "Context".
- [x] **S7R-8: GuessMoveView — green success try indicator** — Added `succeeded` param to `tryIndicator()`. On solved result card, the winning try shows as a green glass sphere instead of gold ring. Green never appears during active puzzle.
