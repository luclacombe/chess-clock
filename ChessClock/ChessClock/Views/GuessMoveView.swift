import SwiftUI
import Combine

/// Full interactive board for the "Guess Move" puzzle.
/// Shown in its own floating window via GuessMoveWindowManager.
struct GuessMoveView: View {
    let state: ClockState
    @ObservedObject var guessService: GuessService

    @State private var showResult = false
    @State private var showRetryCountdown = false
    @State private var countdownSeconds = 0

    private let countdownTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            VStack(spacing: 12) {
                header
                boardSection
                instructionText
            }
            .padding(16)

            // Result overlay
            if showResult, let guess = guessService.guess {
                MoveResultView(guess: guess, game: state.game) {
                    showResult = false
                }
            }

            // Retry countdown overlay
            if showRetryCountdown {
                retryOverlay
            }
        }
        .frame(width: 380, height: 460)
        .onReceive(countdownTimer) { _ in
            if showRetryCountdown {
                countdownSeconds = max(0, countdownSeconds - 1)
            }
        }
    }

    // MARK: - Sub-views

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Guess the Move")
                    .font(.headline)
                Text("\(state.game.white) vs \(state.game.black), \(state.game.year)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Text(state.isAM ? "AM" : "PM")
                .font(.caption2.weight(.bold))
                .foregroundColor(.secondary)
        }
    }

    private var boardSection: some View {
        Group {
            if guessService.hasGuessed {
                // Always positions[0] — the board right before the final checkmate
                BoardView(fen: state.game.positions[0], isFlipped: state.isFlipped)
                    .overlay(
                        alreadyGuessedBadge,
                        alignment: .bottom
                    )
                    .contentShape(Rectangle())
                    .onTapGesture { showRetryCountdown = true }
            } else {
                // Always positions[0] so the user guesses from the mate-in-1 position
                InteractiveBoardView(fen: state.game.positions[0], isFlipped: state.isFlipped) { move in
                    handleMove(move)
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }

    private var alreadyGuessedBadge: some View {
        Text("Tap to see result")
            .font(.caption2.weight(.medium))
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Color.black.opacity(0.6))
            .cornerRadius(5)
            .padding(.bottom, 6)
    }

    private var instructionText: some View {
        Group {
            if guessService.hasGuessed {
                if let guess = guessService.guess {
                    HStack(spacing: 6) {
                        Image(systemName: guess.isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(guess.isCorrect ? .green : .red)
                        Text(guess.isCorrect ? "Correct!" : "Incorrect — the move was \(guess.actualMove.uppercased())")
                            .font(.caption)
                    }
                }
            } else {
                Text("Drag or click a piece, then choose its destination.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }

    private var retryOverlay: some View {
        ZStack {
            Color.black.opacity(0.55).ignoresSafeArea()
            VStack(spacing: 12) {
                Text("Try again in")
                    .font(.headline)
                    .foregroundColor(.white)
                Text(countdownString(countdownSeconds))
                    .font(.system(size: 36, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                Button("Close") { showRetryCountdown = false }
                    .buttonStyle(.bordered)
            }
            .padding(24)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        }
        .onAppear { countdownSeconds = guessService.secondsUntilNextHour }
    }

    // MARK: - Logic

    private func handleMove(_ move: ChessMove) {
        let actual = state.game.finalMove
        let isCorrect = move.uci == actual
        guessService.recordGuess(move: move.uci, isCorrect: isCorrect, actualMove: actual)
        showResult = true
    }

    private func countdownString(_ s: Int) -> String {
        String(format: "%d:%02d", s / 60, s % 60)
    }
}
