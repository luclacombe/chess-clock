# TODO — Chess Clock

> This is the **source of truth** for all development tasks.
> Never mark an item done without verifying its acceptance criteria.
> Run `/sync` at the start and end of every session.

---

## In Progress

_Nothing in progress._

---

## Backlog

_Empty — run `/plan-sprint` to plan Sprint 3._

---

## Done

### Sprint 2 — Clock + Glance (2026-02-23)

- [x] **S2-1: Update DesignTokens.swift — concentric radius system + ring dimensions** — outer=14, ring=10, board=4, ringStroke=8, ringInset=4, bezelGap=2. `bdeb036`
- [x] **S2-2: Update MinuteBezelView — concentric corner radius from token** — RingShape uses `ChessClockRadius.ring` (10pt). `bdeb036`
- [x] **S2-3: Update BoardView — token-based clip radius and color references** — Uses `ChessClockRadius.board` and `ChessClockColor` tokens. `bdeb036`
- [x] **S2-4: Build GlassPillView** — Reusable `.ultraThinMaterial` container with pill radius and space tokens. `b5ad8ac`
- [x] **S2-5: Build Glance face + apply outer clip in ClockView** — 14pt outer clip, blurred board + GlassPillView on hover, deleted old hover text + 6 tests. `b0addec`

### Sprint 1 — Foundation (2026-02-23)

- [x] **S1-1: Create DesignTokens.swift** — All color, typography, spacing, radius, dimension, and animation constants. `050ed42`
- [x] **S1-2: Replace cburnett PNGs with Merida gradient SVGs** — 12 SVGs downloaded from Lichess, PNGs deleted, Contents.json updated. `c2f9f69`
- [x] **S1-3: Add 6pt corner radius to BoardView** — `.clipShape(RoundedRectangle(cornerRadius: 6))`. `43cf99d`
- [x] **S1-4: Build MinuteBezelView** — Custom RingShape, gold fill with gray track, 4 cardinal tick marks, animated. `bd1979f`
- [x] **S1-5: Create PlayerNameFormatter** — PGN name inversion, initial handling, ELO formatting. `43cf99d`
- [x] **S1-6: Update ClockView — lock 300×300 frame and wire MinuteBezelView** — Fixed frame, removed padding, replaced MinuteSquareRingView. `4d8163d`
- [x] **S1-7: Delete ContentView.swift** — Legacy piece-grid test view removed. `43cf99d`
- [x] **S1-8: Delete MoveArrowView.swift and remove all usages** — File deleted, GameReplayView cleaned, 8 arrow tests removed (32 remain). `3c8c260`

### v0.5.1 (patch)

- [x] **Replay start position fix** — `puzzleStartPosIndex` formula corrected from `positions.count - 1` to `positions.count - 2`. Replay now opens at the true puzzle start (mating side to move, opponent's last move shown as context arrow). Previously opened one step too far forward at the checkmate position.
- [x] **GitHub Latest release** — Created formal GitHub Release for v0.5.1 via `gh release create --latest`, replacing the stale v0.4.0 Latest badge.

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
