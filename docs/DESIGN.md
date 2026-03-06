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

### The Layer Model

Four concentric layers, from outside in:

```
Layer 0: CONTENT     — 300×300, clipped to 18pt rounded rect (the outermost shape)
Layer 1: RING        — 8pt stroke, rounded rect path at 6pt inset
Layer 2: BOARD       — 280×280, 8×8 grid, 35pt squares (flush with ring inner edge)
Layer 3: OVERLAYS    — Translucent pills, headers, nav controls
```

**Math:**
- Content clip: `RoundedRectangle(cornerRadius: 18)` on the root view
- Ring path: `RoundedRectangle` at 6pt inset, 8pt stroke → outer edge at 2pt, inner edge at 10pt
- Gap: 0pt — ring inner edge flush with board edge
- Board: `300 - 2×10 = 280×280`
- Square size: `280 / 8 = 35pt`
- Corner radii follow the concentric formula (see Design Tokens)

### State-Dependent Layout

| Face | Board Size | Ring | Overlays |
|------|-----------|------|----------|
| Clock | 280×280 | Full gold noise, 10 FPS Metal | None |
| Glance | 280×280 | Full gold noise | Centered glass pill |
| Detail | 164×164 | Hidden (0% opacity) | Flanking icons + CTA pill + metadata |
| Puzzle | 280×280 | Marble noise ring (PuzzleRingView) | Header pills at top |
| Replay | 280×280 | Hidden (0% opacity) | Header top + nav bottom |

---

## The Five Faces

### Face 1: Clock (Ambient)

The default state. What the user sees 95% of the time.

- Board: 280×280, centered
- Ring: Metal compute shader liquid gold noise, filling clockwise from top-center. Unfilled track at 15% gray. Ring inner edge flush with board. Static glass tube overlays (specular + shadow) add depth.
- Tick marks: 12 total — 4 cardinal (gradient bar spanning ring + 4pt into board, `white 0.85→0.45`, 2.5pt width) + 8 minor (ring-only, `white 0.40`, 1.5pt width). All rendered on top of ring fill.
- AM: White's perspective (rank 1 at bottom). PM: Board flipped (rank 8 at bottom).
- **No text. No labels. No visible affordances.** Pure ambient display.

**Ring progress:** Each second, progress = `(minute × 60 + second) / 3600`. Pie wedge mask with semicircle cap (smooth "snake body" tip). At minute 0, second 0: instant reset to empty. Ring pauses when popover is not visible (zero CPU/GPU when closed).

---

### Face 2: Glance (Hover — macOS only)

Triggered by mouse hover over the app content area.

- Board: Gaussian blur (radius 8pt)
- Ring: Remains fully visible and ticking
- Glass pill: Centered on board. `.ultraThinMaterial`, 8pt corners, 16/12pt padding. Layered shadows + 0.5pt white inner stroke.
  - Line 1: **Formatted time** — "2:47 PM" (18pt, Semibold, `.primary`)
  - Line 2: **Chess context** — "Mate in 2" (12pt, Regular, `.secondary`)
- This is the **only place** where the digital time is displayed.
- Fade in: 0.15s. Fade out: 0.1s.

---

### Face 3: Detail (Click)

Triggered by clicking the board in Clock or Glance face.

**Flanking icons:** Back chevron (left) and gear icon (right) sit in the board row, aligned with board top. `HStack(alignment: .top)`. Both 13pt, Medium, `.secondary`, 28×28 tap targets. Gear navigates to Settings placeholder.

**Board (164×164):** Centered, interactive (tap enters Puzzle), 8pt corners, 0.5pt dark bevel border. Square size: 20.5pt.

**CTA floating pill:** Capsule, `.ultraThinMaterial`, 14/7pt padding. Content by state:
- Not yet played: `play.fill` + "Play" — `accent.gold`
- Solved: `checkmark` + "Solved" — system green
- Failed: `arrow.counterclockwise` + "Review" — `.secondary`
- Hover: `scaleEffect(1.04)` + `brightness(0.08)`, 0.12s ease.

**Game metadata:** Player rows (indicator bead + name + ELO), event line. Names inverted from PGN ("Kramnik,V" → "V. Kramnik"). ELO "?" omitted.

**Ring:** Hidden (0% opacity).

---

### Face 4: Puzzle (Interactive)

Triggered by tapping the board in Detail face or CTA.

**Header (auto-hide pills):** Three pills in HStack at top of board (8pt from edges):
- **Back pill:** `chevron.left`, white 85%.
- **Info pill:** "{LastName} vs {LastName} · Mate in {N}", 11pt caption. Two-line layout.
- **Tries pill:** 3 circles (8pt) — gold/red/white stroke.

Auto-hide after 1.8s. Persistent pip (chevron.down) on hover reveals pills with spring animation. Pills reappear on wrong move for 1.8s.

**Board (280×280):** Interactive when user's turn (`InteractiveBoardView`), static during opponent auto-play. 4pt corners.

**Piece interaction:** Hover brightens (scale 1.03). Selection: scale 1.05, gold 50% overlay. Legal moves: gold dots 55% opacity, 38% diameter. Captures: gold ring. Drag: 6pt minimum.

**Feedback:**
| Event | Response |
|-------|----------|
| Wrong move | Snap back + red square pulse + red border flash (0.5s) + pills reappear |
| Correct move | Slide + from/to highlight |
| Opponent auto-play | 0.4s pause + slide + highlight |

**Result overlay:** Full 280×280 `.ultraThinMaterial` + 10% green/red tint. "Solved"/"Not solved" (28pt). Try phrase. "Review →" gold capsule (0.2s delay). "Done" plain text.

**Ring:** Marble noise ring (PuzzleRingView) with tint feedback — green on correct, red on wrong.

---

### Face 5: Replay (Review)

Triggered by "Review" in puzzle result or from Detail when already completed.

**Back pill (top-left, always visible):** Floating pill at top-left (8pt inset from edges). Contains `chevron.left` 12pt + `"{WhiteLastName} vs {BlackLastName}"` 11pt caption. `pillBackground`/`pillBorder` styling, shadow. No auto-hide — always visible. Tap returns to info face.

**Nav strip (bottom of board):** Slim translucent overlay at bottom of board. `pillBackground` + `UnevenRoundedRectangle(bottomLeading/Trailing: puzzleBoard)`.
- Single HStack: `[←]` chevron 14pt | zone label (colored text, 10pt semibold, `zone.color`) | `·` separator | SAN move (mono 11pt) | `·` | position counter `N/M` (micro 10pt) | `[→]` chevron 14pt.
- Below: `ReplayProgressBar`.

**Interactive progress bar (`ReplayProgressBar`):** 3pt track (`white 0.15`), zone-colored fill proportional to `posIndex/totalMoves`, puzzle-start tick mark (1pt, `white 0.35`), click-to-seek with snap zones (left 8% → move 0, ±3% of puzzle start → puzzle start), hover: thicken to 5pt + radial cursor glow (`white 0.25` → clear, 20pt radius).

**Zone colors:**
- "Opening": `systemGray`
- "Puzzle": `accent.gold`
- "Solution": `feedback.success`
- "Checkmate": darker green (`RGB(0.10, 0.65, 0.10)`)

**Board (280×280):** Display-only. Highlighted from/to squares (`moveHighlight` overlay). 4pt corners.

**Keyboard:** ← → step back/forward. Cmd+← jump to start. Cmd+→ jump to end (macOS 14+).

**Ring:** Hidden.

---

### Floating Window

Borderless `NSPanel`. 300×300, no title bar, no traffic lights. Draggable by background. Close button visible on hover (top-left, `xmark`, `.ultraThinMaterial` circle). System shadow. All five faces work identically.

---

### Promotion Picker

Column picker at promotion file (like chess.com). 4 pieces: Q, R, B, N at square size. `.ultraThinMaterial` per cell. 1pt gap. Scrim `black 30%` over rest of board. No title text.

---

### Onboarding

Overlay with `.regularMaterial` card:
- Title: "Chess Clock"
- 4 body lines: board/ring/puzzle/tap explanations
- Button: "Continue" — gold capsule
- Corner radius: 12pt (`radius.card`)
- Scrim: `black 60%`

---

## Design Tokens

### Colors

```swift
enum ChessClockColor {
    // Board
    static let boardLight    = Color(red: 240/255, green: 217/255, blue: 181/255) // #F0D9B5
    static let boardDark     = Color(red: 181/255, green: 136/255, blue: 99/255)  // #B58863

    // Ring
    static let accentGold      = Color(red: 191/255, green: 155/255, blue: 48/255)  // #BF9B30
    static let accentGoldLight = Color(red: 212/255, green: 185/255, blue: 78/255)  // #D4B94E
    static let accentGoldDeep  = Color(red: 138/255, green: 111/255, blue: 31/255)  // #8A6F1F
    static let accentGoldDim   = accentGold.opacity(0.30)
    static let ringTrack       = Color.gray.opacity(0.15)

    // Move highlighting
    static let moveHighlight = Color(red: 246/255, green: 246/255, blue: 104/255).opacity(0.50) // #F6F668

    // Selection & interaction
    static let squareSelected   = accentGold.opacity(0.50)
    static let legalDot         = accentGold.opacity(0.55)
    static let legalCapture     = accentGold.opacity(0.55)
    static let wrongFlash       = Color.red.opacity(0.40)

    // Semantic
    static let feedbackSuccess  = Color.green
    static let feedbackError    = Color.red

    // Overlays
    static let overlayScrim     = Color.black.opacity(0.45)
    static let headerBg         = Color.black.opacity(0.55)
    static let ctaBg            = Color.black.opacity(0.60)
}
```

### Typography

```swift
enum ChessClockType {
    static let display   = Font.system(size: 18, weight: .semibold, design: .default)  // Hover time
    static let title     = Font.system(size: 17, weight: .semibold, design: .default)  // Result titles
    static let body      = Font.system(size: 13, weight: .regular, design: .default)   // Player names
    static let caption   = Font.system(size: 11, weight: .regular, design: .default)   // Headers
    static let micro     = Font.system(size: 10, weight: .medium, design: .default)    // Tiny labels
    static let mono      = Font.system(size: 11, weight: .medium, design: .monospaced) // SAN notation
}
```

### Spacing

8pt grid system (watchOS-compatible):

| Token | Value | Use |
|-------|-------|-----|
| `space.xs` | 2pt | Within compound elements |
| `space.sm` | 4pt | Related items, line spacing |
| `space.md` | 8pt | Between sections |
| `space.lg` | 12pt | Medium separation |
| `space.xl` | 16pt | Primary padding |

### Concentric Corner Radius Rule

Every nested rounded rectangle **must** follow: `innerRadius = max(outerRadius − insetDistance, 0)`

```
Content outer edge  (0pt inset):   radius = 18pt   ← anchor
Ring path center    (6pt inset):   radius = 12pt
Ring inner edge    (10pt inset):   radius =  8pt
Board edge         (10pt inset):   radius =  8pt   (flush with ring)
```

Overlay elements (pills, cards) are not part of the concentric stack — they use independent tokens.

### Corner Radii

| Token | Value | Use |
|-------|-------|-----|
| `radius.outer` | 18pt | Content area clip, floating window |
| `radius.ring` | 12pt | Ring path center |
| `radius.board` | 8pt | Board clip shape |
| `radius.card` | 12pt | Result cards, onboarding |
| `radius.pill` | 8pt | Hover pill, zone pills |
| `radius.badge` | 4pt | Small badges, promotion cells |

### Dimensions

| Token | Value |
|-------|-------|
| `app.size` | 300pt |
| `ring.stroke` | 8pt |
| `ring.inset` | 6pt |
| `board.inset` | 10pt |
| `board.size` | 280pt |
| `square.size` | 35pt |
| `board.detail` | 164pt |
| `overlay.header` | 36pt |
| `overlay.nav` | 32pt |
| `tick.length` | 12pt (cardinal, spans ring + 4pt into board) |
| `tick.width` | 2.5pt (cardinal) |
| `minorTick.length` | 4pt (ring-only) |
| `minorTick.width` | 1.5pt |

### Animations

| Token | Spec | Use |
|-------|------|-----|
| `anim.micro` | 0.12s ease | Button press, hover |
| `anim.fast` | 0.15s ease | Hover pill out, snap-back |
| `anim.standard` | 0.25s spring(0.3, 0.8) | Overlays, piece slides |
| `anim.smooth` | 0.4s easeInOut | Board resize, face changes |
| `anim.dramatic` | 0.6s easeInOut | Hour-change piece slide |
| `anim.wrongPulse` | 0.3s fade-out | Red flash on wrong move |
| `anim.opponentDelay` | 0.4s | Pause before opponent auto-play |
| `anim.reviewButtonDelay` | 0.5s | "Review" button delay |

---

## Copy Guide

Every text string in the app. **No string should exist in code that isn't listed here.**

### Clock Face
*(No text.)*

### Glance Face
| Element | Example |
|---------|---------|
| Time | "2:47 PM" (`h:mm a` format) |
| Context | "Mate in 2" |

### Detail Face
| Element | Example |
|---------|---------|
| CTA (unplayed) | "▶ Play" (gold) |
| CTA (solved) | "✓ Solved" (green) |
| CTA (failed) | "↺ Review" (secondary) |
| Player (white) | "○ M. Sebag    2454" |
| Player (black) | "● V. Kramnik    2753" |
| Event | "World Championship · Nov 2000" |

**Name rules:** "Kasparov,Garry" → "Garry Kasparov". "Kramnik,V" → "V. Kramnik". ELO "?" → omit.

### Puzzle Face
| Element | Text |
|---------|------|
| Players | "{LastName} vs {LastName}" |
| Context | "Mate in {N}" |
| Solved title | "Solved" |
| Solved detail | "First try" / "Second try" / "Third try" |
| Failed title | "Not solved" |
| Review button | "Review" |
| Done button | "Done" |

### Replay Face
| Element | Text |
|---------|------|
| Back pill | "← {LastName} vs {LastName}" |
| Zones | "Opening" / "Puzzle" / "Solution" / "Checkmate" |
| Move notation | SAN format ("Nxe4", "O-O", "Qf7#") |
| Separator | "·" |
| Position counter | "{N}/{M}" |

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
| Clock → Glance | Mouse enter | Board blur 0.2s, pill fade-in 0.15s |
| Glance → Clock | Mouse exit | Pill fade-out 0.1s, un-blur 0.15s |
| Clock → Detail | Click board | Board scales 280→164 (0.3s spring), ring dims |
| Detail → Clock | Tap back | Reverse of above |
| Detail → Puzzle | Tap CTA/board | Board scales 164→280, metadata out, ring to 0% |
| Puzzle → Result | Puzzle completes | Scrim 0.2s, card scale 0.9→1.0 (0.25s spring) |
| Result → Replay | Tap "Review" | Card/scrim out 0.2s, nav in 0.2s |
| Result → Clock | Tap "Done" | Card out, board pulse, ring back |
| Replay → Detail | Tap back | Nav out, board scales 280→164, metadata in |
| Any → Clock | Popover reopens | Instant reset (WindowObserver) |

### Hour-Change Animation

1. Ring sweeps to full (0.3s), then drains clockwise — trailing edge chases leading edge to empty (0.3s easeIn)
2. Board cross-fade: old out (0.3s), new in (0.3s), overlap 0.15s
3. Total: ~0.9s

### Keyboard Shortcuts

| Key | Context | Action |
|-----|---------|--------|
| `←` | Replay | Step back |
| `→` | Replay | Step forward |
| `Cmd+←` | Replay | Jump to start |
| `Cmd+→` | Replay | Jump to end |
| `Escape` | Non-Clock | Return to previous |
| `Option+Space` | Global | Toggle popover |

---

## Piece Set

**Merida gradient from Lichess.** GPLv2+. SVG in Xcode asset catalog ("Preserve Vector Data" = YES, "Render As" = Original). 12 assets: wK/wQ/wR/wB/wN/wP/bK/bQ/bR/bB/bN/bP. Piece-set agnostic by design — swap by replacing asset files.

---

## Performance Rules

1. **Use Core Animation / Metal for continuous animation, not SwiftUI.** Reserve SwiftUI `.animation()` for discrete state transitions. Ring uses `GoldNoiseShader.metal` + `GoldNoiseRenderer` (IOSurface zero-copy, <0.1% CPU).

2. **`.drawingGroup()` before `.blur()`.** Rasterize >10 subview trees first.

3. **Conditional rendering over opacity for expensive views.** Use `if condition { View }` not `View.opacity(0)` for materials, blur, CALayer views.

4. **All timers pause when no UI visible.** `ClockService` resume/pause lifecycle. `GoldRingLayerView` `isActive` parameter. Zero idle wake-ups.

5. **Hour-keyed caching** for hourly-stable computations.

6. **Prefer scrims over materials for modal overlays.** `Color.black.opacity(0.65)` instead of `.regularMaterial` when background vibrancy is not needed.

7. **Respect reduced motion.** Disable continuous animations; render single static frame; use simple fades.

---

## Sprint Plan

_Sprints 0–6 archived to `docs/archive/DESIGN-sprints-0-6.md`_

### Sprint 6.5 — Replay Face: Board-First Two Overlays Redesign ✓
**Goal:** Redesign GameReplayView with minimal "board-first" layout: always-visible back pill, slim nav strip with progress bar, focus/keyboard fixes.

Tasks:
- [x] S6.5-1: Update DESIGN.md — Replay Face redesign spec
- [x] S6.5-2: Design tokens for replay progress bar
- [x] S6.5-3: ReplayProgressBar — Interactive zone-colored scrubber
- [x] S6.5-4: Rewrite GameReplayView — Board-First Two Overlays
- [x] S6.5-5: Verify build + all tests pass

✓ **Acceptance:** Back pill always visible with player names. Nav strip replaces 5-button bar. Interactive progress bar with zone colors and snap-to-seek. Arrow keys work on hover (no click needed). Focus ring eliminated. All 32 existing tests pass.

### Sprint 7 — Chrome + Polish
**Goal:** Ship the release candidate with borderless floating window, polished transitions, onboarding refresh, and comprehensive audit.

**What already exists:** `FloatingWindowManager.swift` (singleton, `NSPanel`, currently has title bar), `OnboardingOverlayView.swift` (wrong text, "Got it" button), all face transitions wired, performance infrastructure complete, reduced motion partially implemented.

Tasks:

- [ ] **S7-1: BorderlessPanel** — `NSPanel` subclass (`canBecomeKey`, `canBecomeMain`). Borderless, 300×300, draggable, `.floating` level, system shadow. Custom close button on hover (top-left, `xmark`, `.ultraThinMaterial` circle, fade 0.15s). Content: `ClockView` clipped to 18pt rounded rect.

- [ ] **S7-2: Onboarding refresh** — Update text to match Copy Guide. "Got it" → "Continue" gold capsule. Corner radius → 12pt (`radius.card`). Typography → design tokens. Add a dont show again tick box.

- [ ] **S7-3: Hour-change animation** — Detect `hour` change via `.onChange(of:)`. Ring sweep to full (0.3s) → then drain clockwise: trailing edge chases leading edge to empty (0.3s easeIn), so the fill appears to slide off the track. Board cross-fade via `.id(hour)` + `.transition(.opacity)`. Total ~0.9s. Should happen without refreshing app.

- [ ] **S7-4: Face transition audit** — Verify every transition in the Interaction Specification table. All use `withAnimation(ChessClockAnimation.smooth)` (0.4s easeInOut) for ViewMode changes.

- [ ] **S7-5: Performance audit** — Profile each face 60s. Clock idle <0.5% CPU. Popover closed: 0% CPU. Verify `isActive` pauses, timer lifecycle, CALayer panel survival.

- [ ] **S7-6: Accessibility + reduced motion** — VoiceOver labels on all interactive elements. Reduced motion: disable continuous animations, simple fades instead of springs, instant blur toggle.

**Acceptance:** Borderless 300×300 floating window. Every transition matches spec. Hour-change animation works. Onboarding uses v1.0 copy. CPU <0.5% idle. VoiceOver labels. Reduced motion disables continuous animations. Ready for v1.0 release.

---

### Sprint 7 — Implementation Notes

Verbose code snippets and specs for each task. Reference these during implementation.

#### S7-1: BorderlessPanel

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
panel.isReleasedWhenClosed = false
```

Content view: `ClockView(clockService:)` wrapped in `.clipShape(RoundedRectangle(cornerRadius: ChessClockRadius.outer))` — the 18pt clip is the window's visual edge.

Close button: Visible only on hover. Top-left corner, 6pt inset. SF Symbol `xmark` at 10pt, `.secondary` foreground, 20×20 frame, `.ultraThinMaterial` Circle background. Fade in/out with `ChessClockAnimation.fast` (0.15s easeOut). Button action: `panel.close()`.

Window size: Exactly 300×300. No extra chrome, no title bar, no resize handle.

#### S7-2: Onboarding refresh

Current text → new text:
- Title: "Welcome to Chess Clock" → "Chess Clock"
- Body: single block → 4 separate `Text` lines with `ChessClockSpace.sm` (4pt) spacing
- Button: "Got it" → "Continue"

Typography: title `ChessClockType.title` (17pt semibold), body `ChessClockType.body` (13pt regular), button `ChessClockType.body` semibold.

Material: keep `.regularMaterial`. Corner radius: `ChessClockRadius.card` (12pt). Padding: 20pt. Scrim: `Color.black.opacity(0.6)`.

Button style:
```swift
Button("Continue") { onDismiss() }
    .font(.system(size: 13, weight: .semibold))
    .foregroundColor(ChessClockColor.accentGold)
    .padding(.horizontal, 14)
    .padding(.vertical, 7)
    .background(ChessClockColor.accentGold.opacity(0.12))
    .clipShape(Capsule())
    .buttonStyle(.plain)
```

#### S7-3: Hour-change animation

In `ClockView`, when `clockService.state.hour` changes (`.onChange(of:)`):
1. Ring sweeps to full: animate progress to 1.0 (0.3s spring)
2. Ring drains clockwise: after 0.3s delay, animate the **start angle** from 0 → 2π (0.3s easeIn) while keeping the end angle at 2π — the trailing edge chases the leading edge around the track until the fill disappears. This creates a "slide off" effect rather than an instant reset.
3. Reset: once drain completes, snap both start angle and progress back to 0 (no animation)
4. Board cross-fade: `.transition(.opacity)` on `BoardView` keyed by hour: `.id(clockService.state.hour)`
Total: ~0.9s.

#### S7-5: Performance audit

Profile with Instruments → Time Profiler for 60s in each face:
- Clock face (popover open, idle): target <0.5% CPU. Metal compute ~0.05ms/frame at 10 FPS + 1/sec wedge path update.
- During transitions: target <2% CPU.
- Popover closed: target 0% CPU. Verify `isActive` pauses noise timer and `ClockService.pause()` stops the 1s timer.
- Floating window lifecycle: verify `GoldRingLayerView` CALayer survives panel show→close→reshow. Timer must restart via `isActive` toggle.
- Check for SwiftUI `.animation` on container views — these cause full-tree re-evaluation.

#### S7-6: Accessibility + reduced motion

**VoiceOver labels:**
- Clock face board: "Chess clock showing {hour} o'clock position"
- Glance pill: "{time}, Mate in {N}"
- Detail CTA pill: "Play puzzle" / "Puzzle solved" / "Review puzzle"
- Puzzle header pills: back "Go back", info "{White} versus {Black}, Mate in {N}", tries "Try {N} of 3"
- Replay nav buttons: "First move", "Previous move", "Puzzle start", "Next move", "Last move"
- Result card: "Puzzle solved, {try phrase}" / "Puzzle not solved"

**Reduced motion** (`NSWorkspace.shared.accessibilityDisplayShouldReduceMotion`):
- Noise timer not started (already implemented in `GoldRingLayerView`)
- Puzzle ring renders single static frame (already implemented in `PuzzleRingView`)
- Face transitions: simple `.opacity` instead of spring/scale — `if reduceMotion { .easeInOut(0.3) } else { .spring(...) }`
- Board blur on hover: instant toggle
- Result card: fade only, no scale

---

*This document is the source of truth for v1.0. When in doubt, refer here. If something is missing, add it here before implementing.*
