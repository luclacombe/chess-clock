import SwiftUI

/// Shown when the user taps the board in the main clock view.
/// The board is a tappable card with a bottom overlay showing the CTA + result badge.
/// Below the board: game metadata.
struct InfoPanelView: View {
    let state: ClockState
    @ObservedObject var guessService: GuessService
    let onBack: () -> Void
    let onGuess: () -> Void
    let onReplay: () -> Void

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

            // Board card — tappable, with bottom CTA overlay
            boardCard

            Spacer(minLength: 10)

            // Game metadata
            gameMetadata
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Board card

    private var boardCard: some View {
        BoardView(fen: state.fen, isFlipped: state.isFlipped)
            .frame(maxWidth: .infinity)
            .aspectRatio(1, contentMode: .fit)
            .overlay(alignment: .bottom) {
                ctaBar
            }
            .contentShape(Rectangle())
            .onTapGesture { onGuess() }
    }

    private var ctaBar: some View {
        HStack(spacing: 6) {
            // Result badge (shown when puzzle has been played)
            if guessService.hasResult, let result = guessService.result {
                HStack(spacing: 4) {
                    Image(systemName: result.succeeded ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(result.succeeded ? .green : .red)
                        .font(.caption2)
                    Text(result.succeeded
                         ? "Solved (try \(result.triesUsed))"
                         : "Not solved")
                        .font(.caption2.weight(.semibold))
                        .foregroundColor(.white)
                }
            }

            Spacer()

            // AM/PM badge
            Text(state.isAM ? "AM" : "PM")
                .font(.caption2.weight(.bold))
                .foregroundColor(.white.opacity(0.7))

            // CTA
            HStack(spacing: 3) {
                Image(systemName: "play.fill")
                    .font(.caption2)
                Text(guessService.hasResult ? "Review" : "Play Puzzle")
                    .font(.caption.weight(.semibold))
            }
            .foregroundColor(.white)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(Color.black.opacity(0.65))
    }

    // MARK: - Game metadata

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
