import Combine
import Foundation

// MARK: - Supporting types

struct PuzzleResult: Codable {
    let succeeded: Bool
    let triesUsed: Int   // 1, 2, or 3
}

struct PuzzleStats: Codable {
    var winsOnFirstTry: Int = 0
    var winsOnSecondTry: Int = 0
    var winsOnThirdTry: Int = 0
    var losses: Int = 0

    var totalPlayed: Int { winsOnFirstTry + winsOnSecondTry + winsOnThirdTry + losses }
}

// MARK: - GuessService

/// Tracks puzzle attempts and all-time stats. Persists to UserDefaults.
@MainActor
final class GuessService: ObservableObject {

    // MARK: - Published state

    @Published private(set) var engine: PuzzleEngine?        // nil = not started or complete
    @Published private(set) var result: PuzzleResult?        // non-nil if done this hour
    @Published private(set) var stats: PuzzleStats
    @Published private(set) var currentHourKey: String

    // MARK: - Private

    private var cancellable: AnyCancellable?

    // MARK: - Init

    init(clockService: ClockService) {
        let key = Self.hourKey(for: Date())
        currentHourKey = key
        result = Self.loadResult(for: key)
        stats = Self.loadStats()

        cancellable = clockService.$state
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                guard let self else { return }
                let key = Self.hourKey(for: Date())
                if key != self.currentHourKey {
                    self.currentHourKey = key
                    self.engine = nil
                    self.result = Self.loadResult(for: key)
                }
            }
    }

    // MARK: - Public API

    var hasResult: Bool { result != nil }

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

    /// Call when entering puzzle mode.
    /// Returns initial opponent auto-plays (empty if user moves first).
    /// Returns nil if this hour's result already exists — show result instead.
    func startPuzzle(game: ChessGame, hour: Int) -> [(uci: String, fen: String)]? {
        if result != nil { return nil }
        if engine == nil {
            engine = PuzzleEngine(game: game, hour: hour)
        }
        // PuzzleEngine is a struct — extract, mutate, write back
        var eng = engine!
        let autoPlays = eng.advancePastOpponentMoves()
        engine = eng
        return autoPlays
    }

    /// Forward a user's move to the engine. Returns the engine's result or nil if no session.
    func submitMove(uci: String) -> PuzzleEngine.SubmitResult? {
        guard var eng = engine else { return nil }
        let submitResult = eng.submit(uci: uci)
        engine = eng   // write back mutated struct
        switch submitResult {
        case .success:
            finalizeResult(succeeded: true, triesUsed: eng.triesUsed)
            engine = nil
        case .failed:
            finalizeResult(succeeded: false, triesUsed: eng.triesUsed)
            engine = nil
        default:
            break
        }
        return submitResult
    }

    // MARK: - Backward compatibility (removed when Agent D rewrites views)

    /// Legacy type kept so old view files compile. Remove after Agent D updates views.
    struct Guess: Codable {
        let move: String
        let isCorrect: Bool
        let actualMove: String
    }

    /// Legacy computed var for old InfoPanelView/GuessMoveView.
    var guess: Guess? {
        guard let r = result else { return nil }
        return Guess(move: "", isCorrect: r.succeeded, actualMove: "")
    }

    /// Legacy alias for hasResult.
    var hasGuessed: Bool { hasResult }

    /// Legacy no-op — puzzles are now recorded via submitMove.
    func recordGuess(move: String, isCorrect: Bool, actualMove: String) { /* no-op */ }

    // MARK: - Private helpers

    private func finalizeResult(succeeded: Bool, triesUsed: Int) {
        let r = PuzzleResult(succeeded: succeeded, triesUsed: triesUsed)
        result = r
        saveResult(r, for: currentHourKey)
        updateStats(result: r)
    }

    private func updateStats(result: PuzzleResult) {
        if result.succeeded {
            switch result.triesUsed {
            case 1: stats.winsOnFirstTry += 1
            case 2: stats.winsOnSecondTry += 1
            default: stats.winsOnThirdTry += 1
            }
        } else {
            stats.losses += 1
        }
        saveStats(stats)
    }

    private func saveResult(_ r: PuzzleResult, for key: String) {
        if let data = try? JSONEncoder().encode(r) {
            UserDefaults.standard.set(data, forKey: Self.udResultKey(key))
        }
    }

    private func saveStats(_ s: PuzzleStats) {
        if let data = try? JSONEncoder().encode(s) {
            UserDefaults.standard.set(data, forKey: "chessclock_stats_v1")
        }
    }

    private static func loadResult(for key: String) -> PuzzleResult? {
        guard let data = UserDefaults.standard.data(forKey: udResultKey(key)) else { return nil }
        return try? JSONDecoder().decode(PuzzleResult.self, from: data)
    }

    private static func loadStats() -> PuzzleStats {
        guard let data = UserDefaults.standard.data(forKey: "chessclock_stats_v1"),
              let s = try? JSONDecoder().decode(PuzzleStats.self, from: data) else { return PuzzleStats() }
        return s
    }

    private static func udResultKey(_ key: String) -> String { "chessclock_result_\(key)" }

    // Internal (not private) so tests can compute the key
    static func hourKey(for date: Date) -> String {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone.current
        let c = cal.dateComponents([.year, .month, .day, .hour], from: date)
        return "\(c.year ?? 0)-\(c.month ?? 0)-\(c.day ?? 0)-\(c.hour ?? 0)"
    }
}
