import Combine
import Foundation

@MainActor
final class ClockService: ObservableObject {
    @Published private(set) var state: ClockState

    private var cancellable: AnyCancellable?
    private var refCount = 0

    // Placeholder game used when games.json has not been bundled yet.
    static let placeholder = ChessGame(
        white: "Loading...", black: "Loading...",
        whiteElo: "?", blackElo: "?",
        tournament: "Chess Clock", year: 2026,
        finalMove: "",
        positions: Array(repeating: "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1", count: 12)
    )

    init() {
        state = ClockService.makeState()
        startTimer()
    }

    /// Increment consumer count. Restarts timer if it was paused.
    /// Immediately refreshes state so the clock is correct the instant the UI appears.
    func resume() {
        refCount += 1
        if refCount == 1 {
            state = ClockService.makeState()
            startTimer()
        }
    }

    /// Decrement consumer count. Stops timer when no consumers are visible.
    func pause() {
        refCount = max(0, refCount - 1)
        if refCount == 0 {
            cancellable = nil
        }
    }

    private func startTimer() {
        cancellable = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] date in
                guard let self else { return }
                self.state = ClockService.makeState(at: date)
            }
    }

    // Hour-keyed cache for GameScheduler resolution (only changes hourly).
    private static var cachedHour24: Int = -1
    private static var cachedResolution: (game: ChessGame, fenIndex: Int)?

    static func makeState(at date: Date = Date()) -> ClockState {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone.current
        let components = calendar.dateComponents([.hour, .minute, .second], from: date)
        let hour24 = components.hour ?? 0
        let minute  = components.minute ?? 0
        let second  = components.second ?? 0
        let isAM    = hour24 < 12
        let hour12  = hour24 % 12 == 0 ? 12 : hour24 % 12

        // Cache game resolution — only changes hourly
        if hour24 != cachedHour24 {
            cachedHour24 = hour24
            cachedResolution = GameScheduler.resolve(date: date, library: GameLibrary.shared)
        }

        if let resolved = cachedResolution {
            let fen = resolved.game.positions[resolved.fenIndex]
            return ClockState(
                hour: hour12,
                minute: minute,
                second: second,
                isAM: isAM,
                isFlipped: !isAM,
                game: resolved.game,
                fen: fen
            )
        } else {
            return ClockState(
                hour: hour12,
                minute: minute,
                second: second,
                isAM: isAM,
                isFlipped: !isAM,
                game: placeholder,
                fen: placeholder.positions[0]
            )
        }
    }
}
