import XCTest
@testable import ChessClock

final class ChessRulesTests: XCTestCase {

    // MARK: - FEN Parsing

    func testParseStartingPosition() {
        let fen = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"
        guard let state = ChessRules.parseState(fen: fen) else {
            XCTFail("Failed to parse starting position FEN")
            return
        }
        XCTAssertEqual(state.activeColor, .white)
        XCTAssertTrue(state.castling.whiteKingside)
        XCTAssertTrue(state.castling.whiteQueenside)
        XCTAssertTrue(state.castling.blackKingside)
        XCTAssertTrue(state.castling.blackQueenside)
        XCTAssertNil(state.enPassant)
        // White king on e1
        let e1 = ChessSquare(rank: 1, file: 5)
        XCTAssertEqual(state.piece(at: e1)?.type, .king)
        XCTAssertEqual(state.piece(at: e1)?.color, .white)
        // Black king on e8
        let e8 = ChessSquare(rank: 8, file: 5)
        XCTAssertEqual(state.piece(at: e8)?.type, .king)
        XCTAssertEqual(state.piece(at: e8)?.color, .black)
    }

    func testParseActiveColor() {
        let whiteFen = "rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq e3 0 1"
        let blackFen = "rnbqkbnr/pppp1ppp/8/4p3/4P3/8/PPPP1PPP/RNBQKBNR w KQkq e6 0 2"
        XCTAssertEqual(ChessRules.parseState(fen: whiteFen)?.activeColor, .black)
        XCTAssertEqual(ChessRules.parseState(fen: blackFen)?.activeColor, .white)
    }

    func testParseEnPassant() {
        let fen = "rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq e3 0 1"
        let state = ChessRules.parseState(fen: fen)
        XCTAssertNotNil(state?.enPassant)
        XCTAssertEqual(state?.enPassant?.rank, 3)
        XCTAssertEqual(state?.enPassant?.file, 5)  // e-file
    }

    func testParseCastlingRights() {
        let fen = "r3k2r/8/8/8/8/8/8/R3K2R w Kq - 0 1"
        let state = ChessRules.parseState(fen: fen)
        XCTAssertEqual(state?.castling.whiteKingside,  true)
        XCTAssertEqual(state?.castling.whiteQueenside, false)
        XCTAssertEqual(state?.castling.blackKingside,  false)
        XCTAssertEqual(state?.castling.blackQueenside, true)
    }

    // MARK: - ChessSquare helpers

    func testSquareAlgebraic() {
        XCTAssertEqual(ChessSquare(rank: 1, file: 1).algebraic, "a1")
        XCTAssertEqual(ChessSquare(rank: 8, file: 8).algebraic, "h8")
        XCTAssertEqual(ChessSquare(rank: 4, file: 5).algebraic, "e4")
    }

    func testSquareFromAlgebraic() {
        XCTAssertEqual(ChessSquare.from(algebraic: "a1"), ChessSquare(rank: 1, file: 1))
        XCTAssertEqual(ChessSquare.from(algebraic: "h8"), ChessSquare(rank: 8, file: 8))
        XCTAssertEqual(ChessSquare.from(algebraic: "e4"), ChessSquare(rank: 4, file: 5))
        XCTAssertNil(ChessSquare.from(algebraic: "z9"))
        XCTAssertNil(ChessSquare.from(algebraic: ""))
    }

    func testSquareIndices() {
        let e2 = ChessSquare(rank: 2, file: 5)
        XCTAssertEqual(e2.rankIndex, 6)   // rank 2 → rankIndex = 8-2 = 6
        XCTAssertEqual(e2.fileIndex, 4)   // file e (5) → fileIndex = 4

        let a8 = ChessSquare(rank: 8, file: 1)
        XCTAssertEqual(a8.rankIndex, 0)
        XCTAssertEqual(a8.fileIndex, 0)
    }

    // MARK: - ChessMove UCI

    func testMoveUCI() {
        let move = ChessMove(from: ChessSquare(rank: 2, file: 5),
                             to:   ChessSquare(rank: 4, file: 5), promotion: nil)
        XCTAssertEqual(move.uci, "e2e4")
    }

    func testPromotionMoveUCI() {
        let move = ChessMove(from: ChessSquare(rank: 7, file: 5),
                             to:   ChessSquare(rank: 8, file: 5), promotion: .queen)
        XCTAssertEqual(move.uci, "e7e8q")
    }

    func testMoveFromUCI() {
        let move = ChessMove.from(uci: "e2e4")
        XCTAssertEqual(move?.from.algebraic, "e2")
        XCTAssertEqual(move?.to.algebraic,   "e4")
        XCTAssertNil(move?.promotion)
    }

    func testPromotionMoveFromUCI() {
        let move = ChessMove.from(uci: "e7e8q")
        XCTAssertEqual(move?.from.algebraic, "e7")
        XCTAssertEqual(move?.to.algebraic,   "e8")
        XCTAssertEqual(move?.promotion, .queen)
    }

    // MARK: - Legal Move Generation (starting position)

    func testStartingPositionWhiteLegalMoveCount() {
        let fen = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"
        guard let state = ChessRules.parseState(fen: fen) else { XCTFail(); return }
        let moves = ChessRules.legalMoves(in: state)
        // 16 pawn moves (8 pawns × 2 each) + 4 knight moves (Nb1-a3/c3 and Ng1-f3/h3) = 20
        XCTAssertEqual(moves.count, 20, "Starting position must have exactly 20 legal moves")
    }

    // MARK: - Pawn moves

    func testWhitePawnCanMoveOneOrTwo() {
        let fen = "8/8/8/8/8/8/4P3/8 w - - 0 1"
        guard let state = ChessRules.parseState(fen: fen) else { XCTFail(); return }
        let moves = ChessRules.legalMoves(in: state)
        XCTAssertEqual(moves.count, 2, "White pawn on e2 should have 2 moves (e3 and e4)")
    }

    func testWhitePawnBlockedCannotMove() {
        let fen = "8/8/8/8/8/4P3/4P3/8 w - - 0 1"
        guard let state = ChessRules.parseState(fen: fen) else { XCTFail(); return }
        let e2Moves = ChessRules.legalMoves(in: state).filter {
            $0.from == ChessSquare(rank: 2, file: 5)
        }
        XCTAssertTrue(e2Moves.isEmpty, "Pawn on e2 blocked by pawn on e3 should have no moves")
    }

    func testWhitePawnCaptures() {
        // White pawn on e4, black pawns on d5 and f5 (e5 is empty)
        let fen = "8/8/8/3p1p2/4P3/8/8/8 w - - 0 1"
        guard let state = ChessRules.parseState(fen: fen) else { XCTFail(); return }
        let e4Moves = ChessRules.legalMoves(in: state).filter {
            $0.from == ChessSquare(rank: 4, file: 5)
        }
        // e4-e5 free, d5 capture, f5 capture = 3 moves
        XCTAssertEqual(e4Moves.count, 3)
        let targets = Set(e4Moves.map { $0.to.algebraic })
        XCTAssertTrue(targets.contains("e5"))
        XCTAssertTrue(targets.contains("d5"))
        XCTAssertTrue(targets.contains("f5"))
    }

    func testEnPassantCapture() {
        // White pawn on e5, black just played d7-d5 (en passant target = d6)
        let fen = "8/8/8/3pP3/8/8/8/8 w - d6 0 1"
        guard let state = ChessRules.parseState(fen: fen) else { XCTFail(); return }
        let e5Moves = ChessRules.legalMoves(in: state).filter {
            $0.from == ChessSquare(rank: 5, file: 5)
        }
        let targets = Set(e5Moves.map { $0.to.algebraic })
        XCTAssertTrue(targets.contains("e6"), "e5 pawn should be able to advance to e6")
        XCTAssertTrue(targets.contains("d6"), "e5 pawn should be able to capture en passant to d6")
    }

    func testPawnPromotion() {
        // White pawn on e7, can promote
        let fen = "8/4P3/8/8/8/8/8/8 w - - 0 1"
        guard let state = ChessRules.parseState(fen: fen) else { XCTFail(); return }
        let moves = ChessRules.legalMoves(in: state)
        // Should produce 4 promotion moves (Q, R, B, N)
        XCTAssertEqual(moves.count, 4)
        let promos = Set(moves.compactMap { $0.promotion })
        XCTAssertEqual(promos, [.queen, .rook, .bishop, .knight])
    }

    // MARK: - Knight moves

    func testKnightMovesFromCenter() {
        let fen = "8/8/8/8/4N3/8/8/8 w - - 0 1"
        guard let state = ChessRules.parseState(fen: fen) else { XCTFail(); return }
        let moves = ChessRules.legalMoves(in: state)
        XCTAssertEqual(moves.count, 8, "Knight on e4 should have 8 moves from center")
    }

    func testKnightMovesFromCorner() {
        let fen = "N7/8/8/8/8/8/8/8 w - - 0 1"
        guard let state = ChessRules.parseState(fen: fen) else { XCTFail(); return }
        let moves = ChessRules.legalMoves(in: state)
        XCTAssertEqual(moves.count, 2, "Knight on a8 corner should have 2 moves")
    }

    // MARK: - Castling

    func testWhiteKingsideCastling() {
        // White can castle kingside
        let fen = "r3k2r/pppppppp/8/8/8/8/PPPPPPPP/R3K2R w KQkq - 0 1"
        guard let state = ChessRules.parseState(fen: fen) else { XCTFail(); return }
        let kingMoves = ChessRules.legalMoves(in: state).filter {
            $0.from == ChessSquare(rank: 1, file: 5)
        }
        let targets = Set(kingMoves.map { $0.to.algebraic })
        XCTAssertTrue(targets.contains("g1"), "White should be able to castle kingside (e1→g1)")
    }

    func testWhiteQueensideCastling() {
        let fen = "r3k2r/pppppppp/8/8/8/8/PPPPPPPP/R3K2R w KQkq - 0 1"
        guard let state = ChessRules.parseState(fen: fen) else { XCTFail(); return }
        let kingMoves = ChessRules.legalMoves(in: state).filter {
            $0.from == ChessSquare(rank: 1, file: 5)
        }
        let targets = Set(kingMoves.map { $0.to.algebraic })
        XCTAssertTrue(targets.contains("c1"), "White should be able to castle queenside (e1→c1)")
    }

    func testCastlingNotAllowedThroughCheck() {
        // White king cannot castle kingside if f1 is attacked
        let fen = "4k3/8/8/8/8/8/5b2/4K2R w K - 0 1"
        guard let state = ChessRules.parseState(fen: fen) else { XCTFail(); return }
        let kingMoves = ChessRules.legalMoves(in: state).filter {
            $0.from == ChessSquare(rank: 1, file: 5)
        }
        let targets = Set(kingMoves.map { $0.to.algebraic })
        XCTAssertFalse(targets.contains("g1"), "White should not be able to castle through check")
    }

    func testCastlingApplyMoveMovesRook() {
        let fen = "r3k2r/pppppppp/8/8/8/8/PPPPPPPP/R3K2R w KQkq - 0 1"
        guard let state = ChessRules.parseState(fen: fen) else { XCTFail(); return }
        let castleMove = ChessMove(from: ChessSquare(rank: 1, file: 5),
                                   to:   ChessSquare(rank: 1, file: 7), promotion: nil)
        let newState = ChessRules.apply(castleMove, to: state)
        // King should be on g1
        XCTAssertEqual(newState.piece(at: ChessSquare(rank: 1, file: 7))?.type, .king)
        // Rook should be on f1
        XCTAssertEqual(newState.piece(at: ChessSquare(rank: 1, file: 6))?.type, .rook)
        // h1 should be empty
        XCTAssertNil(newState.piece(at: ChessSquare(rank: 1, file: 8)))
    }

    // MARK: - Check detection

    func testKingInCheck() {
        // White king on e1, black rook on e8 → white king is in check
        let fen = "4r3/8/8/8/8/8/8/4K3 w - - 0 1"
        guard let state = ChessRules.parseState(fen: fen) else { XCTFail(); return }
        XCTAssertTrue(ChessRules.isInCheck(.white, in: state))
    }

    func testKingNotInCheck() {
        let fen = "3r4/8/8/8/8/8/8/4K3 w - - 0 1"
        guard let state = ChessRules.parseState(fen: fen) else { XCTFail(); return }
        XCTAssertFalse(ChessRules.isInCheck(.white, in: state))
    }

    func testPinnedPieceCannotMove() {
        // White rook on e4 is pinned to white king on e1 by black rook on e8
        // Moving the rook off the e-file would expose the king
        let fen = "4r3/8/8/8/4R3/8/8/4K3 w - - 0 1"
        guard let state = ChessRules.parseState(fen: fen) else { XCTFail(); return }
        let rookMoves = ChessRules.legalMoves(in: state).filter {
            $0.from == ChessSquare(rank: 4, file: 5)
        }
        // The rook can only move along the e-file (pinned), not horizontally
        let horizontalMoves = rookMoves.filter { $0.to.file != 5 }
        XCTAssertTrue(horizontalMoves.isEmpty, "Pinned rook should not be able to move off the pin axis")
    }

    func testNoLegalMovesInCheckmate() {
        // Scholar's mate position — black is in checkmate
        let fen = "r1bqkb1r/pppp1Qpp/2n2n2/4p3/2B1P3/8/PPPP1PPP/RNB1K1NR b KQkq - 0 4"
        guard let state = ChessRules.parseState(fen: fen) else { XCTFail(); return }
        let moves = ChessRules.legalMoves(in: state)
        XCTAssertTrue(moves.isEmpty, "Should have no legal moves in checkmate")
    }

    // MARK: - Apply move

    func testApplyMoveMoviesPiece() {
        let fen = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"
        guard let state = ChessRules.parseState(fen: fen) else { XCTFail(); return }
        let move = ChessMove(from: ChessSquare(rank: 2, file: 5),
                             to:   ChessSquare(rank: 4, file: 5), promotion: nil)
        let newState = ChessRules.apply(move, to: state)
        XCTAssertNil(newState.piece(at: ChessSquare(rank: 2, file: 5)))
        XCTAssertEqual(newState.piece(at: ChessSquare(rank: 4, file: 5))?.type, .pawn)
        XCTAssertEqual(newState.activeColor, .black)
        // En passant target should be e3
        XCTAssertEqual(newState.enPassant?.rank, 3)
        XCTAssertEqual(newState.enPassant?.file, 5)
    }

    func testApplyPromotionChangesPieceType() {
        let fen = "8/4P3/8/8/8/8/8/4K1k1 w - - 0 1"
        guard let state = ChessRules.parseState(fen: fen) else { XCTFail(); return }
        let move = ChessMove(from: ChessSquare(rank: 7, file: 5),
                             to:   ChessSquare(rank: 8, file: 5), promotion: .queen)
        let newState = ChessRules.apply(move, to: state)
        XCTAssertEqual(newState.piece(at: ChessSquare(rank: 8, file: 5))?.type, .queen)
        XCTAssertNil(newState.piece(at: ChessSquare(rank: 7, file: 5)))
    }

    // MARK: - finalMove matching (real game data)

    func testFinalMoveInGameLibraryIsLegalMove() {
        // Spot-check 10 games: their stored finalMove should be a legal move
        // from positions[0] (the board one move before checkmate).
        let games = GameLibrary.shared.games
        XCTAssertFalse(games.isEmpty)
        let sample = stride(from: 0, to: min(games.count, 10), by: 1).map { games[$0] }

        for game in sample {
            guard !game.finalMove.isEmpty,
                  let move = ChessMove.from(uci: game.finalMove),
                  let state = ChessRules.parseState(fen: game.positions[0]) else {
                XCTFail("Could not parse game data for \(game.white) vs \(game.black)")
                continue
            }
            let legal = ChessRules.isLegal(move, in: state)
            XCTAssertTrue(legal,
                "finalMove '\(game.finalMove)' should be legal in positions[0] for \(game.white) vs \(game.black)")
        }
    }
}
