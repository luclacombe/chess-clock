import SwiftUI

/// Inline multi-move puzzle view. Embedded in ClockView as .puzzle mode (no floating window).
struct GuessMoveView: View {
    let state: ClockState
    @ObservedObject var guessService: GuessService
    let onBack: () -> Void
    let onReplay: () -> Void

    // Opponent animation state
    @State private var isOpponentAnimating: Bool = false

    // Feedback overlays
    @State private var showWrongFlash: Bool = false
    @State private var showSuccess: Bool = false
    @State private var showFailed: Bool = false

    // Delayed "Review Game" button reveal
    @State private var showReviewButton: Bool = false

    var body: some View {
        ZStack {
            // Board (center, 280×280)
            boardSection

            // Header overlay (top of board)
            VStack {
                headerOverlay
                Spacer()
            }

            // Result overlays
            if showSuccess { successOverlay }
            if showFailed  { failedOverlay }
        }
        .frame(width: 280, height: 280)
        .onAppear { initializePuzzle() }
        .onChange(of: showSuccess) { if $0 { scheduleReviewButton() } }
        .onChange(of: showFailed)  { if $0 { scheduleReviewButton() } }
    }

    // MARK: - Sub-views

    private var boardSection: some View {
        let currentFEN = guessService.engine?.currentFEN ?? state.game.positions[state.hour - 1]
        let boardID = guessService.engine?.currentFEN ?? "done"
        let userCanPlay = !isOpponentAnimating && !showSuccess && !showFailed
                          && guessService.engine?.isUserTurn == true

        return Group {
            if userCanPlay {
                InteractiveBoardView(fen: currentFEN, isFlipped: state.isFlipped) { move in handleMove(move) }
                    .id(boardID)
                    .clipShape(RoundedRectangle(cornerRadius: ChessClockRadius.puzzleBoard))
            } else {
                BoardView(fen: currentFEN, isFlipped: state.isFlipped)
                    .id(boardID)
                    .clipShape(RoundedRectangle(cornerRadius: ChessClockRadius.puzzleBoard))
            }
        }
        .frame(width: 280, height: 280)
    }

    private var headerOverlay: some View {
        let triesUsed = guessService.engine?.triesUsed ?? guessService.result?.triesUsed ?? 1
        let whiteName = state.game.white.components(separatedBy: ",").first ?? state.game.white
        let blackName = state.game.black.components(separatedBy: ",").first ?? state.game.black

        return VStack(spacing: 0) {
            // Line 1: back chevron + player names
            HStack {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(ChessClockType.caption)
                        .foregroundColor(Color.white.opacity(0.85))
                        .frame(width: 28, height: 28)
                }
                .buttonStyle(.plain)

                Spacer()

                Text("\(whiteName) vs \(blackName)")
                    .font(ChessClockType.caption)
                    .foregroundColor(Color.white.opacity(0.85))
                    .lineLimit(1)
                    .padding(.trailing, 8)
            }

            // Line 2: "Mate in N" + tries indicator
            HStack {
                Text("Mate in \(state.hour)")
                    .font(ChessClockType.caption)
                    .foregroundColor(Color.white.opacity(0.70))
                    .padding(.leading, 8)

                Spacer()

                // Tries circles: 8pt diameter, 4pt spacing
                HStack(spacing: 4) {
                    ForEach(1...3, id: \.self) { i in
                        if i < triesUsed {
                            // Used a wrong try
                            Circle()
                                .fill(ChessClockColor.feedbackError)
                                .frame(width: 8, height: 8)
                        } else if i == triesUsed {
                            // Current unused slot
                            Circle()
                                .fill(ChessClockColor.accentGold)
                                .frame(width: 8, height: 8)
                        } else {
                            // Future slots
                            Circle()
                                .stroke(Color.white.opacity(0.40), lineWidth: 1)
                                .frame(width: 8, height: 8)
                        }
                    }
                }
                .padding(.trailing, 8)
            }
        }
        .frame(height: 36)
        .background(Color.black.opacity(0.55))
        .clipShape(RoundedRectangle(cornerRadius: ChessClockRadius.puzzleBoard, style: .continuous))
    }

    // MARK: - Inline overlays

    private var wrongFlashOverlay: some View {
        ZStack {
            Color.black.opacity(0.5).ignoresSafeArea()
            VStack(spacing: 8) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.red)
                Text("Not that move")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            .padding(24)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        }
    }

    private var successOverlay: some View {
        ZStack {
            Color.black.opacity(0.55).ignoresSafeArea()
            VStack(spacing: 16) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 52))
                    .foregroundColor(.green)

                Text("Solved!")
                    .font(.title2.weight(.bold))
                    .foregroundColor(.white)

                if let result = guessService.result {
                    Text(result.triesUsed == 1 ? "Solved on the first try!" : "Solved in \(result.triesUsed) tries")
                        .font(.callout)
                        .foregroundColor(.white.opacity(0.85))
                }

                statsLine

                if showReviewButton {
                    VStack(spacing: 8) {
                        Button("Review Game") { onReplay() }
                            .buttonStyle(.borderedProminent)
                        Button("Close") { onBack() }
                            .buttonStyle(.plain)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .transition(.opacity)
                }
            }
            .padding(24)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
            .padding(16)
        }
    }

    private var failedOverlay: some View {
        ZStack {
            Color.black.opacity(0.55).ignoresSafeArea()
            VStack(spacing: 12) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 52))
                    .foregroundColor(.red)

                Text("Not solved")
                    .font(.title2.weight(.bold))
                    .foregroundColor(.white)

                VStack(alignment: .leading, spacing: 4) {
                    Text("The continuation:")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.white.opacity(0.7))
                    ForEach(solutionMoves().indices, id: \.self) { i in
                        Text("\(i + 1). \(solutionMoves()[i].uppercased())")
                            .font(.body.weight(.bold))
                            .foregroundColor(.green)
                    }
                }

                statsLine

                if showReviewButton {
                    VStack(spacing: 8) {
                        Button("Review Game") { onReplay() }
                            .buttonStyle(.borderedProminent)
                        Button("Close") { onBack() }
                            .buttonStyle(.plain)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .transition(.opacity)
                }
            }
            .padding(24)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
            .padding(16)
        }
    }

    private var statsLine: some View {
        let s = guessService.stats
        return Text("All time: \(s.totalPlayed - s.losses)W / \(s.losses)L")
            .font(.caption)
            .foregroundColor(.white.opacity(0.7))
    }

    // MARK: - Logic

    private func scheduleReviewButton() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation { showReviewButton = true }
        }
    }

    private func initializePuzzle() {
        guard let autoPlays = guessService.startPuzzle(game: state.game, hour: state.hour) else {
            // Result already exists for this hour — show it
            if let result = guessService.result {
                showSuccess = result.succeeded
                showFailed = !result.succeeded
            }
            return
        }
        // Apply any initial opponent auto-plays (when opponent moves first)
        if !autoPlays.isEmpty {
            playOpponentMoves(autoPlays)
        }
    }

    private func handleMove(_ move: ChessMove) {
        guard let result = guessService.submitMove(uci: move.uci) else { return }
        switch result {
        case .success:
            showSuccess = true

        case .correctContinue(let opponentMoves):
            if opponentMoves.isEmpty { break }
            playOpponentMoves(opponentMoves)

        case .wrong(_, let resetAutoPlays):
            showWrongFlash = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                showWrongFlash = false
                if !resetAutoPlays.isEmpty {
                    playOpponentMoves(resetAutoPlays)
                }
            }

        case .failed:
            showFailed = true
        }
    }

    /// Animate opponent moves sequentially, showing the UCI text for each.
    private func playOpponentMoves(_ moves: [(uci: String, fen: String)]) {
        guard !moves.isEmpty else { return }
        isOpponentAnimating = true
        playNextOpponentMove(moves, index: 0)
    }

    private func playNextOpponentMove(_ moves: [(uci: String, fen: String)], index: Int) {
        guard index < moves.count else {
            // All done — engine is already at the correct FEN (published via @ObservedObject)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                isOpponentAnimating = false
            }
            return
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            playNextOpponentMove(moves, index: index + 1)
        }
    }

    /// Mating-side moves in order from the starting position to checkmate.
    private func solutionMoves() -> [String] {
        let matingColor: PieceColor = state.game.mateBy == "white" ? .white : .black
        var moves: [String] = []
        for i in stride(from: state.hour - 1, through: 0, by: -1) {
            guard i < state.game.positions.count,
                  i < state.game.moveSequence.count,
                  let gs = ChessRules.parseState(fen: state.game.positions[i]),
                  gs.activeColor == matingColor else { continue }
            moves.append(state.game.moveSequence[i])
        }
        return moves
    }
}
