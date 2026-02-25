# DESIGN.md — Chess Clock v1.0 Design Language

> This is the **single source of truth** for the v1.0 UI overhaul.
> Every screen, every token, every string, every animation is specified here.
> Engineers implement exactly what this document describes — no improvisation.
> If something is ambiguous, clarify it here before writing code.

---

## Philosophy

This app has an identity problem. Right now it is a chess board that happens to tell time. It must become **a clock that happens to use chess.**

Think of an Apple Watch face. The face is ambient — you glance at it and know the time. You don't read instructions. You don't parse labels. The visual arrangement IS the information. Complications add depth, but the face stands alone.

The chess clock works the same way:
- The **board** is the dial — its arrangement tells the hour
- The **minute ring** is the bezel — it tells the minutes
- The **board flip** is the AM/PM hand — orientation tells morning or afternoon
- Everything else is a complication that appears only when sought

The design language is called **"Precision Ambient"** — quiet when passive, sharp when active.

---

## Principles

These rules resolve ambiguity. When in doubt, apply these:

1. **The clock is primary.** Every decision should reinforce "this is a clock." The minute ring is always the most prominent decorative element. The board serves the clock, not the other way around.

2. **Show, don't tell.** If information can be communicated visually, never use text. A piece sliding IS the opponent's move. A red flash IS "wrong move." The board orientation IS AM/PM.

3. **Quiet until needed.** The default state is silent — no labels, no affordances, no instructions. Information appears only when the user seeks it through interaction.

4. **Always a square.** The app is 300×300 at all times, in every state, in every context. No exceptions. Content must adapt to the fixed canvas through overlays and scaling — never by expanding the frame.

5. **Concentric harmony.** Every corner radius, every boundary, every ring follows concentric geometry — inner shapes echo outer shapes at proportionally smaller radii. This is how Apple designs every device from iPhone to Watch.

6. **watchOS-forward.** This app will be ported to Apple Watch. Design decisions should translate naturally to a circular bezel, smaller canvas, and tap-only interaction. Hover states are macOS-only enhancements, not load-bearing.

7. **Piece-set agnostic.** The visual system must work with any chess piece artwork. No view should depend on specific piece styling. Themes are a future feature — build the architecture now.

---

## Layout System

### The 300×300 Canvas

The app content area is exactly **300×300 points**. This never changes.

```
┌──────────────────────────────────────────┐
│              System popover              │  ← we don't control this
│  ┌──────────────────────────────────┐    │
│  │         300 × 300 content        │    │  ← our canvas
│  │                                  │    │
│  └──────────────────────────────────┘    │
└──────────────────────────────────────────┘
```

### The Layer Model

Five concentric layers, from outside in:

```
Layer 0: CONTENT     — 300×300, clipped to 18pt rounded rect (the outermost shape)
Layer 1: RING        — 8pt stroke, rounded rect path at 6pt inset
Layer 2: BOARD       — 280×280, 8×8 grid, 35pt squares (flush with ring inner edge)
Layer 3: OVERLAYS    — Translucent pills, headers, nav controls
```

**Math:**
- Content clip: `RoundedRectangle(cornerRadius: 18)` on the root view — this is the anchor for all concentric radii
- Ring path: `RoundedRectangle` at 6pt inset from content edge, 8pt stroke → outer edge at 2pt, inner edge at 10pt
- Gap: 0pt — ring inner edge is flush with board edge (no bezel channel). The 2pt outer gap (content edge → ring outer edge) provides breathing room.
- Board: `300 - 2×10 = 280×280`
- Square size: `280 / 8 = 35pt`
- Corner radii follow the concentric formula (see Design Tokens → Concentric Corner Radius Rule)

### State-Dependent Layout

The 300×300 canvas is constant. What changes per face:

| Face | Board Size | Ring | Overlays |
|------|-----------|------|----------|
| Clock | 280×280 | Full gold, continuous gradient rotation (CALayer) | None |
| Glance | 280×280 | Full gold, continuous gradient rotation (CALayer) | Centered glass pill (shadow + inner stroke) |
| Detail | 164×164 | Hidden (0% opacity) | Flanking icons + floating CTA pill + metadata below board |
| Puzzle | 280×280 | Hidden (0% opacity) | Header overlay at top |
| Replay | 280×280 | Hidden (0% opacity) | Header top + nav bottom |

The board is always centered horizontally. In the Detail face, it shifts up to make room for metadata.

---

## The Five Faces

### Face 1: Clock (Ambient)

The default state. What the user sees 95% of the time.

```
╭──────────── ring fills clockwise ───────────╮
│ ╷                                         ╷ │
│                                             │
│    ╭────────────────────────────────╮       │
│    │ ♜       ♝                    ♛ │       │
│    │    ♟  ♟     ♟    ♟   ♝   ♚     │       │
│    │          ♟            ♟        │       │
│    │       ♙  ♙      ♕  ♙           │       │
│    │ ♕  ♙                           │       │
│    │    ♙           ♙      ♙  ♙     │       │
│    │                       ♔        │       │
│    ╰────────────────────────────────╯       │
│                                             │
│ ╵                                         ╵ │
╰─────────────────────────────────────────────╯
```

- Board: 280×280, centered
- Ring: GPU-rendered animated simplex noise mapped to gold colors, filling clockwise from top-center. Metal compute shader generates 3D FBM noise (2 octaves) through a 5-tone gold color ramp, rendered at half resolution (150×150) and upscaled by CALayer. Animated at 10 FPS via Timer — flows like liquid gold. Unfilled track visible at 15% gray. Ring inner edge is flush with the board edge (no gap). Static glass tube overlays (inner specular highlight + outer shadow strip) add cylindrical depth.
- Tick marks: 4 cardinal points (top-center, right-center, bottom-center, left-center). Rendered **on top of** the ring fill (z-order above everything except the content clip) — always visible regardless of ring progress. Each tick is a gradient bar: brighter at the outer end (`white 0.85 opacity`) fading toward the board (`white 0.45 opacity`). `.butt` lineCap. Each tick casts a centered shadow onto the surfaces below it: `Color.black.opacity(0.40)`, radius 1.5pt on the ring portion; `Color.black.opacity(0.30)`, radius 2pt on the board portion (the shadow softens slightly as it falls further from the tick). Positioned at ring outer edge (2pt) to 4pt inside board edge (14pt from content edge) — spanning the full 8pt ring plus 4pt into the board. The board-side portion of the tick is where the shadow on the board is cast. Sized for clear legibility at a glance (see `tick.length`, `tick.width` tokens).
- AM: White's perspective (rank 1 at bottom). PM: Board flipped (rank 8 at bottom).
- **No text. No labels. No visible affordances.** Pure ambient display.

**Ring animation — Metal compute shader architecture (Sprint 4N, optimized Sprint 4P):**

The ring texture is generated by a Metal compute shader (`GoldNoiseShader.metal`) that produces 3D FBM simplex noise mapped through a 5-tone gold color ramp. `GoldNoiseRenderer` manages the Metal pipeline with double-buffered IOSurface-backed textures at half resolution (150×150), upscaled by `CALayer.contentsGravity = .resize`. A 10 FPS Timer drives frame updates. The ring looks like slowly flowing liquid gold.

**Design principle (Sprint 4N):** The CAGradientLayer + locations drift approach (Sprint 4F) produced a "chuggy" pattern — linear interpolation between fixed gradient stops is not organic. Real noise requires GPU computation. A Metal compute kernel generates true simplex noise with zero CPU readback (IOSurface zero-copy to CALayer).

```
NSViewRepresentable ("GoldRingLayerView")
  └─ NSView (wantsLayer = true, isFlipped = true)
      ├─ trackLayer: CAShapeLayer              — gray 15% ring (even-odd, static)
      ├─ goldContainer: CALayer                — masked by progressMask (pie wedge)
      │   ├─ noiseLayer: CALayer               — Metal noise IOSurface, ring-masked, 10 FPS
      │   │   └─ GoldNoiseRenderer             — Metal compute pipeline, half-res (150×150), IOSurface zero-copy
      │   ├─ specularStrip: CAShapeLayer       — white 20% inner highlight (static)
      │   └─ shadowStrip: CAShapeLayer         — black 8% outer shadow (static)
      ├─ progressMask: CAShapeLayer            — pie wedge from center, updated 1/sec
      └─ ticksLayer: CALayer                   — 4 cardinal ticks (static)
```

**Key behaviors:**

- **Noise texture (liquid gold):** `GoldNoiseShader.metal` computes 3D simplex noise (Gustavson/McEwan) with 2-octave FBM (persistence 0.5, lacunarity 2.0). The third dimension is time, so the pattern evolves smoothly. Output is mapped through a 5-tone gold color ramp (deep → cool → primary → warm → light) via smoothstep segments. `GoldNoiseRenderer` renders at 150×150 using double-buffered IOSurface-backed `MTLTexture` pairs. GPU completion is async via `addCompletedHandler` — the main thread is never blocked. The IOSurface is set directly as `noiseLayer.contents` (zero-copy, no CPU readback). A 10 FPS Timer drives rendering. Noise parameters: `scale = 0.012` (large blobs), `speed = 0.22` (moderate flow). Timer pauses when the popover is not visible (`isActive` parameter driven by `ClockView`'s `WindowObserver`) — zero CPU/GPU when closed.

- **Progress advance:** Each second, `updateNSView` computes `progress = (minute × 60 + second) / 3600` and updates the pie wedge `CGPath` on the progress mask. Simple `CATransaction` with 0.3s ease duration. Model layer's path updated directly.

- **Hour rollback:** At minute 0, second 0, the wedge resets to empty without animation (direct path set inside `CATransaction.setDisableActions(true)`).

- **Glass tube:** Specular highlight (1pt inner strip, white 20%) and outer shadow (1pt outer strip, black 8%) are static `CAShapeLayer` even-odd fills inside the gold container, masked by the same progress wedge.

- **Board inner shadow:** 6pt stroke, 4pt blur, 22% opacity where the ring meets the board (rendered in SwiftUI on `BoardView`, not in the CALayer ring).

- **Ring path geometry:** Even-odd `CGPath` with two concentric `CGPath.addRoundedRect` calls. Outer rect at 2pt inset, corner radius `ChessClockRadius.outer - 2 = 16pt`. Inner rect at 10pt inset, corner radius `ChessClockRadius.outer - 10 = 8pt`. Result: 8pt band matching concentric radius rule.

- **Noise clipping:** The noise layer fills the full 300×300 bounds. A `CAShapeLayer` mask (ring path, even-odd) clips the visible noise to the ring band only.

**What was removed (Sprint 4N):** `CAGradientLayer`, 17-color gradient arrays, `baseLocations`/`driftedLocations`, `CABasicAnimation` color drift. Prior to that (Sprint 4F): gradient rotation, glowing tip, breathing pulse, spring physics. **What was removed (Sprint 4P):** `CGImage` readback pipeline (`textureToImage`, `getBytes`, `CGContext`), synchronous `waitUntilCompleted()`, per-frame texture allocation.

**Performance target (Sprint 4P):** <0.1% CPU sustained when open, ~0% when closed. Metal compute runs on GPU (~0.05ms/frame). IOSurface zero-copy — no CPU readback. Async GPU completion via `addCompletedHandler` — main thread never blocked. Timer pauses when popover is not visible. App-side: ~0.01ms/frame for async dispatch + ~0.01ms once per second for wedge path update.

---

### Face 2: Glance (Hover — macOS only)

Triggered by mouse hover over the app content area.

```
╭──────────── ring remains visible ────────────╮
│                                              │
│    ╭──────────────────────────────────╮      │
│    │ ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ │      │
│    │ ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ │      │
│    │ ░░░░░  ╭────────────────╮ ░░░░░░ │      │
│    │ ░░░░░  │    2:47 PM     │ ░░░░░░ │      │
│    │ ░░░░░  │    Mate in 2   │ ░░░░░░ │      │
│    │ ░░░░░  ╰────────────────╯ ░░░░░░ │      │
│    │ ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ │      │
│    ╰──────────────────────────────────╯      │
│                                              │
╰──────────────────────────────────────────────╯
```

- Board: Gaussian blur (radius 8pt)
- Ring: Remains fully visible and ticking (the clock doesn't stop)
- Glass pill: Centered on the board. `.ultraThinMaterial` background, 8pt corner radius, 16pt horizontal padding, 12pt vertical padding. Layered shadows (drop shadow: black 25%, radius 12, y-offset 4; tight shadow: black 10%, radius 2, y-offset 1) lift the pill off the background. A 0.5pt white inner stroke at 25% opacity simulates a glass edge highlight.
  - Line 1: **Formatted time** — "2:47 PM" (SF Pro Display, 18pt, Semibold, `.primary`)
  - Line 2: **Chess context** — "Mate in 2" (SF Pro Text, 12pt, Regular, `.secondary`)
- This is the **only place** in the entire app where the digital time is displayed.
- Fade in: 0.15s ease. Fade out: 0.1s ease.

---

### Face 3: Detail (Click)

Triggered by clicking the board in Clock or Glance face.

```
╭──────────────────────────────────────────────╮
│            (top gap ~12pt)                    │
│  ←    ╭──────────────────────╮          ⚙    │  Icons flank board top
│       │                      │               │  Board: 164×164
│       │    (board, scaled)   │               │  centered
│       │                      │               │
│       ╰──────────────────────╯               │
│              ↻ Review                        │  CTA floating pill
│  ○ M. Sebag                       2454       │  White indicator + name + ELO
│  ● V. Kramnik                     2753       │  Black indicator + name + ELO
│         Titled Tue · Jul 2024                │  Event, centered
│                                              │
╰──────────────────────────────────────────────╯
```

**Flanking icons (no separate header row):**
- The back chevron and gear icon sit in the board row, flanking the board and aligned with its top edge. Layout is an `HStack(alignment: .top)`: icon — spacer — board — spacer — icon.
- Left: Back chevron (SF Symbol `chevron.left`, 13pt, Medium weight, `.secondary`). Tap returns to Clock face. 28×28 tap target.
- Right: Gear icon (SF Symbol `gearshape`, 13pt, Medium weight, `.secondary`). Placeholder for future settings. Inactive in v1.0. 28×28 tap target.
- Layout math: 300pt frame, 8pt outer padding each side = 284pt internal. Icons 28pt each, board 164pt, spacers = (284 - 28 - 164 - 28) / 2 = 32pt each side.

**Board (164×164):**
- Centered horizontally within the icon-flanked row, ~12pt top gap from content edge
- Still interactive — tap enters Puzzle face
- Rounded corners (8pt radius — uses `radius.board`) with 0.5pt dark bevel border (`Color.black.opacity(0.12)`) for ring-board definition
- Square size: 164/8 = 20.5pt (readable for display, not for interaction)

**CTA floating pill (below board):**
- Capsule shape (fully rounded), `.ultraThinMaterial` background. 14pt horizontal padding, 7pt vertical padding.
- Light shadow: black 15%, radius 6, y-offset 2.
- 8pt spacing between board bottom and pill top.
- Content depends on puzzle state:
  - **Not yet played:** `play.fill` icon (10pt) + "Play" — `accent.gold` foreground.
  - **Solved:** `checkmark` icon (10pt) + "Solved" — system green foreground.
  - **Failed:** `arrow.counterclockwise` icon (10pt) + "Review" — `.secondary` foreground.

**Game metadata (below CTA pill):**
- 8pt spacing between CTA pill and first player row
- Layout: 16pt horizontal padding from content edges
- Each player row is an `HStack`: indicator circle (8pt diameter) + 6pt gap + player name (leading, SF Pro Text, 13pt, Regular, `.primary`) + Spacer + ELO (trailing, SF Pro Text, 13pt, Regular, `.secondary`)
- White player indicator: **glassy bead** — white fill with a top-lit `LinearGradient` overlay (bright top → clear center → subtle shadow at bottom), 0.5pt gray stroke, micro drop shadow
- Black player indicator: **glassy bead** — dark fill (`Color(white: 0.15)`) with a specular `LinearGradient` overlay (white highlight at top → clear → dark at bottom), micro drop shadow
- 4pt vertical spacing between player rows
- Event line: centered, SF Pro Text, 11pt, Regular, `.secondary`
- Player names are inverted from PGN format: "Kramnik,Vladimir" → "Vladimir Kramnik"
- If only initial available: "Kramnik,V" → "V. Kramnik"
- ELO shown trailing-aligned on the same row. If ELO is "?", omit the ELO entirely.
- Event names cleaned up: "Titled Tue 1st Aug Late" → "Titled Tuesday, Aug 2023"
- **Removed:** Round number, AM/PM text, "White:"/"Black:" labels, separate 28pt header row

**Ring:** Hidden (0% opacity). Fully invisible in the Detail face — the board and metadata own the visual space entirely.

---

### Face 4: Puzzle (Interactive)

Triggered by tapping the board in Detail face (when puzzle not yet attempted) or tapping CTA.

```
╭──────────────────────────────────────────────╮
│  ←  Kasparov vs Kramnik                      │  Translucent header
│      Mate in 3  ● ● ○                        │  overlays top of board
│  ╭──────────────────────────────────────╮    │
│  │                                      │    │
│  │                                      │    │  Board: 280×280
│  │         (interactive board)          │    │  fills the space
│  │                                      │    │
│  │                                      │    │
│  │                                      │    │
│  ╰──────────────────────────────────────╯    │
│                                              │
╰──────────────────────────────────────────────╯
```

**Header (auto-hide pills — Sprint 4.5):**

Three separate pill-shaped elements in an HStack at the top of the board. Each pill has `.ultraThinMaterial` background with `ChessClockRadius.pill` (8pt) corner radius, positioned 8pt from board edges and 8pt from board top:

- **Back pill** (left): `chevron.left` SF Symbol, 12pt, white 85%. Tap → return to Detail face. h-padding: 10pt, v-padding: 6pt.
- **Info pill** (center): "{LastName} vs {LastName} · Mate in {N}", `ChessClockType.caption` (11pt), white 85%. h-padding: 10pt, v-padding: 6pt. No tap action.
- **Tries pill** (right): HStack of 3 circles (8pt diameter, 4pt spacing) — gold fill (current try) / red fill (failed try) / white stroke 40% (remaining). h-padding: 8pt, v-padding: 6pt.

**Auto-hide behavior:**
- On puzzle appear: pills visible immediately. Auto-hide after **2.5s** (fade + slide up, `easeOut` 0.2s). `headerVisible` state → `false`.
- When hidden: persistent **pip** — `chevron.down` SF Symbol (12pt, white 60%), `.ultraThinMaterial.opacity(0.7)` background, 4pt corner radius, 24×20pt. Positioned top-center of board, 6pt from top edge.
- Hover over pip → pills spring back into view (`.spring(response: 0.28, dampingFraction: 0.78)` + `.move(edge: .top).combined(with: .opacity)`). Auto-hide again after 2.5s.
- On wrong move → pills reappear for **1.8s** (same spring animation, different timer).
- Pip must not intercept board drag/click events outside its own bounds.

Player names: last names only ("Kasparov vs Kramnik"). Extract last name from "Kasparov,G" → "Kasparov".

**Board (280×280):**
- Interactive when it's the user's turn: `InteractiveBoardView`
- Static during opponent auto-play: `BoardView`
- Rounded corners (4pt)
- No instruction text below. No "Drag or click a piece."

**Ring:** Faded to 0% opacity. Gone. You're in chess mode now.

**Piece interaction:**
- Hover over own piece: piece brightens subtly (opacity 1.0 → the piece "lifts" with a subtle scale to 1.03)
- Selection (click): piece scales to 1.05, subtle shadow appears beneath. Selected square gets `accent.gold` at **50%** overlay (Sprint 4.5: 30%→50%).
- Legal destinations: small gold dots (not black) at **55%** opacity, centered on empty destination squares, **38%** of square diameter (Sprint 4.5: 28% opacity, 32% size). For capture destinations: gold ring (not filled dot) at **55%** opacity.
- Drag: piece follows cursor at full square size. Minimum 6pt to initiate.
- Drop on legal square: piece slides to destination (0.2s spring).
- Drop on illegal square: piece snaps back (0.15s spring).

**Feedback (during play — NO text overlays):**

| Event | Visual Response | Duration |
|-------|----------------|----------|
| Wrong move | Piece snaps back to origin. Destination square pulses red at 40% opacity. **Board-edge red stroke flash** (`feedbackError` at 75% opacity, 3pt `strokeBorder`, 0.5s fade-out). **Header pills reappear for 1.8s.** | Snap: 0.15s. Dest pulse: 0.3s. Border flash: 0.5s. |
| Correct move | Piece slides to destination. From/to squares get `move.highlight` overlay. | Slide: 0.2s. Highlight persists. |
| Opponent auto-play | 0.4s pause. Opponent piece slides to destination. From/to squares highlighted. | Slide: 0.25s. |

**No "Opponent is moving..." text. No "Opponent: G3F3" badge. The piece moving IS the communication.**

**Puzzle result overlay — full-board frosted glass (Sprint 4.5):**

Full 280×280 overlay covering the board (board visible through material blur):

```
╭──────────────────────────────────────────╮
│  ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░  │  ultraThinMaterial + 10% green/red tint
│  ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░  │  board visible through blur
│  ░░░░░░                                  │
│  ░░░░░░         Solved                   │  28pt, semibold, white
│  ░░░░░░       First try                  │  13pt, white 60% (success only)
│  ░░░░░░                                  │
│  ░░░░░░   ╭──────────╮     Done          │  Review: gold capsule pill
│  ░░░░░░   │ Review → │                   │  Done: white 50% plain text
│  ░░░░░░   ╰──────────╯                   │
╰──────────────────────────────────────────╯
```

- Background: ZStack of `.ultraThinMaterial` + tint color at 10% opacity (`feedbackSuccess.opacity(0.10)` for solved, `feedbackError.opacity(0.10)` for failed). Clipped to `ChessClockRadius.puzzleBoard` (4pt).
- **No icon** (no SF Symbol checkmark or xmark).
- Title: "Solved" or "Not solved". Font: 28pt semibold, `.white`.
- Subtitle (success only): try phrase ("First try" / "Second try" / "Third try"). Font: 13pt regular, `.white.opacity(0.60)`.
- "Review →" button: `.ultraThinMaterial` capsule background, `accent.gold` foreground, 13pt semibold. h-padding: 12pt, v-padding: 6pt. Tap → Replay face. Appears after **0.2s** delay (`.opacity` transition via `DispatchQueue.main.asyncAfter`).
- "Done" button: plain text, `.white.opacity(0.50)`, 13pt regular. Tap → return to Detail face. Immediate.
- Overlay transition: `.opacity` over 0.2s.
- **Removed:** SF Symbol icons, `.regularMaterial` card, scrim, `showReviewButton` 0.5s delay.

**Try count phrasing:**
- 1 try: "First try"
- 2 tries: "Second try"
- 3 tries: "Third try"

---

### Face 5: Replay (Review)

Triggered by "Review" button in puzzle result card, or from Detail face when puzzle already completed.

```
╭──────────────────────────────────────────────╮
│  ←  Kasparov vs Kramnik                      │  Translucent header
│          [ Puzzle ]                          │  Zone pill (color-coded)
│  ╭──────────────────────────────────────╮    │
│  │                                      │    │
│  │    (board with highlighted           │    │  Board: 280×280
│  │     from/to squares)                 │    │
│  │                                      │    │
│  │                                      │    │
│  ╰──────────────────────────────────────╯    │
│    ⏮  ◂  ⦿  ▸  ⏭     Nxe4    42 of 91      │  Nav pill
╰──────────────────────────────────────────────╯
```

**Header overlay (top ~36pt of board):**
- Same structure as Puzzle header but without tries indicator
- Line 1: Back chevron + "Kasparov vs Kramnik"
- Line 2: Zone pill (centered)

**Zone pill:**
- Capsule shape (full corner radius), centered horizontally
- 8pt horizontal padding, 3pt vertical padding
- SF Pro Text, 10pt, Semibold, white foreground
- Background color by zone:
  - **"Opening"**: `systemGray` (was "Game context")
  - **"Puzzle"**: `accent.gold` (was "Puzzle start")
  - **"Solution"**: `feedback.success` (system green)
  - **"Checkmate"**: darker green (`RGB(0.10, 0.65, 0.10)`)

**Board (280×280):**
- **Highlighted squares replace arrows.** The from-square and to-square of the current move get a `move.highlight` overlay (#F6F668 at 50% opacity blended with the square's base color).
- **No MoveArrowView.** Delete it.
- Board is display-only (not interactive).
- Rounded corners (4pt).

**Nav overlay (bottom ~32pt of board):**
- Background: `#000000` at 55% opacity, bottom corners match board radius
- Layout: Navigation buttons left, move info right
- Navigation buttons: 5 controls, SF Symbols, 14pt, white foreground, 12pt spacing
  - `backward.end.fill` — jump to game start
  - `chevron.left` — step back one move
  - `circle.fill` (small, 8pt) — jump to puzzle start position
  - `chevron.right` — step forward one move
  - `forward.end.fill` — jump to checkmate
- Move info (right side):
  - SAN notation: "Nxe4" (SF Mono, 11pt, Medium, white at 85%)
  - Position counter: "42 of 91" (SF Pro Text, 10pt, Regular, white at 60%)
- All buttons: `.buttonStyle(.plain)`, `.focusable(false)` — **no blue focus ring**
- **Keyboard navigation works immediately** on view appear — no click required. Arrow keys step forward/back.

**SAN notation generation:**
- Convert UCI (e.g., "h3h4") to standard algebraic notation (e.g., "Kh4", "Nxe4", "O-O", "Qf7#")
- Derive piece type from the from-square in the current position
- Detect captures by checking if the to-square is occupied
- Handle castling (e1g1 → "O-O", e1c1 → "O-O-O")
- Handle en passant
- Add "+" for check, "#" for checkmate
- Handle disambiguation when two pieces of same type can reach the same square
- This is a display-layer function using `BoardPosition` and `ChessRules` — no pipeline change needed

**Ring:** Hidden (0% opacity).

---

### Floating Window

The right-click menu opens the app as a floating panel.

**Current problems:** Title bar with traffic lights, "Chess Clock" text, green button causes a layout shift.

**Solution:** Borderless `NSPanel`.

```swift
class BorderlessPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

let panel = BorderlessPanel(
    contentRect: NSRect(x: 0, y: 0, width: 300, height: 300),
    styleMask: [.borderless, .nonactivatingPanel],
    backing: .buffered,
    defer: false
)
panel.level = .floating
panel.isMovableByWindowBackground = true
panel.backgroundColor = .clear
panel.isOpaque = false
panel.hasShadow = true
panel.hidesOnDeactivate = false
panel.collectionBehavior.insert(.canJoinAllSpaces)
```

- **No title bar.** No traffic lights. No title text.
- **Draggable** by background (`isMovableByWindowBackground`).
- **Close:** Custom × button in top-left corner, visible only on hover (SF Symbol `xmark`, 10pt, `.secondary`, with a small circular `.ultraThinMaterial` background).
- **Size:** 300×300 (same as popover content).
- **Corner radius:** Applied via `.clipShape(RoundedRectangle(cornerRadius: 18))` on the SwiftUI root view (uses `radius.outer`).
- **Shadow:** System shadow (`hasShadow = true`).
- All five faces work identically in the floating window.

---

### Promotion Picker

When a pawn reaches the promotion rank during puzzle play.

**Current:** Centered overlay with title "Choose promotion" and 4 buttons.

**New design:** Column picker at the promotion file position (like chess.com).

```
    │  │  │  │ ♛ │  │  │  │
    │  │  │  │ ♜ │  │  │  │   ← 4 pieces in a vertical column
    │  │  │  │ ♝ │  │  │  │      at the promotion file
    │  │  │  │ ♞ │  │  │  │
```

- Appears at the file where the pawn promotes
- Drops down from the promotion rank (or up, depending on board orientation)
- 4 pieces: Queen, Rook, Bishop, Knight — each rendered at square size (35×35)
- Background: `.ultraThinMaterial` per piece cell
- 1pt gap between cells
- **No title text.** Four chess pieces IS the instruction.
- Tap a piece → promotion applied, picker disappears
- Scrim: `#000000` at 30% opacity over the rest of the board

---

### Onboarding

**Deferred to Sprint 6.** The current onboarding overlay will receive a visual refresh to match the new design language, but its content structure (explaining the clock concept) is adequate for v1.0. Updated to use the new typography and material system.

Key changes:
- "Got it" → "Continue"
- Use `.regularMaterial` instead of hardcoded black overlay
- Match new typography scale
- Rounded corners: 12pt (card radius)

---

## Design Tokens

### Colors

```swift
enum ChessClockColor {
    // Board
    static let boardLight    = Color(red: 240/255, green: 217/255, blue: 181/255) // #F0D9B5 — Lichess
    static let boardDark     = Color(red: 181/255, green: 136/255, blue: 99/255)  // #B58863 — Lichess

    // Ring
    static let accentGold      = Color(red: 191/255, green: 155/255, blue: 48/255)  // #BF9B30 — jewelry gold
    static let accentGoldLight = Color(red: 212/255, green: 185/255, blue: 78/255)  // #D4B94E — lighter warm gold (gradient highlight)
    static let accentGoldDeep  = Color(red: 138/255, green: 111/255, blue: 31/255)  // #8A6F1F — deeper gold (gradient shadow)
    static let accentGoldDim   = accentGold.opacity(0.30)                            // Ring in non-clock faces
    static let ringTrack       = Color.gray.opacity(0.15)                            // Unfilled ring portion
    static let ringGradient    = LinearGradient(colors: [accentGoldLight, accentGoldDeep], startPoint: .topLeading, endPoint: .bottomTrailing)

    // Move highlighting
    static let moveHighlight = Color(red: 246/255, green: 246/255, blue: 104/255).opacity(0.50) // #F6F668 at 50%

    // Selection & interaction (Sprint 4.5: opacities increased for visibility)
    static let squareSelected   = accentGold.opacity(0.50)                         // Selected piece square (was 0.30)
    static let legalDot         = accentGold.opacity(0.55)                         // Legal move dot (was 0.28)
    static let legalCapture     = accentGold.opacity(0.55)                         // Legal capture ring (was 0.28)
    static let wrongFlash       = Color.red.opacity(0.40)                          // Wrong move pulse

    // Semantic
    static let feedbackSuccess  = Color.green                                      // System green
    static let feedbackError    = Color.red                                        // System red

    // Overlays
    static let overlayScrim     = Color.black.opacity(0.45)                        // Behind result cards
    static let headerBg         = Color.black.opacity(0.55)                        // Translucent headers
    static let ctaBg            = Color.black.opacity(0.60)                        // CTA bar on board
}
```

### Typography

```swift
enum ChessClockType {
    static let display   = Font.system(size: 18, weight: .semibold, design: .default)  // Hover time
    static let title     = Font.system(size: 17, weight: .semibold, design: .default)  // Result titles
    static let body      = Font.system(size: 13, weight: .regular, design: .default)   // Player names, events
    static let caption   = Font.system(size: 11, weight: .regular, design: .default)   // Headers, zone labels
    static let micro     = Font.system(size: 10, weight: .medium, design: .default)    // Tiny labels
    static let mono      = Font.system(size: 11, weight: .medium, design: .monospaced) // Move notation (SAN)
}
```

### Spacing

8pt grid system (watchOS-compatible):

| Token | Value | Use |
|-------|-------|-----|
| `space.xs` | 2pt | Within compound elements |
| `space.sm` | 4pt | Related items, bezel gap, line spacing |
| `space.md` | 8pt | Between sections |
| `space.lg` | 12pt | Medium separation, button spacing |
| `space.xl` | 16pt | Primary padding, pill internal padding |

### Concentric Corner Radius Rule

Every nested rounded rectangle **must** follow the concentric formula:

```
innerRadius = max(outerRadius − insetDistance, 0)
```

This ensures the gap between nested shapes is uniform at the corners — the same visual principle Apple applies from iPhone bezels to Watch faces. Violating this rule produces visible "pinching" (inner radius too large) or "ballooning" (inner radius too small) at corners.

**Derivation for the Clock face layer model:**

```
Content outer edge  (0pt inset):   radius = 18pt   ← anchor (radius.outer)
Ring path center    (6pt inset):   radius = 18 − 6  = 12pt  (radius.ring)
Ring inner edge    (10pt inset):   radius = 18 − 10 =  8pt  (derived, matches radius.board)
Board edge         (10pt inset):   radius = 18 − 10 =  8pt  (radius.board — flush with ring inner edge)
```

**Rules for all future sprints:**

1. When adding any new nested shape inside the content area, compute its radius as `radius.outer − insetFromContentEdge`.
2. If the computed value is ≤ 0, use 0 (sharp corners).
3. Overlay elements (result cards, pills, zone badges) are **not** part of the concentric stack — they float on top and use their own independent radius tokens (`radius.card`, `radius.pill`, `radius.badge`).
4. The Detail face board (164×164 at 68pt inset) is a standalone element, not concentrically nested in the ring. It uses `radius.board` (4pt) as a visual minimum.
5. **Never hardcode a corner radius literal.** Always reference a `ChessClockRadius` token or compute from `radius.outer − inset`.

### Corner Radii

Tokens marked ★ are derived from the concentric rule above — do not set them independently.

| Token | Value | Derivation | Use |
|-------|-------|-----------|-----|
| `radius.outer` | 18pt | Anchor value | Content area clip, floating window |
| `radius.ring` | 12pt | ★ `outer − ringInset` (18 − 6) | Ring path center corner arcs |
| `radius.board` | 8pt | ★ `outer − boardInset` (18 − 10) | Board clip shape (all faces) |
| `radius.card` | 12pt | Independent | Result cards, onboarding card |
| `radius.pill` | 8pt | Independent | Hover pill, zone pills |
| `radius.badge` | 4pt | Independent | Small badges, promotion cells |

### Dimensions

| Token | Value | Derivation |
|-------|-------|-----------|
| `app.size` | 300pt | Fixed. Never changes. |
| `ring.stroke` | 8pt | Weight of the minute ring |
| `ring.inset` | 6pt | Ring path center position from content edge |
| `bezel.gap` | 0pt | Eliminated — ring inner edge flush with board |
| `board.inset` | 10pt | `ring.inset + ring.stroke/2` = 6 + 4 |
| `board.size` | 280pt | `app.size - 2 × board.inset` |
| `square.size` | 35pt | `board.size / 8` |
| `board.detail` | 164pt | Board in Detail face (20.5pt squares) |
| `header.height` | 28pt | Top header bar (Detail face) |
| `overlay.header` | 36pt | Translucent header on board (Puzzle/Replay) |
| `overlay.nav` | 32pt | Navigation pill at bottom (Replay) |
| `tick.length` | 12pt | Cardinal tick mark length (1.5× ring width — spans ring + 4pt into board edge, rendered on top of fill as gradient bar) |
| `tick.width` | 2.5pt | Cardinal tick mark stroke (single-layer gradient bar, no outline) |
| `ring.outerEdge` | 2pt | Ring outer edge distance from content edge (`ringInset − ringStroke/2`) |
| `ring.innerEdge` | 10pt | Ring inner edge distance from content edge (`ringInset + ringStroke/2`) |
| `shimmer.minOpacity` | — | **Removed** (Sprint 3.95) — shimmer replaced by diffused energy pulses, then pulses removed (Sprint 4R) in favor of CALayer gradient rotation. |

### Animations

| Token | Spec | Use |
|-------|------|-----|
| `anim.micro` | 0.12s ease | Button press, hover highlight |
| `anim.fast` | 0.15s ease | Hover pill out, piece snap-back |
| `anim.standard` | 0.25s spring(response: 0.3, dampingFraction: 0.8) | Overlays, piece slides, state transitions |
| `anim.smooth` | 0.4s easeInOut | Board resize, face changes |
| `anim.ring` | — | **Removed** (Sprint 4R) — ring sweep now uses `CABasicAnimation` on the progress wedge `CGPath` (0.5s ease-in-out). Gradient rotation uses `CABasicAnimation("transform.rotation.z")` with ~120s infinite cycle. Both run in WindowServer render server. |
| `anim.shimmer` | — | **Removed** (Sprint 3.95) — shimmer replaced by pulses, then pulses removed (Sprint 4R) in favor of CALayer gradient rotation. |
| `anim.dramatic` | 0.6s easeInOut | Hour-change piece slide |
| `anim.wrongPulse` | 0.3s fade-out | Red flash on wrong move |
| `anim.opponentDelay` | 0.4s | Pause before opponent auto-play |
| `anim.reviewButtonDelay` | 0.5s | Delay before "Review" appears in result card |

---

## Copy Guide

Every text string in the app. **No string should exist in code that isn't listed here.**

### Clock Face
*(No text.)*

### Glance Face
| Element | Text | Example |
|---------|------|---------|
| Time | `h:mm a` format (system locale) | "2:47 PM", "10:03 AM" |
| Context | "Mate in {N}" | "Mate in 2" |

### Detail Face
| Element | Text | Example |
|---------|------|---------|
| Back | *(SF Symbol `chevron.left` only)* | |
| Settings | *(SF Symbol `gearshape` only)* | |
| CTA (unplayed) | "▶ Play" | Floating pill, gold foreground |
| CTA (solved) | "✓ Solved" | Floating pill, green foreground |
| CTA (failed) | "↺ Review" | Floating pill, secondary foreground |
| Player (white) | "○ {FirstName} {LastName}    {ELO}" | "○ M. Sebag    2454" (indicator + name left, ELO right) |
| Player (black) | "● {FirstName} {LastName}    {ELO}" | "● V. Kramnik    2753" (indicator + name left, ELO right) |
| Event | "{EventName} · {MonthAbbr} {Year}" | "World Championship · Nov 2000" |

**Player name formatting rules:**
- Input "Kasparov,Garry" → Output "Garry Kasparov"
- Input "Kramnik,V" → Output "V. Kramnik" (add period after single initial)
- Input "Kramnik,Vladimir" → Output "Vladimir Kramnik"
- If ELO is "?" → omit " · {ELO}" entirely

### Puzzle Face
| Element | Text | Example |
|---------|------|---------|
| Back | *(SF Symbol `chevron.left` only)* | |
| Players | "{LastName} vs {LastName}" | "Kasparov vs Kramnik" |
| Context | "Mate in {N}" | "Mate in 3" |
| Wrong move | *(no text — visual flash only)* | |
| Opponent move | *(no text — piece animation only)* | |
| Solved title | "Solved" | |
| Solved detail | "First try" / "Second try" / "Third try" | |
| Failed title | "Not solved" | |
| Review button | "Review" | |
| Done button | "Done" | |

### Replay Face
| Element | Text | Example |
|---------|------|---------|
| Back | *(SF Symbol `chevron.left` only)* | |
| Players | "{LastName} vs {LastName}" | "Kasparov vs Kramnik" |
| Zone: before puzzle | "Opening" | |
| Zone: puzzle start | "Puzzle" | |
| Zone: after puzzle | "Solution" | |
| Zone: checkmate | "Checkmate" | |
| Move notation | SAN format | "Nxe4", "O-O", "Qf7#" |
| Position counter | "{N} of {Total}" | "42 of 91" |

### Onboarding
| Element | Text |
|---------|------|
| Title | "Chess Clock" |
| Line 1 | "The board shows a real game, moments before checkmate." |
| Line 2 | "The gold ring counts the minutes." |
| Line 3 | "A new puzzle every hour." |
| Line 4 | "Tap the board to learn more." |
| Dismiss | "Continue" |

---

## Interaction Specification

### Face Transitions

| From | To | Trigger | Animation |
|------|-----|---------|-----------|
| Clock → Glance | Mouse enter | Board blur: 0.2s ease. Pill fade-in: 0.15s (starts after blur begins). |
| Glance → Clock | Mouse exit | Pill fade-out: 0.1s. Board un-blur: 0.15s. |
| Clock → Detail | Click board | Board scales 280→164: 0.3s spring. Board slides up. Ring dims: 0.25s. Metadata fades in from below: 0.2s (staggered). |
| Detail → Clock | Tap back | Reverse of above. Metadata slides down, board scales 164→280, ring brightens. |
| Detail → Puzzle | Tap CTA / board | Board scales 164→280: 0.3s spring. Metadata slides out: 0.2s. Ring fades to 0%: 0.2s. Header overlay fades in: 0.2s. |
| Puzzle → result card | Puzzle completes | Scrim fades in: 0.2s. Card scales from 0.9→1.0 with fade: 0.25s spring. |
| Result → Replay | Tap "Review" | Card and scrim fade out: 0.2s. Header content cross-fades: 0.15s. Nav overlay fades in: 0.2s. |
| Result → Clock | Tap "Done" | Card and scrim fade out. Board scales down then up (brief pulse). Ring fades back in. Return to Clock face. |
| Replay → Detail | Tap back | Nav overlay fades out. Header fades out. Board scales 280→164. Ring dims to 30%. Metadata fades in. |
| Any → Clock | Popover reopens | Instant reset. No animation. (WindowObserver resets ViewMode.) |

### Hour-Change Animation

When the clock transitions from one hour to the next (e.g., 2:59 → 3:00):

1. Ring sweeps to full (0.3s), then resets to 0 with a quick counter-clockwise wipe (0.2s)
2. Board position cross-fades: old position fades out (0.3s) while new position fades in (0.3s), overlapping by 0.15s
3. Total duration: ~0.6s

*Note: Piece-by-piece slide animation (where individual pieces move from old to new positions) is a stretch goal. Cross-fade is the minimum viable implementation.*

### Keyboard Shortcuts

| Key | Context | Action |
|-----|---------|--------|
| `←` | Replay face | Step back one move |
| `→` | Replay face | Step forward one move |
| `Escape` | Any non-Clock face | Return to previous face |
| `Option+Space` | Global (existing) | Toggle popover open/close |

---

## Piece Set

### Decision

**Ship v1.0 with the Merida gradient piece set from Lichess.**

- Source: `github.com/lichess-org/lila/tree/master/public/piece/merida`
- License: GPLv2+ (same as current cburnett — no licensing change)
- Format: SVG → add directly to Xcode asset catalog (Xcode 15+ supports SVG natively)
- Quality: 7/10 — the most elegant traditional Staunton silhouettes available in open-source, with a subtle linear gradient overlay that adds dimensionality

### Why Merida Over cburnett

| Aspect | cburnett | Merida (gradient) |
|--------|----------|-------------------|
| Shading | Zero — flat white fill, black outline | Linear gradient overlay (white → transparent) |
| Proportions | Functional | Refined Staunton (elegant knight, taller king cross) |
| Visual weight | "Rubber stamp" | "Polished piece under directional light" |
| Recognition | Universal | Universal (Merida is the most widely used chess font) |

### Asset Preparation

1. Download all 12 SVGs from the Lichess Merida directory (wK, wQ, wR, wB, wN, wP, bK, bQ, bR, bB, bN, bP)
2. Add to `ChessClock/Assets.xcassets` with the same names as current pieces
3. In asset catalog: set "Preserve Vector Data" = YES, "Render As" = Original
4. Delete old PNG assets
5. No code changes needed — `Image("wK")` continues to work

### Future Path

The piece rendering system is piece-set-agnostic by design — pieces are referenced by name ("wK", "bQ", etc.) and rendered as `Image`. Swapping to a different set requires only replacing the 12 asset files. Commission custom pieces when the app warrants it.

---

## Technical Requirements

### New Components to Build

| Component | Purpose | Sprint |
|-----------|---------|--------|
| `DesignTokens.swift` | Central file defining all color, type, spacing, radius, animation constants | 1 |
| `MinuteBezelView.swift` / `GoldRingLayerView.swift` | Ring component: originally SwiftUI shapes (Sprint 1), rewritten to CALayer architecture (Sprint 4R) for <0.5% CPU | 1, 4R |
| `PlayerNameFormatter.swift` | Invert PGN names: "Kramnik,V" → "V. Kramnik" | 1 |
| `SANFormatter.swift` | Convert UCI to SAN using board position context | 5 |
| `HighlightSquaresOverlay.swift` | Yellow overlay on from/to squares (replaces MoveArrowView) | 5 |
| `BorderlessPanel.swift` | NSPanel subclass with `canBecomeKey` override | 6 |
| `GlassPillView.swift` | Reusable `.ultraThinMaterial` rounded rect container | 2 |

### Components to Delete

| Component | Reason |
|-----------|--------|
| `MoveArrowView.swift` | Replaced by highlighted squares |
| `ContentView.swift` | Legacy test view, unused |

### Components to Modify (Heavy)

| Component | Changes |
|-----------|---------|
| `ClockView.swift` | Fixed 300×300 frame. New layer model. All five face layouts. |
| `MinuteSquareRingView.swift` | Replace entirely with `MinuteBezelView` (or rename and rewrite) |
| `GuessMoveView.swift` | Fixed square, overlay header, remove all unnecessary text, new feedback |
| `GameReplayView.swift` | Fixed square, highlight squares, SAN notation, overlay nav, no focus ring |
| `InfoPanelView.swift` | New layout, player name formatting, metadata hierarchy, gear icon |
| `InteractiveBoardView.swift` | Gold selection/legal-move colors, hover brightness, refined feedback |
| `BoardView.swift` | Rounded corners, accept `highlightedSquares` parameter |
| `FloatingWindowManager.swift` | Borderless panel, custom close button, fixed 300×300 |
| `OnboardingOverlayView.swift` | Updated text, material background, typography |
| `PromotionPickerView.swift` | Column layout at promotion file, no title text |

---

## Performance Rules

These rules prevent regressions. A 300×300 menu bar widget must be nearly invisible in Activity Monitor.

1. **Use Core Animation / Metal for continuous animation, not SwiftUI.** SwiftUI's `AngularGradient`, `TimelineView`, and shape-based animation all run on the app's CPU (10-15% for the ring). For continuously animated elements, use `CALayer` via `NSViewRepresentable`. For procedural textures (noise, gradients), use Metal compute shaders with IOSurface-backed textures rendered to `CALayer.contents` at a controlled frame rate. The minute ring is the canonical example: `GoldNoiseShader.metal` generates simplex noise on the GPU, `GoldNoiseRenderer` renders at 150×150 (half-res) at 10 FPS into double-buffered IOSurfaces with async GPU completion — the `CALayer` displays the IOSurface directly (zero-copy, no CPU readback), achieving flowing liquid gold at <0.1% CPU. Reserve SwiftUI `.animation(.linear, value:)` for discrete state transitions (progress advance, face changes) that happen infrequently.

2. **`.drawingGroup()` before `.blur()`.** On views with >10 subviews (e.g. BoardView's 64 squares), rasterize into one Metal texture first. Otherwise the blur processes each subview independently.

3. **Conditional rendering over opacity for expensive views.** Views with `.ultraThinMaterial`, `.blur()`, or `NSViewRepresentable` CALayer hierarchies must be removed from the tree when invisible — `if condition { View }` not `View.opacity(0)`. SwiftUI evaluates `body` regardless of opacity, and CALayer animations consume GPU even at zero opacity.

4. **All timers must pause when no UI is visible.** `ClockService` uses reference-counted `resume()`/`pause()` (timer starts lazily on first `resume()`, not in `init()`). `GoldRingLayerView` uses an `isActive` parameter driven by popover visibility via `WindowObserver` — the noise timer is invalidated when `isActive` becomes `false` and recreated when `true`. Zero idle wake-ups when popover is closed.

5. **Hour-keyed caching for hourly-stable computations.** `GameScheduler.resolve()` and similar operations that only change hourly must cache results keyed on `hour24`.

6. **Prefer simple scrims over `.regularMaterial` for modal overlays.** `.regularMaterial` and `.ultraThinMaterial` are vibrancy effects — they composite the blurred background in real time, costing 8-12% GPU when layered over complex views like the 64-square board. For modal overlays where the user cannot interact with the content behind (wrong-move flash, result cards, puzzle feedback), use `Color.black.opacity(0.65)` instead. Reserve materials only for overlays where the blurred background is part of the visual design (hover pill, onboarding).

7. **Respect reduced motion.** When `NSWorkspace.shared.accessibilityDisplayShouldReduceMotion` is true, disable all continuous animations (noise timer, any CALayer animations) — render a single static frame and stop. Progress advance can still animate but should use a simple 0.3s ease rather than spring physics.

---

## Sprint Plan

### Completed Sprints (Retrospective)

**Sprint 0 — Design Document ✓**
Locked v1.0 design spec before any code. This document.

**Sprint 1 — Foundation ✓**
- [x] `DesignTokens.swift` — all color, type, spacing, radius, animation constants
- [x] Merida gradient SVGs replacing cburnett PNGs (12 assets)
- [x] `MinuteBezelView` — rounded rect ring, gold fill, gray track, 4 cardinal tick marks
- [x] `PlayerNameFormatter` — invert PGN names, handle initials, format ELO
- [x] Locked app frame to 300×300; deleted `ContentView.swift`, `MoveArrowView.swift`

**Sprint 2 — Clock + Glance ✓**
- [x] Concentric corner radii (18→12→8pt); 8pt ring stroke
- [x] Clock face: board 280×280, gold ring fill, no text or affordances
- [x] Glance face: board blur on hover, `GlassPillView` with time + "Mate in N"

**Sprint 3 — Detail Face ✓**
- [x] `InfoPanelView`: board 164pt, board scale animation (280→164), flanking back+gear icons
- [x] CTA floating pill, player metadata with glassy indicators, event line
- [x] Ring dims to 0% opacity in Detail face

**Sprint 3.5 — Ring Polish ✓**
- [x] `second` added to `ClockState` for continuous sweep; shimmer pulse
- [x] `GlassPillView` upgrade: layered shadows + inner stroke for glass edge

**Sprint 3.75 — Ring Geometry Fix ✓**
- [x] `FilledRingTrack` (even-odd fill) + `ProgressWedge` mask replaced stroke-based ring
- [x] Board edge bevel (0.5pt dark `strokeBorder`)

**Sprint 3.9 — Visual Refinement ✓**
- [x] Glass tube overlays: inner specular (white 20%) + outer shadow (black 8%)
- [x] Tick marks: single gradient stroke (white 0.40→0.15 outer-to-inner), removed black halo
- [x] `GlassPillView`: top specular highlight, stroke opacity 0.30
- [x] Player indicators: glassy beads with top-lit gradient + micro drop shadow

**Sprint 3.95 — Ring Fix ✓**
- [x] Removed `.animation` from root ZStack (was conflicting with `TimelineView`)
- [x] Replaced pulse system with 3 diffused energy pulses; removed `ChessClockPulse` enum
- [x] Added board inner shadow (6pt stroke, 4pt blur, 22% opacity)

**Sprints 4R → 4F → 4N → 4P — Ring Performance ✓**
Evolution: SwiftUI shapes (10–15% CPU) → `CAGradientLayer` rotation (artifacts) → locations drift (chuggy) → Metal noise + IOSurface (<0.1% CPU open, ~0% closed).
- [x] `GoldRingLayerView` — `NSViewRepresentable` wrapping `CALayer` hierarchy
- [x] `GoldNoiseShader.metal` — 3D simplex noise, 2-octave FBM, 5-tone gold color ramp
- [x] `GoldNoiseRenderer` — Metal compute pipeline, 150×150 half-res, IOSurface zero-copy
- [x] 10 FPS Timer, async GPU completion (`addCompletedHandler`), `isActive` pauses on hide
- [x] Removed: `CAGradientLayer`, locations drift, `CGImage` readback, `waitUntilCompleted()`

---

### Sprint 4 — Puzzle Face ✓
**Goal:** Ship the interactive puzzle in a fixed 300×300 square.

Tasks:
- [ ] Puzzle face layout: board 280×280, translucent header overlay, ring hidden
- [ ] Header: back + short player names + "Mate in N" + tries indicator (all in 36pt overlay)
- [ ] Remove: all instruction text, "Opponent is moving...", "Opponent: G3F3", "Not that move"
- [ ] Wrong move feedback: piece snap-back + red square pulse (no text overlay)
- [ ] Correct move feedback: piece slide + from/to highlight (no text)
- [ ] Opponent auto-play: animated piece movement only (no text)
- [ ] Update InteractiveBoardView: gold selection color, gold legal-move dots
- [ ] Puzzle result cards: clean material cards with "Solved"/"Not solved", "Review"/"Done"
- [ ] Promotion picker: column layout at promotion file, no title text
- [ ] Tick mark extension: increase `tick.length` from 8pt → 12pt so ticks protrude 4pt into the board. Update `BoardView` inner shadow to also receive the tick shadow: each tick casts `black 0.30 opacity, radius 2pt` on the board surface (softer than the ring shadow). The tick gradient should fade to `white 0.20 opacity` at the board-side tip to visually taper the intrusion.
- [ ] CTA pill hover animation (Detail face): on `isHovered`, animate `scaleEffect(1.04)` + `brightness(0.08)` with `anim.micro` (0.12s ease). Use `withAnimation(.easeInOut(duration: 0.12))` driven by an `@State var isHovered`. This applies to all three pill states (Play / Solved / Review).

**Performance note (Sprint 4R audit):** The current `GuessMoveView` overlays use `.regularMaterial` on top of a live 64-square board (+8-12% GPU when visible). Consider replacing `.regularMaterial` with a simpler dark scrim (`.black.opacity(0.65)`) for the wrong-flash and result overlays — the overlay is modal, so the vibrancy effect behind it serves no purpose. Alternatively, hide the board underneath (opacity 0 or remove from tree) when the overlay is showing.

**Acceptance:** Entire puzzle flow works within 300×300. All feedback is visual. No unnecessary text.

### Sprint 4.5 — Polish & Header Redesign
**Goal:** Fix tick z-order, balance Detail face layout, improve board interaction visibility, implement auto-hide puzzle header pills, and redesign the result overlay as full-board frosted glass.

Tasks:
- [ ] S4.5-1 Tick z-order — move `GoldRingLayerView` above `boardWithRing` in `ClockView` ZStack so tick marks render on top of board surface
- [ ] S4.5-2 Detail face vertical balance — fix `InfoPanelView` layout so top and bottom margins are symmetric (~12pt each); remove bottom `Spacer()`, use `alignment: .top` on frame
- [ ] S4.5-3 Interaction color polish — update `DesignTokens`: `squareSelected` 0.30→0.50, `legalDot` 0.28→0.55, `legalCapture` 0.28→0.55
- [ ] S4.5-4 Legal dot size — increase legal move dot diameter from `sq * 0.32` to `sq * 0.38` in `InteractiveBoardView`
- [ ] S4.5-5 Puzzle header auto-hide pills — replace static `headerOverlay` with three-pill HStack (back, info, tries); auto-hides after 2.5s; persistent pip chevron on hover reveals pills
- [ ] S4.5-6 Wrong move border flash — board-edge 3pt red `strokeBorder` flash on wrong move (0.5s), plus pills reappear for 1.8s
- [ ] S4.5-7 Result overlay frosted glass — replace `successOverlay`/`failedOverlay` with full-board `.ultraThinMaterial` + 10% color tint; no icon; 28pt title; "Review →" gold capsule (0.2s delay); "Done" plain

**Acceptance:** Tick marks visible above board. Detail face has equal margins. Board interactions are higher-contrast (50%/55%). Puzzle header auto-hides with pip. Wrong move shows rim flash. Result is frosted glass, board visible through.

---

### Sprint 5 — Replay Face
**Goal:** Ship game review with highlighted squares, SAN notation, overlay navigation.

Tasks:
- [ ] Build `SANFormatter` — convert UCI to SAN using position context
- [ ] Build `HighlightSquaresOverlay` — yellow overlay on from/to squares on `BoardView`
- [ ] Replay face layout: board 280×280, header overlay, nav overlay at bottom
- [ ] Zone pills: "Opening" (gray), "Puzzle" (gold), "Solution" (green), "Checkmate" (dark green)
- [ ] Nav controls: 5 SF Symbol buttons in bottom overlay, `.buttonStyle(.plain)`, no focus ring
- [ ] SAN notation display: SF Mono, right-aligned in nav overlay
- [ ] Position counter: "42 of 91" format
- [ ] Keyboard navigation: arrow keys work immediately on view appear (no pre-click)
- [ ] Remove: MoveArrowView usage, UCI text display, blue focus ring

**Acceptance:** Game review shows highlighted squares (no arrows), SAN notation, compact nav. Keyboard works immediately, no blue square ring around replay face.

### Sprint 6 — Chrome + Polish
**Goal:** Ship the release candidate with all transitions, floating window, and edge cases.

Tasks:
- [ ] Borderless floating window: `BorderlessPanel` subclass, no title bar, custom close on hover
- [ ] Floating window: 300×300, all faces work identically
- [ ] Face transitions: all animations per the Interaction Specification
- [ ] Hour-change animation: ring reset + board cross-fade
- [ ] Onboarding refresh: new text, material background, typography
- [ ] Cross-face coherence audit: verify every transition, every state, every edge case
- [ ] Test on light mode and dark mode (materials adapt automatically)
- [ ] Accessibility: ensure VoiceOver reads meaningful content, reduced-motion respected
- [ ] *Performance audit*: verify <0.5% CPU idle (popover open, clock face), <2% during transitions, 0% when popover closed. Profile with Instruments → Time Profiler for 60 seconds in each face. Check that `GoldRingLayerView` CALayer animations survive floating window lifecycle (panel show/hide/reshow).
- [ ] Reduced motion: verify that when `NSWorkspace.shared.accessibilityDisplayShouldReduceMotion` is true, the noise timer is not started and a single static frame is rendered. Progress advance should use 0.3s ease (already implemented).

**Acceptance:** Complete, polished app. Every face, every transition, every interaction matches this spec. CPU <0.5% idle. Ready for v1.0 release.

---

## Open Questions (Resolved)

| Question | Resolution |
|----------|-----------|
| App size | **300×300.** Fits Apple Watch Ultra. More compact and Apple-like. |
| Ring weight | **8pt.** Increased from initial 6pt after Sprint 1 — thicker ring better balances the 300×300 canvas. |
| Tick marks | **4 cardinal only.** Start simple, add detail later if needed. |
| Piece set | **Merida (gradient) from Lichess.** Most elegant available. GPLv2+. |
| Board corners | **4pt radius.** Derived via concentric formula: `outer(14) − boardInset(10) = 4`. Departure from chess.com/Lichess sharp corners, justified by watch/clock context. |
| Background material | **`.regularMaterial`** for the popover. Board is a card sitting inside it. |

---

*This document is the source of truth for v1.0. When in doubt, refer here. If something is missing, add it here before implementing.*
