# Services/

## Data Flow

```
Timer (1s) → ClockService.makeState(at: date)
                  └── GameScheduler.resolve(date:library:seed:)
                            └── GameLibrary.shared.games
                  → ClockState (published to all views)
```

## ClockService.swift

`@MainActor final class`, `ObservableObject`. Owns the 1-second `Timer`.

- `@Published private(set) var state: ClockState` — the single source of truth for all views
- `makeState(at: Date = Date())` is **static** — testable without an instance, no `self` dependency
- On init: sets initial state synchronously, then starts `Timer.publish(every: 1.0) → sink → makeState`
- **Placeholder game** — `ClockService.placeholder` is a static `ChessGame` with 12 copies of the starting FEN. Used when `GameLibrary.shared.games` is empty (e.g. `games.json` not in bundle during development).

**Testing:** pass any `Date` to `makeState(at:)` to simulate arbitrary times. The test target uses this to verify hour/minute/isAM/game without waiting for real time.

## GameLibrary.swift

Singleton: `GameLibrary.shared`. Loads `games.json` from `Bundle.main` exactly once at startup (`private init()`). If the file is missing or JSON is malformed, `games` is `[]` and an error is printed — the app continues with a placeholder.

**Do not instantiate directly** — `init` is private. Tests that need a library instance must use `GameLibrary.shared` or test via `GameScheduler` with a hand-built array.

## GameScheduler.swift

Pure static function — no state, no side effects.

```swift
static func resolve(date: Date, library: GameLibrary, seed: Int? = nil) -> (game: ChessGame, fenIndex: Int)?
```

**Algorithm (hourly rotation):**
- Epoch: `2026-01-01` (local timezone)
- `daysSinceEpoch` = calendar days from epoch to `date`
- `hourlyIndex = daysSinceEpoch * 24 + hour24` — a new game is selected every hour
- `gameIndex = (((hourlyIndex + seed) % count) + count) % count` — double-modulo keeps it positive
- `seed` — per-device random value stored in `UserDefaults` under key `"deviceGameSeed"`. First launch generates and saves it. `getOrCreateSeed()` handles this. Pass an explicit seed in tests.
- AM (0–11) pulls from games where `mateBy == "white"`, PM (12–23) from `mateBy == "black"`. Falls back to full library if the filtered pool is empty.
- `fenIndex = hour12 - 1` — hour 1 → `positions[0]` (mate in 1), hour 12 → `positions[11]`

Returns `nil` if `library.games` is empty. Same `(date, seed)` always returns the same game.

## PuzzleEngine.swift

Pure value-type (`struct`) puzzle engine. No side effects, no persistence. Drives the multi-move puzzle.

**Key properties:**
- `startPositionIndex: Int` — `(hour - 1) * 2` — the positions[] index where the puzzle begins (mating side to move)
- `currentPositionIndex: Int` — advances toward 0 as moves are played
- `triesUsed: Int` — starts at 1, incremented on wrong moves; max 3
- `isComplete: Bool`, `succeeded: Bool`
- `isUserTurn: Bool` — checks `ChessRules.parseState(fen:)` to determine which side has the move
- `expectedMove: String` — `game.moveSequence[currentPositionIndex]`

**API:**
- `advancePastOpponentMoves() -> [(uci, fen)]` — auto-plays consecutive opponent moves; returns pairs for UI animation
- `submit(uci:) -> SubmitResult` — validates user move; returns `.correctContinue`, `.success`, `.wrong`, or `.failed`

`SubmitResult.wrong` resets the engine to `startPositionIndex` internally and returns the opponent auto-plays already applied at reset.

## GuessService.swift

`@MainActor final class ObservableObject`. Tracks puzzle attempts and all-time stats. Persists to `UserDefaults`.

**Published state:**
- `engine: PuzzleEngine?` — nil when puzzle not started or complete
- `result: PuzzleResult?` — non-nil if done this hour (`PuzzleResult(succeeded:triesUsed:)`)
- `stats: PuzzleStats` — `winsOnFirstTry`, `winsOnSecondTry`, `winsOnThirdTry`, `losses`
- `currentHourKey: String` — `"YYYY-M-D-H"` identifying the current puzzle slot

**Key API:**
- `startPuzzle(game:hour:) -> [(uci, fen)]?` — call when entering puzzle mode. Returns `nil` if already completed this hour; returns initial opponent auto-plays otherwise.
- `submitMove(uci:) -> PuzzleEngine.SubmitResult?` — forwards the user's move to the engine; finalizes and persists result on terminal outcomes.
- `secondsUntilNextHour: Int` — countdown for the result overlay.

**UserDefaults keys:**
- `"chessclock_result_{key}"` — JSON-encoded `PuzzleResult` per hourly slot
- `"chessclock_stats_v1"` — JSON-encoded `PuzzleStats`
- `"deviceGameSeed"` — per-device `Int` seed for `GameScheduler`
- `"onboardingDismissed"` — bool flag managed by `OnboardingService`

**Legacy API (kept for backward compatibility, remove after views update):** `Guess`, `guess`, `hasGuessed`, `recordGuess`.

Listens to `ClockService.$state` to detect hour rollovers and clear the engine.

## FloatingWindowManager.swift

`@MainActor final class`. Singleton: `FloatingWindowManager.shared`.

- Intercepts right-click on the `NSStatusBarWindow` via `NSEvent.addLocalMonitorForEvents(matching: .rightMouseDown)` and shows a context menu ("Open as Floating Window" + "Quit Chess Clock").
- `NSMenuDelegate` clears the menu on close so left-click still shows the MenuBarExtra popover.
- `showFloatingWindow()` opens an `NSPanel` (titled, closable, resizable, non-activating, floating level) hosting a `ClockView` with its own `ClockService` instance.
- `setup()` must be called once (from `ChessClockApp`) to install the event monitor.

## HotkeyService.swift

Uses Carbon `InstallEventHandler` + `RegisterEventHotKey` to register **Option+Space** as a global hotkey. On trigger, locates the `NSStatusBarWindow`'s status item via KVC (`"statusItem"`) and calls `performClick(nil)` to toggle the popover. `register()` / `unregister()` are called by `ChessClockApp`.

## ChessRules.swift

Legal chess move generation. No evaluation — purely rules, not an engine.

- `ChessSquare(rank:file:)` — 1-indexed (rank 1–8, file a=1 h=8). Has `rankIndex`/`fileIndex` matching `BoardPosition.squares` layout. Static factory `ChessSquare.from(rankIndex:fileIndex:)` for 0-indexed conversion.
- `ChessMove(from:to:promotion:)` — UCI via `.uci` property. Parse with `ChessMove.from(uci:)`.
- `GameState` — board + activeColor + castlingRights + enPassant square. `piece(at:)` helper.
- `ChessRules.parseState(fen:)` — parse full FEN → `GameState?`.
- `ChessRules.legalMoves(in:)` — all legal moves for the active side.
- `ChessRules.isLegal(_:in:)` — check a specific move.
- `ChessRules.apply(_:to:)` — apply a move, returns new `GameState`.
- `ChessRules.isAttacked(_:by:in:)` — ray-casting attack detection.

## OnboardingService.swift

Pure static struct. `shouldShowOnboarding: Bool` reads `UserDefaults` key `"onboardingDismissed"`. `dismissOnboarding()` sets it to `true`.
