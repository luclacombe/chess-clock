# TODO Done — Sprint 3.5: Ring Polish + Detail Fix (2026-02-23)

- [x] **S3.5-1: Update DesignTokens — corner radii, ring geometry, tick sizes** — outer 14→18, ring 9→12, board 4→8, ringInset 5→6, bezelGap 1→0, tickLength 6→8, tickWidth 2→2.5, added shimmer animation token.
- [x] **S3.5-2: Add `second` to ClockState + ClockService** — ClockState gains `second: Int`, ClockService extracts `.second` from date components.
- [x] **S3.5-3: Rewrite MinuteBezelView — continuous sweep, shimmer, ticks** — Progress now `(minute*60+second)/3600`, linear interpolation per second, shimmer pulse (opacity 0.78↔1.0, 2.5s), tick dark halo for contrast.
- [x] **S3.5-4: Upgrade GlassPillView — shadow + inner stroke** — Drop shadow + tight shadow + 0.5pt white inner stroke for glass-edge effect.
- [x] **S3.5-5: Fix InfoPanelView — header, CTA floating pill** — Header gains 16pt padding + 13pt icons + 28×28 tap targets. CTA redesigned as floating capsule pill below board.
- [x] **S3.5-6: Update ClockView — pass second, detail ring styling** — Passes second to MinuteBezelView, detail ring 20% opacity + 0.5pt blur.
- [x] **S3.5-7: Update DESIGN.md — spec changes** — All sections updated: radii, dimensions, ring animation, pill, CTA, Sprint 3.5 section added.
