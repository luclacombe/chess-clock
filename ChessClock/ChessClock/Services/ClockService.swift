import Combine
import Foundation

@MainActor
final class ClockService: ObservableObject {
    @Published private(set) var state: ClockState

    private var cancellable: AnyCancellable?

    // Placeholder game used when games.json has not been bundled yet.
    static let placeholder = ChessGame(
        white: "Loading...", black: "Loading...",
        whiteElo: "?", blackElo: "?",
        tournament: "Chess Clock", year: 2026,
        positions: Array(repeating: "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1", count: 12)
    )

    init() {
        state = ClockService.makeState(for: Date())
        cancellable = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] date in
                guard let self else { return }
                self.state = ClockService.makeState(for: date)
            }
    }

    private static func makeState(for date: Date) -> ClockState {
        let library = GameLibrary.shared

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone.current
        let components = calendar.dateComponents([.hour, .minute], from: date)
        let hour24 = components.hour ?? 0
        let minute  = components.minute ?? 0
        let isAM    = hour24 < 12
        let hour12  = hour24 % 12 == 0 ? 12 : hour24 % 12

        if let resolved = GameScheduler.resolve(date: date, library: library) {
            let fen = resolved.game.positions[resolved.fenIndex]
            return ClockState(
                hour: hour12,
                minute: minute,
                isAM: isAM,
                game: resolved.game,
                fen: fen
            )
        } else {
            // Library is empty — use placeholder so the UI never crashes.
            let fenIndex = hour12 - 1
            return ClockState(
                hour: hour12,
                minute: minute,
                isAM: isAM,
                game: placeholder,
                fen: placeholder.positions[fenIndex]
            )
        }
    }
}
