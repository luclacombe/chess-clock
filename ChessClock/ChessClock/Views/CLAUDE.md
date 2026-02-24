# Views/

All views are pure SwiftUI. They receive data as constructor arguments. No Combine, no timers.

## Composition Hierarchy

```
ClockView (holds ClockService + GuessService, manages ViewMode)
  ├── [.clock]  BoardView(fen:isFlipped:) + GoldRingLayerView overlay (CALayer)
  │               └── hover → Glance face (blurred board + GlassPillView); tap → ViewMode = .info
  ├── [.info]   InfoPanelView(state:guessService:onBack:onGuess:)
  │               ├── BoardView (tappable, CTA bar overlay at bottom)
  │               └── GameInfoView(game:) — player names, event, date, round
  ├── [.puzzle] GuessMoveView(state:guessService:onBack:onReplay:)
  │               ├── InteractiveBoardView or BoardView (depending on turn)
  │               ├── wrongFlashOverlay / successOverlay / failedOverlay (inline ZStack)
  │               └── PromotionPickerView overlay (when pawn reaches back rank)
  └── [.replay] GameReplayView(game:hour:isFlipped:onBack:)
                  ├── BoardView + MoveArrowView overlay (fades in/out per move)
                  └── navButtons (⏮ ← ⦿ → ⏭) + keyboard ← / →
```

`ClockView` is fixed at 300×300, clipped to 14pt rounded rect. On first launch it overlays `OnboardingOverlayView`.

## File Notes

**ClockView.swift** — Root view. Owns `@StateObject GuessService`. `WindowObserver` (NSViewRepresentable) resets mode to `.clock` on popover reopen. Root ZStack clipped to `ChessClockRadius.outer` (14pt). Clock face hover triggers Glance face: board blurs (8pt Gaussian), centered `GlassPillView` shows formatted time + "Mate in N". Ring remains un-blurred and ticking.

**BoardView.swift** — 8×8 grid via nested `ForEach`. Lichess colors: light `#F0D9B5`, dark `#B58863`. `isFlipped` inverts row order for PM (Black's perspective). No interaction — pure display.

**InteractiveBoardView.swift** — Extends the board layout with piece interaction. Single `DragGesture(minimumDistance: 6)` on the container maps touch coordinates to squares. Separate tap gesture per square for click-select. Selected piece highlighted in yellow. Legal destinations shown as black dots (empty squares) or ring overlay (captures). Promotion picker appears as an overlay when a pawn reaches the back rank. Calls `onMove(ChessMove)` with the completed move.

**InfoPanelView.swift** — Tap-mode info panel. Shows `BoardView` as a tappable card with a bottom CTA bar (result badge left + AM/PM badge + "Play Puzzle"/"Review" right). Below board: `GameInfoView`. Player ELO shown inline in parentheses.

**GameInfoView.swift** — Reusable metadata display. Shows White/Black player rows (name + ELO right-aligned), Event, Date (month + year if available), optional Round. Used inside `InfoPanelView`.

**GuessMoveView.swift** — Inline multi-move puzzle (no floating window). Shows header (back + game title), context line ("N AM — N Moves to Checkmate — Play as White/Black"), 3-dot tries indicator, and either `InteractiveBoardView` (user's turn) or static `BoardView` (opponent animating). Three inline result overlays:
- `wrongFlashOverlay` — xmark + "Not that move", dismisses after 1.2s
- `successOverlay` — checkmark + "Solved!" + try count + stats + "Review Game"/"Close" (buttons appear after 0.5s delay)
- `failedOverlay` — xmark + "Not solved" + solution moves + stats + "Review Game"/"Close"

**GameReplayView.swift** — Full game replay. Pre-computes all positions via `computeAllPositions(game:)` using `ChessRules.apply`. Position timeline: posIndex 0 = starting position, posIndex N = checkmate. Zone banner ("Game context" / "Puzzle start" / "Solution" / "Checkmate") is color-coded. `MoveArrowView` overlay fades in/out. Keyboard ← / → navigation via `onMoveCommand`.

**MoveArrowView.swift** — Fills an amber shaft-and-arrowhead arrow from one square center to another. Internal static helpers `squareCenter(sq:squareSize:isFlipped:)` and `arrowPath(from:to:squareSize:)` are `internal` (not `private`) for testability. Pending deletion in TODO.md S1-8 (to be replaced by highlighted squares).

**GoldRingLayerView.swift** — CALayer-based minute ring (Sprint 4N). `NSViewRepresentable` with a `CALayer` whose `contents` is a GPU-rendered simplex noise texture mapped to gold colors. `GoldNoiseRenderer` renders at half-res (150×150) via Metal compute shader at 10 FPS, ring-masked by even-odd `CAShapeLayer`. Progress mask (pie wedge) on the gold container, updated 1/sec with 0.3s ease. Reduce motion: single static frame, no timer. Accepts `minute: Int` and `second: Int`.

**GoldNoiseRenderer.swift** — Metal compute pipeline manager. Failable `init()` creates `MTLDevice`, `MTLCommandQueue`, `MTLComputePipelineState` from `goldNoise` kernel. `renderFrame(size:) -> CGImage?` renders at half resolution and converts texture to CGImage via pixel readback. Tunable `scale` (blob size) and `speed` (flow rate) properties.

**GoldNoiseShader.metal** — Metal compute kernel. 3D simplex noise (Gustavson/McEwan) with 2-octave FBM, mapped through a 5-tone gold color ramp via smoothstep segments. Kernel `goldNoise` takes `time`, `scale`, `speed` buffer params and writes RGBA to output texture.

**MinuteBezelView.swift** — Empty file. Previously contained the SwiftUI ring implementation (`FilledRingTrack`, `ProgressWedge`, `RingCenterlinePath`, `MinuteBezelView`). Replaced by `GoldRingLayerView` in Sprint 4R.

**MinuteSquareRingView.swift** — Legacy clockwise square-perimeter ring. Replaced by `GoldRingLayerView`.

**PromotionPickerView.swift** — Centered overlay with 4 piece buttons (Q, R, B, N) in a horizontal row. Calls `onPick(PieceType)`.

**OnboardingOverlayView.swift** — First-launch explanation overlay. Shown once; `OnboardingService.dismissOnboarding()` sets a `UserDefaults` flag. Dismiss button reads "Got it".

**PieceView.swift** — `Image(piece.imageName).resizable().scaledToFit()`.
