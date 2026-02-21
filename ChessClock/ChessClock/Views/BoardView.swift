import SwiftUI

struct BoardView: View {
    let fen: String
    var isFlipped: Bool = false  // true in PM: shows board from Black's perspective

    // Classic lichess board colors
    private static let lightSquare = Color(red: 240/255, green: 217/255, blue: 181/255)
    private static let darkSquare  = Color(red: 181/255, green: 136/255, blue:  99/255)

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
                            let squareColor = isLight ? Self.lightSquare : Self.darkSquare
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
    }
}

#Preview {
    BoardView(fen: "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1")
        .frame(width: 320)
}
