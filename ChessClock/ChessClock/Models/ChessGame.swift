import Foundation

struct ChessGame: Codable {
    let white: String        // e.g. "Kasparov, G"
    let black: String        // e.g. "Karpov, A"
    let whiteElo: String     // e.g. "2805" or "?" for historical/unknown
    let blackElo: String     // e.g. "2760" or "?"
    let tournament: String   // e.g. "World Chess Championship 1986"
    let year: Int            // e.g. 1986
    let positions: [String]  // exactly 12 FEN strings
    // positions[0] = board position 1 move before final checkmate  → used at hour 1
    // positions[1] = board position 2 moves before final checkmate → used at hour 2
    // positions[i] = board position (i+1) moves before checkmate   → used at hour (i+1)
    // positions[11] = board position 12 moves before checkmate     → used at hour 12
}
