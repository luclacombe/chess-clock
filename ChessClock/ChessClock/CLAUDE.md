# ChessClock — Source Root

## Entry Point

`ChessClockApp.swift` — `@main`. Creates a single `ClockService` as `@StateObject` and wraps it in a `MenuBarExtra(.window)` with a `crown.fill` SF Symbol icon. The window content is `ClockView(clockService:)`. On appear, registers `HotkeyService` (Option+Space global hotkey) and calls `FloatingWindowManager.shared.setup(clockService:)` to install the right-click context menu.

No dock icon. No `NSApplicationMain`. Pure SwiftUI throughout (except `FloatingWindowManager` and `HotkeyService` which require AppKit/Carbon, and `GoldRingLayerView`/`PuzzleRingView`/`ReplayBackgroundView` which use `NSViewRepresentable` + CALayer + Metal).

## Design Tokens

`DesignTokens.swift` — Single source of truth for all UI constants. Defines enums: `ChessClockColor` (colors), `ChessClockType` (fonts), `ChessClockSpace` (spacing), `ChessClockRadius` (corner radii), `ChessClockSize` (dimensions), `ChessClockAnimation` (animation curves), `ChessClockTiming` (feedback durations), `ChessClockCTADetail` (button metrics). No magic numbers in views — all values sourced from here.

## Subdirectory CLAUDE.md Files

- `Views/CLAUDE.md` — view composition, data flow into views, rendering details
- `Models/CLAUDE.md` — data types, FEN parsing, positions array indexing
- `Services/CLAUDE.md` — service layer, timer, game scheduling, data flow

## View Modes

`ClockView` drives all UI through a private `ViewMode` enum:

```
ViewMode.clock    → BoardView + GoldRingLayerView overlay (default)
ViewMode.info     → InfoPanelView (game metadata + CTA)
ViewMode.puzzle   → GuessMoveView + PuzzleRingView (inline puzzle, no floating window)
ViewMode.replay   → GameReplayView + ReplayBackgroundView (full game review)
ViewMode.settings → SettingsPlaceholderView ("Coming Soon")
```

`WindowObserver` (an `NSViewRepresentable`) resets `ViewMode` to `.clock` whenever the MenuBarExtra popover becomes key (i.e., user reopens it). Also clears all onboarding overlays.

## Key Constraint

All views receive data via `ClockService.state: ClockState` — they are pure display, no business logic. Nothing in Views/ or Models/ imports Combine or touches a Timer.
