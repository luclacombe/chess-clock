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
- **Reference counting:** `resume()` increments refCount and starts timer if first consumer; `pause()` decrements and stops timer when no consumers remain. Used to avoid running the timer while the popover is hidden.
- **Caching:** `cachedHour24` and `cachedResolution` avoid re-resolving the game every second — only recomputes when the hour changes.
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
- `submit(uci:) -> SubmitResult` — validates user move; returns `.correctContinue(opponentMoves:)`, `.success`, `.wrong(triesRemaining:resetAutoPlays:)`, or `.failed`

`SubmitResult.wrong` resets the engine to `startPositionIndex` internally and returns the opponent auto-plays already applied at reset.

## GuessService.swift

`@MainActor final class ObservableObject`. Tracks puzzle attempts and all-time stats. Persists to `UserDefaults`.

**Published state:**
- `engine: PuzzleEngine?` — nil when puzzle not started or complete
- `result: PuzzleResult?` — non-nil if done this hour (`PuzzleResult(succeeded:triesUsed:)`)
- `stats: PuzzleStats` — `winsOnFirstTry`, `winsOnSecondTry`, `winsOnThirdTry`, `losses`; computed `totalPlayed`
- `currentHourKey: String` — `"YYYY-M-D-H"` identifying the current puzzle slot

**Key API:**
- `init(clockService: ClockService)` — subscribes to clock state changes for hour rollover detection
- `startPuzzle(game:hour:) -> [(uci, fen)]?` — call when entering puzzle mode. Returns `nil` if already completed this hour; returns initial opponent auto-plays otherwise.
- `submitMove(uci:) -> PuzzleEngine.SubmitResult?` — forwards the user's move to the engine; finalizes and persists result on terminal outcomes.
- `secondsUntilNextHour: Int` — countdown for the result overlay.
- `hasResult: Bool` — whether puzzle completed this hour.

**UserDefaults keys (managed across services):**
- `"chessclock_result_{key}"` — JSON-encoded `PuzzleResult` per hourly slot
- `"chessclock_stats_v1"` — JSON-encoded `PuzzleStats`
- `"deviceGameSeed"` — per-device `Int` seed for `GameScheduler`
- `"welcomeScreenShown"` — Stage 0 flag
- `"onboardingDismissed"` — Stage A flag
- `"infoPanelOnboardingSeen"` — Stage B flag
- `"replayNudgeSeen"` — Stage C flag
- `"replayOnboardingSeen"` — Stage D flag
- `"puzzleOnboardingSeen"` — Stage E flag

**Struct mutation pattern:** `var eng = engine!; eng.submit(...); engine = eng` — PuzzleEngine is a value type, requires copy-mutate-assign for SwiftUI observable compatibility.

Listens to `ClockService.$state` to detect hour rollovers and clear the engine. Caches `lastHourAMKey` to avoid Calendar+string formatting on most ticks.

## FloatingWindowManager.swift

`@MainActor final class`. Singleton: `FloatingWindowManager.shared`.

- `setup(clockService:)` must be called once (from `ChessClockApp`) to install the event monitor and store the ClockService reference.
- Intercepts right-click on the `NSStatusBarWindow` via `NSEvent.addLocalMonitorForEvents(matching: .rightMouseDown)` and shows a context menu ("Open as Floating Window" + "Quit Chess Clock").
- `NSMenuDelegate` clears the menu on close so left-click still shows the MenuBarExtra popover.
- `showFloatingWindow()` opens a `BorderlessPanel` (NSPanel subclass, borderless, non-activating, floating level, movable by background, available on all spaces) hosting a `ClockView`.
- `FloatingWindowContent` wraps `ClockView` with hover-visible close/minimize buttons.

## HotkeyService.swift

Uses Carbon `InstallEventHandler` + `RegisterEventHotKey` to register **Option+Space** as a global hotkey. On trigger, locates the `NSStatusBarWindow`'s status item via KVC (`NSSelectorFromString("statusItem")`) and calls `performClick(nil)` to toggle the popover. `register()` / `unregister()` are called by `ChessClockApp`.

## ChessRules.swift

Legal chess move generation. No evaluation — purely rules, not an engine.

- `ChessSquare(rank:file:)` — 1-indexed (rank 1–8, file a=1 h=8). Has `rankIndex`/`fileIndex` matching `BoardPosition.squares` layout. Static factory `ChessSquare.from(rankIndex:fileIndex:)` for 0-indexed conversion. `from(algebraic:)` parses "e4".
- `ChessMove(from:to:promotion:)` — UCI via `.uci` property. Parse with `ChessMove.from(uci:)`.
- `CastlingRights` — tracks all four castling rights; static `.all`, `.none`.
- `GameState` — board + activeColor + castlingRights + enPassant square. `piece(at:)` helper.
- `ChessRules.parseState(fen:)` — parse full FEN → `GameState?`.
- `ChessRules.legalMoves(in:)` — all legal moves for the active side.
- `ChessRules.legalMoves(from:to:in:)` — filter legal moves by from/to squares.
- `ChessRules.isLegal(_:in:)` — check a specific move.
- `ChessRules.apply(_:to:)` — apply a move, returns new `GameState` (handles castling, en passant, promotion).
- `ChessRules.isInCheck(_:in:)` — check detection by color.
- `ChessRules.isAttacked(_:by:in:)` — ray-casting attack detection.
- `ChessRules.kingSquare(of:in:)` — find king position.

## SANFormatter.swift

Converts UCI move strings to Standard Algebraic Notation (SAN). Pure utility, no state.

- `SANFormatter.format(uci:in:) -> String` — converts UCI (e.g. `"e2e4"`) to SAN (e.g. `"e4"`).
- Handles castling (`O-O`, `O-O-O`), captures (`x`), promotion (`=Q`), disambiguation (file, rank, or both), check (`+`), and checkmate (`#`).
- Falls back to raw UCI if parsing fails.
- Used by `GameReplayView` to display move notation.

## PlayerNameFormatter.swift

Converts PGN "Last,First" names to readable format with optional ELO.

- `PlayerNameFormatter.format(pgn:elo:) -> String`
- `"Kasparov,Garry"` + `"2851"` → `"Garry Kasparov · 2851"`
- Single-letter first names get a period: `"Kramnik,V"` → `"V. Kramnik"`
- ELO of `"?"` or empty is omitted.
- Used by `InfoPanelView`.

## OnboardingService.swift

Pure static struct. Manages 6 progressive onboarding stages via `UserDefaults` bool flags:

| Stage | Key | Trigger |
|---|---|---|
| 0 | `welcomeScreenShown` | First launch (welcome screen) |
| A | `onboardingDismissed` | Clock tour (3-step) |
| B | `infoPanelOnboardingSeen` | First info panel visit |
| C | `replayNudgeSeen` | First puzzle completion |
| D | `replayOnboardingSeen` | First replay visit |
| E | `puzzleOnboardingSeen` | First puzzle visit |

Each stage has `shouldShowStageX: Bool` and `dismissStageX()`. Backward-compat aliases `shouldShowOnboarding` / `dismissOnboarding` map to Stage A. `resetAll()` clears all 6 flags (testing).

**Debug mode:** `debugReplay: Bool` (static let) — when `true`, replays onboarding from Stage 0 every popover open. Toggle to `false` for production.

## Service Dependency Graph

```
ClockService
  ├── GameScheduler.resolve()
  │   └── GameLibrary.shared
  └── (observed by GuessService)

GuessService
  ├── PuzzleEngine (creates and mutates)
  ├── ClockService.$state (observes for hour rollovers)
  └── UserDefaults (results, stats)

FloatingWindowManager
  └── ClockService (passed in setup())

HotkeyService
  └── NSStatusItem (via KVC)

PuzzleEngine → ChessRules
SANFormatter → ChessRules
PlayerNameFormatter → (none)
OnboardingService → UserDefaults
GameLibrary → Bundle
ChessRules → (none)
```
