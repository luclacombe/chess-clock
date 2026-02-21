import XCTest
@testable import ChessClock

@MainActor
final class BoardPositionTests: XCTestCase {

    // MARK: - TC1: Starting position — king placement

    func testStartingPositionKingPlacement() {
        let position = BoardPosition(fen: "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1")

        // White king: rankIndex 7 (rank 1), fileIndex 4 (file e)
        let whiteKing = position.squares[7][4]
        XCTAssertNotNil(whiteKing, "White king must be present at e1 (rankIndex 7, fileIndex 4)")
        XCTAssertEqual(whiteKing?.type, .king,  "e1 piece must be a king")
        XCTAssertEqual(whiteKing?.color, .white, "e1 king must be white")

        // Black king: rankIndex 0 (rank 8), fileIndex 4 (file e)
        let blackKing = position.squares[0][4]
        XCTAssertNotNil(blackKing, "Black king must be present at e8 (rankIndex 0, fileIndex 4)")
        XCTAssertEqual(blackKing?.type, .king,  "e8 piece must be a king")
        XCTAssertEqual(blackKing?.color, .black, "e8 king must be black")
    }

    // MARK: - TC2: All 12 piece types recognized (starting position FEN)

    func testAllTwelvePieceTypesRecognized() {
        // rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR
        let position = BoardPosition(fen: "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR")

        // -- Rank 8 (rankIndex 0): r n b q k b n r  (black pieces)
        let bR0 = position.squares[0][0]
        XCTAssertEqual(bR0?.type, .rook,   "a8 must be a rook")
        XCTAssertEqual(bR0?.color, .black, "a8 rook must be black")

        let bN1 = position.squares[0][1]
        XCTAssertEqual(bN1?.type, .knight, "b8 must be a knight")
        XCTAssertEqual(bN1?.color, .black, "b8 knight must be black")

        let bB2 = position.squares[0][2]
        XCTAssertEqual(bB2?.type, .bishop, "c8 must be a bishop")
        XCTAssertEqual(bB2?.color, .black, "c8 bishop must be black")

        let bQ3 = position.squares[0][3]
        XCTAssertEqual(bQ3?.type, .queen,  "d8 must be a queen")
        XCTAssertEqual(bQ3?.color, .black, "d8 queen must be black")

        let bK4 = position.squares[0][4]
        XCTAssertEqual(bK4?.type, .king,   "e8 must be a king")
        XCTAssertEqual(bK4?.color, .black, "e8 king must be black")

        // -- Rank 7 (rankIndex 1): all black pawns
        for fileIndex in 0..<8 {
            let piece = position.squares[1][fileIndex]
            XCTAssertEqual(piece?.type, .pawn,   "Rank 7, file \(fileIndex) must be a pawn")
            XCTAssertEqual(piece?.color, .black, "Rank 7, file \(fileIndex) pawn must be black")
        }

        // -- Rank 2 (rankIndex 6): all white pawns
        for fileIndex in 0..<8 {
            let piece = position.squares[6][fileIndex]
            XCTAssertEqual(piece?.type, .pawn,   "Rank 2, file \(fileIndex) must be a pawn")
            XCTAssertEqual(piece?.color, .white, "Rank 2, file \(fileIndex) pawn must be white")
        }

        // -- Rank 1 (rankIndex 7): R N B Q K B N R  (white pieces)
        let wR0 = position.squares[7][0]
        XCTAssertEqual(wR0?.type, .rook,   "a1 must be a rook")
        XCTAssertEqual(wR0?.color, .white, "a1 rook must be white")

        let wN1 = position.squares[7][1]
        XCTAssertEqual(wN1?.type, .knight, "b1 must be a knight")
        XCTAssertEqual(wN1?.color, .white, "b1 knight must be white")

        let wB2 = position.squares[7][2]
        XCTAssertEqual(wB2?.type, .bishop, "c1 must be a bishop")
        XCTAssertEqual(wB2?.color, .white, "c1 bishop must be white")

        let wQ3 = position.squares[7][3]
        XCTAssertEqual(wQ3?.type, .queen,  "d1 must be a queen")
        XCTAssertEqual(wQ3?.color, .white, "d1 queen must be white")

        let wK4 = position.squares[7][4]
        XCTAssertEqual(wK4?.type, .king,   "e1 must be a king")
        XCTAssertEqual(wK4?.color, .white, "e1 king must be white")
    }

    // MARK: - TC3: Numbers 1–8 in FEN produce correct nil squares

    func testFENDigitsProduceNilSquares() {
        // Use the starting position which contains "8" in ranks 3–6 and mixed
        // digits elsewhere.  The middle four ranks (rankIndex 2–5) must all be nil.
        let position = BoardPosition(fen: "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR")

        for rankIndex in 2...5 {
            for fileIndex in 0..<8 {
                XCTAssertNil(
                    position.squares[rankIndex][fileIndex],
                    "Square [\(rankIndex)][\(fileIndex)] must be nil (empty rank '8')"
                )
            }
        }
    }

    // MARK: - TC4: Full empty FEN → all 64 squares nil

    func testAllEmptyFENProduces64NilSquares() {
        let position = BoardPosition(fen: "8/8/8/8/8/8/8/8")

        XCTAssertEqual(position.squares.count, 8, "Board must have exactly 8 ranks")

        var nilCount = 0
        for rankIndex in 0..<8 {
            XCTAssertEqual(position.squares[rankIndex].count, 8,
                           "Rank \(rankIndex) must have exactly 8 squares")
            for fileIndex in 0..<8 {
                if position.squares[rankIndex][fileIndex] == nil {
                    nilCount += 1
                }
            }
        }

        XCTAssertEqual(nilCount, 64, "All 64 squares must be nil for an all-empty FEN")
    }

    // MARK: - TC5: Invalid FEN falls back to starting position

    func testInvalidFENFallsBackToStartingPosition() {
        // Must not crash and must return the standard starting position
        let position = BoardPosition(fen: "invalid_fen_string")

        // The starting position has exactly 32 pieces — verify none of the
        // home-rank / pawn-rank squares are nil (quick structural check).
        let expectedOccupiedRanks = [0, 1, 6, 7]
        for rankIndex in expectedOccupiedRanks {
            for fileIndex in 0..<8 {
                XCTAssertNotNil(
                    position.squares[rankIndex][fileIndex],
                    "Fallback starting position: rank \(rankIndex), file \(fileIndex) must not be nil"
                )
            }
        }

        // Middle four ranks must be empty in the starting position
        for rankIndex in 2...5 {
            for fileIndex in 0..<8 {
                XCTAssertNil(
                    position.squares[rankIndex][fileIndex],
                    "Fallback starting position: rank \(rankIndex), file \(fileIndex) must be nil"
                )
            }
        }
    }

    // MARK: - TC6: Endgame FEN → sparse board with exactly 2 pieces

    func testEndgameFENProducesTwoPiecesAtCorrectPositions() {
        // "8/8/8/8/8/8/4k3/4K3"
        // rankIndex 6 (rank 2): 4 empty + k (fileIndex 4) + 3 empty  → black king at [6][4]
        // rankIndex 7 (rank 1): 4 empty + K (fileIndex 4) + 3 empty  → white king at [7][4]
        let position = BoardPosition(fen: "8/8/8/8/8/8/4k3/4K3")

        // Count total non-nil squares
        var pieceCount = 0
        for rankIndex in 0..<8 {
            for fileIndex in 0..<8 {
                if position.squares[rankIndex][fileIndex] != nil {
                    pieceCount += 1
                }
            }
        }
        XCTAssertEqual(pieceCount, 2, "Endgame FEN must produce exactly 2 pieces")

        // Black king at rankIndex 6, fileIndex 4
        let blackKing = position.squares[6][4]
        XCTAssertNotNil(blackKing, "Black king must be present at rankIndex 6, fileIndex 4")
        XCTAssertEqual(blackKing?.type, .king,   "Piece at [6][4] must be a king")
        XCTAssertEqual(blackKing?.color, .black, "Piece at [6][4] must be black")

        // White king at rankIndex 7, fileIndex 4
        let whiteKing = position.squares[7][4]
        XCTAssertNotNil(whiteKing, "White king must be present at rankIndex 7, fileIndex 4")
        XCTAssertEqual(whiteKing?.type, .king,   "Piece at [7][4] must be a king")
        XCTAssertEqual(whiteKing?.color, .white, "Piece at [7][4] must be white")
    }
}
