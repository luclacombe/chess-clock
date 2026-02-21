import SwiftUI

struct GameInfoView: View {
    let game: ChessGame

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            playerRow(label: "White", name: game.white, elo: game.whiteElo)
            playerRow(label: "Black", name: game.black, elo: game.blackElo)
            Divider().padding(.vertical, 2)
            infoRow(label: "Event", value: game.tournament)
            if let month = game.month {
                infoRow(label: "Date", value: "\(month) \(game.year)")
            } else {
                infoRow(label: "Date", value: "\(game.year)")
            }
            if let round = game.round {
                infoRow(label: "Round", value: round)
            }
        }
        .font(.caption)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
    }

    private func playerRow(label: String, name: String, elo: String) -> some View {
        HStack(spacing: 4) {
            Text(label + ":")
                .foregroundColor(.secondary)
                .frame(width: 42, alignment: .leading)
            Text(name)
                .foregroundColor(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            Spacer()
            if elo != "?" && !elo.isEmpty {
                Text(elo)
                    .foregroundColor(.secondary)
                    .monospacedDigit()
            }
        }
    }

    private func infoRow(label: String, value: String) -> some View {
        HStack(spacing: 4) {
            Text(label + ":")
                .foregroundColor(.secondary)
                .frame(width: 42, alignment: .leading)
            Text(value)
                .foregroundColor(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            Spacer()
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        GameInfoView(game: ChessGame(
            white: "Kasparov, G", black: "Karpov, A",
            whiteElo: "2805", blackElo: "2760",
            tournament: "World Chess Championship", year: 1986,
            month: "November", round: "7",
            positions: Array(
                repeating: "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1",
                count: 12
            )
        ))
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
