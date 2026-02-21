import Foundation

struct ClockState {
    let hour: Int      // 1–12
    let minute: Int    // 0–59
    let isAM: Bool
    let isFlipped: Bool  // true when PM (= !isAM); board shown from Black's perspective
    let game: ChessGame
    let fen: String    // game.positions[hour - 1], the board to display right now
}
