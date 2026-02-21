import Foundation

// MARK: - Square

/// A chess square with rank (1–8) and file (1–8, a=1).
struct ChessSquare: Hashable, Equatable {
    let rank: Int   // 1–8 (1 = white's back rank)
    let file: Int   // 1–8 (a=1, h=8)

    /// Index into BoardPosition.squares rows: rankIndex 0 = rank 8.
    var rankIndex: Int { 8 - rank }
    /// Index into BoardPosition.squares columns.
    var fileIndex: Int { file - 1 }

    var fileChar: Character {
        Character(UnicodeScalar(Int(("a" as UnicodeScalar).value) + file - 1)!)
    }

    /// Algebraic notation, e.g. "e2".
    var algebraic: String { "\(fileChar)\(rank)" }

    static func from(rankIndex: Int, fileIndex: Int) -> ChessSquare {
        ChessSquare(rank: 8 - rankIndex, file: fileIndex + 1)
    }

    /// Parse algebraic notation, e.g. "e2" → rank=2, file=5.
    static func from(algebraic alg: String) -> ChessSquare? {
        guard alg.count == 2 else { return nil }
        let chars = Array(alg)
        guard let fileOffset = chars[0].asciiValue,
              let fileASCII = ("a" as Character).asciiValue,
              let rank = chars[1].wholeNumberValue else { return nil }
        let file = Int(fileOffset) - Int(fileASCII) + 1
        guard (1...8).contains(file), (1...8).contains(rank) else { return nil }
        return ChessSquare(rank: rank, file: file)
    }
}

// MARK: - Move

/// A chess move in UCI format.
struct ChessMove: Hashable, Equatable {
    let from: ChessSquare
    let to: ChessSquare
    let promotion: PieceType?   // non-nil only for pawn promotions

    var uci: String {
        let base = from.algebraic + to.algebraic
        guard let promo = promotion else { return base }
        switch promo {
        case .queen:  return base + "q"
        case .rook:   return base + "r"
        case .bishop: return base + "b"
        case .knight: return base + "n"
        default:      return base
        }
    }

    /// Parse a UCI string such as "e2e4" or "e7e8q".
    static func from(uci: String) -> ChessMove? {
        guard uci.count == 4 || uci.count == 5 else { return nil }
        let s = Array(uci)
        let fromAlg = String(s[0...1])
        let toAlg = String(s[2...3])
        guard let from = ChessSquare.from(algebraic: fromAlg),
              let to   = ChessSquare.from(algebraic: toAlg)   else { return nil }
        var promo: PieceType?
        if uci.count == 5 {
            switch s[4] {
            case "q": promo = .queen
            case "r": promo = .rook
            case "b": promo = .bishop
            case "n": promo = .knight
            default: return nil
            }
        }
        return ChessMove(from: from, to: to, promotion: promo)
    }
}

// MARK: - Castling Rights

struct CastlingRights {
    var whiteKingside:  Bool
    var whiteQueenside: Bool
    var blackKingside:  Bool
    var blackQueenside: Bool

    static let all  = CastlingRights(whiteKingside: true,  whiteQueenside: true,
                                     blackKingside: true,  blackQueenside: true)
    static let none = CastlingRights(whiteKingside: false, whiteQueenside: false,
                                     blackKingside: false, blackQueenside: false)
}

// MARK: - Game State

/// Full chess position including side to move, castling, and en passant.
struct GameState {
    /// Same layout as BoardPosition.squares: board[rankIndex][fileIndex],
    /// rankIndex 0 = rank 8, rankIndex 7 = rank 1.
    let board: [[ChessPiece?]]
    let activeColor: PieceColor
    let castling: CastlingRights
    let enPassant: ChessSquare?   // target square for en passant capture, or nil

    func piece(at sq: ChessSquare) -> ChessPiece? {
        guard (0...7).contains(sq.rankIndex), (0...7).contains(sq.fileIndex) else { return nil }
        return board[sq.rankIndex][sq.fileIndex]
    }
}

// MARK: - Chess Rules

enum ChessRules {

    // MARK: FEN Parsing

    /// Parse a full FEN string into a GameState, or return nil on failure.
    static func parseState(fen: String) -> GameState? {
        let parts = fen.split(separator: " ", maxSplits: 5, omittingEmptySubsequences: false)
        guard parts.count >= 1 else { return nil }

        // Parse piece placement (same logic as BoardPosition)
        guard let board = parsePlacement(String(parts[0])) else { return nil }

        let active: PieceColor
        if parts.count >= 2 {
            active = parts[1] == "b" ? .black : .white
        } else {
            active = .white
        }

        let castling: CastlingRights
        if parts.count >= 3 {
            let c = String(parts[2])
            castling = CastlingRights(
                whiteKingside:  c.contains("K"),
                whiteQueenside: c.contains("Q"),
                blackKingside:  c.contains("k"),
                blackQueenside: c.contains("q")
            )
        } else {
            castling = .all
        }

        let enPassant: ChessSquare?
        if parts.count >= 4, parts[3] != "-" {
            enPassant = ChessSquare.from(algebraic: String(parts[3]))
        } else {
            enPassant = nil
        }

        return GameState(board: board, activeColor: active, castling: castling, enPassant: enPassant)
    }

    private static func parsePlacement(_ placement: String) -> [[ChessPiece?]]? {
        let ranks = placement.split(separator: "/", omittingEmptySubsequences: false)
        guard ranks.count == 8 else { return nil }
        var board: [[ChessPiece?]] = []
        for rankStr in ranks {
            var row: [ChessPiece?] = []
            for ch in rankStr {
                if let digit = ch.wholeNumberValue, (1...8).contains(digit) {
                    for _ in 0..<digit { row.append(nil) }
                } else {
                    let color: PieceColor = ch.isUppercase ? .white : .black
                    switch ch.lowercased() {
                    case "k": row.append(ChessPiece(type: .king,   color: color))
                    case "q": row.append(ChessPiece(type: .queen,  color: color))
                    case "r": row.append(ChessPiece(type: .rook,   color: color))
                    case "b": row.append(ChessPiece(type: .bishop, color: color))
                    case "n": row.append(ChessPiece(type: .knight, color: color))
                    case "p": row.append(ChessPiece(type: .pawn,   color: color))
                    default:  row.append(nil)
                    }
                }
            }
            guard row.count == 8 else { return nil }
            board.append(row)
        }
        return board
    }

    // MARK: Legal Move Generation

    /// All legal moves for the active side in `state`.
    static func legalMoves(in state: GameState) -> [ChessMove] {
        var result: [ChessMove] = []
        for ri in 0..<8 {
            for fi in 0..<8 {
                guard let piece = state.board[ri][fi], piece.color == state.activeColor else { continue }
                let sq = ChessSquare.from(rankIndex: ri, fileIndex: fi)
                let pseudos = pseudoLegal(from: sq, piece: piece, state: state)
                for move in pseudos {
                    if !leavesKingInCheck(move, state: state) {
                        result.append(move)
                    }
                }
            }
        }
        return result
    }

    /// Check if a specific move (possibly partial — no promotion specified) is legal.
    /// Returns the legal move(s) matching from/to (may be >1 for promotions).
    static func legalMoves(from: ChessSquare, to: ChessSquare, in state: GameState) -> [ChessMove] {
        legalMoves(in: state).filter { $0.from == from && $0.to == to }
    }

    static func isLegal(_ move: ChessMove, in state: GameState) -> Bool {
        legalMoves(in: state).contains(move)
    }

    // MARK: Apply Move

    /// Apply a move and return the new state. Caller must ensure the move is legal.
    static func apply(_ move: ChessMove, to state: GameState) -> GameState {
        var board = state.board
        var castling = state.castling
        var newEP: ChessSquare? = nil

        let movingPiece = board[move.from.rankIndex][move.from.fileIndex]!

        // En passant capture: remove the captured pawn
        if movingPiece.type == .pawn, let ep = state.enPassant, move.to == ep {
            let capturedRankIndex = move.from.rankIndex  // capturing pawn's rank
            board[capturedRankIndex][move.to.fileIndex] = nil
        }

        // Castling: move the rook
        if movingPiece.type == .king {
            let fileDelta = move.to.file - move.from.file
            if abs(fileDelta) == 2 {
                let ri = move.from.rankIndex
                if fileDelta > 0 {
                    // Kingside: rook h-file → f-file
                    board[ri][7] = nil
                    board[ri][5] = ChessPiece(type: .rook, color: movingPiece.color)
                } else {
                    // Queenside: rook a-file → d-file
                    board[ri][0] = nil
                    board[ri][3] = ChessPiece(type: .rook, color: movingPiece.color)
                }
            }
            // King moved: revoke all castling rights for this color
            if movingPiece.color == .white {
                castling.whiteKingside = false; castling.whiteQueenside = false
            } else {
                castling.blackKingside = false; castling.blackQueenside = false
            }
        }

        // Rook moves: revoke the relevant castling right
        if movingPiece.type == .rook {
            switch (movingPiece.color, move.from.rank, move.from.file) {
            case (.white, 1, 8): castling.whiteKingside  = false
            case (.white, 1, 1): castling.whiteQueenside = false
            case (.black, 8, 8): castling.blackKingside  = false
            case (.black, 8, 1): castling.blackQueenside = false
            default: break
            }
        }

        // If a rook is captured on its home square, revoke the right
        if let captured = board[move.to.rankIndex][move.to.fileIndex], captured.type == .rook {
            switch (move.to.rank, move.to.file) {
            case (1, 8): castling.whiteKingside  = false
            case (1, 1): castling.whiteQueenside = false
            case (8, 8): castling.blackKingside  = false
            case (8, 1): castling.blackQueenside = false
            default: break
            }
        }

        // Pawn double push: set en-passant target
        if movingPiece.type == .pawn, abs(move.to.rank - move.from.rank) == 2 {
            let epRank = (move.from.rank + move.to.rank) / 2
            newEP = ChessSquare(rank: epRank, file: move.from.file)
        }

        // Move piece (with promotion)
        board[move.from.rankIndex][move.from.fileIndex] = nil
        let placed = move.promotion.map { ChessPiece(type: $0, color: movingPiece.color) } ?? movingPiece
        board[move.to.rankIndex][move.to.fileIndex] = placed

        let newActive: PieceColor = state.activeColor == .white ? .black : .white
        return GameState(board: board, activeColor: newActive, castling: castling, enPassant: newEP)
    }

    // MARK: Check Detection

    static func isInCheck(_ color: PieceColor, in state: GameState) -> Bool {
        guard let king = kingSquare(of: color, in: state.board) else { return false }
        return isAttacked(king, by: color == .white ? .black : .white, in: state.board)
    }

    static func kingSquare(of color: PieceColor, in board: [[ChessPiece?]]) -> ChessSquare? {
        for ri in 0..<8 {
            for fi in 0..<8 {
                if let p = board[ri][fi], p.type == .king, p.color == color {
                    return ChessSquare.from(rankIndex: ri, fileIndex: fi)
                }
            }
        }
        return nil
    }

    /// Returns true if `square` is attacked by any piece of `attackerColor`.
    static func isAttacked(_ square: ChessSquare, by attackerColor: PieceColor, in board: [[ChessPiece?]]) -> Bool {
        let ri = square.rankIndex
        let fi = square.fileIndex

        // Knight attacks
        for (dr, df) in [(-2,-1),(-2,1),(-1,-2),(-1,2),(1,-2),(1,2),(2,-1),(2,1)] as [(Int,Int)] {
            let nr = ri + dr; let nf = fi + df
            guard (0..<8).contains(nr), (0..<8).contains(nf) else { continue }
            if let p = board[nr][nf], p.color == attackerColor, p.type == .knight { return true }
        }

        // Diagonal rays: bishop, queen, and one-step pawn/king
        for (dr, df) in [(-1,-1),(-1,1),(1,-1),(1,1)] as [(Int,Int)] {
            var nr = ri + dr; var nf = fi + df; var dist = 0
            while (0..<8).contains(nr) && (0..<8).contains(nf) {
                if let p = board[nr][nf] {
                    if p.color == attackerColor {
                        if p.type == .bishop || p.type == .queen { return true }
                        if dist == 0 && p.type == .king { return true }
                        if dist == 0 && p.type == .pawn {
                            // White pawn attacks diagonally upward (decreasing rankIndex).
                            // A white pawn at (nr,nf) attacks (nr-1, nf±1).
                            // dr == 1 means the pawn is one rankIndex below the target (nr = ri+1),
                            // which is the correct attack direction for a white pawn.
                            if attackerColor == .white && dr == 1  { return true }
                            // Black pawn attacks diagonally downward (increasing rankIndex).
                            if attackerColor == .black && dr == -1 { return true }
                        }
                    }
                    break
                }
                dist += 1; nr += dr; nf += df
            }
        }

        // Orthogonal rays: rook, queen, and one-step king
        for (dr, df) in [(-1,0),(1,0),(0,-1),(0,1)] as [(Int,Int)] {
            var nr = ri + dr; var nf = fi + df; var dist = 0
            while (0..<8).contains(nr) && (0..<8).contains(nf) {
                if let p = board[nr][nf] {
                    if p.color == attackerColor {
                        if p.type == .rook || p.type == .queen { return true }
                        if dist == 0 && p.type == .king { return true }
                    }
                    break
                }
                dist += 1; nr += dr; nf += df
            }
        }

        return false
    }

    // MARK: - Private helpers

    private static func leavesKingInCheck(_ move: ChessMove, state: GameState) -> Bool {
        let next = apply(move, to: state)
        // If there is no king (possible in isolated test positions), allow the move.
        guard let king = kingSquare(of: state.activeColor, in: next.board) else { return false }
        return isAttacked(king, by: state.activeColor == .white ? .black : .white, in: next.board)
    }

    /// Generate pseudo-legal moves for a piece (ignores pins/checks).
    private static func pseudoLegal(from sq: ChessSquare, piece: ChessPiece, state: GameState) -> [ChessMove] {
        switch piece.type {
        case .pawn:   return pawnMoves(from: sq, color: piece.color, state: state)
        case .knight: return jumpMoves(from: sq, color: piece.color, offsets: [(-2,-1),(-2,1),(-1,-2),(-1,2),(1,-2),(1,2),(2,-1),(2,1)], board: state.board)
        case .bishop: return slideMoves(from: sq, color: piece.color, dirs: [(-1,-1),(-1,1),(1,-1),(1,1)], board: state.board)
        case .rook:   return slideMoves(from: sq, color: piece.color, dirs: [(-1,0),(1,0),(0,-1),(0,1)],   board: state.board)
        case .queen:  return slideMoves(from: sq, color: piece.color, dirs: [(-1,-1),(-1,1),(1,-1),(1,1),(-1,0),(1,0),(0,-1),(0,1)], board: state.board)
        case .king:   return kingMoves(from: sq, color: piece.color, state: state)
        }
    }

    // MARK: Pawn moves

    private static func pawnMoves(from sq: ChessSquare, color: PieceColor, state: GameState) -> [ChessMove] {
        var moves: [ChessMove] = []
        let ri = sq.rankIndex
        let fi = sq.fileIndex
        let board = state.board
        // Direction: white moves toward rank 8 (rankIndex decreases), black toward rank 1 (rankIndex increases)
        let dir = color == .white ? -1 : 1
        let startRankIndex = color == .white ? 6 : 1  // rank 2 (white) or rank 7 (black)
        let promoRankIndex = color == .white ? 0 : 7  // rank 8 (white) or rank 1 (black)

        // Forward one square
        let r1 = ri + dir
        if (0..<8).contains(r1), board[r1][fi] == nil {
            let dest = ChessSquare.from(rankIndex: r1, fileIndex: fi)
            if r1 == promoRankIndex {
                for pt in [PieceType.queen, .rook, .bishop, .knight] {
                    moves.append(ChessMove(from: sq, to: dest, promotion: pt))
                }
            } else {
                moves.append(ChessMove(from: sq, to: dest, promotion: nil))
            }
            // Double push from starting rank
            let r2 = ri + 2 * dir
            if ri == startRankIndex, (0..<8).contains(r2), board[r2][fi] == nil {
                moves.append(ChessMove(from: sq, to: ChessSquare.from(rankIndex: r2, fileIndex: fi), promotion: nil))
            }
        }

        // Captures (diagonal)
        for df in [-1, 1] {
            let nf = fi + df
            guard (0..<8).contains(r1), (0..<8).contains(nf) else { continue }
            let dest = ChessSquare.from(rankIndex: r1, fileIndex: nf)
            let isCapture = board[r1][nf].map { $0.color != color } ?? false
            let isEP = state.enPassant == dest
            if isCapture || isEP {
                if r1 == promoRankIndex {
                    for pt in [PieceType.queen, .rook, .bishop, .knight] {
                        moves.append(ChessMove(from: sq, to: dest, promotion: pt))
                    }
                } else {
                    moves.append(ChessMove(from: sq, to: dest, promotion: nil))
                }
            }
        }

        return moves
    }

    // MARK: Knight / jump moves

    private static func jumpMoves(from sq: ChessSquare, color: PieceColor, offsets: [(Int,Int)], board: [[ChessPiece?]]) -> [ChessMove] {
        var moves: [ChessMove] = []
        for (dr, df) in offsets {
            let nr = sq.rankIndex + dr; let nf = sq.fileIndex + df
            guard (0..<8).contains(nr), (0..<8).contains(nf) else { continue }
            if let p = board[nr][nf], p.color == color { continue }  // can't capture own piece
            moves.append(ChessMove(from: sq, to: ChessSquare.from(rankIndex: nr, fileIndex: nf), promotion: nil))
        }
        return moves
    }

    // MARK: Sliding moves

    private static func slideMoves(from sq: ChessSquare, color: PieceColor, dirs: [(Int,Int)], board: [[ChessPiece?]]) -> [ChessMove] {
        var moves: [ChessMove] = []
        for (dr, df) in dirs {
            var nr = sq.rankIndex + dr; var nf = sq.fileIndex + df
            while (0..<8).contains(nr) && (0..<8).contains(nf) {
                if let p = board[nr][nf] {
                    if p.color != color {
                        moves.append(ChessMove(from: sq, to: ChessSquare.from(rankIndex: nr, fileIndex: nf), promotion: nil))
                    }
                    break
                }
                moves.append(ChessMove(from: sq, to: ChessSquare.from(rankIndex: nr, fileIndex: nf), promotion: nil))
                nr += dr; nf += df
            }
        }
        return moves
    }

    // MARK: King moves (including castling)

    private static func kingMoves(from sq: ChessSquare, color: PieceColor, state: GameState) -> [ChessMove] {
        var moves = jumpMoves(from: sq, color: color, offsets: [(-1,-1),(-1,0),(-1,1),(0,-1),(0,1),(1,-1),(1,0),(1,1)], board: state.board)

        // Castling
        let opponent: PieceColor = color == .white ? .black : .white
        let backRank = color == .white ? 1 : 8
        let kingFile = 5  // e-file
        guard sq.rank == backRank, sq.file == kingFile else { return moves }
        // King must not be in check currently
        guard !isAttacked(sq, by: opponent, in: state.board) else { return moves }

        let kingsideRight  = color == .white ? state.castling.whiteKingside  : state.castling.blackKingside
        let queensideRight = color == .white ? state.castling.whiteQueenside : state.castling.blackQueenside

        // Kingside castling (king to g-file)
        if kingsideRight {
            let f1 = ChessSquare(rank: backRank, file: 6)
            let g1 = ChessSquare(rank: backRank, file: 7)
            let h1 = ChessSquare(rank: backRank, file: 8)
            if state.piece(at: f1) == nil, state.piece(at: g1) == nil,
               state.piece(at: h1)?.type == .rook, state.piece(at: h1)?.color == color,
               !isAttacked(f1, by: opponent, in: state.board),
               !isAttacked(g1, by: opponent, in: state.board) {
                moves.append(ChessMove(from: sq, to: g1, promotion: nil))
            }
        }

        // Queenside castling (king to c-file)
        if queensideRight {
            let b1 = ChessSquare(rank: backRank, file: 2)
            let c1 = ChessSquare(rank: backRank, file: 3)
            let d1 = ChessSquare(rank: backRank, file: 4)
            let a1 = ChessSquare(rank: backRank, file: 1)
            if state.piece(at: b1) == nil, state.piece(at: c1) == nil, state.piece(at: d1) == nil,
               state.piece(at: a1)?.type == .rook, state.piece(at: a1)?.color == color,
               !isAttacked(c1, by: opponent, in: state.board),
               !isAttacked(d1, by: opponent, in: state.board) {
                moves.append(ChessMove(from: sq, to: c1, promotion: nil))
            }
        }

        return moves
    }
}
