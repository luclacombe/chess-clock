# Views/

All views are pure SwiftUI. They receive data as constructor arguments — no `@StateObject`, no service references except in `ClockView` which holds `@ObservedObject var clockService: ClockService`.

## Composition Hierarchy

```
ClockView
  ├── BoardView(fen:)
  │     └── [overlay] MinuteSquareRingView(minute:boardSize:)
  ├── AMPMView(isAM:)
  └── GameInfoView(game:)
```

`ClockView` uses a `GeometryReader` inside the `BoardView` overlay to pass the board's actual rendered width to `MinuteSquareRingView` so the ring aligns exactly with the board edge.

## File Notes

**ClockView.swift** — Root view. VStack with 10pt spacing. Board + ring overlay on top, AMPMView, then GameInfoView. Fixed minimum frame: 300×380.

**BoardView.swift** — 8×8 grid via nested `ForEach`. Uses `GeometryReader` to derive `squareSize = width / 8`. Board colors: lichess palette — light `(240, 217, 181)`, dark `(181, 136, 99)`. `rankIndex 0` = rank 8 (top of board, black's home rank). Piece images rendered by `PieceView` with 5% padding inside each square.

**PieceView.swift** — Single `Image(piece.imageName).resizable().scaledToFit()`. Image names come from `ChessPiece.imageName` (e.g. `"wK"`, `"bP"`). These map to the cburnett PNG assets in `Assets.xcassets`.

**MinuteSquareRingView.swift** — Clockwise square-perimeter ring. `progress = minute / 60.0`. Starts at top-center `(midX, minY)` and traces 5 segments: top-center → top-right → bottom-right → bottom-left → top-left → top-center. Stroke: gold `(1.0, 0.76, 0.0)`, lineWidth 5, square lineCap. `MinuteRingShape` conforms to `Shape` — the geometry is in `path(in:)`.

**GameInfoView.swift** — Two text lines: (1) `"White (ELO) vs Black (ELO)"` — ELO omitted when `"?"` or empty; (2) `"Tournament Year"` — year formatted as `String(game.year)` (no locale comma). Both lines use `minimumScaleFactor(0.7)` and `lineLimit(1)` to handle long names.

**AMPMView.swift** — `HStack` with SF Symbol + text. AM: `sun.max.fill` in yellow. PM: `moon.fill` in `(0.4, 0.4, 0.9)` blue-purple.
