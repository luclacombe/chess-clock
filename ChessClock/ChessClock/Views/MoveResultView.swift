import SwiftUI
import Combine

/// Full-screen overlay shown after the user completes a guess.
struct MoveResultView: View {
    let guess: GuessService.Guess
    let game: ChessGame
    /// Called when the user dismisses this result.
    let onDismiss: () -> Void

    @State private var secondsLeft: Int = 0
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            Color.black.opacity(0.55).ignoresSafeArea()

            VStack(spacing: 20) {
                // Result icon + headline
                VStack(spacing: 8) {
                    Image(systemName: guess.isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .font(.system(size: 52))
                        .foregroundColor(guess.isCorrect ? .green : .red)

                    Text(guess.isCorrect ? "You got it!" : "Not quite")
                        .font(.title2.weight(.bold))
                        .foregroundColor(.white)
                }

                Divider().background(Color.white.opacity(0.3))

                // Move comparison
                VStack(spacing: 6) {
                    moveRow(label: "Your move", uci: guess.move, highlight: guess.isCorrect ? .green : .red)
                    if !guess.isCorrect {
                        moveRow(label: "Actual move", uci: guess.actualMove, highlight: .green)
                    }
                }

                // Game info
                VStack(spacing: 4) {
                    Text("\(game.white) vs \(game.black)")
                        .font(.footnote.weight(.semibold))
                        .foregroundColor(.white)
                    Text("\(game.tournament), \(game.year)")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }

                Divider().background(Color.white.opacity(0.3))

                // Next puzzle countdown
                VStack(spacing: 4) {
                    Text("Next puzzle in")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                    Text(countdownString(secondsLeft))
                        .font(.title3.weight(.semibold))
                        .foregroundColor(.white)
                        .monospacedDigit()
                }

                Button("Close") { onDismiss() }
                    .buttonStyle(.borderedProminent)
            }
            .padding(24)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
            .padding(24)
        }
        .onAppear { secondsLeft = secondsUntilNextHour() }
        .onReceive(timer) { _ in
            secondsLeft = max(0, secondsLeft - 1)
        }
    }

    // MARK: - Sub-views

    private func moveRow(label: String, uci: String, highlight: Color) -> some View {
        HStack(spacing: 8) {
            Text(label + ":")
                .font(.caption.weight(.semibold))
                .foregroundColor(.white.opacity(0.75))
                .frame(width: 80, alignment: .trailing)
            Text(uci.isEmpty ? "—" : uci.uppercased())
                .font(.body.weight(.bold))
                .foregroundColor(highlight)
                .padding(.horizontal, 10)
                .padding(.vertical, 3)
                .background(highlight.opacity(0.15))
                .cornerRadius(6)
        }
    }

    // MARK: - Helpers

    private func countdownString(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%d:%02d", m, s)
    }

    private func secondsUntilNextHour() -> Int {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone.current
        let now = Date()
        var c = cal.dateComponents([.year, .month, .day, .hour], from: now)
        c.hour = (c.hour ?? 0) + 1
        c.minute = 0; c.second = 0
        guard let next = cal.date(from: c) else { return 3600 }
        return max(0, Int(next.timeIntervalSince(now)))
    }
}
