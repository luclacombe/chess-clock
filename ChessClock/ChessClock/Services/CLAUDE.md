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

**Algorithm (v1.0 — hourly rotation):**
- Epoch: `2026-01-01` (local timezone)
- `daysSinceEpoch` = calendar days from epoch to `date` (negative for pre-epoch dates — handled by double-modulo)
- `hourlyIndex = daysSinceEpoch * 24 + hour24` — a new game is selected every hour
- `gameIndex = ((hourlyIndex % count) + count) % count` — double-modulo keeps it positive
- `fenIndex = hour12 - 1` — hour 1 → `positions[0]` (mate in 1), hour 6 → `positions[5]` (6 moves before checkmate), hour 12 → `positions[11]`
- AM (0–11) pulls from games where `mateBy == "white"`, PM (12–23) from `mateBy == "black"`

Returns `nil` if `library.games` is empty. Same `date` always returns the same game (deterministic).

## ChessRules.swift

Legal chess move generation. No evaluation; this is purely rules, not an engine.

- `ChessSquare(rank:file:)` — 1-indexed (rank 1–8, file a=1 h=8). Has `rankIndex`/`fileIndex` matching `BoardPosition.squares` layout.
- `ChessMove(from:to:promotion:)` — UCI via `.uci` property. Parse with `ChessMove.from(uci:)`.
- `GameState` — board + activeColor + castlingRights + enPassant square.
- `ChessRules.parseState(fen:)` — parse full FEN → `GameState?`.
- `ChessRules.legalMoves(in:)` — all legal moves for the active side.
- `ChessRules.isLegal(_:in:)` — check a specific move.
- `ChessRules.apply(_:to:)` — apply a move, returns new `GameState`.
- `ChessRules.isAttacked(_:by:in:)` — ray-casting attack detection.

## GuessService.swift

`@MainActor final class ObservableObject`. Tracks and persists the user's guess for each hourly puzzle.

- `currentHourKey: String` — `"YYYY-M-D-H"` string identifying the current puzzle slot.
- `guess: Guess?` — nil if not yet guessed this hour; persisted to `UserDefaults`.
- `hasGuessed: Bool` — convenience computed property.
- `secondsUntilNextHour: Int` — countdown to next puzzle.
- `recordGuess(move:isCorrect:actualMove:)` — saves guess for current hour.
- Listens to `ClockService.$state` to detect hour rollovers and clear state.

## GuessMoveWindowManager.swift

Opens/manages the floating `NSPanel` for the interactive "Guess Move" puzzle.
- `GuessMoveWindowManager.shared.open(state:guessService:)` — opens or brings forward the panel.

## ClockService.swift

`@MainActor final class`, `ObservableObject`. Owns the 1-second `Timer`.

- `@Published private(set) var state: ClockState` — the single source of truth for all views
- `makeState(at: Date = Date())` is **static** — testable without an instance, no `self` dependency
- On init: sets initial state synchronously, then starts `Timer.publish` → `sink` → `makeState`
- **Placeholder game** — `ClockService.placeholder` is a static `ChessGame` with 12 copies of the starting FEN. Used when `GameLibrary.shared.games` is empty (e.g. `games.json` not in bundle during development).

**Testing:** pass any `Date` to `makeState(at:)` to simulate arbitrary times. The test target uses this to verify hour/minute/isAM/game without waiting for real time.
