import XCTest
@testable import ChessClock

/// Integration tests for GuessService — the puzzle session manager.
/// Each test clears relevant UserDefaults keys in setUp() to avoid interference.
@MainActor
final class GuessServiceTests: XCTestCase {

    // MARK: - Helpers

    private let wFEN = "8/8/8/8/8/8/8/8 w - - 0 1"
    private let bFEN = "8/8/8/8/8/8/8/8 b - - 0 1"
    private let moveSeq = ["a1a2","a2a3","a3a4","a4a5","a5a6","a6a7",
                           "a7a8","a8b8","b8b7","b7b6","b6b5","b5b4"]

    // Retain services for the full test lifetime to avoid @MainActor deinit crashes.
    private var clockService: ClockService!
    private var service: GuessService!
    // Extra slot for tests that spin up a second service instance (testStats_persisted).
    private var service2: GuessService?

    override func setUp() {
        super.setUp()
        // Clear all chess clock UserDefaults to ensure test isolation
        for key in UserDefaults.standard.dictionaryRepresentation().keys
            where key.hasPrefix("chessclock_") {
            UserDefaults.standard.removeObject(forKey: key)
        }
        clockService = ClockService()
        service = GuessService(clockService: clockService)
    }

    override func tearDown() {
        service2 = nil
        service = nil
        clockService = nil
        super.tearDown()
    }

    private func makeGame() -> ChessGame {
        let positions = (0..<12).map { i in i % 2 == 0 ? wFEN : bFEN }
        return ChessGame(
            white: "W", black: "B", whiteElo: "?", blackElo: "?",
            tournament: "T", year: 2024,
            mateBy: "white", finalMove: moveSeq[0],
            moveSequence: moveSeq, positions: positions
        )
    }

    // MARK: - Test 1: startPuzzle creates engine

    func testStartPuzzle_createsEngine() {
        let autoPlays = service.startPuzzle(game: makeGame(), hour: 1)
        XCTAssertNotNil(autoPlays, "startPuzzle should return auto-plays array (possibly empty)")
        XCTAssertNotNil(service.engine, "engine should be set after startPuzzle")
        XCTAssertEqual(autoPlays?.count, 0, "Hour 1 with white-mates: user goes first, no initial auto-plays")
    }

    // MARK: - Test 2: startPuzzle with existing result returns nil

    func testStartPuzzle_withExistingResult_returnsNil() {
        _ = service.startPuzzle(game: makeGame(), hour: 1)
        _ = service.submitMove(uci: moveSeq[0])   // correct → result saved
        XCTAssertNotNil(service.result)
        let second = service.startPuzzle(game: makeGame(), hour: 1)
        XCTAssertNil(second, "startPuzzle returns nil when result already exists")
    }

    // MARK: - Test 3: correct move sets succeeded result

    func testSubmitMove_correct_setsSucceededResult() {
        _ = service.startPuzzle(game: makeGame(), hour: 1)
        _ = service.submitMove(uci: moveSeq[0])
        XCTAssertNotNil(service.result)
        XCTAssertTrue(service.result!.succeeded)
        XCTAssertEqual(service.result!.triesUsed, 1)
        XCTAssertNil(service.engine, "Engine cleared after puzzle complete")
    }

    // MARK: - Test 4: three wrong moves sets failed result

    func testSubmitMove_threeWrong_setsFailedResult() {
        _ = service.startPuzzle(game: makeGame(), hour: 1)
        _ = service.submitMove(uci: "bad1")
        _ = service.submitMove(uci: "bad2")
        _ = service.submitMove(uci: "bad3")
        XCTAssertNotNil(service.result)
        XCTAssertFalse(service.result!.succeeded)
        XCTAssertNil(service.engine, "Engine cleared after failure")
    }

    // MARK: - Test 5: stats winsOnFirstTry increments

    func testStats_winsOnFirstTry_increments() {
        _ = service.startPuzzle(game: makeGame(), hour: 1)
        _ = service.submitMove(uci: moveSeq[0])
        XCTAssertEqual(service.stats.winsOnFirstTry, 1)
        XCTAssertEqual(service.stats.totalPlayed, 1)
    }

    // MARK: - Test 6: stats winsOnSecondTry increments

    func testStats_winsOnSecondTry_increments() {
        _ = service.startPuzzle(game: makeGame(), hour: 1)
        _ = service.submitMove(uci: "bad")        // try 1 wrong
        _ = service.submitMove(uci: moveSeq[0])  // try 2 correct
        XCTAssertEqual(service.stats.winsOnSecondTry, 1)
        XCTAssertEqual(service.stats.winsOnFirstTry, 0)
    }

    // MARK: - Test 7: stats loss increments

    func testStats_loss_increments() {
        _ = service.startPuzzle(game: makeGame(), hour: 1)
        _ = service.submitMove(uci: "bad1")
        _ = service.submitMove(uci: "bad2")
        _ = service.submitMove(uci: "bad3")
        XCTAssertEqual(service.stats.losses, 1)
        XCTAssertEqual(service.stats.totalPlayed, 1)
    }

    // MARK: - Test 8: stats persisted across service instances

    func testStats_persisted() {
        _ = service.startPuzzle(game: makeGame(), hour: 1)
        _ = service.submitMove(uci: moveSeq[0])  // correct, try 1
        XCTAssertEqual(service.stats.winsOnFirstTry, 1)

        // New service instance should load stats from UserDefaults
        service2 = GuessService(clockService: clockService)
        XCTAssertEqual(service2!.stats.winsOnFirstTry, 1,
                       "Stats should persist across GuessService instances via UserDefaults")
    }

    // MARK: - Test 9: hasResult reflects result state

    func testHasResult() {
        XCTAssertFalse(service.hasResult)
        _ = service.startPuzzle(game: makeGame(), hour: 1)
        XCTAssertFalse(service.hasResult, "No result until puzzle completed")
        _ = service.submitMove(uci: moveSeq[0])
        XCTAssertTrue(service.hasResult)
    }

    // MARK: - Test 10: hour 2 auto-plays opponent first

    func testStartPuzzle_hour2_returnsOneAutoPlay() {
        // Hour 2: starts at positions[1] = bFEN (opponent first for white-mates game)
        let autoPlays = service.startPuzzle(game: makeGame(), hour: 2)
        XCTAssertEqual(autoPlays?.count, 1, "Hour 2 white-mates: opponent goes first → 1 auto-play")
    }
}
