import XCTest
@testable import ChessClock

@MainActor
final class ClockServiceTests: XCTestCase {

    // MARK: - Helpers

    private func makeDate(year: Int = 2026, month: Int = 1, day: Int = 15,
                          hour: Int, minute: Int) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone.current
        let components = DateComponents(year: year, month: month, day: day,
                                        hour: hour, minute: minute)
        return calendar.date(from: components)!
    }

    // MARK: - ClockState field tests

    func testMorningTime_hoursMinutesAndAMFlag() {
        // 3:45 AM → hour=3, minute=45, isAM=true
        let date = makeDate(hour: 3, minute: 45)
        let state = ClockService.makeState(at: date)
        XCTAssertEqual(state.hour, 3)
        XCTAssertEqual(state.minute, 45)
        XCTAssertTrue(state.isAM)
    }

    func testNoon_hour12PM() {
        // 12:00 PM (noon) → hour=12, isAM=false
        let date = makeDate(hour: 12, minute: 0)
        let state = ClockService.makeState(at: date)
        XCTAssertEqual(state.hour, 12)
        XCTAssertEqual(state.minute, 0)
        XCTAssertFalse(state.isAM)
    }

    func testMidnight_hour12AM() {
        // 12:00 AM (midnight, 00:00) → hour=12, isAM=true
        let date = makeDate(hour: 0, minute: 0)
        let state = ClockService.makeState(at: date)
        XCTAssertEqual(state.hour, 12)
        XCTAssertEqual(state.minute, 0)
        XCTAssertTrue(state.isAM)
    }

    func testLateEvening_hour11PM() {
        // 23:59 → hour=11, minute=59, isAM=false
        let date = makeDate(hour: 23, minute: 59)
        let state = ClockService.makeState(at: date)
        XCTAssertEqual(state.hour, 11)
        XCTAssertEqual(state.minute, 59)
        XCTAssertFalse(state.isAM)
    }

    func testAMtoPM_isAMFlips() {
        // 11:59 AM → isAM=true; 12:00 PM → isAM=false
        let before = makeDate(hour: 11, minute: 59)
        let atNoon = makeDate(hour: 12, minute: 0)
        XCTAssertTrue(ClockService.makeState(at: before).isAM)
        XCTAssertFalse(ClockService.makeState(at: atNoon).isAM)
    }

    func testGameSwitchesBetween_11_59AM_and_12_00PM() {
        // GameScheduler uses a different half-day slot at noon vs 11:59 AM.
        // The games may or may not differ (depends on library size & date), but
        // the isAM flag must flip and the fen must still match hour-1 position.
        let before = makeDate(hour: 11, minute: 59)
        let atNoon = makeDate(hour: 12, minute: 0)
        let stateBefore = ClockService.makeState(at: before)
        let stateAt = ClockService.makeState(at: atNoon)
        // isAM flips
        XCTAssertTrue(stateBefore.isAM)
        XCTAssertFalse(stateAt.isAM)
        // FEN is still consistent with the game's positions array
        XCTAssertEqual(stateBefore.fen, stateBefore.game.positions[stateBefore.hour - 1])
        XCTAssertEqual(stateAt.fen, stateAt.game.positions[stateAt.hour - 1])
    }

    func testFenAlwaysMatchesGamePositionForCurrentHour() {
        // state.fen == state.game.positions[state.hour - 1] for any date
        let date = makeDate(hour: 5, minute: 30)
        let state = ClockService.makeState(at: date)
        XCTAssertEqual(state.fen, state.game.positions[state.hour - 1])
    }

    func testStateIsConsistentAcrossVariousDates() {
        // Should produce valid, crash-free ClockState for any date
        let testDates: [(Int, Int, Int, Int, Int)] = [
            (2026, 1, 1, 0, 0),    // epoch midnight
            (2026, 2, 21, 9, 15),  // today morning
            (2025, 12, 31, 23, 59), // pre-epoch late night
            (2099, 6, 15, 12, 0),  // far future noon
            (2026, 6, 15, 1, 0),   // hour 1 AM
            (2026, 6, 15, 12, 0),  // hour 12 PM
        ]
        for (y, mo, d, h, mi) in testDates {
            let date = makeDate(year: y, month: mo, day: d, hour: h, minute: mi)
            let state = ClockService.makeState(at: date)
            XCTAssertGreaterThanOrEqual(state.hour, 1, "hour out of range for \(y)-\(mo)-\(d) \(h):\(mi)")
            XCTAssertLessThanOrEqual(state.hour, 12, "hour out of range for \(y)-\(mo)-\(d) \(h):\(mi)")
            XCTAssertGreaterThanOrEqual(state.minute, 0)
            XCTAssertLessThanOrEqual(state.minute, 59)
            XCTAssertEqual(state.fen, state.game.positions[state.hour - 1],
                           "FEN mismatch for \(y)-\(mo)-\(d) \(h):\(mi)")
        }
    }
}
