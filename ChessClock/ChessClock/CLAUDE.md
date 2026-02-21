# ChessClock — Source Root

## Entry Point

`ChessClockApp.swift` — `@main`. Creates a single `ClockService` as `@StateObject` and wraps it in a `MenuBarExtra(.window)` with a `crown.fill` SF Symbol icon. The window content is `ClockView(clockService:)`.

No dock icon. No `NSApplicationMain`. No AppKit — pure SwiftUI throughout.

## Subdirectory CLAUDE.md Files

- `Views/CLAUDE.md` — view composition, data flow into views, rendering details
- `Models/CLAUDE.md` — data types, FEN parsing, positions array indexing
- `Services/CLAUDE.md` — service layer, timer, game scheduling, data flow

## Unused File

`ContentView.swift` — legacy piece-grid test view left over from project setup. Not referenced anywhere. Safe to delete.

## Key Constraint

All views receive data via `ClockService.state: ClockState` — they are pure display, no business logic. Nothing in Views/ or Models/ imports Combine or touches a Timer.
