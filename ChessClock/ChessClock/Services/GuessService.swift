import Combine
import Foundation

/// Tracks the user's "Guess Move" attempts, persisted across app restarts.
@MainActor
final class GuessService: ObservableObject {

    struct Guess: Codable {
        let move: String        // UCI move the user played, e.g. "e7e8q"
        let isCorrect: Bool
        let actualMove: String  // The actual checkmate move from the game
    }

    @Published private(set) var currentHourKey: String
    @Published private(set) var guess: Guess?

    private var cancellable: AnyCancellable?

    init(clockService: ClockService) {
        currentHourKey = Self.hourKey(for: Date())
        guess = Self.loadGuess(for: currentHourKey)

        // Watch for hour changes by observing the clock state every second.
        cancellable = clockService.$state
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                guard let self else { return }
                let key = Self.hourKey(for: Date())
                if key != self.currentHourKey {
                    self.currentHourKey = key
                    self.guess = Self.loadGuess(for: key)
                }
            }
    }

    /// Record the user's guess for the current hour.
    func recordGuess(move: String, isCorrect: Bool, actualMove: String) {
        let g = Guess(move: move, isCorrect: isCorrect, actualMove: actualMove)
        guess = g
        if let data = try? JSONEncoder().encode(g) {
            UserDefaults.standard.set(data, forKey: udKey(currentHourKey))
        }
    }

    /// True if the user has already submitted a guess for the current hour.
    var hasGuessed: Bool { guess != nil }

    /// Seconds until the start of the next hour (when the puzzle resets).
    var secondsUntilNextHour: Int {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone.current
        let now = Date()
        var comps = cal.dateComponents([.year, .month, .day, .hour], from: now)
        comps.hour = (comps.hour ?? 0) + 1
        comps.minute = 0
        comps.second = 0
        guard let nextHour = cal.date(from: comps) else { return 3600 }
        return max(0, Int(nextHour.timeIntervalSince(now)))
    }

    // MARK: - Private

    private func udKey(_ key: String) -> String { "chessclock_guess_\(key)" }

    private static func hourKey(for date: Date) -> String {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone.current
        let c = cal.dateComponents([.year, .month, .day, .hour], from: date)
        return "\(c.year ?? 0)-\(c.month ?? 0)-\(c.day ?? 0)-\(c.hour ?? 0)"
    }

    private static func loadGuess(for key: String) -> Guess? {
        let udKey = "chessclock_guess_\(key)"
        guard let data = UserDefaults.standard.data(forKey: udKey) else { return nil }
        return try? JSONDecoder().decode(Guess.self, from: data)
    }
}
