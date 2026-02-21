import SwiftUI

/// An interactive chess board where the active side's pieces can be dragged or
/// click-selected and moved. Illegal moves snap back; promotions show a picker.
struct InteractiveBoardView: View {
    let fen: String
    let isFlipped: Bool
    /// Called when the user completes a legal move.
    let onMove: (ChessMove) -> Void

    // Classic lichess board colors
    private static let lightSquare = Color(red: 240/255, green: 217/255, blue: 181/255)
    private static let darkSquare  = Color(red: 181/255, green: 136/255, blue:  99/255)
    private static let selectedTint = Color.yellow.opacity(0.45)
    private static let legalDotColor = Color.black.opacity(0.22)
    private static let legalCaptureTint = Color.black.opacity(0.18)

    // Interaction state
    @State private var selectedSquare: ChessSquare?
    @State private var legalDestinations: [ChessSquare] = []
    @State private var dragFrom: ChessSquare?
    @State private var dragPosition: CGPoint = .zero
    @State private var isDragging = false
    // Snap-back animation
    @State private var snapBackSquare: ChessSquare?
    // Promotion pending
    @State private var promotionFrom: ChessSquare?
    @State private var promotionTo: ChessSquare?

    var body: some View {
        guard let gameState = ChessRules.parseState(fen: fen) else {
            return AnyView(Text("Invalid FEN").foregroundColor(.red))
        }
        let allLegal = ChessRules.legalMoves(in: gameState)
        return AnyView(boardBody(gameState: gameState, allLegal: allLegal))
    }

    private func boardBody(gameState: GameState, allLegal: [ChessMove]) -> some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let sq = size / 8

            ZStack(alignment: .topLeading) {
                // Board squares and pieces
                VStack(spacing: 0) {
                    ForEach(0..<8, id: \.self) { rowIndex in
                        HStack(spacing: 0) {
                            ForEach(0..<8, id: \.self) { fileIndex in
                                let rankIndex = isFlipped ? (7 - rowIndex) : rowIndex
                                let square = ChessSquare.from(rankIndex: rankIndex, fileIndex: fileIndex)
                                let piece = gameState.piece(at: square)
                                let isSelected = selectedSquare == square
                                let isLegalDest = legalDestinations.contains(square)
                                let isCaptureDest = isLegalDest && piece != nil
                                let isLight = (rankIndex + fileIndex) % 2 == 1
                                let squareColor = isLight ? Self.lightSquare : Self.darkSquare
                                let isDraggedFrom = dragFrom == square && isDragging

                                ZStack {
                                    // Square background
                                    squareColor
                                    if isSelected { Self.selectedTint }
                                    if isLegalDest && !isCaptureDest {
                                        Circle()
                                            .fill(Self.legalDotColor)
                                            .frame(width: sq * 0.32, height: sq * 0.32)
                                    }
                                    if isCaptureDest {
                                        RoundedRectangle(cornerRadius: 0)
                                            .fill(Self.legalCaptureTint)
                                        Circle()
                                            .strokeBorder(Self.legalDotColor, lineWidth: sq * 0.08)
                                    }

                                    // Piece (hidden while being dragged)
                                    if let p = piece, !isDraggedFrom {
                                        Image(p.imageName)
                                            .resizable()
                                            .scaledToFit()
                                            .padding(sq * 0.05)
                                    }
                                }
                                .frame(width: sq, height: sq)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    handleTap(square: square, gameState: gameState, allLegal: allLegal)
                                }
                            }
                        }
                    }
                }
                .gesture(
                    DragGesture(minimumDistance: 6, coordinateSpace: .local)
                        .onChanged { value in
                            if dragFrom == nil {
                                // Identify the piece being dragged
                                let from = squareAt(x: value.startLocation.x,
                                                    y: value.startLocation.y,
                                                    squareSize: sq, boardSize: size)
                                guard let from,
                                      let piece = gameState.piece(at: from),
                                      piece.color == gameState.activeColor else { return }
                                dragFrom = from
                                selectedSquare = from
                                legalDestinations = allLegal
                                    .filter { $0.from == from }
                                    .map { $0.to }
                                isDragging = true
                            }
                            dragPosition = value.location
                        }
                        .onEnded { value in
                            defer {
                                isDragging = false
                                dragFrom = nil
                            }
                            guard let from = dragFrom else { return }
                            guard let to = squareAt(x: value.location.x,
                                                    y: value.location.y,
                                                    squareSize: sq, boardSize: size) else { return }
                            let candidates = allLegal.filter { $0.from == from && $0.to == to }
                            if candidates.count == 1 {
                                commitMove(candidates[0])
                            } else if candidates.count > 1 {
                                // Promotion required
                                promotionFrom = from
                                promotionTo = to
                                selectedSquare = nil
                                legalDestinations = []
                            }
                            // else: snap back — just clearing the state is enough
                            if candidates.isEmpty {
                                selectedSquare = nil
                                legalDestinations = []
                            }
                        }
                )

                // Floating dragged piece
                if isDragging, let from = dragFrom,
                   let piece = gameState.piece(at: from) {
                    Image(piece.imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: sq * 0.9, height: sq * 0.9)
                        .position(dragPosition)
                        .allowsHitTesting(false)
                }
            }
            .frame(width: size, height: size)

            // Promotion picker overlay
            if promotionFrom != nil {
                PromotionPickerView(color: gameState.activeColor) { pieceType in
                    if let pf = promotionFrom, let pt = promotionTo {
                        let move = ChessMove(from: pf, to: pt, promotion: pieceType)
                        commitMove(move)
                    }
                    promotionFrom = nil
                    promotionTo = nil
                }
                .frame(width: size, height: size)
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }

    // MARK: - Interaction logic

    private func handleTap(square: ChessSquare, gameState: GameState, allLegal: [ChessMove]) {
        guard promotionFrom == nil else { return }

        if let from = selectedSquare {
            // Something is already selected: try to move there
            let candidates = allLegal.filter { $0.from == from && $0.to == square }
            if candidates.count == 1 {
                commitMove(candidates[0])
                return
            } else if candidates.count > 1 {
                // Promotion
                promotionFrom = from
                promotionTo = square
                selectedSquare = nil
                legalDestinations = []
                return
            }
        }

        // Select this square if it has an active-color piece
        if let piece = gameState.piece(at: square), piece.color == gameState.activeColor {
            selectedSquare = square
            legalDestinations = allLegal.filter { $0.from == square }.map { $0.to }
        } else {
            selectedSquare = nil
            legalDestinations = []
        }
    }

    private func commitMove(_ move: ChessMove) {
        selectedSquare = nil
        legalDestinations = []
        onMove(move)
    }

    // MARK: - Coordinate helpers

    /// Convert a point in local board coordinates to a ChessSquare.
    private func squareAt(x: CGFloat, y: CGFloat, squareSize: CGFloat, boardSize: CGFloat) -> ChessSquare? {
        guard x >= 0, y >= 0, x < boardSize, y < boardSize else { return nil }
        let col = Int(x / squareSize)
        let row = Int(y / squareSize)
        guard (0..<8).contains(col), (0..<8).contains(row) else { return nil }
        let rankIndex = isFlipped ? (7 - row) : row
        let fileIndex = col
        return ChessSquare.from(rankIndex: rankIndex, fileIndex: fileIndex)
    }
}
