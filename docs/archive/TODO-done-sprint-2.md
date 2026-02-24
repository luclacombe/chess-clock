# TODO Done — Sprint 2: Clock + Glance (2026-02-23)

- [x] **S2-1: Update DesignTokens.swift — concentric radius system + ring dimensions** — outer=14, ring=10, board=4, ringStroke=8, ringInset=4, bezelGap=2. `bdeb036`
- [x] **S2-2: Update MinuteBezelView — concentric corner radius from token** — RingShape uses `ChessClockRadius.ring` (10pt). `bdeb036`
- [x] **S2-3: Update BoardView — token-based clip radius and color references** — Uses `ChessClockRadius.board` and `ChessClockColor` tokens. `bdeb036`
- [x] **S2-4: Build GlassPillView** — Reusable `.ultraThinMaterial` container with pill radius and space tokens. `b5ad8ac`
- [x] **S2-5: Build Glance face + apply outer clip in ClockView** — 14pt outer clip, blurred board + GlassPillView on hover, deleted old hover text + 6 tests. `b0addec`
