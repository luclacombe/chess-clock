import SwiftUI

struct GameInfoView: View {
    let game: ChessGame

    // Formats "PlayerName (ELO)" or just "PlayerName" when ELO is "?" or empty.
    private func playerLabel(_ name: String, elo: String) -> String {
        let trimmed = elo.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty || trimmed == "?" {
            return name
        }
        return "\(name) (\(trimmed))"
    }

    var body: some View {
        VStack(alignment: .center, spacing: 4) {
            // Line 1: player names + ELOs
            Text("\(playerLabel(game.white, elo: game.whiteElo)) vs \(playerLabel(game.black, elo: game.blackElo))")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .multilineTextAlignment(.center)

            // Line 2: tournament + year
            Text("\(game.tournament) \(game.year)")
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
    }
}

#Preview {
    VStack(spacing: 20) {
        // Modern game with ELO
        GameInfoView(game: ChessGame(
            white: "Kasparov, G", black: "Karpov, A",
            whiteElo: "2805", blackElo: "2760",
            tournament: "World Chess Championship", year: 1986,
            positions: Array(
                repeating: "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1",
                count: 12
            )
        ))
        // Historical game with unknown ELO
        GameInfoView(game: ChessGame(
            white: "Morphy, P", black: "Anderssen, A",
            whiteElo: "?", blackElo: "?",
            tournament: "Opera Game", year: 1858,
            positions: Array(
                repeating: "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1",
                count: 12
            )
        ))
    }
    .padding()
    .frame(width: 320)
}
