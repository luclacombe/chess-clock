import Foundation

struct GameScheduler {
    // Reads the device seed from UserDefaults. If absent, generates a random one,
    // stores it, and returns it. Deterministic per device across days.
    static func getOrCreateSeed() -> Int {
        let key = "deviceGameSeed"
        if let stored = UserDefaults.standard.object(forKey: key) as? Int {
            return stored
        }
        let newSeed = Int.random(in: 0..<Int.max)
        UserDefaults.standard.set(newSeed, forKey: key)
        return newSeed
    }

    // Returns the game and fenIndex appropriate for `date`, or nil if library is empty.
    // fenIndex is 0-based: game.positions[fenIndex] is the FEN to display.
    // seed: when nil, reads or creates the device seed from UserDefaults.
    static func resolve(date: Date, library: GameLibrary, seed: Int? = nil) -> (game: ChessGame, fenIndex: Int)? {
        guard !library.games.isEmpty else { return nil }

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone.current

        let epoch = calendar.date(from: DateComponents(year: 2026, month: 1, day: 1))!
        let daysSinceEpoch = calendar.dateComponents([.day], from: epoch, to: date).day ?? 0

        let components = calendar.dateComponents([.hour], from: date)
        let hour24 = components.hour ?? 0
        let isAM = hour24 < 12
        let hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12

        let actualSeed = seed ?? getOrCreateSeed()
        let halfDayIndex = daysSinceEpoch * 2 + (isAM ? 0 : 1)
        let gameIndex = (((halfDayIndex + actualSeed) % library.games.count) + library.games.count) % library.games.count
        let fenIndex = hour12 - 1  // 0–11

        return (game: library.games[gameIndex], fenIndex: fenIndex)
    }
}
