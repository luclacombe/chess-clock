import SwiftUI

struct BoardView: View {
    let fen: String
    var isFlipped: Bool = false  // true in PM: shows board from Black's perspective

    var body: some View {
        let position = BoardPosition(fen: fen)

        GeometryReader { geometry in
            let squareSize = geometry.size.width / 8

            VStack(spacing: 0) {
                ForEach(0..<8, id: \.self) { rowIndex in
                    let rankIndex = isFlipped ? (7 - rowIndex) : rowIndex
                    HStack(spacing: 0) {
                        ForEach(0..<8, id: \.self) { fileIndex in
                            let isLight = (rankIndex + fileIndex) % 2 == 1
                            let squareColor = isLight ? ChessClockColor.boardLight : ChessClockColor.boardDark
                            let piece = position.squares[rankIndex][fileIndex]

                            ZStack {
                                squareColor

                                if let piece = piece {
                                    PieceView(piece: piece)
                                        .padding(squareSize * 0.05)
                                }
                            }
                            .frame(width: squareSize, height: squareSize)
                        }
                    }
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: ChessClockRadius.board))
        .overlay(RoundedRectangle(cornerRadius: ChessClockRadius.board).strokeBorder(Color.black.opacity(0.12), lineWidth: 0.5))
    }
}

#Preview {
    BoardView(fen: "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1")
        .frame(width: 320)
}
