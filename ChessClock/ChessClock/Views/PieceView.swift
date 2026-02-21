import SwiftUI

struct PieceView: View {
    let piece: ChessPiece

    var body: some View {
        Image(piece.imageName)
            .resizable()
            .scaledToFit()
    }
}
