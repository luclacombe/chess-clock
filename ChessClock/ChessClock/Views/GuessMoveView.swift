import SwiftUI

/// Inline multi-move puzzle view. Embedded in ClockView as .puzzle mode (no floating window).
struct GuessMoveView: View {
    let state: ClockState
    @ObservedObject var guessService: GuessService
    let onBack: () -> Void
    let onReplay: () -> Void

    // Opponent animation state
    @State private var isOpponentAnimating: Bool = false
    @State private var lastOpponentMove: (from: ChessSquare, to: ChessSquare)? = nil

    // Feedback overlays
    @State private var showSuccess: Bool = false
    @State private var showFailed: Bool = false

    // S4.5-5: Auto-hide header pills
    @State private var headerVisible: Bool = true
    @State private var headerHideTask: DispatchWorkItem?

    // S4.5-6: Wrong move border flash
    @State private var wrongBorderOpacity: Double = 0

    // S5-5: Wrong-answer tries pill
    @State private var wrongTriesPillVisible: Bool = false
    @State private var wrongTriesHideTask: DispatchWorkItem?

    // S4.5-7: Delayed review button reveal
    @State private var reviewButtonVisible: Bool = false

    var body: some View {
        ZStack {
            // Board (center, 280x280)
            boardSection

            // Combined header/pip zone
            VStack {
                headerPipZone
                Spacer()
            }

            // Wrong-answer tries pill (only when header is hidden)
            if wrongTriesPillVisible && !headerVisible {
                VStack {
                    wrongTriesPill
                        .padding(.top, 6)
                        .transition(.opacity)
                    Spacer()
                }
            }

            // Result overlays
            if showSuccess { successOverlay }
            if showFailed  { failedOverlay }
        }
        .frame(width: 280, height: 280)
        .onAppear { initializePuzzle() }
    }

    // MARK: - Sub-views

    private var boardSection: some View {
        let currentFEN = guessService.engine?.currentFEN ?? state.game.positions[state.hour - 1]
        let boardID = guessService.engine?.currentFEN ?? "done"
        let userCanPlay = !isOpponentAnimating && !showSuccess && !showFailed
                          && guessService.engine?.isUserTurn == true

        return Group {
            if userCanPlay {
                InteractiveBoardView(fen: currentFEN, isFlipped: state.isFlipped, highlightedSquares: lastOpponentMove) { move in handleMove(move) }
                    .id(boardID)
                    .clipShape(RoundedRectangle(cornerRadius: ChessClockRadius.puzzleBoard))
            } else {
                BoardView(fen: currentFEN, isFlipped: state.isFlipped, highlightedSquares: lastOpponentMove)
                    .id(boardID)
                    .clipShape(RoundedRectangle(cornerRadius: ChessClockRadius.puzzleBoard))
            }
        }
        .frame(width: 280, height: 280)
        .overlay(
            RoundedRectangle(cornerRadius: ChessClockRadius.puzzleBoard)
                .strokeBorder(ChessClockColor.feedbackError, lineWidth: 3)
                .opacity(wrongBorderOpacity)
        )
    }

    // MARK: - Header/Pip Zone (S5-5)

    private var headerPipZone: some View {
        ZStack {
            if headerVisible {
                puzzleHeaderPills
            } else {
                puzzlePip
            }
        }
        .frame(height: 44)
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
        .onHover { hovering in
            if hovering {
                headerHideTask?.cancel()
                withAnimation(.spring(response: 0.28, dampingFraction: 0.78)) {
                    headerVisible = true
                }
            } else {
                scheduleHeaderHide(after: ChessClockTiming.headerAutoHide)
            }
        }
    }

    // MARK: - Header Pills (S5-5)

    private var puzzleHeaderPills: some View {
        let triesUsed = guessService.engine?.triesUsed ?? guessService.result?.triesUsed ?? 1
        let whiteName = state.game.white.components(separatedBy: ",").first ?? state.game.white
        let blackName = state.game.black.components(separatedBy: ",").first ?? state.game.black

        return HStack(spacing: 8) {
            // Back pill (left)
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 12))
                    .foregroundColor(Color.white.opacity(0.85))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.plain)
            .background(ChessClockColor.pillBackground, in: RoundedRectangle(cornerRadius: ChessClockRadius.pill))
            .overlay(RoundedRectangle(cornerRadius: ChessClockRadius.pill).stroke(ChessClockColor.pillBorder, lineWidth: 0.5))
            .shadow(color: .black.opacity(0.25), radius: 4, y: 2)

            // Info pill (center) — two-line layout
            VStack(spacing: 2) {
                Text("\(whiteName) vs \(blackName)")
                    .font(ChessClockType.caption)
                    .foregroundColor(Color.white.opacity(0.85))
                    .lineLimit(1)
                    .truncationMode(.tail)
                Text("Mate in \(state.hour)")
                    .font(ChessClockType.caption)
                    .foregroundColor(Color.white.opacity(0.85))
                    .lineLimit(1)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(ChessClockColor.pillBackground, in: RoundedRectangle(cornerRadius: ChessClockRadius.pill))
            .overlay(RoundedRectangle(cornerRadius: ChessClockRadius.pill).stroke(ChessClockColor.pillBorder, lineWidth: 0.5))
            .shadow(color: .black.opacity(0.25), radius: 4, y: 2)

            // Tries pill (right)
            HStack(spacing: 4) {
                ForEach(1...3, id: \.self) { i in
                    if i < triesUsed {
                        Circle()
                            .fill(ChessClockColor.feedbackError)
                            .frame(width: 8, height: 8)
                    } else if i == triesUsed {
                        Circle()
                            .fill(ChessClockColor.accentGold)
                            .frame(width: 8, height: 8)
                    } else {
                        Circle()
                            .stroke(Color.white.opacity(0.40), lineWidth: 1)
                            .frame(width: 8, height: 8)
                    }
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(ChessClockColor.pillBackground, in: RoundedRectangle(cornerRadius: ChessClockRadius.pill))
            .overlay(RoundedRectangle(cornerRadius: ChessClockRadius.pill).stroke(ChessClockColor.pillBorder, lineWidth: 0.5))
            .shadow(color: .black.opacity(0.25), radius: 4, y: 2)
        }
        .padding(.horizontal, 8)
        .padding(.top, 8)
        .transition(.asymmetric(
            insertion: .move(edge: .top).combined(with: .opacity),
            removal: .move(edge: .top).combined(with: .opacity)
        ))
    }

    // MARK: - Pip (S5-5)

    private var puzzlePip: some View {
        Image(systemName: "chevron.down")
            .font(.system(size: 12))
            .foregroundColor(Color.white.opacity(0.60))
            .frame(width: 24, height: 20)
            .background(ChessClockColor.pillBackground, in: RoundedRectangle(cornerRadius: 4))
            .padding(.top, 6)
            .transition(.opacity)
    }

    // MARK: - Wrong Tries Pill (S5-5)

    private var wrongTriesPill: some View {
        let triesUsed = guessService.engine?.triesUsed ?? guessService.result?.triesUsed ?? 1
        return HStack(spacing: 4) {
            ForEach(1...3, id: \.self) { i in
                if i < triesUsed {
                    Circle().fill(ChessClockColor.feedbackError).frame(width: 8, height: 8)
                } else if i == triesUsed {
                    Circle().fill(ChessClockColor.accentGold).frame(width: 8, height: 8)
                } else {
                    Circle().stroke(Color.white.opacity(0.40), lineWidth: 1).frame(width: 8, height: 8)
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(ChessClockColor.pillBackground, in: RoundedRectangle(cornerRadius: ChessClockRadius.pill))
        .overlay(RoundedRectangle(cornerRadius: ChessClockRadius.pill).stroke(ChessClockColor.pillBorder, lineWidth: 0.5))
        .shadow(color: .black.opacity(0.25), radius: 4, y: 2)
    }

    // MARK: - Inline overlays (S4.5-7)

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
            // Frosted glass base
            Rectangle()
                .fill(.ultraThinMaterial)
            // Green tint
            ChessClockColor.feedbackSuccess.opacity(0.10)
        }
        .overlay {
            VStack(spacing: 12) {
                Text("Solved")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(.white)

                Text(tryPhrase)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(.white.opacity(0.60))

                HStack(spacing: 16) {
                    if reviewButtonVisible {
                        Button("Review \u{2192}") { onReplay() }
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(ChessClockColor.accentGold)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(.ultraThinMaterial)
                            .clipShape(Capsule())
                            .buttonStyle(.plain)
                            .transition(.opacity)
                    }

                    Button("Done") { onBack() }
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(.white.opacity(0.50))
                        .buttonStyle(.plain)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: ChessClockRadius.puzzleBoard))
        .transition(.opacity)
        .onAppear { scheduleReviewButton() }
    }

    private var failedOverlay: some View {
        ZStack {
            Rectangle()
                .fill(.ultraThinMaterial)
            ChessClockColor.feedbackError.opacity(0.10)
        }
        .overlay {
            VStack(spacing: 12) {
                Text("Not solved")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(.white)

                HStack(spacing: 16) {
                    if reviewButtonVisible {
                        Button("Review \u{2192}") { onReplay() }
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(ChessClockColor.accentGold)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(.ultraThinMaterial)
                            .clipShape(Capsule())
                            .buttonStyle(.plain)
                            .transition(.opacity)
                    }

                    Button("Done") { onBack() }
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(.white.opacity(0.50))
                        .buttonStyle(.plain)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: ChessClockRadius.puzzleBoard))
        .transition(.opacity)
        .onAppear { scheduleReviewButton() }
    }

    // MARK: - Logic

    // S4.5-5: Auto-hide header logic

    private func scheduleHeaderHide(after seconds: Double) {
        headerHideTask?.cancel()
        let task = DispatchWorkItem {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.78)) {
                headerVisible = false
            }
        }
        headerHideTask = task
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds, execute: task)
    }

    private func showHeaderBriefly(seconds: Double) {
        headerHideTask?.cancel()
        withAnimation(.spring(response: 0.28, dampingFraction: 0.78)) {
            headerVisible = true
        }
        scheduleHeaderHide(after: seconds)
    }

    // S4.5-7: Review button delay

    private func scheduleReviewButton() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation { reviewButtonVisible = true }
        }
    }

    private func initializePuzzle() {
        reviewButtonVisible = false
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
        // S4.5-5: Schedule header auto-hide
        scheduleHeaderHide(after: 2.5)
    }

    private func handleMove(_ move: ChessMove) {
        guard let result = guessService.submitMove(uci: move.uci) else { return }
        switch result {
        case .success:
            lastOpponentMove = nil
            showSuccess = true

        case .correctContinue(let opponentMoves):
            lastOpponentMove = nil
            if opponentMoves.isEmpty { break }
            playOpponentMoves(opponentMoves)

        case .wrong(_, let resetAutoPlays):
            // S4.5-6: Red border flash (kept for S5-6 removal)
            wrongBorderOpacity = 0.75
            withAnimation(.easeOut(duration: 0.5)) { wrongBorderOpacity = 0 }
            // S5-5: Show tries pill centered
            wrongTriesHideTask?.cancel()
            withAnimation(.spring(response: 0.28, dampingFraction: 0.78)) {
                wrongTriesPillVisible = true
            }
            let task = DispatchWorkItem { [self] in
                withAnimation(.spring(response: 0.28, dampingFraction: 0.78)) {
                    wrongTriesPillVisible = false
                }
            }
            wrongTriesHideTask = task
            DispatchQueue.main.asyncAfter(deadline: .now() + ChessClockTiming.wrongTriesDisplay, execute: task)
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
        let move = moves[index]
        // Parse UCI to ChessSquare from/to and highlight immediately when the move plays
        if move.uci.count >= 4 {
            let chars = Array(move.uci)
            let fromFile = Int(chars[0].asciiValue! - Character("a").asciiValue!)
            let fromRank = 8 - Int(String(chars[1]))!  // rankIndex: rank 8 -> 0, rank 1 -> 7
            let toFile = Int(chars[2].asciiValue! - Character("a").asciiValue!)
            let toRank = 8 - Int(String(chars[3]))!
            lastOpponentMove = (
                from: ChessSquare.from(rankIndex: fromRank, fileIndex: fromFile),
                to: ChessSquare.from(rankIndex: toRank, fileIndex: toFile)
            )
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {  // was 0.8
            playNextOpponentMove(moves, index: index + 1)
        }
    }

}
