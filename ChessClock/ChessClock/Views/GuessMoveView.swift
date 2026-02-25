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

    private var successOverlay: some View {
        let triesUsed = guessService.result?.triesUsed ?? 1
        let tryPhrase: String = {
            switch triesUsed {
            case 1: return "First try"
            case 2: return "Second try"
            default: return "Third try"
            }
        }()

        return ZStack {
            ChessClockColor.overlayScrim  // Color.black.opacity(0.45)

            VStack(spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 36))
                    .foregroundColor(ChessClockColor.feedbackSuccess)

                Text("Solved")
                    .font(ChessClockType.title)  // 17pt semibold
                    .foregroundColor(.primary)

                Text(tryPhrase)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(.secondary)

                HStack(spacing: 16) {
                    if showReviewButton {
                        Button("Review") { onReplay() }
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(ChessClockColor.accentGold)
                            .buttonStyle(.plain)
                            .transition(.opacity)
                    }

                    Button("Done") { onBack() }
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(.secondary)
                        .buttonStyle(.plain)
                }
            }
            .padding(20)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: ChessClockRadius.card))
        }
    }

    private var failedOverlay: some View {
        ZStack {
            ChessClockColor.overlayScrim  // Color.black.opacity(0.45)

            VStack(spacing: 12) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 36))
                    .foregroundColor(ChessClockColor.feedbackError)

                Text("Not solved")
                    .font(ChessClockType.title)  // 17pt semibold
                    .foregroundColor(.primary)

                HStack(spacing: 16) {
                    if showReviewButton {
                        Button("Review") { onReplay() }
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(ChessClockColor.accentGold)
                            .buttonStyle(.plain)
                            .transition(.opacity)
                    }

                    Button("Done") { onBack() }
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(.secondary)
                        .buttonStyle(.plain)
                }
            }
            .padding(20)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: ChessClockRadius.card))
        }
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
            if !resetAutoPlays.isEmpty {
                playOpponentMoves(resetAutoPlays)
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

}
