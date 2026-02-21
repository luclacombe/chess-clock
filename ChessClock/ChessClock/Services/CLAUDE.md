# Services/

## Data Flow

```
Timer (1s) → ClockService.makeState(at: date)
                  └── GameScheduler.resolve(date:library:)
                            └── GameLibrary.shared.games
                  → ClockState (published to all views)
```

## GameLibrary.swift

Singleton: `GameLibrary.shared`. Loads `games.json` from `Bundle.main` exactly once at startup (`private init()`). If the file is missing or JSON is malformed, `games` is `[]` and an error is printed — the app continues with a placeholder.

**Do not instantiate directly** — `init` is private. Tests that need a library instance must use `GameLibrary.shared` (which reads the bundled file) or test via `GameScheduler` with a hand-built array.

## GameScheduler.swift

Pure static function — no state, no side effects.

```swift
static func resolve(date: Date, library: GameLibrary) -> (game: ChessGame, fenIndex: Int)?
```

**Algorithm:**
- Epoch: `2026-01-01` (local timezone)
- `daysSinceEpoch` = calendar days from epoch to `date` (negative for pre-epoch dates — handled by double-modulo)
- `halfDayIndex = daysSinceEpoch * 2 + (isAM ? 0 : 1)` — AM and PM each get a distinct index
- `gameIndex = ((halfDayIndex % count) + count) % count` — double-modulo keeps it positive
- `fenIndex = hour12 - 1` — maps hour 1→0, hour 12→11

Returns `nil` if `library.games` is empty. Same `date` always returns the same game (deterministic).

## ClockService.swift

`@MainActor final class`, `ObservableObject`. Owns the 1-second `Timer`.

- `@Published private(set) var state: ClockState` — the single source of truth for all views
- `makeState(at: Date = Date())` is **static** — testable without an instance, no `self` dependency
- On init: sets initial state synchronously, then starts `Timer.publish` → `sink` → `makeState`
- **Placeholder game** — `ClockService.placeholder` is a static `ChessGame` with 12 copies of the starting FEN. Used when `GameLibrary.shared.games` is empty (e.g. `games.json` not in bundle during development).

**Testing:** pass any `Date` to `makeState(at:)` to simulate arbitrary times. The test target uses this to verify hour/minute/isAM/game without waiting for real time.
