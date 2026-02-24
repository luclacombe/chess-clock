# Progress Log

> Append a new entry at the start of each development session.
> Run `/sync` to auto-update this file.

---

## 2026-02-24 — Sprint 4R: Ring Performance (CALayer Rewrite)
**Goal:** Replace SwiftUI minute ring with Core Animation for <0.5% CPU and Apple-quality animation
**Completed:**
- S4R-1 GoldRingLayerView foundation — NSViewRepresentable, CAGradientLayer(.conic) with 17 gold stops, even-odd ring path, progress mask, specular/shadow strips, tick marks
- S4R-2 Continuous animations — gradient rotation (120s), locations shimmer (5s autoreverse), all in render server
- S4R-3 Spring progress + glow — CASpringAnimation wedge advance, 16pt glowing tip with breathing pulse, pointAlongRingPath perimeter walker
- S4R-4 Integration — ClockView wired to GoldRingLayerView, old shapes removed (FilledRingTrack, ProgressWedge, RingCenterlinePath), ChessClockTube removed
- S4R-5 Profiling — architecture verified for render-server execution
- S4R-6 Reduced motion — skip rotation/shimmer/glow pulse when accessibility reduce motion is on
**Blocked / Skipped:**
- S4R-5 manual CPU measurement requires running app + Activity Monitor (user to verify)
- S4R-6 visual tuning of animation parameters requires visual inspection (user to fine-tune rotation speed, shimmer intensity, spring feel)
**Agents deployed:** 1 (foreground, S4R-1/2/3)
**Next session:** Run app and verify ring visuals + CPU. Run `/plan-sprint` for next sprint.
**Notes:**
- S4R-2 and S4R-3 share a file — ran sequentially in one agent instead of parallel
- Removed 385 lines of old SwiftUI ring code, added 520 lines of CALayer implementation
- ChessClockAnimation.ring token kept (still used elsewhere); ChessClockTube removed

---

## 2026-02-24 — Sprint 3.95: Ring Fix
**Goal:** Fix the broken golden minute ring animation from Sprint 3.9
**Completed:**
- S3.95-1: Diagnosed root causes — `.animation` on root ZStack fighting TimelineView, erratic sin()-based pulse math, 6 blur ops per frame
- S3.95-2: Scoped `.animation(.linear, value: second)` to fill group only — eliminated animation system conflict
- S3.95-3: Replaced TimelineView dual-pulse system with 3 diffused energy pulses (constant-speed, heavily blurred, fade-in entry, ProgressWedge mask for diagonal end)
- S3.95-4: Removed ChessClockPulse enum and ChessClockTube.centerHighlight from DesignTokens
- S3.95-5: Simplified glass tube overlays to 2 layers (inner specular + outer shadow)
- S3.95-6: Added board inner shadow (6pt stroke, 4pt blur, 22% opacity) for 3D depth
- S3.95-7: Brightened tick marks (0.70/0.30 gradient) with centered shadow for raised/embossed look
- S3.95-8: Updated DESIGN.md with learnings and final pulse parameters
**Blocked / Skipped:**
- None
**Next session:**
- Plan Sprint 4 (Puzzle Face)
**Notes:**
- Key learning: never apply `.animation` broadly to a ZStack containing TimelineView — scope it to only the layers that need it
- Energy pulse aesthetic achieved through heavy blur (5-8pt), `.round` lineCap, multiple overlapping speeds, and short pulse widths (4-8%) for contrast against gold base

## Template

```
## YYYY-MM-DD — Session N
**Goal:** [What we set out to do]
**Completed:**
- [Task ID] Description of what was done
**Blocked / Skipped:**
- [Task ID] Reason
**Next session:**
- Start at: [Task ID] [Task name]
**Notes:**
- [Any context to carry forward]
```

---
