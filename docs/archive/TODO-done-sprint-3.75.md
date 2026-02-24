# TODO Done — Sprint 3.75: Ring Geometry + Detail Face Fix (2026-02-23)

- [x] **S3.75-1: Update DesignTokens — gradient colors, shimmer amplitude, detail board size** — accentGoldLight/accentGoldDeep, ringGradient, shimmer 1.8s/0.50↔1.0, boardDetail 196→176, ringOuterEdge/ringInnerEdge/shimmerMinOpacity. `cc54fff`
- [x] **S3.75-2: Rewrite MinuteBezelView — filled ring shape, gradient, enhanced shimmer, flat ticks** — FilledRingTrack (even-odd fill) + ProgressWedge mask, gold gradient, .butt lineCap ticks at ring edges. `a65333b`
- [x] **S3.75-3: Add board edge bevel to BoardView** — 0.5pt dark strokeBorder overlay for ring-board definition. `16995a7`
- [x] **S3.75-4: Fix InfoPanelView layout — top padding, reduced board, tighter spacing** — 8pt top padding, 20pt header padding, 2pt board spacing, 6pt CTA spacing. `390bb0d`
- [x] **S3.75-5: Hide ring completely in Detail face** — Ring opacity 0.0 for .info, removed blur. `1eb003c`
- [x] **S3.75-6: Update DESIGN.md with Sprint 3.75 spec changes** — All tokens, layout, animation changes documented.
