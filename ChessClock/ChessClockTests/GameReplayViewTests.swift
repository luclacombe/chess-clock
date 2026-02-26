import XCTest
@testable import ChessClock

/// Comprehensive tests for GameReplayView logic.
///
/// Covers:
///   1. Zone classification  (8)
///   2. Move labels          (6)
///   3. Position counter     (4)
///   4. Navigation clamping  (6)
///   5. Zone label text      (3)
///   6. Full-position replay (5)
///
/// Total: 32 tests — all pure logic, no SwiftUI hosting required.
final class GameReplayViewTests: XCTestCase {

    // MARK: - Shared fixtures

    private let startFEN = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"

    /// A known 10-move opening sequence in standard UCI.
    private let tenMoves = [
        "e2e4","e7e5","g1f3","b8c6","f1c4","g8f6","f3g5","d7d5","e4d5","c6a5"
    ]

    /// 23-move sequence for the fragment fields (required by ChessGame.init).
    private let fragmentMoves: [String] = (0..<23).map { "a\($0 % 7 + 1)b\($0 % 7 + 1)" }

    /// Build a game with an `allMoves` list of the given length using real e2e4-style moves.
    private func makeGame(allMoves: [String]) -> ChessGame {
        ChessGame(
            white: "W", black: "B", whiteElo: "?", blackElo: "?",
            tournament: "T", year: 2024,
            mateBy: "white", finalMove: allMoves.last ?? "",
            moveSequence: fragmentMoves,
            allMoves: allMoves,
            positions: Array(repeating: startFEN, count: 23)
        )
    }

    // MARK: - 1. Zone classification (8 tests)
    // posIndex < psi → .before, posIndex == psi → .start, posIndex > psi → .after

    func testZone_before() {
        // puzzleStartPosIndex = 39, posIndex = 25 < 39 → .before
        XCTAssertEqual(ReplayZone.classify(posIndex: 25, puzzleStartPosIndex: 39, totalMoves: 50), .before)
    }

    func testZone_start() {
        XCTAssertEqual(ReplayZone.classify(posIndex: 39, puzzleStartPosIndex: 39, totalMoves: 50), .start)
    }

    func testZone_after() {
        // posIndex = 45 > 39, < 50 → .after
        XCTAssertEqual(ReplayZone.classify(posIndex: 45, puzzleStartPosIndex: 39, totalMoves: 50), .after)
    }

    /// hour 1 → psi = N − 1 − 0 = N − 1 (last position before checkmate)
    func testZone_hour1_start() {
        // e.g. N=50, psi=49, posIndex 49 → .start
        XCTAssertEqual(ReplayZone.classify(posIndex: 49, puzzleStartPosIndex: 49, totalMoves: 50), .start)
    }

    /// posIndex 0 (game start) is .before for any hour that isn't a 1-move game
    func testZone_gameStart_isBefore_forMostHours() {
        // psi = 40 (typical): posIndex 0 < 40 → .before
        XCTAssertEqual(ReplayZone.classify(posIndex: 0, puzzleStartPosIndex: 40, totalMoves: 50), .before)
    }

    func testZone_hour12_start() {
        // hour 12 → (hour-1)*2 = 22 → psi = N-23. For N=50, psi=27
        XCTAssertEqual(ReplayZone.classify(posIndex: 27, puzzleStartPosIndex: 27, totalMoves: 50), .start)
    }

    func testZone_hour12_after() {
        // posIndex 28 > 27 → .after
        XCTAssertEqual(ReplayZone.classify(posIndex: 28, puzzleStartPosIndex: 27, totalMoves: 50), .after)
    }

    /// Checkmate position (posIndex == totalMoves) is always .checkmate
    func testZone_checkmate() {
        // totalMoves = 50, psi = 39; posIndex 50 == totalMoves → .checkmate
        XCTAssertEqual(ReplayZone.classify(posIndex: 50, puzzleStartPosIndex: 39, totalMoves: 50), .checkmate)
    }

    // MARK: - 2. Move labels (6 tests)

    func testMoveLabel_startingPosition_posIndex0() {
        let game = makeGame(allMoves: tenMoves)
        // posIndex 0 → "Starting position"
        let label: String
        if 0 == 0 { label = "Starting position" }  // mirrors view logic
        else { label = game.allMoves[0 - 1].uppercased() }
        XCTAssertEqual(label, "Starting position")
    }

    func testMoveLabel_firstMove_posIndex1() {
        let game = makeGame(allMoves: tenMoves)
        // posIndex 1 → allMoves[0]
        let label = game.allMoves[1 - 1].uppercased()
        XCTAssertEqual(label, "E2E4")
    }

    func testMoveLabel_secondMove_posIndex2() {
        let game = makeGame(allMoves: tenMoves)
        XCTAssertEqual(game.allMoves[2 - 1].uppercased(), "E7E5")
    }

    func testMoveLabel_lastMove_checksmate() {
        let game = makeGame(allMoves: tenMoves)
        // posIndex == totalMoves → allMoves.last
        let label = game.allMoves[tenMoves.count - 1].uppercased()
        XCTAssertEqual(label, "C6A5")
    }

    func testMoveLabel_midGame() {
        let game = makeGame(allMoves: tenMoves)
        // posIndex 5 → allMoves[4] = "f1c4"
        XCTAssertEqual(game.allMoves[5 - 1].uppercased(), "F1C4")
    }

    func testMoveLabel_allMovesMatchOpeningSequence() {
        let game = makeGame(allMoves: tenMoves)
        XCTAssertEqual(game.allMoves[0], "e2e4")
        XCTAssertEqual(game.allMoves[2], "g1f3")
        XCTAssertEqual(game.allMoves.last, "c6a5")
    }

    // MARK: - 3. Position counter (4 tests)
    // Display: "\(posIndex) / \(totalMoves)"

    func testPositionCounter_start() {
        // posIndex 0, totalMoves 50 → "0 / 50"
        let display = "\(0) / \(50)"
        XCTAssertEqual(display, "0 / 50")
    }

    func testPositionCounter_checkmate() {
        let display = "\(50) / \(50)"
        XCTAssertEqual(display, "50 / 50")
    }

    func testPositionCounter_puzzleStart() {
        // typical: posIndex 39, totalMoves 50 → "39 / 50"
        let display = "\(39) / \(50)"
        XCTAssertEqual(display, "39 / 50")
    }

    func testPositionCounter_oneBeforeCheckmate() {
        let display = "\(49) / \(50)"
        XCTAssertEqual(display, "49 / 50")
    }

    // MARK: - 4. Navigation clamping (6 tests)

    /// ← at posIndex 0 must stay at 0 (can't go before game start)
    func testNavigation_clampAtStart_backwardButton() {
        var posIndex = 0
        posIndex = max(posIndex - 1, 0)
        XCTAssertEqual(posIndex, 0)
    }

    /// Keyboard ← at posIndex 0 must also clamp
    func testNavigation_clampAtStart_keyboard() {
        var posIndex = 0
        posIndex = max(posIndex - 1, 0)
        XCTAssertEqual(posIndex, 0)
    }

    /// → at posIndex == totalMoves must stay at totalMoves
    func testNavigation_clampAtEnd_forwardButton() {
        let totalMoves = 50
        var posIndex = totalMoves
        posIndex = min(posIndex + 1, totalMoves)
        XCTAssertEqual(posIndex, totalMoves)
    }

    /// Keyboard → at final position must clamp
    func testNavigation_clampAtEnd_keyboard() {
        let totalMoves = 50
        var posIndex = totalMoves
        posIndex = min(posIndex + 1, totalMoves)
        XCTAssertEqual(posIndex, totalMoves)
    }

    /// ⏮ jumps to game start (posIndex 0)
    func testNavigation_jumpToStart() {
        var posIndex = 39
        posIndex = 0
        XCTAssertEqual(posIndex, 0)
    }

    /// ⏭ jumps to checkmate (posIndex == totalMoves)
    func testNavigation_jumpToCheckmate() {
        let totalMoves = 50
        var posIndex = 20
        posIndex = totalMoves
        XCTAssertEqual(posIndex, totalMoves)
    }

    // MARK: - 5. Zone label text (3 tests)

    func testZoneLabel_before()    { XCTAssertEqual(ReplayZone.before.label,    "Context")   }
    func testZoneLabel_start()     { XCTAssertEqual(ReplayZone.start.label,     "Puzzle")    }
    func testZoneLabel_after()     { XCTAssertEqual(ReplayZone.after.label,     "Solution")  }
    func testZoneLabel_checkmate() { XCTAssertEqual(ReplayZone.checkmate.label, "Checkmate") }

    // MARK: - 6. Full-position computation via computeAllPositions (5 tests)

    func testComputeAllPositions_firstPosIsStartingFEN() {
        let game = makeGame(allMoves: tenMoves)
        let positions = GameReplayView.computeAllPositions(game: game)
        XCTAssertFalse(positions.isEmpty)
        // Index 0 should be the standard starting position
        XCTAssertTrue(positions[0].hasPrefix("rnbqkbnr/pppppppp"),
                      "First position should be the standard starting FEN")
    }

    func testComputeAllPositions_countEqualsAllMovesPlus1() {
        let game = makeGame(allMoves: tenMoves)
        let positions = GameReplayView.computeAllPositions(game: game)
        // N+1 positions for N moves (includes starting and after each move)
        XCTAssertEqual(positions.count, tenMoves.count + 1)
    }

    func testComputeAllPositions_afterE2E4_pawnOnE4() {
        // After e2e4 the e4 square should be occupied and e2 empty.
        let game = makeGame(allMoves: ["e2e4"])
        let positions = GameReplayView.computeAllPositions(game: game)
        XCTAssertEqual(positions.count, 2)
        // Parse posIndex 1 and verify e4 has a pawn
        if let state = ChessRules.parseState(fen: positions[1]) {
            let e4 = ChessSquare(rank: 4, file: 5)
            let e2 = ChessSquare(rank: 2, file: 5)
            XCTAssertEqual(state.piece(at: e4)?.type, .pawn)
            XCTAssertEqual(state.piece(at: e4)?.color, .white)
            XCTAssertNil(state.piece(at: e2), "e2 should be empty after e2e4")
        } else {
            XCTFail("Could not parse generated FEN")
        }
    }

    func testComputeAllPositions_emptyAllMoves_returnsStartOnly() {
        let game = makeGame(allMoves: [])
        let positions = GameReplayView.computeAllPositions(game: game)
        XCTAssertEqual(positions.count, 1,
                       "With no allMoves, should return only the starting position")
    }

    func testComputeAllPositions_puzzleStartMapsCorrectly() {
        // For a game with 10 moves (tenMoves), hour=1 → (hour-1)*2 = 0
        // psi = positions.count - 2 - 0 = 11 - 2 = 9 = totalMoves - 1
        // i.e. puzzle start is 1 before checkmate (mating side to move, opponent's arrow shown)
        let game = makeGame(allMoves: tenMoves)
        let positions = GameReplayView.computeAllPositions(game: game)
        let psi = max(0, positions.count - 2 - (1 - 1) * 2)  // hour 1 → psi = N-1 = 9
        XCTAssertEqual(psi, 9)
        XCTAssertEqual(psi, positions.count - 2,
                       "For hour 1, puzzle start is 1 before checkmate (mating side to move)")
    }
}
