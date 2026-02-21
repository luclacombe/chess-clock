import SwiftUI

/// Overlay that lets the user pick a promotion piece (Q, R, B, N).
struct PromotionPickerView: View {
    let color: PieceColor
    let onPick: (PieceType) -> Void

    private let options: [PieceType] = [.queen, .rook, .bishop, .knight]

    var body: some View {
        ZStack {
            Color.black.opacity(0.45)
                .ignoresSafeArea()

            VStack(spacing: 12) {
                Text("Choose promotion")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.white)

                HStack(spacing: 12) {
                    ForEach(options, id: \.self) { pieceType in
                        Button {
                            onPick(pieceType)
                        } label: {
                            Image(ChessPiece(type: pieceType, color: color).imageName)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 52, height: 52)
                                .padding(6)
                                .background(Color.white.opacity(0.9))
                                .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(20)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        }
    }
}
