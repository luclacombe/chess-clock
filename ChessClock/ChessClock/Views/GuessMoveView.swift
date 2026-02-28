import SwiftUI

/// Inline multi-move puzzle view. Embedded in ClockView as .puzzle mode (no floating window).
struct GuessMoveView: View {
    let state: ClockState
    @ObservedObject var guessService: GuessService
    let onBack: () -> Void
    let onReplay: () -> Void
    var onFeedback: ((Bool) -> Void)? = nil
    var showOnboarding: Bool = false
    var onDismissOnboarding: (() -> Void)? = nil

    // Opponent animation state
    @State private var isOpponentAnimating: Bool = false
    @State private var lastOpponentMove: (from: ChessSquare, to: ChessSquare)? = nil

    // Feedback overlays
    @State private var showSuccess: Bool = false
    @State private var showFailed: Bool = false

    // S4.5-5: Auto-hide header pills
    @State private var headerVisible: Bool = true
    @State private var headerHideTask: DispatchWorkItem?

    // S5-5: Wrong-answer tries pill
    @State private var wrongTriesPillVisible: Bool = false
    @State private var wrongTriesHideTask: DispatchWorkItem?

    // Feedback glow (blurred board edge)
    @State private var feedbackGlowOpacity: Double = 0
    @State private var feedbackGlowColor: Color = .clear
    @State private var feedbackGlowHideTask: DispatchWorkItem?

    var body: some View {
        ZStack {
            // Board (center, 280x280)
            boardSection

            // Combined header/pip zone (hidden during result overlays)
            if !showSuccess && !showFailed {
                VStack {
                    headerPipZone
                    Spacer()
                }
            }

            // Wrong-answer tries pill (only when header is hidden)
            if wrongTriesPillVisible && !headerVisible {
                VStack {
                    wrongTriesPill
                        .padding(.top, 6)
                    Spacer()
                }
                .transition(.opacity)
            }

            // Result overlays
            if showSuccess { resultCard(succeeded: true) }
            if showFailed  { resultCard(succeeded: false) }

            // Stage E: puzzle onboarding overlay
            if showOnboarding {
                ZStack {
                    VStack {
                        Spacer()

                        OnboardingCalloutView(
                            text: puzzleOnboardingText,
                            onTap: {}
                        )
                        .padding(.horizontal, 16)
                        .padding(.bottom, 12)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture { onDismissOnboarding?() }
                .transition(.opacity)
            }
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
                .strokeBorder(feedbackGlowColor, lineWidth: 4)
                .blur(radius: 6)
                .opacity(feedbackGlowOpacity)
        )
        .blur(radius: (showSuccess || showFailed) ? 6 : 0)
        .animation(ChessClockAnimation.smooth, value: showSuccess)
        .animation(ChessClockAnimation.smooth, value: showFailed)
    }

    // MARK: - Header/Pip Zone (S5-5)

    private var headerPipZone: some View {
        ZStack(alignment: .top) {
            if headerVisible {
                puzzleHeaderPills
                    .contentShape(Rectangle())
                    .onHover { hovering in
                        if hovering {
                            headerHideTask?.cancel()
                        } else {
                            scheduleHeaderHide(after: ChessClockTiming.headerAutoHide)
                        }
                    }
            } else if !wrongTriesPillVisible {
                puzzlePip
                    .contentShape(Rectangle())
                    .onHover { hovering in
                        if hovering {
                            headerHideTask?.cancel()
                            withAnimation(.spring(response: 0.28, dampingFraction: 0.78)) {
                                headerVisible = true
                            }
                            scheduleHeaderHide(after: ChessClockTiming.headerAutoHide)
                        }
                    }
            }
        }
        .frame(maxWidth: .infinity, alignment: .top)
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
                    .contentShape(Rectangle())
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
            HStack(spacing: 5) {
                ForEach(1...3, id: \.self) { i in
                    tryIndicator(index: i, triesUsed: triesUsed)
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
            .font(.system(size: 10))
            .foregroundColor(Color.white.opacity(0.60))
            .frame(width: 22, height: 16)
            .background(Color(white: 0.25).opacity(0.50), in: RoundedRectangle(cornerRadius: 4))
            .padding(.top, 6)
            .transition(.opacity.animation(.easeIn(duration: 0.35)))
    }

    // MARK: - Wrong Tries Pill (S5-5)

    private var wrongTriesPill: some View {
        let triesUsed = guessService.engine?.triesUsed ?? guessService.result?.triesUsed ?? 1
        return HStack(spacing: 5) {
            ForEach(1...3, id: \.self) { i in
                tryIndicator(index: i, triesUsed: triesUsed)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(ChessClockColor.pillBackground, in: RoundedRectangle(cornerRadius: ChessClockRadius.pill))
        .overlay(RoundedRectangle(cornerRadius: ChessClockRadius.pill).stroke(ChessClockColor.pillBorder, lineWidth: 0.5))
        .shadow(color: .black.opacity(0.25), radius: 4, y: 2)
    }

    // MARK: - Try Indicator (3D glass spheres)

    @ViewBuilder
    private func tryIndicator(index: Int, triesUsed: Int, succeeded: Bool = false) -> some View {
        if index < triesUsed {
            // Used (wrong) — red glass sphere
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(red: 1.0, green: 0.42, blue: 0.36),
                            Color(red: 0.85, green: 0.15, blue: 0.10),
                            Color(red: 0.48, green: 0.06, blue: 0.04)
                        ],
                        center: .init(x: 0.33, y: 0.28),
                        startRadius: 0,
                        endRadius: 5.5
                    )
                )
                .overlay(
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.white.opacity(0.50), Color.clear],
                                center: .init(x: 0.30, y: 0.24),
                                startRadius: 0,
                                endRadius: 2.2
                            )
                        )
                )
                .shadow(color: Color.red.opacity(0.35), radius: 1.5, y: 0.5)
                .frame(width: 9, height: 9)
        } else if index == triesUsed && succeeded {
            // Solved on this try — green glass sphere
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(red: 0.40, green: 0.92, blue: 0.40),
                            Color(red: 0.15, green: 0.72, blue: 0.18),
                            Color(red: 0.06, green: 0.40, blue: 0.08)
                        ],
                        center: .init(x: 0.33, y: 0.28),
                        startRadius: 0,
                        endRadius: 5.5
                    )
                )
                .overlay(
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.white.opacity(0.50), Color.clear],
                                center: .init(x: 0.30, y: 0.24),
                                startRadius: 0,
                                endRadius: 2.2
                            )
                        )
                )
                .shadow(color: Color.green.opacity(0.35), radius: 1.5, y: 0.5)
                .frame(width: 9, height: 9)
        } else if index == triesUsed {
            // Current — gold ring with angular gradient lighting
            Circle()
                .strokeBorder(
                    AngularGradient(
                        colors: [
                            ChessClockColor.accentGoldLight,
                            ChessClockColor.accentGold,
                            ChessClockColor.accentGoldDeep,
                            ChessClockColor.accentGold,
                            ChessClockColor.accentGoldLight
                        ],
                        center: .center,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(270)
                    ),
                    lineWidth: 1.5
                )
                .overlay(
                    Circle()
                        .trim(from: 0.88, to: 1.0)
                        .stroke(Color.white.opacity(0.35), lineWidth: 0.5)
                )
                .shadow(color: ChessClockColor.accentGold.opacity(0.45), radius: 2, y: 0)
                .frame(width: 9, height: 9)
        } else {
            // Remaining — white ring with subtle angular gradient
            Circle()
                .strokeBorder(
                    AngularGradient(
                        colors: [
                            Color.white.opacity(0.45),
                            Color.white.opacity(0.22),
                            Color.white.opacity(0.14),
                            Color.white.opacity(0.22),
                            Color.white.opacity(0.45)
                        ],
                        center: .center,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(270)
                    ),
                    lineWidth: 1
                )
                .shadow(color: Color.white.opacity(0.08), radius: 1, y: 0)
                .frame(width: 9, height: 9)
        }
    }

    // MARK: - Result Card (S5-7)

    private func resultCard(succeeded: Bool) -> some View {
        let triesUsed = guessService.result?.triesUsed ?? 1
        // For not-solved, force all 3 red (triesUsed >= 4 makes all indices < triesUsed)
        let displayTries = succeeded ? triesUsed : 4

        return VStack(spacing: 10) {
            Text(succeeded ? "Solved" : "Not solved")
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(.primary)

            HStack(spacing: 5) {
                ForEach(1...3, id: \.self) { i in
                    tryIndicator(index: i, triesUsed: displayTries, succeeded: succeeded)
                }
            }

            HStack(spacing: 12) {
                Button("Review \u{2192}") { onReplay() }
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(ChessClockColor.accentGold)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(ChessClockColor.accentGold.opacity(0.12))
                    .clipShape(Capsule())
                    .buttonStyle(.plain)

                Button("Done") { onBack() }
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(Color(white: 0.5).opacity(0.10))
                    .clipShape(Capsule())
                    .buttonStyle(.plain)
            }
        }
        .padding(24)
        .background {
            ZStack {
                RoundedRectangle(cornerRadius: ChessClockRadius.card)
                    .fill(.regularMaterial)
                RoundedRectangle(cornerRadius: ChessClockRadius.card)
                    .fill(succeeded ? Color.green.opacity(0.12) : Color.red.opacity(0.12))
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: ChessClockRadius.card))
        .overlay(
            RoundedRectangle(cornerRadius: ChessClockRadius.card)
                .stroke((succeeded ? Color.green : Color.red).opacity(0.25), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.20), radius: 12, y: 4)
        .transition(.scale(scale: 0.92).combined(with: .opacity))
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

    private func showFeedbackGlow(color: Color) {
        feedbackGlowHideTask?.cancel()
        feedbackGlowColor = color
        withAnimation(.easeIn(duration: ChessClockTiming.feedbackRampUp)) {
            feedbackGlowOpacity = 0.75
        }
        let task = DispatchWorkItem {
            withAnimation(.easeOut(duration: ChessClockTiming.feedbackRampDown)) {
                feedbackGlowOpacity = 0
            }
        }
        feedbackGlowHideTask = task
        DispatchQueue.main.asyncAfter(
            deadline: .now() + ChessClockTiming.feedbackRampUp + ChessClockTiming.feedbackHold,
            execute: task
        )
    }

    private var puzzleOnboardingText: String {
        let side = state.isAM ? "White" : "Black"
        return "It's \(state.hour):\(String(format: "%02d", state.minute)) \(state.isAM ? "AM" : "PM")\nFind the mate in \(state.hour) as \(side)"
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
            onFeedback?(true)
            showFeedbackGlow(color: ChessClockColor.feedbackSuccess)
            lastOpponentMove = nil
            if opponentMoves.isEmpty { break }
            playOpponentMoves(opponentMoves)

        case .wrong(_, let resetAutoPlays):
            onFeedback?(false)
            showFeedbackGlow(color: ChessClockColor.feedbackError)
            // S5-5: Show tries pill centered
            wrongTriesHideTask?.cancel()
            withAnimation(.spring(response: 0.28, dampingFraction: 0.78)) {
                wrongTriesPillVisible = true
            }
            let task = DispatchWorkItem { [self] in
                withAnimation(.easeOut(duration: 0.45)) {
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
