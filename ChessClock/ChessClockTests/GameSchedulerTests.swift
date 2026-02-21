import XCTest
@testable import ChessClock

// NOTE: GameLibrary is a `final class` with `private init()` and `let games: [ChessGame]`.
// It cannot be subclassed or have its stored property mutated from outside the module.
// Since TEST_HOST points to the app bundle, GameLibrary.shared loads the real games.json
// (588 games). All tests that need a populated library use GameLibrary.shared.
//
// For the "empty library" case (test 6), GameScheduler.resolve guards `!library.games.isEmpty`
// and returns nil. Because we cannot construct a zero-game GameLibrary from outside the module,
// that branch is verified by code inspection. A note is left in the test body.
//
// v1.0 change: GameScheduler now rotates games hourly (hourlyIndex = daysSinceEpoch * 24 + hour24)
// and always returns fenIndex == 0 (positions[0] = 1 move before checkmate).

@MainActor
final class GameSchedulerTests: XCTestCase {

    // MARK: - Helpers

    private var calendar: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone.current
        return cal
    }()

    /// Builds a Date from explicit components in the current timezone.
    private func makeDate(year: Int, month: Int, day: Int, hour: Int, minute: Int = 0) -> Date {
        calendar.date(from: DateComponents(
            year: year, month: month, day: day, hour: hour, minute: minute
        ))!
    }

    // MARK: - Test 1: Determinism

    /// Calling resolve twice with the same date must return identical results.
    func testDeterminism() {
        let library = GameLibrary.shared
        let date = makeDate(year: 2026, month: 2, day: 15, hour: 1)

        guard let first = GameScheduler.resolve(date: date, library: library),
              let second = GameScheduler.resolve(date: date, library: library) else {
            XCTFail("resolve returned nil for a non-empty library")
            return
        }

        XCTAssertEqual(first.fenIndex, second.fenIndex,
                       "fenIndex must be identical across two calls with the same date")
        XCTAssertEqual(first.game.white, second.game.white,
                       "game.white must be identical across two calls with the same date")
        XCTAssertEqual(first.game.black, second.game.black,
                       "game.black must be identical across two calls with the same date")
    }

    // MARK: - Test 2: fenIndex is always 0

    /// fenIndex must equal hour12 - 1 (hour 1 → 0, hour 12 → 11).
    func testFenIndexMatchesHour12() {
        let library = GameLibrary.shared
        // (hour24, expected fenIndex = hour12 - 1)
        let cases: [(Int, Int)] = [
            (1,  0),   // 1 AM  → hour12=1  → fenIndex=0  (mate in 1)
            (0,  11),  // midnight → hour12=12 → fenIndex=11
            (12, 11),  // noon  → hour12=12 → fenIndex=11
            (23, 10),  // 11 PM → hour12=11 → fenIndex=10
            (9,  8),   // 9 AM  → hour12=9  → fenIndex=8
            (6,  5),   // 6 PM  → hour12=6  → fenIndex=5
        ]

        for (hour24, expectedFenIndex) in cases {
            let date = makeDate(year: 2026, month: 2, day: 15, hour: hour24)
            guard let result = GameScheduler.resolve(date: date, library: library) else {
                XCTFail("resolve returned nil for a non-empty library (hour \(hour24))")
                continue
            }
            XCTAssertEqual(result.fenIndex, expectedFenIndex,
                           "hour24=\(hour24) should produce fenIndex=\(expectedFenIndex)")
        }
    }

    // MARK: - Test 3: AM resolves to white-wins game; PM resolves to black-wins game

    /// AM hours pull exclusively from games where White delivers checkmate.
    /// PM hours pull exclusively from games where Black delivers checkmate.
    func testAMResolvesToWhiteWinsGame() {
        let library = GameLibrary.shared
        let amDate = makeDate(year: 2026, month: 2, day: 15, hour: 9)  // 9 AM

        guard let result = GameScheduler.resolve(date: amDate, library: library, seed: 0) else {
            XCTFail("resolve returned nil for a non-empty library")
            return
        }

        XCTAssertEqual(result.game.mateBy, "white",
                       "AM should resolve to a game where White delivers checkmate")
    }

    func testPMResolvesToBlackWinsGame() {
        let library = GameLibrary.shared
        let pmDate = makeDate(year: 2026, month: 2, day: 15, hour: 13) // 1 PM

        guard let result = GameScheduler.resolve(date: pmDate, library: library, seed: 0) else {
            XCTFail("resolve returned nil for a non-empty library")
            return
        }

        XCTAssertEqual(result.game.mateBy, "black",
                       "PM should resolve to a game where Black delivers checkmate")
    }

    // MARK: - Test 4: Consecutive hours produce different games

    /// Two consecutive hours on the same day should produce different games
    /// because hourlyIndex differs by 1 each hour.
    func testConsecutiveHoursDifferInGame() {
        let library = GameLibrary.shared
        // Compare two consecutive AM hours to stay in the same pool
        let hour9  = makeDate(year: 2026, month: 2, day: 15, hour: 9)
        let hour10 = makeDate(year: 2026, month: 2, day: 15, hour: 10)

        guard let r9  = GameScheduler.resolve(date: hour9,  library: library, seed: 0),
              let r10 = GameScheduler.resolve(date: hour10, library: library, seed: 0) else {
            XCTFail("resolve returned nil for a non-empty library")
            return
        }

        // hourlyIndex for hour9 = daysSinceEpoch*24+9, for hour10 = daysSinceEpoch*24+10
        // So gameIndex should differ by 1 in the white-wins pool
        let pool = library.games.filter { $0.mateBy == "white" }
        let count = pool.count

        let d = daysSinceEpoch(for: hour9)
        let gi9  = gameIndex(hourlyIndex: d * 24 + 9,  count: count)
        let gi10 = gameIndex(hourlyIndex: d * 24 + 10, count: count)
        XCTAssertEqual((gi10 - gi9 + count) % count, 1,
                       "Consecutive hours should advance gameIndex by 1 (mod pool size)")

        // The two results should reference different games
        let same = r9.game.white == r10.game.white && r9.game.black == r10.game.black
        XCTAssertFalse(same, "Consecutive hours should show different games")
    }

    // MARK: - Test 5: Pre-epoch date does not crash

    /// A date before the epoch (2025-12-31 11:00 AM) produces a negative daysSinceEpoch.
    /// The double-modulo formula must still return a valid result in [0, count).
    func testPreEpochDateDoesNotCrash() {
        let library = GameLibrary.shared
        let preEpoch = makeDate(year: 2025, month: 12, day: 31, hour: 11)

        guard let result = GameScheduler.resolve(date: preEpoch, library: library) else {
            XCTFail("resolve returned nil for a non-empty library")
            return
        }

        // hour 11 → hour12=11 → fenIndex=10
        XCTAssertEqual(result.fenIndex, 10,
                       "fenIndex for hour 11 must be 10, even for pre-epoch dates")
        XCTAssertTrue(library.games.indices.contains(library.games.firstIndex(where: {
            $0.white == result.game.white && $0.black == result.game.black
        }) ?? -1), "The returned game must exist in the library")
    }

    // MARK: - Test 6: Empty library returns nil (verified by code inspection)

    func testEmptyLibraryReturnsNil_CodeInspectionOnly() {
        // Affirmative assertion: the real library is non-empty, so resolve returns non-nil.
        let library = GameLibrary.shared
        let date = makeDate(year: 2026, month: 2, day: 15, hour: 3)
        XCTAssertNotNil(GameScheduler.resolve(date: date, library: library),
                        "A non-empty library must return a non-nil result")

        // The nil-return branch for an empty library is verified by code inspection of
        // GameScheduler.swift: `guard !library.games.isEmpty else { return nil }`.
    }

    // MARK: - Test 7: Modulo wrap-around stays within valid range

    /// A sweep of consecutive hourlyIndex values must always produce a gameIndex within [0, count).
    func testModuloWrapAroundStaysInValidRange() {
        let pool = GameLibrary.shared.games.filter { $0.mateBy == "white" }
        let count = pool.count
        XCTAssertGreaterThan(count, 1,
                             "White-wins pool must have more than 1 game for this test to be meaningful")

        let iterations = count * 2 + 3
        var seenGameIndices = Set<Int>()

        for hdi in 0..<iterations {
            let gi = gameIndex(hourlyIndex: hdi, count: count)
            XCTAssertGreaterThanOrEqual(gi, 0, "gameIndex must be >= 0 (hourlyIndex=\(hdi))")
            XCTAssertLessThan(gi, count,        "gameIndex must be < count (hourlyIndex=\(hdi))")
            seenGameIndices.insert(gi)
        }

        XCTAssertEqual(seenGameIndices.count, count,
                       "Every gameIndex in [0, count) must be reachable")

        XCTAssertEqual(gameIndex(hourlyIndex: count, count: count), 0,
                       "gameIndex(hourlyIndex: count) should wrap to 0")

        for hdi in 0..<(count - 1) {
            let a = gameIndex(hourlyIndex: hdi,     count: count)
            let b = gameIndex(hourlyIndex: hdi + 1, count: count)
            XCTAssertEqual((b - a + count) % count, 1,
                           "Consecutive hourlyIndex values should advance gameIndex by 1")
        }
    }

    // MARK: - Test 8: Different seeds produce different game indices

    func testDifferentSeedsDifferentGameIndex() {
        let library = GameLibrary.shared
        let date = makeDate(year: 2026, month: 2, day: 15, hour: 9)

        guard let result0 = GameScheduler.resolve(date: date, library: library, seed: 0),
              let result1 = GameScheduler.resolve(date: date, library: library, seed: 1) else {
            XCTFail("resolve returned nil for a non-empty library")
            return
        }

        XCTAssertNotEqual(result0.game.white + result0.game.black,
                          result1.game.white + result1.game.black,
                          "Different seeds must yield different games on the same date")
    }

    // MARK: - Test 9: Same date + same seed → identical result

    func testSameSeedSameDateIsDeterministic() {
        let library = GameLibrary.shared
        let date = makeDate(year: 2026, month: 2, day: 15, hour: 9)
        let seed = 42

        guard let first = GameScheduler.resolve(date: date, library: library, seed: seed),
              let second = GameScheduler.resolve(date: date, library: library, seed: seed) else {
            XCTFail("resolve returned nil for a non-empty library")
            return
        }

        XCTAssertEqual(first.fenIndex, second.fenIndex,
                       "Same date + same seed must produce the same fenIndex")
        XCTAssertEqual(first.game.white, second.game.white,
                       "Same date + same seed must produce the same game")
    }

    // MARK: - Test 10: Seed is written to UserDefaults on first call

    func testSeedIsWrittenToUserDefaultsOnFirstCall() {
        let key = "deviceGameSeed"
        UserDefaults.standard.removeObject(forKey: key)

        XCTAssertNil(UserDefaults.standard.object(forKey: key),
                     "Key must be absent before first call")

        let library = GameLibrary.shared
        let date = makeDate(year: 2026, month: 2, day: 15, hour: 9)
        _ = GameScheduler.resolve(date: date, library: library)

        XCTAssertNotNil(UserDefaults.standard.object(forKey: key),
                        "deviceGameSeed must be written to UserDefaults after first resolve call")
    }

    // MARK: - Test 11: All games have a non-empty finalMove

    func testAllGamesHaveNonEmptyFinalMove() {
        for (i, game) in GameLibrary.shared.games.enumerated() {
            XCTAssertFalse(game.finalMove.isEmpty,
                           "Game \(i) (\(game.white) vs \(game.black)) must have a non-empty finalMove")
        }
    }

    // MARK: - Private helpers mirroring GameScheduler's internal formulas

    private func daysSinceEpoch(for date: Date) -> Int {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone.current
        let epoch = cal.date(from: DateComponents(year: 2026, month: 1, day: 1))!
        return cal.dateComponents([.day], from: epoch, to: date).day ?? 0
    }

    private func gameIndex(hourlyIndex: Int, count: Int) -> Int {
        return ((hourlyIndex % count) + count) % count
    }
}
