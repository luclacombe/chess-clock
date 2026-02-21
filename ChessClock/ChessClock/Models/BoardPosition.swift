import Foundation

enum PieceType {
    case king, queen, rook, bishop, knight, pawn
}

enum PieceColor {
    case white, black
}

struct ChessPiece {
    let type: PieceType
    let color: PieceColor

    // Returns the asset catalog image name: e.g. "wK", "bR", "wP"
    var imageName: String {
        let colorPrefix = color == .white ? "w" : "b"
        let typeLetter: String
        switch type {
        case .king:   typeLetter = "K"
        case .queen:  typeLetter = "Q"
        case .rook:   typeLetter = "R"
        case .bishop: typeLetter = "B"
        case .knight: typeLetter = "N"
        case .pawn:   typeLetter = "P"
        }
        return colorPrefix + typeLetter
    }
}

struct BoardPosition {
    // squares[rankIndex][fileIndex]
    // rankIndex 0 = rank 8 (top of board, black's starting rank, displayed at top)
    // rankIndex 7 = rank 1 (bottom of board, white's starting rank, displayed at bottom)
    // fileIndex 0 = file a (left), fileIndex 7 = file h (right)
    let squares: [[ChessPiece?]]  // always 8×8

    // Initialize from a full FEN string or just the piece placement field.
    // Falls back to the standard starting position if the FEN is invalid.
    init(fen: String) {
        if let parsed = BoardPosition.parse(fen: fen) {
            self.squares = parsed
        } else {
            // Invalid FEN — use hardcoded starting-position squares so there's
            // no recursive dependency on BoardPosition.startingPosition.
            self.squares = BoardPosition.startingPositionSquares
        }
    }

    // MARK: - Private helpers

    /// Parses the piece-placement section of a FEN string.
    /// Returns `nil` if the FEN is malformed.
    private static func parse(fen: String) -> [[ChessPiece?]]? {
        // Extract only the piece-placement field (first space-separated token)
        let placementField: String
        if let spaceIndex = fen.firstIndex(of: " ") {
            placementField = String(fen[fen.startIndex..<spaceIndex])
        } else {
            placementField = fen
        }

        let rankStrings = placementField.split(separator: "/", omittingEmptySubsequences: false)
        guard rankStrings.count == 8 else { return nil }

        var board: [[ChessPiece?]] = []
        board.reserveCapacity(8)

        for rankStr in rankStrings {
            var row: [ChessPiece?] = []
            row.reserveCapacity(8)

            for ch in rankStr {
                if let digit = ch.wholeNumberValue, digit >= 1, digit <= 8 {
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
                    default:  row.append(nil) // Unknown character — treat as empty
                    }
                }
            }

            // Each decoded rank must be exactly 8 squares wide
            guard row.count == 8 else { return nil }
            board.append(row)
        }

        return board
    }

    // MARK: - Static starting position

    /// Pre-built 8×8 squares for the standard chess starting position.
    /// Stored as a static constant so the fallback path in `init(fen:)` never
    /// triggers a recursive call to `startingPosition`.
    private static let startingPositionSquares: [[ChessPiece?]] = {
        // This is the standard starting position — parse() is guaranteed to succeed.
        parse(fen: "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR")!
    }()

    /// The standard chess starting position.
    static let startingPosition = BoardPosition(
        fen: "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"
    )
}
