# TODO Done — Sprint 3.9: Visual Refinement (2026-02-23)

- [x] **S3.9-1: Update DesignTokens — pulse tokens, tube tokens, CTA sizing, remove shimmer** — ChessClockPulse, ChessClockTube, ChessClockCTADetail enums added; boardDetail 176→164; shimmerMinOpacity + anim.shimmer removed. `c044af5`
- [x] **S3.9-2: Rewrite MinuteBezelView — glass tube overlays, simplified ticks, remove shimmer** — FilledRingTrack parameterized with outerInset/innerInset; three tube overlay layers; tick marks simplified to single-layer gradient bars. `24fc694`
- [x] **S3.9-3: Add traveling pulse animation to MinuteBezelView** — RingCenterlinePath shape; TimelineView-driven dual pulses with layered glow (core + inner + outer); pulse speed scales with fill. `a12d36a`
- [x] **S3.9-4: Rewrite InfoPanelView — flanking icons, player indicators, smaller board/CTA** — Back/gear icons flank 164pt board; glassy white/black circle indicators; ELO right-aligned; CTA uses ChessClockCTADetail tokens. `9f05dca`
- [x] **S3.9-5: Update DESIGN.md — Face 1 ticks, Face 3 layout, token tables** — Gradient bar ticks replace halo description; flanking icons + 164pt board in Face 3; token tables updated. `326adc8`
- [x] **S3.9-6: Glass polish audit — GlassPillView + CTA pill** — Top-edge specular highlight on hover pill; 0.5pt white inner stroke on CTA pill; stroke opacity 0.25→0.30. `96fe5d1`
