# TODO Done — Sprint 4P (Ring Performance)

> Archived 2026-02-25

### Sprint 4P — Ring Performance (Zero-Copy IOSurface + Timer Lifecycle) ✓

- [x] **S4P-1: GoldNoiseRenderer — IOSurface zero-copy + async rendering** — Rewrote Metal pipeline with double-buffered IOSurface-backed textures, async GPU completion, eliminated all CPU readback. `30ff743`
- [x] **S4P-2: GoldRingLayerView + ClockView — Timer lifecycle + IOSurface integration** — Added `isActive` parameter, timer pauses when popover closes, adapted to async IOSurface rendering. `5444fc4`
- [x] **S4P-3: ClockService — Lazy timer start** — Removed eager `startTimer()` from init(). `b74d3c7`
- [x] **S4P-4: Docs update** — Updated DESIGN.md and Views/CLAUDE.md with IOSurface architecture.
