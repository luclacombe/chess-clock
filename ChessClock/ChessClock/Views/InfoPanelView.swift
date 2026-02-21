import SwiftUI

/// Shown when the user taps the board in the main clock view.
/// Displays game metadata and a "Guess Move" button.
struct InfoPanelView: View {
    let state: ClockState
    @ObservedObject var guessService: GuessService
    let onBack: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: onBack) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.caption.weight(.semibold))
                        Text("Back")
                            .font(.caption.weight(.semibold))
                    }
                    .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                Spacer()
            }
            .padding(.bottom, 10)

            // Mini board preview
            BoardView(fen: state.fen, isFlipped: state.isFlipped)
                .frame(maxWidth: .infinity)
                .aspectRatio(1, contentMode: .fit)
                .overlay(alignment: .bottomTrailing) {
                    Text(state.isAM ? "AM" : "PM")
                        .font(.caption2.weight(.bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Color.black.opacity(0.55))
                        .cornerRadius(4)
                        .padding(4)
                }

            Spacer(minLength: 10)

            // Game metadata
            gameMetadata

            Spacer(minLength: 12)

            // Guess Move button
            guessMoveButton
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Sub-views

    private var gameMetadata: some View {
        VStack(alignment: .leading, spacing: 4) {
            metaRow(label: "White", value: playerString(name: state.game.white, elo: state.game.whiteElo))
            metaRow(label: "Black", value: playerString(name: state.game.black, elo: state.game.blackElo))
            Divider().padding(.vertical, 2)
            metaRow(label: "Event", value: state.game.tournament)
            metaRow(label: "Year",  value: yearString)
            if let round = state.game.round {
                metaRow(label: "Round", value: round)
            }
        }
        .font(.caption)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func metaRow(label: String, value: String) -> some View {
        HStack(alignment: .top, spacing: 4) {
            Text(label + ":")
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
                .frame(width: 44, alignment: .leading)
            Text(value)
                .lineLimit(2)
                .minimumScaleFactor(0.85)
        }
    }

    private var guessMoveButton: some View {
        Group {
            if guessService.hasGuessed {
                // Already guessed — just show the result inline and a reminder
                VStack(spacing: 6) {
                    resultBadge
                    Button("Open Result") {
                        GuessMoveWindowManager.shared.open(state: state, guessService: guessService)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            } else {
                Button {
                    GuessMoveWindowManager.shared.open(state: state, guessService: guessService)
                } label: {
                    Label("Guess Move", systemImage: "chess.king.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.regular)
            }
        }
    }

    private var resultBadge: some View {
        Group {
            if let guess = guessService.guess {
                HStack(spacing: 6) {
                    Image(systemName: guess.isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(guess.isCorrect ? .green : .red)
                    Text(guess.isCorrect ? "Correct!" : "Incorrect")
                        .font(.caption.weight(.semibold))
                }
            }
        }
    }

    // MARK: - Helpers

    private func playerString(name: String, elo: String) -> String {
        elo == "?" || elo.isEmpty ? name : "\(name) (\(elo))"
    }

    private var yearString: String {
        if let month = state.game.month {
            return "\(month) \(state.game.year)"
        }
        return "\(state.game.year)"
    }
}
