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
Layer 0: CONTENT     — 300×300, clipped to 14pt rounded rect (the outermost shape)
Layer 1: RING        — 8pt stroke, rounded rect path at 4pt inset
Layer 2: GAP         — 2pt breathing room (the bezel channel)
Layer 3: BOARD       — 280×280, 8×8 grid, 35pt squares
Layer 4: OVERLAYS    — Translucent pills, headers, nav controls
```

**Math:**
- Content clip: `RoundedRectangle(cornerRadius: 14)` on the root view — this is the anchor for all concentric radii
- Ring path: `RoundedRectangle` at 4pt inset from content edge, 8pt stroke → outer edge at 0pt, inner edge at 8pt
- Gap: 2pt → board starts at 10pt inset
- Board: `300 - 2×10 = 280×280`
- Square size: `280 / 8 = 35pt`
- Corner radii follow the concentric formula (see Design Tokens → Concentric Corner Radius Rule)

### State-Dependent Layout

The 300×300 canvas is constant. What changes per face:

| Face | Board Size | Ring | Overlays |
|------|-----------|------|----------|
| Clock | 280×280 | Full gold, ticking | None |
| Glance | 280×280 | Full gold, ticking | Centered glass pill |
| Detail | 196×196 | Dimmed to 30% | Header + metadata below board |
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
- Ring: Gold, filling clockwise from top-center. Unfilled track visible at 15% gray.
- Tick marks: 4 cardinal points (top-center, right-center, bottom-center, left-center). Small inward-pointing indices. Gold when the ring has passed them, gray otherwise.
- AM: White's perspective (rank 1 at bottom). PM: Board flipped (rank 8 at bottom).
- **No text. No labels. No visible affordances.** Pure ambient display.

**Ring animation:** Each minute, the ring grows by 1/60th over 0.5s with ease timing. The fill is smooth and liquid, not a static jump.

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
- Glass pill: Centered on the board. `.ultraThinMaterial` background, 8pt corner radius, 16pt horizontal padding, 12pt vertical padding.
  - Line 1: **Formatted time** — "2:47 PM" (SF Pro Display, 18pt, Semibold, `.primary`)
  - Line 2: **Chess context** — "Mate in 2" (SF Pro Text, 12pt, Regular, `.secondary`)
- This is the **only place** in the entire app where the digital time is displayed.
- Fade in: 0.15s ease. Fade out: 0.1s ease.

---

### Face 3: Detail (Click)

Triggered by clicking the board in Clock or Glance face.

```
╭──────────────────────────────────────────────╮
│  ←                                      ⚙    │  28pt header
│                                              │
│         ╭──────────────────────╮             │
│         │                      │             │  Board: 196×196
│         │    (board, scaled)   │             │  centered
│         │                      │             │
│         │ ──────────────────── │             │
│         │  ▶ Play              │             │  CTA overlay
│         ╰──────────────────────╯             │
│                                              │
│   Garry Kasparov · 2851                      │  Player 1 (White)
│   Vladimir Kramnik · 2753                    │  Player 2 (Black)
│   World Championship · 2000                  │  Event · Year
│                                              │
╰──────────────────────────────────────────────╯
```

**Header (28pt):**
- Left: Back chevron (SF Symbol `chevron.left`, 11pt, `.secondary`). Tap returns to Clock face.
- Right: Gear icon (SF Symbol `gearshape`, 11pt, `.secondary`). Placeholder for future settings. Inactive in v1.0.

**Board (196×196):**
- Centered horizontally, positioned below header with 4pt spacing
- Still interactive — tap enters Puzzle face
- Rounded corners (4pt radius — uses `radius.board`, not strict concentricity at this inset)
- Square size: 196/8 = 24.5pt (readable for display, not for interaction)

**CTA overlay (bottom edge of board):**
- Height: 28pt. Full width of board.
- Background: `#000000` at 60% opacity
- Corner radius: bottom-left and bottom-right match board radius (4pt)
- Content depends on puzzle state:
  - **Not yet played:** "▶ Play" — SF Pro Text, 12pt, Semibold. `accent.gold` foreground. Play icon (SF Symbol `play.fill`, 10pt).
  - **Solved:** "✓ Solved · Review" — system green foreground. Checkmark icon.
  - **Failed:** "✗ · Review" — system red foreground. X icon.

**Game metadata (below board):**
- 8pt spacing between board bottom and first text line
- Layout: Left-aligned, 16pt horizontal padding from content edges
- Line 1: White player — "Garry Kasparov · 2851" (SF Pro Text, 13pt, Regular, `.primary`)
- Line 2: Black player — "Vladimir Kramnik · 2753" (SF Pro Text, 13pt, Regular, `.primary`)
- Line 3: Event — "World Championship · 2000" (SF Pro Text, 11pt, Regular, `.secondary`)
- Player names are inverted from PGN format: "Kramnik,Vladimir" → "Vladimir Kramnik"
- If only initial available: "Kramnik,V" → "V. Kramnik"
- ELO shown after dot separator. If ELO is "?", omit the dot and ELO entirely.
- Event names cleaned up: "Titled Tue 1st Aug Late" → "Titled Tuesday, Aug 2023"
- **Removed:** Round number, AM/PM text, "White:"/"Black:" labels

**Ring:** Visible but dimmed to 30% opacity. Tick marks also at 30%. Still ticking (subtle reminder: "I'm still a clock").

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

**Header overlay (overlays top ~36pt of board):**
- Background: `#000000` at 55% opacity, with top corners matching board radius
- Line 1: Back chevron (left) + "Kasparov vs Kramnik" (right-aligned, SF Pro Text, 11pt, `.white` at 85%)
- Line 2: "Mate in 3" (SF Pro Text, 11pt, `.white` at 70%) + tries indicator (right-aligned)
- Tries indicator: 3 circles, 8pt diameter, 4pt spacing
  - Unused: gold fill (`accent.gold`)
  - Failed attempt: `feedback.error` (system red)
  - Remaining: white stroke at 40% opacity, no fill
- Player names use short format: last names only ("Kasparov vs Kramnik")

**Board (280×280):**
- Interactive when it's the user's turn: `InteractiveBoardView`
- Static during opponent auto-play: `BoardView`
- Rounded corners (4pt)
- No instruction text below. No "Drag or click a piece."

**Ring:** Faded to 0% opacity. Gone. You're in chess mode now.

**Piece interaction:**
- Hover over own piece: piece brightens subtly (opacity 1.0 → the piece "lifts" with a subtle scale to 1.03)
- Selection (click): piece scales to 1.05, subtle shadow appears beneath. Selected square gets `accent.gold` at 30% overlay.
- Legal destinations: small gold dots (not black) at 28% opacity, centered on empty destination squares. For capture destinations: gold ring (not filled dot) at 28% opacity.
- Drag: piece follows cursor at full square size. Minimum 6pt to initiate.
- Drop on legal square: piece slides to destination (0.2s spring).
- Drop on illegal square: piece snaps back (0.15s spring).

**Feedback (during play — NO text overlays):**

| Event | Visual Response | Duration |
|-------|----------------|----------|
| Wrong move | Piece snaps back to origin. Destination square pulses red at 40% opacity. | Snap: 0.15s. Red pulse: 0.3s fade-out. |
| Correct move | Piece slides to destination. From/to squares get `move.highlight` overlay. | Slide: 0.2s. Highlight persists. |
| Opponent auto-play | 0.4s pause. Opponent piece slides to destination. From/to squares highlighted. | Slide: 0.25s. |

**No "Opponent is moving..." text. No "Opponent: G3F3" badge. The piece moving IS the communication.**

**Puzzle result cards (centered overlay after completion):**

Solved:
```
    ╭────────────────────────╮
    │                        │
    │          ✓             │  system green, SF Symbol checkmark.circle.fill, 36pt
    │        Solved          │  SF Pro Display, 17pt, Semibold, .primary
    │       First try        │  SF Pro Text, 12pt, Regular, .secondary
    │                        │
    │   [Review]    [Done]   │  Two buttons, side by side
    │                        │
    ╰────────────────────────╯
```

Failed:
```
    ╭────────────────────────╮
    │                        │
    │          ✗             │  system red, SF Symbol xmark.circle.fill, 36pt
    │      Not solved        │  SF Pro Display, 17pt, Semibold, .primary
    │                        │
    │   [Review]    [Done]   │
    │                        │
    ╰────────────────────────╯
```

- Card: `.regularMaterial` background, 12pt corner radius, centered on board
- Scrim behind card: `#000000` at 45% opacity over the board
- "Review" button: SF Pro Text, 13pt, Semibold, `accent.gold` foreground. Tap → Replay face.
- "Done" button: SF Pro Text, 13pt, Regular, `.secondary` foreground. Tap → Clock face.
- "Review" button appears after 0.5s delay (prevents accidental tap).
- **Removed:** "The continuation" move list, "All time: W/L" stats, exclamation marks.

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
- **Corner radius:** Applied via `.clipShape(RoundedRectangle(cornerRadius: 14))` on the SwiftUI root view (uses `radius.outer`).
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
    static let accentGold    = Color(red: 191/255, green: 155/255, blue: 48/255)  // #BF9B30 — jewelry gold
    static let accentGoldDim = accentGold.opacity(0.30)                            // Ring in non-clock faces
    static let ringTrack     = Color.gray.opacity(0.15)                            // Unfilled ring portion

    // Move highlighting
    static let moveHighlight = Color(red: 246/255, green: 246/255, blue: 104/255).opacity(0.50) // #F6F668 at 50%

    // Selection & interaction
    static let squareSelected   = accentGold.opacity(0.30)                         // Selected piece square
    static let legalDot         = accentGold.opacity(0.28)                         // Legal move dot
    static let legalCapture     = accentGold.opacity(0.28)                         // Legal capture ring
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
Content outer edge  (0pt inset):   radius = 14pt   ← anchor (radius.outer)
Ring path center    (4pt inset):   radius = 14 − 4  = 10pt  (radius.ring)
Ring inner edge     (8pt inset):   radius = 14 − 8  =  6pt  (derived, not a token)
Board edge         (10pt inset):   radius = 14 − 10 =  4pt  (radius.board)
```

**Rules for all future sprints:**

1. When adding any new nested shape inside the content area, compute its radius as `radius.outer − insetFromContentEdge`.
2. If the computed value is ≤ 0, use 0 (sharp corners).
3. Overlay elements (result cards, pills, zone badges) are **not** part of the concentric stack — they float on top and use their own independent radius tokens (`radius.card`, `radius.pill`, `radius.badge`).
4. The Detail face board (196×196 at 52pt inset) is a standalone element, not concentrically nested in the ring. It uses `radius.board` (4pt) as a visual minimum.
5. **Never hardcode a corner radius literal.** Always reference a `ChessClockRadius` token or compute from `radius.outer − inset`.

### Corner Radii

Tokens marked ★ are derived from the concentric rule above — do not set them independently.

| Token | Value | Derivation | Use |
|-------|-------|-----------|-----|
| `radius.outer` | 14pt | Anchor value | Content area clip, floating window |
| `radius.ring` | 10pt | ★ `outer − ringInset` (14 − 4) | Ring path center corner arcs |
| `radius.board` | 4pt | ★ `outer − boardInset` (14 − 10) | Board clip shape (all faces) |
| `radius.card` | 12pt | Independent | Result cards, onboarding card |
| `radius.pill` | 8pt | Independent | Hover pill, zone pills |
| `radius.badge` | 4pt | Independent | Small badges, promotion cells |

### Dimensions

| Token | Value | Derivation |
|-------|-------|-----------|
| `app.size` | 300pt | Fixed. Never changes. |
| `ring.stroke` | 8pt | Weight of the minute ring |
| `ring.inset` | 4pt | Half of stroke (ring path position) |
| `bezel.gap` | 2pt | Between ring inner edge and board |
| `board.inset` | 10pt | `ring.inset + ring.stroke/2 + bezel.gap` = 4 + 4 + 2 |
| `board.size` | 280pt | `app.size - 2 × board.inset` |
| `square.size` | 35pt | `board.size / 8` |
| `board.detail` | 196pt | Board in Detail face (24.5pt squares) |
| `header.height` | 28pt | Top header bar (Detail face) |
| `overlay.header` | 36pt | Translucent header on board (Puzzle/Replay) |
| `overlay.nav` | 32pt | Navigation pill at bottom (Replay) |
| `tick.length` | 4pt | Cardinal tick mark length (inward from ring) |
| `tick.width` | 1.5pt | Cardinal tick mark stroke |

### Animations

| Token | Spec | Use |
|-------|------|-----|
| `anim.micro` | 0.12s ease | Button press, hover highlight |
| `anim.fast` | 0.15s ease | Hover pill out, piece snap-back |
| `anim.standard` | 0.25s spring(response: 0.3, dampingFraction: 0.8) | Overlays, piece slides, state transitions |
| `anim.smooth` | 0.4s easeInOut | Board resize, face changes |
| `anim.ring` | 0.5s ease | Minute ring fill growth |
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
| CTA (unplayed) | "▶ Play" | |
| CTA (solved) | "✓ Solved · Review" | |
| CTA (failed) | "✗ · Review" | |
| Player (white) | "{FirstName} {LastName} · {ELO}" | "Garry Kasparov · 2851" |
| Player (black) | "{FirstName} {LastName} · {ELO}" | "Vladimir Kramnik · 2753" |
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
| Clock → Detail | Click board | Board scales 280→196: 0.3s spring. Board slides up. Ring dims: 0.25s. Metadata fades in from below: 0.2s (staggered). |
| Detail → Clock | Tap back | Reverse of above. Metadata slides down, board scales 196→280, ring brightens. |
| Detail → Puzzle | Tap CTA / board | Board scales 196→280: 0.3s spring. Metadata slides out: 0.2s. Ring fades to 0%: 0.2s. Header overlay fades in: 0.2s. |
| Puzzle → result card | Puzzle completes | Scrim fades in: 0.2s. Card scales from 0.9→1.0 with fade: 0.25s spring. |
| Result → Replay | Tap "Review" | Card and scrim fade out: 0.2s. Header content cross-fades: 0.15s. Nav overlay fades in: 0.2s. |
| Result → Clock | Tap "Done" | Card and scrim fade out. Board scales down then up (brief pulse). Ring fades back in. Return to Clock face. |
| Replay → Detail | Tap back | Nav overlay fades out. Header fades out. Board scales 280→196. Ring dims to 30%. Metadata fades in. |
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
| `MinuteBezelView.swift` | New ring component: rounded rect path with tick marks, fill animation, track | 1 |
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

## Sprint Plan

### Sprint 0 — Design Document ✓
*This document.* Lock before any code.

### Sprint 1 — Foundation ✓
**Goal:** Ship the visual atoms that everything else builds on.

Tasks:
- [x] Create `DesignTokens.swift` with all color, type, spacing, radius, animation constants
- [x] Replace cburnett PNGs with Merida gradient SVGs (12 assets)
- [x] Add corner radius to `BoardView` via `.clipShape(RoundedRectangle(cornerRadius: 6))`
- [x] Build `MinuteBezelView` — rounded rect ring with gold fill, gray track, 4 cardinal tick marks, smooth animation
- [x] Create `PlayerNameFormatter` — invert PGN names, handle initials, format ELO
- [x] Lock app frame to 300×300 (remove 332/500 height toggle)
- [x] Delete `ContentView.swift` (unused legacy file)
- [x] Delete `MoveArrowView.swift` (to be replaced in Sprint 5)

**Acceptance:** ✓ App builds and displays the clock face at 300×300 with new pieces, rounded board, and new bezel ring.

### Sprint 2 — Clock + Glance ✓
**Goal:** Ship the primary surface — what users see 95% of the time.

Tasks:
- [x] Apply concentric corner radius system: update `radius.outer` (14pt), `radius.ring` (10pt), `radius.board` (4pt) in `DesignTokens.swift`
- [x] Increase ring stroke to 8pt and update derived dimensions (`ringStroke`, `ringInset`, `bezelGap`) in `DesignTokens.swift`
- [x] Update `MinuteBezelView` ring path: 4pt inset, concentric corner radius from `radius.ring` token
- [x] Update `BoardView` clip radius to use `ChessClockRadius.board` token (4pt)
- [x] Apply `radius.outer` (14pt) clip to the root content view in `ClockView`
- [x] Clock face: board 280×280 centered within bezel ring, no text, no affordances
- [x] Ring: gold fill traces clockwise, gray track for unfilled portion, tick marks at 12/3/6/9
- [x] Ring animation: smooth 1/60th growth per minute (0.5s ease)
- [x] Glance face: board gaussian blur on hover, centered glass pill with formatted time + "Mate in N"
- [x] Build `GlassPillView` (reusable `.ultraThinMaterial` container)
- [x] Hover timing: fade in 0.15s, fade out 0.1s

✓ **Acceptance:** Clock displays correctly with 8pt ring and concentric corner radii (14pt outer → 10pt ring → 4pt board). Hovering shows time + chess context in a frosted pill. Ring ticks smoothly.

### Sprint 3 — Detail Face
**Goal:** Ship the info panel with proper information hierarchy.

Tasks:
- [ ] Detail face layout: board 196×196 centered, metadata below, header with back + gear
- [ ] Board scale animation: 280→196 with 0.3s spring on transition from Clock
- [ ] Ring dims to 30% opacity in Detail face
- [ ] CTA overlay on board bottom: "▶ Play" / "✓ Solved · Review" / "✗ · Review"
- [ ] Player names: full names formatted via `PlayerNameFormatter`, no "White:"/"Black:" labels
- [ ] Event line: cleaned up format ("Titled Tuesday · Aug 2023")
- [ ] Remove: Round number, AM/PM text, mini board duplicate
- [ ] Gear icon placeholder (top-right, inactive in v1.0)

**Acceptance:** Clicking the clock shows game info with properly formatted names, clean hierarchy, and working CTA.

### Sprint 4 — Puzzle Face
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

**Acceptance:** Entire puzzle flow works within 300×300. All feedback is visual. No unnecessary text.

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

**Acceptance:** Game review shows highlighted squares (no arrows), SAN notation, compact nav. Keyboard works immediately.

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

**Acceptance:** Complete, polished app. Every face, every transition, every interaction matches this spec. Ready for v1.0 release.

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
