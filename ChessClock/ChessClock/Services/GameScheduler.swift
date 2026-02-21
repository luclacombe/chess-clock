import Foundation

struct GameScheduler {
    // Returns the game and fenIndex appropriate for `date`, or nil if library is empty.
    // fenIndex is 0-based: game.positions[fenIndex] is the FEN to display.
    static func resolve(date: Date, library: GameLibrary) -> (game: ChessGame, fenIndex: Int)? {
        guard !library.games.isEmpty else { return nil }

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone.current

        let epoch = calendar.date(from: DateComponents(year: 2026, month: 1, day: 1))!
        let daysSinceEpoch = calendar.dateComponents([.day], from: epoch, to: date).day ?? 0

        let components = calendar.dateComponents([.hour], from: date)
        let hour24 = components.hour ?? 0
        let isAM = hour24 < 12
        let hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12

        let halfDayIndex = daysSinceEpoch * 2 + (isAM ? 0 : 1)
        let gameIndex = ((halfDayIndex % library.games.count) + library.games.count) % library.games.count
        let fenIndex = hour12 - 1  // 0–11

        return (game: library.games[gameIndex], fenIndex: fenIndex)
    }
}
