# ChessClock — Source Root

## Entry Point

`ChessClockApp.swift` — `@main`. Creates a single `ClockService` as `@StateObject` and wraps it in a `MenuBarExtra(.window)` with a `crown.fill` SF Symbol icon. The window content is `ClockView(clockService:)`. Also calls `FloatingWindowManager.shared.setup()` and registers `HotkeyService` for the Option+Space global hotkey.

No dock icon. No `NSApplicationMain`. No AppKit — pure SwiftUI throughout (except `FloatingWindowManager` and `HotkeyService` which require AppKit/Carbon).

## Subdirectory CLAUDE.md Files

- `Views/CLAUDE.md` — view composition, data flow into views, rendering details
- `Models/CLAUDE.md` — data types, FEN parsing, positions array indexing
- `Services/CLAUDE.md` — service layer, timer, game scheduling, data flow

## View Modes

`ClockView` drives all UI through a private `ViewMode` enum:

```
ViewMode.clock  → BoardView + MinuteSquareRingView overlay (default)
ViewMode.info   → InfoPanelView (game metadata + CTA)
ViewMode.puzzle → GuessMoveView (inline puzzle, no floating window)
ViewMode.replay → GameReplayView (full game review)
```

`WindowObserver` (an `NSViewRepresentable`) resets `ViewMode` to `.clock` whenever the MenuBarExtra popover becomes key (i.e., user reopens it).

## Unused File

`ContentView.swift` — legacy piece-grid test view left over from project setup. Not referenced anywhere. Pending deletion in TODO.md task S1-7.

## Key Constraint

All views receive data via `ClockService.state: ClockState` — they are pure display, no business logic. Nothing in Views/ or Models/ imports Combine or touches a Timer.
