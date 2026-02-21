import Foundation

struct ChessGame: Codable {
    let white: String        // e.g. "Kasparov, G"
    let black: String        // e.g. "Karpov, A"
    let whiteElo: String     // e.g. "2805" or "?" for historical/unknown
    let blackElo: String     // e.g. "2760" or "?"
    let tournament: String   // e.g. "World Chess Championship 1986"
    let year: Int            // e.g. 1986
    let month: String?       // e.g. "January", nil if not in PGN
    let round: String?       // e.g. "3", nil if not in PGN or unknown
    let mateBy: String       // "white" or "black" — who delivers the final checkmate
    let finalMove: String    // UCI notation of the checkmate move, e.g. "e7e8q"
    let positions: [String]  // exactly 12 FEN strings
    // positions[0] = board position 1 move before final checkmate  → the puzzle position
    // positions[i] = board position (i+1) moves before checkmate
    // positions[11] = board position 12 moves before checkmate

    init(white: String, black: String, whiteElo: String, blackElo: String,
         tournament: String, year: Int,
         month: String? = nil, round: String? = nil,
         mateBy: String = "white",
         finalMove: String = "",
         positions: [String]) {
        self.white = white
        self.black = black
        self.whiteElo = whiteElo
        self.blackElo = blackElo
        self.tournament = tournament
        self.year = year
        self.month = month
        self.round = round
        self.mateBy = mateBy
        self.finalMove = finalMove
        self.positions = positions
    }
}

extension ChessGame {
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            white: try c.decode(String.self, forKey: .white),
            black: try c.decode(String.self, forKey: .black),
            whiteElo: try c.decode(String.self, forKey: .whiteElo),
            blackElo: try c.decode(String.self, forKey: .blackElo),
            tournament: try c.decode(String.self, forKey: .tournament),
            year: try c.decode(Int.self, forKey: .year),
            month: try c.decodeIfPresent(String.self, forKey: .month),
            round: try c.decodeIfPresent(String.self, forKey: .round),
            mateBy: (try c.decodeIfPresent(String.self, forKey: .mateBy)) ?? "white",
            finalMove: (try c.decodeIfPresent(String.self, forKey: .finalMove)) ?? "",
            positions: try c.decode([String].self, forKey: .positions)
        )
    }
}
