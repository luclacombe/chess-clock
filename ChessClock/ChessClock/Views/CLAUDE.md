# Views/

All views are pure SwiftUI. They receive data as constructor arguments. No Combine, no timers. All dimensions, colors, and animation values come from `DesignTokens.swift`.

## Composition Hierarchy

```
ClockView (holds ClockService + GuessService, manages ViewMode)
  ├── [.clock]    BoardView(fen:isFlipped:) + GoldRingLayerView (CALayer, Metal noise)
  │                 └── hover → Glance face (blurred board + GlassPillView); tap → .info
  ├── [.info]     InfoPanelView(state:guessService:onBack:onGuess:onReplay:onSettings:)
  │                 ├── BoardView (tappable, CTA pill overlay)
  │                 └── GameInfoView(game:) — player names, event, date, round
  ├── [.puzzle]   GuessMoveView(state:guessService:onBack:onReplay:) + PuzzleRingView
  │                 ├── InteractiveBoardView or static BoardView (depending on turn)
  │                 ├── Header pills (auto-hide) + tries indicator
  │                 └── Result card overlays (succeeded / failed)
  ├── [.replay]   GameReplayView(game:hour:isFlipped:isActive:onBack:) + ReplayBackgroundView
  │                 ├── BoardView + move highlight overlay
  │                 ├── Nav pill (← →) + zone label + SAN pill
  │                 └── ReplayProgressBar (zone-colored, draggable, halftone cursor)
  └── [.settings] SettingsPlaceholderView(onBack:) — "Coming Soon"

Onboarding overlays (conditional):
  ├── WelcomeOverlayView (Stage 0) — cinematic focus pull, bokeh motes + tagline
  ├── OnboardingOverlayView (Stage A) — 3-step clock tour
  └── OnboardingCalloutView — reusable pill used across stages B–E
```

`ClockView` is fixed at 300×300, clipped to `ChessClockRadius.outer` (18pt). On first launch it overlays `WelcomeOverlayView` → `OnboardingOverlayView` in sequence.

## File Notes

**ClockView.swift** — Root view. Owns `@StateObject GuessService`. `WindowObserver` (NSViewRepresentable) resets mode to `.clock` on popover reopen and clears all onboarding overlays. Root ZStack clipped to rounded rect. Clock face hover triggers Glance face: board blurs (8pt Gaussian), centered `GlassPillView` shows formatted time + "Mate in N". Ring remains un-blurred and ticking. Orchestrates 6 onboarding stages (0, A–E) via state flags, `.onChange(of: viewMode)` triggers, and `DispatchQueue.main.asyncAfter` delays. **Hour-change animation:** freezes old board (snapshotFen), ring sweeps to full (0.3s), drains clockwise (2.5s cubic ease-in), brief white flash, new board swaps in.

**BoardView.swift** — 8×8 grid via nested `ForEach`. Lichess colors: light `#F0D9B5`, dark `#B58863`. `isFlipped` inverts row order for PM (Black's perspective). Optional `highlightedSquares: (from: ChessSquare, to: ChessSquare)?` for move highlighting. Implements `Equatable` for SwiftUI optimization. No interaction — pure display.

**InteractiveBoardView.swift** — Extends the board layout with piece interaction. Single `DragGesture(minimumDistance: 6)` on the container maps touch coordinates to squares. Separate tap gesture per square for click-select. Selected piece highlighted. Legal destinations shown as dots (empty) or ring overlay (captures). Snap-back spring animation on illegal drops. Red pulse on invalid target. Scale animations for hover/select (1.03 → 1.05 → 1.08). Promotion picker appears when pawn reaches back rank. Caches legal moves on FEN change. Calls `onMove(ChessMove)`.

**InfoPanelView.swift** — Detail panel. Top row: back button | board (164×164) | settings button. CTA pill: icon + text, changes based on result state — "Play" (gold) / solved checkmark (green) / "Review" (gray). Below: `GameInfoView` with player rows (white/black with ELO), event, date/round. Hover scale (1.04) + brightness boost. Optional `highlightMetadata` and `highlightCTA` bools add gold glow overlays for onboarding Stages B and C.

**GameInfoView.swift** — Reusable metadata display. Player rows (label + name + ELO right-aligned), Event, Date (month + year), optional Round. Used inside `InfoPanelView`.

**GuessMoveView.swift** — Inline multi-move puzzle. Shows `InteractiveBoardView` (user's turn) or static `BoardView` (opponent animating). Header pills auto-hide after ~2s, reappear on hover. 3-dot tries indicator (glass spheres: used = red, current = gold ring, remaining = white ring). Wrong tries pill appears centered on incorrect move. Result card overlays: green "Solved!" (with try count + stats + buttons) or red "Not solved" (with solution + stats + buttons). Buttons appear after 0.5s delay. Feedback glow ring on board border (green = correct, red = wrong). Opponent moves animated with 0.4s delay. Optional `onFeedback` callback for ring tint coordination. Stage E onboarding callout.

**GameReplayView.swift** — Full game replay. Pre-computes all positions via `computeAllPositions(game:)` using `ChessRules.apply`. `ReplayZone` enum classifies positions: `before` (gray), `start` (gold), `after` (gold), `checkmate` (red) — each with color and label. SAN formatting via `SANFormatter.format()`. Keyboard navigation (← → and CMD+← CMD+→ for jump). Controls row: nav pill | zone label pill | SAN + counter pill. `ReplayProgressBar` with zone-colored fill, snap zones, and halftone cursor on hover. Optional `highlightProgressBar` for onboarding Stage D. Board size 164×164 with move from/to highlights.

**GoldRingLayerView.swift** — CALayer-based minute ring (`NSViewRepresentable`). `GoldNoiseRenderer` renders animated Metal simplex noise at 15 FPS to an IOSurface, ring-masked by even-odd `CAShapeLayer`. Progress mask (pie wedge, single-path, even-odd fill) updated 1/sec with 0.3s ease. Accepts `minute`, `second`, `isActive`, `hourChange`, `hideTickMarks`, `forceFullRing`. 4 cardinal tick marks (12/3/6/9) with shadows + gradient taper. `hideTickMarks` controls per-tick group visibility — each tick slides in from its respective edge (8pt translate + opacity) over 0.5s easeOut for onboarding reveal on A-3. `forceFullRing` shows the ring at full progress (full bounds rect mask); when it transitions true→false, triggers a 3-phase fill animation: gold fade-out (0.3s) → snap empty + restore → frame-by-frame clockwise fill from 0 to actual progress (fixed velocity, linear, 3s for full ring). To reuse this sequence, set `forceFullRing = true` then toggle to `false`. Normal progress updates suppressed during `forceFullRing` or `fillAnimating`. When `isActive` is false, noise timer stops (zero CPU/GPU). **Hour-change animation:** sweep to full (0.3s easeInEaseOut) → drain clockwise (2.5s cubic ease-in via frame-by-frame wedge updates). **Butt rounding:** `wedgePath` closes with a quadratic bezier (~1pt leftward bulge) instead of flat `closeSubpath()`, staying within half tick width. Reduce motion: single static frame, no timer.

**PuzzleRingView.swift** — CALayer-based decorative marble noise ring for puzzle mode (`NSViewRepresentable`). Same Metal renderer as gold ring but always fully visible (no progress mask). Accepts `isActive`, `tintTarget: TintTarget`, `tintSeq: Int`. **Tint state machine:** phases `idle` → `rampUp` (0.18s) → `holding` (0.4s) → `rampDown` (0.36s). If same tint re-triggers during hold: `pulseDip` → `pulseRecover`. Tint RGB and strength passed to renderer shader. Layer includes inner board shadow, specular strip, and shadow strip.

**ReplayProgressBar.swift** — Interactive progress bar for game replay. Context zone (70% width) + puzzle zone (30% width). Zone-colored fill with soft right-edge fade gradient (except at checkmate). Halftone cursor (grid of white dots with quadratic falloff) on hover. Snap logic: snap to 0 in left 10%, snap to puzzle start near zone boundary (±3%), linear interpolation within each zone. Drag and hover seek via `onSeek(Int)`. Expands height on hover.

**ReplayBackgroundView.swift** — CALayer-based animated marble noise background for replay mode (`NSViewRepresentable`). Full 300×300 renderer at 12 FPS. Dark scrim overlay (56% black) for text readability. `colorScheme=1.0` (marble brown), large blobs, gentle drift. Timer lifecycle: starts/stops based on `isActive`.

**GoldNoiseRenderer.swift** — Metal compute pipeline manager. Failable `init?(width:height:)` creates device, queue, pipeline from `goldNoise` kernel, and pre-allocates 2 `IOSurface` + 2 `MTLTexture` pairs (double-buffer, `.bgra8Unorm`). `renderFrame(completion:)` dispatches compute kernel asynchronously — main thread never blocked. Caller sets `CALayer.contents = ioSurface` directly (zero-copy). Tunable properties: `scale` (blob size), `speed` (flow rate), `colorScheme` (0 = gold, 1 = marble), `tintR/G/B` + `tintStrength` (shader color blend).

**GoldNoiseShader.metal** — Metal compute kernel. 3D simplex noise (Gustavson/McEwan) with 2-octave FBM, mapped through a 5-tone gold color ramp via smoothstep segments. Supports `colorScheme` (gold vs marble) and tint blending. Kernel `goldNoise` takes `time`, `scale`, `speed` buffer params and writes RGBA to output texture.

**OnboardingCalloutView.swift** — Reusable "Gold Ember" callout pill for onboarding stages. Fully opaque (no transparency). Layers: dark espresso base → 3D depth gradient → top-edge gold gleam → gold border stroke. Outer glow (dual gold shadows) + grounding shadow. HStack: icon + text VStack + progress dots (filled gold for completed, outline for remaining). Whole view tappable. Init: `text`, optional `subtext`, `step`, `totalSteps`, `onTap`.

**WelcomeOverlayView.swift** — Stage 0 cinematic "focus pull." Transparent overlay with bokeh gold motes (10 blurred circles, randomized size/position/opacity/color/lifespan) and tagline "Every board tells the time" (serif, 4-layer dark shadow halo). Board blur/dim/scale driven by ClockView. Auto-dismiss after 6.5s or tap to fast-finish. `DustMoteView` (private) — individual bokeh particle with 2-phase animation (fade-in + drift-up/fade-out).

**OnboardingOverlayView.swift** — Stage A. 3-step progressive tour. Step 1: "Every hour, a real game" (board spotlight, ring extra dark). Step 2: "The ring shows the minutes" (ring spotlight, board extra dark). Step 3: "Tap anywhere for game details" (no scrim, board pulses infinitely). Uses `RingAnnulusShape` for spotlight mask with destinationOut blend, crisp edges (no blur). Callout positioned at bottom. Final tap calls `onBoardTap()` to navigate to info panel + `OnboardingService.dismissStageA()`. Optional `onReachFinalStep` callback fires when advancing to step 3 (used for tick mark fade-in).

**GlassPillView.swift** — Reusable frosted-glass container. `.ultraThinMaterial` background, top-edge white specular highlight, 0.5pt white border, dual shadows. Generic `@ViewBuilder` content.

**PromotionPickerView.swift** — Centered overlay with 4 piece buttons (Q, R, B, N) in a vertical column at the promotion file. Semi-transparent scrim. `onPick(PieceType)`.

**SettingsPlaceholderView.swift** — Placeholder for settings mode. Back button + centered gear icon + "Coming Soon" text.

**PieceView.swift** — `Image(piece.imageName).resizable().scaledToFit()`.
