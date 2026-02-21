# Done — v0.3.0

- [UI-1] Simplified ClockView to board + ring only by default; tap opens InfoPanelView
- [UI-2] Hover hint "Click for more info" overlay on ClockView
- [UI-3] Updated OnboardingOverlayView text for new UX
- [SCHED-1] Hourly game rotation: new game every hour (`hourlyIndex = daysSinceEpoch * 24 + hour24`)
- [SCHED-2] Fixed `fenIndex = hour12 - 1` so hour N shows the position N moves before checkmate
- [DATA-1] Added `finalMove` (UCI) field to `games.json` and `ChessGame` model
- [FEAT-1] ChessRules engine: FEN parsing, legal move generation, check detection, move application
- [FEAT-2] GuessService: guess state + UserDefaults persistence per hourly slot
- [FEAT-3] GuessMoveWindowManager: floating NSPanel for the puzzle window
- [FEAT-4] InfoPanelView: game metadata + Guess Move button + result badge
- [FEAT-5] InteractiveBoardView: drag/click piece interaction, legal move highlighting
- [FEAT-6] PromotionPickerView: 4-piece promotion overlay
- [FEAT-7] GuessMoveView: full puzzle screen; always shows positions[0] (mate-in-1 position)
- [FEAT-8] MoveResultView: correct/incorrect result + countdown to next puzzle
- [TEST-1] 22 new ChessRulesTests covering FEN parsing, move generation, check, real game spot-check
- [TEST-2] Updated GameSchedulerTests for hourly rotation and hour-based fenIndex
- [TEST-3] Updated ClockServiceTests for `positions[hour-1]` FEN mapping
