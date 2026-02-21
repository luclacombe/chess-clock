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
    // AM hours pull from games where White delivers checkmate (mateBy == "white").
    // PM hours pull from games where Black delivers checkmate (mateBy == "black").
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

        // Filter games by who wins: AM = White checkmates, PM = Black checkmates
        let mateByFilter = isAM ? "white" : "black"
        let pool = library.games.filter { $0.mateBy == mateByFilter }
        let games = pool.isEmpty ? library.games : pool

        let actualSeed = seed ?? getOrCreateSeed()
        let halfDayIndex = daysSinceEpoch * 2 + (isAM ? 0 : 1)
        let gameIndex = (((halfDayIndex + actualSeed) % games.count) + games.count) % games.count
        let fenIndex = hour12 - 1  // 0–11

        return (game: games[gameIndex], fenIndex: fenIndex)
    }
}
