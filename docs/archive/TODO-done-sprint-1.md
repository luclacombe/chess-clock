# TODO Done — Sprint 1: Foundation (2026-02-23)

- [x] **S1-1: Create DesignTokens.swift** — All color, typography, spacing, radius, dimension, and animation constants. `050ed42`
- [x] **S1-2: Replace cburnett PNGs with Merida gradient SVGs** — 12 SVGs downloaded from Lichess, PNGs deleted, Contents.json updated. `c2f9f69`
- [x] **S1-3: Add 6pt corner radius to BoardView** — `.clipShape(RoundedRectangle(cornerRadius: 6))`. `43cf99d`
- [x] **S1-4: Build MinuteBezelView** — Custom RingShape, gold fill with gray track, 4 cardinal tick marks, animated. `bd1979f`
- [x] **S1-5: Create PlayerNameFormatter** — PGN name inversion, initial handling, ELO formatting. `43cf99d`
- [x] **S1-6: Update ClockView — lock 300×300 frame and wire MinuteBezelView** — Fixed frame, removed padding, replaced MinuteSquareRingView. `4d8163d`
- [x] **S1-7: Delete ContentView.swift** — Legacy piece-grid test view removed. `43cf99d`
- [x] **S1-8: Delete MoveArrowView.swift and remove all usages** — File deleted, GameReplayView cleaned, 8 arrow tests removed (32 remain). `3c8c260`
