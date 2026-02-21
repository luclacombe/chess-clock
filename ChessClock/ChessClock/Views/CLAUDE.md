# Views/

All views are pure SwiftUI. They receive data as constructor arguments.

## Composition Hierarchy

```
ClockView (holds ClockService + GuessService)
  ├── [default] BoardView(fen:) + MinuteSquareRingView overlay
  │     └── Hover hint ("Click for more info") + tap → showInfo
  └── [on tap] InfoPanelView(state:guessService:onBack:)
        ├── BoardView preview
        ├── Game metadata (white, black, event, year, round)
        └── "Guess Move" button → GuessMoveWindowManager.shared.open(...)

GuessMoveWindowManager → NSPanel → GuessMoveView(state:guessService:)
  ├── [not guessed] InteractiveBoardView(fen:isFlipped:onMove:)
  │     └── PromotionPickerView overlay (when promotion needed)
  └── [on move] MoveResultView(guess:game:onDismiss:) overlay
```

`ClockView` is fixed at 312×312 (board + 12pt padding on each side). On first launch it overlays `OnboardingOverlayView`.

## File Notes

**ClockView.swift** — Root view. Two modes: `.clock` (board + ring) and `.info` (InfoPanelView). Hover shows "Click for more info" overlay. Tap switches to info mode. Owns `@StateObject GuessService`.

**BoardView.swift** — 8×8 grid via nested `ForEach`. Lichess colors. `isFlipped` inverts row order for PM (Black's perspective).

**InteractiveBoardView.swift** — Extends BoardView with piece interaction. Single `DragGesture` on the container maps touch coordinates to squares. Tap gesture on individual squares for click-select. Selected piece and legal destinations are highlighted. Promotion picker appears as an overlay when a pawn reaches the back rank. Calls `onMove` with the completed `ChessMove`.

**InfoPanelView.swift** — Shows mini board preview + game metadata + "Guess Move" button. Shows result badge if already guessed.

**GuessMoveView.swift** — The full puzzle screen in the floating window. If already guessed, shows the static board and a tap-for-result badge; the interactive board is replaced. Calls `GuessService.recordGuess` on move.

**MoveResultView.swift** — Full-screen overlay shown after a guess. Shows correct/incorrect, the actual move, game info, and a live countdown to the next puzzle.

**PromotionPickerView.swift** — Overlay with 4 piece buttons (Q, R, B, N). Calls `onPick(PieceType)`.

**OnboardingOverlayView.swift** — First-launch explanation: board = 1 move before checkmate, ring = minutes, new puzzle every hour, tap to access info/guess.

**PieceView.swift** — `Image(piece.imageName).resizable().scaledToFit()`.

**MinuteSquareRingView.swift** — Clockwise square-perimeter ring. Gold stroke, 5pt wide, square lineCap.
