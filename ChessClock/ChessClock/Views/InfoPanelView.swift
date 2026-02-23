import SwiftUI

/// Detail face — shown when the user taps the board in the main clock view.
/// Flanking icons + 164×164 board → CTA pill → player rows with indicators → event.
struct InfoPanelView: View {
    let state: ClockState
    @ObservedObject var guessService: GuessService
    let onBack: () -> Void
    let onGuess: () -> Void
    let onReplay: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // 1. Board section with flanking icons
            HStack(alignment: .top) {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                        .frame(width: 28, height: 28)
                }
                .buttonStyle(.plain)

                Spacer()

                BoardView(fen: state.fen, isFlipped: state.isFlipped)
                    .frame(width: ChessClockSize.boardDetail, height: ChessClockSize.boardDetail)
                    .clipShape(RoundedRectangle(cornerRadius: ChessClockRadius.board))
                    .contentShape(Rectangle())
                    .onTapGesture { tapAction() }

                Spacer()

                Button(action: {}) {
                    Image(systemName: "gearshape")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                        .frame(width: 28, height: 28)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 8)

            // 2. CTA pill
            Button(action: tapAction) {
                HStack(spacing: 6) {
                    Image(systemName: ctaIcon)
                        .font(.system(size: ChessClockCTADetail.iconSize, weight: .semibold))
                    Text(ctaText)
                        .font(.system(size: ChessClockCTADetail.fontSize, weight: .semibold))
                }
                .foregroundColor(ctaForeground)
                .padding(.horizontal, ChessClockCTADetail.hPadding)
                .padding(.vertical, ChessClockCTADetail.vPadding)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
                .overlay {
                    Capsule()
                        .strokeBorder(Color.white.opacity(0.25), lineWidth: 0.5)
                }
                .shadow(color: .black.opacity(0.15), radius: 6, x: 0, y: 2)
            }
            .buttonStyle(.plain)
            .padding(.top, 6)

            // 3. Game metadata
            VStack(alignment: .leading, spacing: ChessClockSpace.sm) {
                // White player row
                whitePlayerRow

                // Black player row
                blackPlayerRow

                // Event line (centered)
                Text(eventString)
                    .font(ChessClockType.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            .padding(.top, ChessClockSpace.md)
            .padding(.horizontal, ChessClockSpace.xl)
            .frame(maxWidth: .infinity, alignment: .leading)

            // 4. Bottom spacer
            Spacer()
        }
        .padding(.top, 12)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Player Rows

    private var whitePlayerRow: some View {
        HStack {
            // Glassy white indicator
            ZStack {
                Circle()
                    .fill(Color.white)
                LinearGradient(
                    stops: [
                        .init(color: .white.opacity(0.9), location: 0.0),
                        .init(color: .clear, location: 0.45),
                        .init(color: .black.opacity(0.08), location: 1.0)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .clipShape(Circle())
                Circle()
                    .stroke(Color.gray.opacity(0.35), lineWidth: 0.5)
            }
            .frame(width: 8, height: 8)
            .shadow(color: .black.opacity(0.15), radius: 1, y: 0.5)

            Spacer().frame(width: 6)

            Text(PlayerNameFormatter.format(pgn: state.game.white, elo: "?"))
                .font(ChessClockType.body)
                .foregroundColor(.primary)

            Spacer()

            if state.game.whiteElo != "?" && !state.game.whiteElo.isEmpty {
                Text(state.game.whiteElo)
                    .font(ChessClockType.body)
                    .foregroundColor(.secondary)
            }
        }
    }

    private var blackPlayerRow: some View {
        HStack {
            // Glassy black indicator
            ZStack {
                Circle()
                    .fill(Color(white: 0.15))
                LinearGradient(
                    stops: [
                        .init(color: .white.opacity(0.30), location: 0.0),
                        .init(color: .clear, location: 0.45),
                        .init(color: .black.opacity(0.15), location: 1.0)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .clipShape(Circle())
            }
            .frame(width: 8, height: 8)
            .shadow(color: .black.opacity(0.20), radius: 1, y: 0.5)

            Spacer().frame(width: 6)

            Text(PlayerNameFormatter.format(pgn: state.game.black, elo: "?"))
                .font(ChessClockType.body)
                .foregroundColor(.primary)

            Spacer()

            if state.game.blackElo != "?" && !state.game.blackElo.isEmpty {
                Text(state.game.blackElo)
                    .font(ChessClockType.body)
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - CTA Properties

    private var ctaIcon: String {
        if !guessService.hasResult { return "play.fill" }
        if guessService.result?.succeeded == true { return "checkmark" }
        return "arrow.counterclockwise"
    }

    private var ctaText: String {
        if !guessService.hasResult { return "Play" }
        if guessService.result?.succeeded == true { return "Solved" }
        return "Review"
    }

    private var ctaForeground: Color {
        if !guessService.hasResult {
            return ChessClockColor.accentGold
        } else if guessService.result?.succeeded == true {
            return ChessClockColor.feedbackSuccess
        } else {
            return .secondary
        }
    }

    // MARK: - Helpers

    private func tapAction() {
        if guessService.hasResult {
            onReplay()
        } else {
            onGuess()
        }
    }

    private var eventString: String {
        if let month = state.game.month {
            return "\(state.game.tournament) · \(String(month.prefix(3))) \(state.game.year)"
        }
        return "\(state.game.tournament) · \(state.game.year)"
    }
}
