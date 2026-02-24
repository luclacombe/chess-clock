# Models/

Plain value types. No networking, no timers, no Combine. All `Codable` structs match the `games.json` schema exactly.

## ChessGame.swift

Codable struct. Full field list:

| Field | Type | Notes |
|---|---|---|
| `white`, `black` | `String` | PGN format: `"Kasparov,G"` |
| `whiteElo`, `blackElo` | `String` | `"2851"` or `"?"` for historical/unknown |
| `tournament` | `String` | |
| `year` | `Int` | |
| `month` | `String?` | e.g. `"January"` — optional |
| `round` | `String?` | optional |
| `mateBy` | `String` | `"white"` or `"black"` — who delivers the final checkmate |
| `finalMove` | `String` | UCI of the checkmate move, e.g. `"e7e8q"` |
| `positions` | `[String]` | **23 FEN strings** — see indexing below |
| `moveSequence` | `[String]` | 23 UCIs; `moveSequence[i]` is the move FROM `positions[i]`; `moveSequence[0]` == `finalMove` |
| `allMoves` | `[String]` | Full game UCI list from move 1 to checkmate (used by `GameReplayView`) |

**`positions` indexing** — always exactly 23 FEN strings:

```
positions[0]  = board 1 move before final checkmate  → displayed at clock hour  1 (mate in 1)
positions[1]  = board 2 moves before final checkmate → displayed at clock hour  2
...
positions[11] = board 12 moves before checkmate      → displayed at clock hour 12
```

`fenIndex = hour - 1` (0-based). Hour 1 → `positions[0]` (mate in 1). Hour 12 → `positions[11]`.

Indices 12–22 hold interleaved puzzle-start positions (mating side to move):
```
positions[2*(N-1)] = puzzle start for hour N  (mating side to move; even indices 0,2,4,...,22)
positions[2*(N-1) + 1] = opponent's reply     (odd indices 1,3,5,...,21)
```

`whiteElo` / `blackElo` are `String`, not `Int`, because historical games have `"?"`. Views handle this.

`moveSequence` and `allMoves` default to `[]` if absent from JSON (backward compatibility).

## BoardPosition.swift

Parses a FEN string into an 8×8 grid of `ChessPiece?`.

**Orientation:**
```
squares[rankIndex][fileIndex]
rankIndex 0 = rank 8 (top of board — black's home rank)
rankIndex 7 = rank 1 (bottom of board — white's home rank)
fileIndex 0 = file a (left), fileIndex 7 = file h (right)
```
This matches FEN rank order directly (FEN lists rank 8 first).

**Invalid FEN** — `init(fen:)` falls back to `startingPositionSquares` (a `static let`) rather than calling `startingPosition` recursively. `parse()` returns `nil` for malformed input — wrong rank count, wrong file count, unknown characters are all handled.

Only the piece-placement field is used (everything after the first space is ignored).

**Types:**
- `PieceType` — `king, queen, rook, bishop, knight, pawn`
- `PieceColor` — `white, black`
- `ChessPiece` — `type + color`, computed `imageName: String` → e.g. `"wK"`, `"bP"`

## ClockState.swift

Plain snapshot struct. Created fresh every second by `ClockService.makeState(at:)`. No methods.

```swift
struct ClockState {
    let hour: Int        // 1–12
    let minute: Int      // 0–59
    let isAM: Bool
    let isFlipped: Bool  // true when PM — board shown from Black's perspective
    let game: ChessGame
    let fen: String      // = game.positions[hour - 1]
}
```
