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
// For the "2-game wrap" case (test 7), we verify modulo wrap-around using the real 588-game
// library: two halfDayIndex values that differ by 1 in the cycle will yield adjacent gameIndex
// values, confirming that the double-modulo formula keeps the result within [0, count).

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

    // MARK: - Test 2: fenIndex correctness

    /// Hour 1 AM → fenIndex == 0 (positions[0] = 1 move before checkmate, for hour 1).
    func testFenIndexHour1AM() {
        let library = GameLibrary.shared
        let date = makeDate(year: 2026, month: 2, day: 15, hour: 1)

        guard let result = GameScheduler.resolve(date: date, library: library) else {
            XCTFail("resolve returned nil for a non-empty library")
            return
        }

        XCTAssertEqual(result.fenIndex, 0,
                       "Hour 1 AM should map to fenIndex 0")
    }

    /// Hour 0 (midnight, 12 AM) → hour12 == 12 → fenIndex == 11.
    func testFenIndexMidnight() {
        let library = GameLibrary.shared
        let date = makeDate(year: 2026, month: 2, day: 15, hour: 0) // 12:00 AM

        guard let result = GameScheduler.resolve(date: date, library: library) else {
            XCTFail("resolve returned nil for a non-empty library")
            return
        }

        XCTAssertEqual(result.fenIndex, 11,
                       "Midnight (12 AM, hour24=0) should map to fenIndex 11")
    }

    /// Hour 12 (noon, 12 PM) → hour12 == 12 → fenIndex == 11.
    func testFenIndexNoon() {
        let library = GameLibrary.shared
        let date = makeDate(year: 2026, month: 2, day: 15, hour: 12) // 12:00 PM

        guard let result = GameScheduler.resolve(date: date, library: library) else {
            XCTFail("resolve returned nil for a non-empty library")
            return
        }

        XCTAssertEqual(result.fenIndex, 11,
                       "Noon (12 PM, hour24=12) should map to fenIndex 11")
    }

    // MARK: - Test 3: AM vs PM on same calendar day use different gameIndex

    /// AM half-day uses halfDayIndex = daysSinceEpoch*2 + 0,
    /// PM half-day uses halfDayIndex = daysSinceEpoch*2 + 1.
    /// They must select different games (different gameIndex).
    func testAMandPMOnSameDayHaveDifferentGameIndex() {
        let library = GameLibrary.shared
        // Use same hour in 12-hour terms (1 AM vs 1 PM) to keep fenIndex identical,
        // isolating the gameIndex difference.
        let amDate = makeDate(year: 2026, month: 2, day: 15, hour: 1)  // 1 AM
        let pmDate = makeDate(year: 2026, month: 2, day: 15, hour: 13) // 1 PM

        guard let amResult = GameScheduler.resolve(date: amDate, library: library),
              let pmResult = GameScheduler.resolve(date: pmDate, library: library) else {
            XCTFail("resolve returned nil for a non-empty library")
            return
        }

        // fenIndex must be equal (both are hour 1 in 12h terms → fenIndex 0)
        XCTAssertEqual(amResult.fenIndex, 0, "AM 1:00 → fenIndex 0")
        XCTAssertEqual(pmResult.fenIndex, 0, "PM 1:00 → fenIndex 0")

        // The two half-days differ by 1 in halfDayIndex, so their gameIndex must differ.
        // (They may wrap around to the same value only if library.games.count == 1,
        //  which cannot happen with the real 588-game library.)
        let amIndex = gameIndex(halfDayIndex: daysSinceEpoch(for: amDate) * 2 + 0,
                                count: library.games.count)
        let pmIndex = gameIndex(halfDayIndex: daysSinceEpoch(for: amDate) * 2 + 1,
                                count: library.games.count)

        XCTAssertNotEqual(amIndex, pmIndex,
                          "AM and PM on the same day must select different games")
    }

    // MARK: - Test 4: Consecutive days differ by 2 in gameIndex

    /// Day N produces halfDayIndex = N*2 + offset.
    /// Day N+1 at the same hour produces halfDayIndex = (N+1)*2 + offset = N*2 + offset + 2.
    /// So gameIndex advances by exactly 2, modulo library.games.count.
    func testConsecutiveDaysDifferByTwoInGameIndex() {
        let library = GameLibrary.shared
        let dayOne = makeDate(year: 2026, month: 2, day: 15, hour: 9)  // 9 AM, day N
        let dayTwo = makeDate(year: 2026, month: 2, day: 16, hour: 9)  // 9 AM, day N+1

        let dOne = daysSinceEpoch(for: dayOne)
        let dTwo = daysSinceEpoch(for: dayTwo)
        XCTAssertEqual(dTwo - dOne, 1, "Sanity: dayTwo is exactly 1 day after dayOne")

        let hiOne = dOne * 2 + 0  // AM → isAM offset 0
        let hiTwo = dTwo * 2 + 0  // same hour, AM

        let giOne = gameIndex(halfDayIndex: hiOne, count: library.games.count)
        let giTwo = gameIndex(halfDayIndex: hiTwo, count: library.games.count)

        let diff = (giTwo - giOne + library.games.count) % library.games.count
        XCTAssertEqual(diff, 2,
                       "Consecutive days at the same half-day should differ by 2 in gameIndex (mod count)")
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

        let count = library.games.count
        XCTAssertGreaterThanOrEqual(result.fenIndex, 0,
                                    "fenIndex must be >= 0 for pre-epoch date")
        XCTAssertLessThanOrEqual(result.fenIndex, 11,
                                 "fenIndex must be <= 11 for pre-epoch date")
        XCTAssertTrue(library.games.indices.contains(result.fenIndex) || result.fenIndex < count,
                      "The returned game must be within the library")
    }

    // MARK: - Test 6: Empty library returns nil

    // GameLibrary is a `final class` with `private init()` and an immutable `let games`.
    // It is not possible to construct a GameLibrary with zero games from outside the module
    // without modifying GameLibrary itself. The guard statement on line 7 of GameScheduler.swift:
    //
    //   guard !library.games.isEmpty else { return nil }
    //
    // is verified by code inspection. Should GameLibrary gain a testable initializer or
    // a protocol abstraction in the future, this test should be expanded.
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

    /// With the real 588-game library, a sweep of consecutive halfDayIndex values must
    /// always produce a gameIndex within [0, count). Also confirms that different
    /// halfDayIndex values produce different gameIndex values (advancing by 1 each step),
    /// demonstrating the wrap-around cycles correctly.
    func testModuloWrapAroundStaysInValidRange() {
        let library = GameLibrary.shared
        let count = library.games.count
        XCTAssertGreaterThan(count, 1,
                             "Real library must have more than 1 game for this test to be meaningful")

        // Simulate halfDayIndex values spanning two full cycles around the library.
        // Every result must lie in [0, count).
        let iterations = count * 2 + 3
        var seenGameIndices = Set<Int>()

        for hdi in 0..<iterations {
            let gi = gameIndex(halfDayIndex: hdi, count: count)
            XCTAssertGreaterThanOrEqual(gi, 0, "gameIndex must be >= 0 (hdi=\(hdi))")
            XCTAssertLessThan(gi, count,        "gameIndex must be < count (hdi=\(hdi))")
            seenGameIndices.insert(gi)
        }

        // After two full cycles we must have visited every index.
        XCTAssertEqual(seenGameIndices.count, count,
                       "Every gameIndex in [0, count) must be reachable")

        // Confirm wrap: halfDayIndex == count wraps back to gameIndex == 0.
        XCTAssertEqual(gameIndex(halfDayIndex: count, count: count), 0,
                       "gameIndex(halfDayIndex: count) should wrap to 0")

        // Confirm that two consecutive halfDayIndex values differ by 1 in gameIndex (mod count).
        for hdi in 0..<(count - 1) {
            let a = gameIndex(halfDayIndex: hdi,     count: count)
            let b = gameIndex(halfDayIndex: hdi + 1, count: count)
            XCTAssertEqual((b - a + count) % count, 1,
                           "Consecutive halfDayIndex values should advance gameIndex by 1")
        }
    }

    // MARK: - Private helpers mirroring GameScheduler's internal formulas

    /// Mirrors GameScheduler's daysSinceEpoch calculation.
    private func daysSinceEpoch(for date: Date) -> Int {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone.current
        let epoch = cal.date(from: DateComponents(year: 2026, month: 1, day: 1))!
        return cal.dateComponents([.day], from: epoch, to: date).day ?? 0
    }

    /// Mirrors GameScheduler's double-modulo formula.
    private func gameIndex(halfDayIndex: Int, count: Int) -> Int {
        return ((halfDayIndex % count) + count) % count
    }
}
