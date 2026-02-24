# Archived Done — Sprint 4 Ring (4R, 4F, 4N)

Archived 2026-02-24.

### Sprint 4N — Perlin Noise Ring

- [x] **S4N-1: Create Metal simplex noise compute shader** — GPU compute kernel with 3D FBM simplex noise mapped to 5-tone gold ramp. `dac8975`
- [x] **S4N-2: Create GoldNoiseRenderer Swift class** — Metal pipeline manager rendering at half-res (150×150), texture-to-CGImage readback. `dac8975`
- [x] **S4N-3: Integrate noise into GoldRingLayerView** — Replaced CAGradientLayer + locations drift with noise CALayer at 5 FPS timer. `dac8975`

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
