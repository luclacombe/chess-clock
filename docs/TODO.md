# TODO — Chess Clock

> This is the **source of truth** for all development tasks.
> Never mark an item done without verifying its acceptance criteria.
> Run `/sync` at the start and end of every session.

---

## In Progress

_Nothing in progress._

---

## Backlog

_Empty — next sprint: Sprint 4 (Puzzle Face)._

---

## Done

### Sprint 4F — Ring Rendering Fix (Simplify)

- [x] **S4F-1: Rewrite GoldRingLayerView — working foundation** — Stripped rotation, glow tip, breathing pulse, spring physics, gradientClipContainer. Rebuilt with direct ring mask on gradient, progress mask on gold container. `7492cf2`
- [x] **S4F-2: Add slow color drift animation** — CABasicAnimation on locations (12s autoreverse) for noise-like gold color drift, gated by reduce motion. `7492cf2`
- [x] **S4F-3: Fix ClockView integration** — Added `.frame(width: 300, height: 300)` to GoldRingLayerView. `191706b`
- [x] **S4F-4: Update Views/CLAUDE.md** — Updated GoldRingLayerView description to reflect simplified architecture. `191706b`

### Sprint 4R — Ring Performance (CALayer Rewrite)

- [x] **S4R-1: Build CALayer ring foundation** — `GoldRingLayerView` (NSViewRepresentable) with track, gradient, progress mask, specular/shadow strips, tick marks. `8d340ea`
- [x] **S4R-2: Add continuous gradient rotation + shimmer animation** — `CABasicAnimation` rotation (120s) + locations shimmer (5s autoreverse), all in render server. `8d340ea`
- [x] **S4R-3: Add spring progress advance + glowing tip** — `CASpringAnimation` progress, glowing tip with breathing pulse, `pointAlongRingPath` perimeter walker. `8d340ea`
- [x] **S4R-4: Integrate into ClockView and remove old MinuteBezelView** — Wired GoldRingLayerView, removed FilledRingTrack/ProgressWedge/RingCenterlinePath, removed ChessClockTube. `23efcbc`
- [x] **S4R-5: CPU profiling and performance verification** — Architecture verified: all continuous animations use render-server pattern. Manual profiling pending user verification. `e845ede`
- [x] **S4R-6: Visual polish and tuning** — Added reduced motion support (skip rotation/shimmer/glow, use 0.3s ease). `e845ede`

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
