import Foundation

final class GameLibrary {
    static let shared = GameLibrary()
    let games: [ChessGame]

    private init() {
        guard let url = Bundle.main.url(forResource: "games", withExtension: "json") else {
            print("GameLibrary: games.json not found in bundle — returning empty library")
            games = []
            return
        }
        do {
            let data = try Data(contentsOf: url)
            games = try JSONDecoder().decode([ChessGame].self, from: data)
            print("GameLibrary: loaded \(games.count) games")
        } catch {
            print("GameLibrary: failed to decode games.json — \(error)")
            games = []
        }
    }
}
