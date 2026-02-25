# TODO — Chess Clock

> This is the **source of truth** for all development tasks.
> Never mark an item done without verifying its acceptance criteria.
> Run `/sync` at the start and end of every session.

---

## In Progress

_Nothing in progress._

---

## Backlog

### Sprint 4.5 — Polish & Header Redesign

> **Goal:** Fix tick z-order, balance Detail face layout, improve board interaction visibility, implement auto-hide puzzle header pills, and redesign the result overlay as full-board frosted glass.
> **Design spec:** `docs/DESIGN.md` → Sprint 4.5 section + updated Face 4 spec + updated Design Tokens

- [ ] **S4.5-1: ClockView — Tick z-order fix** — Move `GoldRingLayerView` to render AFTER `boardWithRing` in the outer ZStack so tick marks appear above the board surface.
  - Files: `ChessClock/ChessClock/Views/ClockView.swift`
  - Depends on: none
  - Acceptance:
    - [ ] In `ClockView.swift`, the `if viewMode == .clock { GoldRingLayerView(...) }` block appears AFTER the `switch viewMode { ... }` block in the ZStack (not before it)
    - [ ] The `GoldRingLayerView` retains `.transition(.opacity)` and `.frame(width: 300, height: 300)`
    - [ ] Build succeeds
  - Verify: `xcodebuild -project ChessClock/ChessClock.xcodeproj -scheme ChessClock -configuration Debug build 2>&1 | tail -3`

- [ ] **S4.5-2: InfoPanelView — Vertical balance fix** — Remove the bottom `Spacer()`, add `.padding(.bottom, 12)` to match top padding, and add `alignment: .top` to the `.frame(maxWidth:maxHeight:)` call so top and bottom margins are symmetric.
  - Files: `ChessClock/ChessClock/Views/InfoPanelView.swift`
  - Depends on: none
  - Acceptance:
    - [ ] The `Spacer()` at the end of the root `VStack` is deleted
    - [ ] `.padding(.top, 12)` becomes `.padding(.vertical, 12)` (or equivalent `.padding(.top, 12).padding(.bottom, 12)`)
    - [ ] `.frame(maxWidth: .infinity, maxHeight: .infinity)` becomes `.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)`
    - [ ] Build succeeds
  - Verify: `xcodebuild -project ChessClock/ChessClock.xcodeproj -scheme ChessClock -configuration Debug build 2>&1 | tail -3`

- [ ] **S4.5-3: DesignTokens — Interaction color opacity updates** — Increase opacity values for `squareSelected` (0.30→0.50), `legalDot` (0.28→0.55), and `legalCapture` (0.28→0.55).
  - Files: `ChessClock/ChessClock/DesignTokens.swift`
  - Depends on: none
  - Acceptance:
    - [ ] `squareSelected = accentGold.opacity(0.50)` (was 0.30)
    - [ ] `legalDot = accentGold.opacity(0.55)` (was 0.28)
    - [ ] `legalCapture = accentGold.opacity(0.55)` (was 0.28)
    - [ ] Build succeeds
  - Verify: `xcodebuild -project ChessClock/ChessClock.xcodeproj -scheme ChessClock -configuration Debug build 2>&1 | tail -3`

- [ ] **S4.5-4: InteractiveBoardView — Legal dot size increase** — Increase legal move dot diameter from `sq * 0.32` to `sq * 0.38`.
  - Files: `ChessClock/ChessClock/Views/InteractiveBoardView.swift`
  - Depends on: none
  - Acceptance:
    - [ ] `Circle().fill(Self.legalDotColor).frame(width: sq * 0.32, height: sq * 0.32)` changed to `sq * 0.38` for both width and height
    - [ ] Build succeeds
  - Verify: `xcodebuild -project ChessClock/ChessClock.xcodeproj -scheme ChessClock -configuration Debug build 2>&1 | tail -3`

- [ ] **S4.5-5: GuessMoveView — Auto-hide header pills** — Replace the static `headerOverlay` with an auto-hide three-pill system and persistent down-chevron pip. See DESIGN.md Sprint 4.5 header spec.
  - Files: `ChessClock/ChessClock/Views/GuessMoveView.swift`
  - Depends on: none
  - Acceptance:
    - [ ] Added: `@State private var headerVisible: Bool = true` and `@State private var headerHideTask: DispatchWorkItem?`
    - [ ] Old `headerOverlay` computed var replaced by `puzzleHeaderPills` (three pills: back, info, tries) and `puzzlePip` (down-chevron)
    - [ ] Pills: each pill has `.ultraThinMaterial` background, `ChessClockRadius.pill` (8pt) corner radius; HStack 8pt spacing; 8pt padding from board edges and board top
    - [ ] Back pill taps `onBack()`. Info pill shows "{lastName} vs {lastName} · Mate in {N}". Tries pill shows 3 circles (8pt, 4pt spacing, gold/red/outline).
    - [ ] Pills animate in/out with `.spring(response: 0.28, dampingFraction: 0.78)` + `.asymmetric(insertion/removal: .move(edge: .top).combined(with: .opacity))`
    - [ ] On `.onAppear`: `scheduleHeaderHide(after: 2.5)` called (pills shown → auto-hides after 2.5s)
    - [ ] `scheduleHeaderHide(after:)` cancels pending task, creates new `DispatchWorkItem` that animates `headerVisible = false` after given seconds
    - [ ] `showHeaderBriefly(seconds:)` cancels pending task, animates `headerVisible = true`, calls `scheduleHeaderHide(after: seconds)`
    - [ ] Pip: `chevron.down` (12pt, white 60%), `.ultraThinMaterial.opacity(0.7)` background, 4pt radius, 24×20pt; `.onHover { if $0 { showHeaderBriefly(2.5) } }`; visible only when `!headerVisible`
    - [ ] Build succeeds
  - Verify: `xcodebuild -project ChessClock/ChessClock.xcodeproj -scheme ChessClock -configuration Debug build 2>&1 | tail -3`

- [ ] **S4.5-6: GuessMoveView — Wrong move border flash** — Add board-edge red `strokeBorder` flash (rim only, 0.5s) on wrong move, and trigger header pills to reappear for 1.8s.
  - Files: `ChessClock/ChessClock/Views/GuessMoveView.swift`
  - Depends on: S4.5-5
  - Acceptance:
    - [ ] `@State private var wrongBorderOpacity: Double = 0` added
    - [ ] `boardSection` has `.overlay(RoundedRectangle(cornerRadius: ChessClockRadius.puzzleBoard).strokeBorder(ChessClockColor.feedbackError, lineWidth: 3).opacity(wrongBorderOpacity))` applied to the board view inside `boardSection`
    - [ ] In `handleMove(.wrong(...))`: `wrongBorderOpacity = 0.75` set immediately, then `withAnimation(.easeOut(duration: 0.5)) { wrongBorderOpacity = 0 }` triggered, and `showHeaderBriefly(seconds: 1.8)` called
    - [ ] Build succeeds
  - Verify: `xcodebuild -project ChessClock/ChessClock.xcodeproj -scheme ChessClock -configuration Debug build 2>&1 | tail -3`

- [ ] **S4.5-7: GuessMoveView — Result overlay frosted glass** — Replace `successOverlay` and `failedOverlay` with full 280×280 `.ultraThinMaterial` frosted glass overlay with colored tint, no icon, and prominent buttons.
  - Files: `ChessClock/ChessClock/Views/GuessMoveView.swift`
  - Depends on: S4.5-6
  - Acceptance:
    - [ ] `successOverlay` rewritten: ZStack of `.ultraThinMaterial` + `ChessClockColor.feedbackSuccess.opacity(0.10)` tint, clipped to `ChessClockRadius.puzzleBoard`. No SF Symbol icon. Title "Solved" at 28pt semibold white. Try phrase at 13pt white 60%. Buttons below.
    - [ ] `failedOverlay` rewritten: same structure with `ChessClockColor.feedbackError.opacity(0.10)` tint. Title "Not solved" at 28pt semibold white. No try phrase.
    - [ ] "Review →" button: `.ultraThinMaterial` capsule background, `ChessClockColor.accentGold` foreground, 13pt semibold, h:12 v:6 padding. Tap → `onReplay()`. Appears after 0.2s (`.transition(.opacity)` + `DispatchQueue.main.asyncAfter(0.2)`).
    - [ ] "Done" button: `.white.opacity(0.50)` foreground, 13pt regular, no background. Tap → `onBack()`. Immediate.
    - [ ] `showReviewButton: Bool` state removed; review button delay handled inline in the overlay
    - [ ] Both overlays use `.frame(maxWidth: .infinity, maxHeight: .infinity)` to fill 280×280
    - [ ] Build succeeds
  - Verify: `xcodebuild -project ChessClock/ChessClock.xcodeproj -scheme ChessClock -configuration Debug build 2>&1 | tail -3`

<!-- Sprint 4.5 Dependency Graph
S4.5-1 (ClockView z-order)     ─── INDEPENDENT ───────────────────────────
S4.5-2 (InfoPanel balance)     ─── INDEPENDENT ───────────────────────────
S4.5-3 (DesignTokens opacity)  ─── INDEPENDENT ───────────────────────────
S4.5-4 (IBV dot size)          ─── INDEPENDENT ───────────────────────────
S4.5-5 (header pills)          ─── INDEPENDENT ──► S4.5-6 ──► S4.5-7

Wave 1 (4 parallel agents): S4.5-1, S4.5-2, S4.5-3, S4.5-4
Wave 2 (1 agent sequential): S4.5-5 → S4.5-6 → S4.5-7
Recommended: 5 agents total
-->

---

## Done

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
