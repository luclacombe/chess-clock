import XCTest
@testable import ChessClock

@MainActor
final class GameLibraryTests: XCTestCase {

    // MARK: - GameLibrary bundle load

    func testBundleLoadSucceeds_gameCountGreaterThanZero() {
        XCTAssertGreaterThan(GameLibrary.shared.games.count, 0,
                             "games.json must load at least one game from the app bundle")
    }

    // MARK: - ChessGame structural invariants across all bundle games

    func testAllGamesHaveExactly12Positions() {
        for game in GameLibrary.shared.games {
            XCTAssertEqual(game.positions.count, 12,
                           "\(game.white) vs \(game.black) (\(game.year)) has \(game.positions.count) positions, expected 12")
        }
    }

    func testNoGameHasEmptyWhiteOrBlackName() {
        for game in GameLibrary.shared.games {
            XCTAssertFalse(game.white.isEmpty,
                           "Found game with empty white player name (black: \(game.black), year: \(game.year))")
            XCTAssertFalse(game.black.isEmpty,
                           "Found game with empty black player name (white: \(game.white), year: \(game.year))")
        }
    }

    func testAllYearsAreReasonable() {
        for game in GameLibrary.shared.games {
            XCTAssertGreaterThan(game.year, 1800,
                                 "Year \(game.year) is unreasonably early (\(game.white) vs \(game.black))")
            XCTAssertLessThan(game.year, 2100,
                              "Year \(game.year) is unreasonably late (\(game.white) vs \(game.black))")
        }
    }

    // MARK: - JSON round-trip

    func testChessGameJSONRoundTrip() throws {
        let original = ChessGame(
            white: "Kasparov, G",
            black: "Karpov, A",
            whiteElo: "2805",
            blackElo: "2760",
            tournament: "World Chess Championship",
            year: 1986,
            positions: Array(repeating: "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1", count: 12)
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(ChessGame.self, from: data)

        XCTAssertEqual(decoded.white, original.white)
        XCTAssertEqual(decoded.black, original.black)
        XCTAssertEqual(decoded.whiteElo, original.whiteElo)
        XCTAssertEqual(decoded.blackElo, original.blackElo)
        XCTAssertEqual(decoded.tournament, original.tournament)
        XCTAssertEqual(decoded.year, original.year)
        XCTAssertEqual(decoded.positions, original.positions)
    }

    func testChessGameJSONRoundTrip_withUnknownElo() throws {
        let original = ChessGame(
            white: "Morphy, P",
            black: "Anderssen, A",
            whiteElo: "?",
            blackElo: "?",
            tournament: "Opera Game",
            year: 1858,
            positions: Array(repeating: "8/8/8/8/8/8/4k3/4K3 w - - 0 1", count: 12)
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(ChessGame.self, from: data)
        XCTAssertEqual(decoded.whiteElo, "?")
        XCTAssertEqual(decoded.blackElo, "?")
        XCTAssertEqual(decoded.year, 1858)
    }

    func testChessGameJSONRoundTrip_withMonthAndRound() throws {
        let original = ChessGame(
            white: "Kasparov, G",
            black: "Karpov, A",
            whiteElo: "2805",
            blackElo: "2760",
            tournament: "World Chess Championship",
            year: 1986,
            month: "November",
            round: "7",
            positions: Array(repeating: "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1", count: 12)
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(ChessGame.self, from: data)
        XCTAssertEqual(decoded.month, "November")
        XCTAssertEqual(decoded.round, "7")
    }

    func testChessGameJSONRoundTrip_withNilMonthAndRound() throws {
        let original = ChessGame(
            white: "Morphy, P",
            black: "Anderssen, A",
            whiteElo: "?",
            blackElo: "?",
            tournament: "Opera Game",
            year: 1858,
            positions: Array(repeating: "8/8/8/8/8/8/4k3/4K3 w - - 0 1", count: 12)
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(ChessGame.self, from: data)
        XCTAssertNil(decoded.month)
        XCTAssertNil(decoded.round)
    }
}
