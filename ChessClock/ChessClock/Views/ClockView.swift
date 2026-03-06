import AppKit
import SwiftUI

// MARK: - View mode

private enum ViewMode: Equatable { case clock, info, puzzle, replay, settings }

// MARK: - ClockView

struct ClockView: View {
    @ObservedObject var clockService: ClockService
    @StateObject private var guessService: GuessService
    @State private var viewMode: ViewMode = .clock
    @State private var isHovering = false
    @State private var isPopoverVisible = true
    @State private var puzzleRingTint: TintTarget = .none
    @State private var puzzleFeedbackSeq: Int = 0
    @State private var hourChangeActive = false
    // Hour-change: freeze old board during ring drain, flash to swap
    @State private var snapshotFen: String = ""
    @State private var snapshotFlipped: Bool = false
    @State private var hourFlash: Bool = false
    // Onboarding
    @State private var showWelcome = OnboardingService.shouldShowWelcome
    @State private var showOnboarding = false  // Stage A — delayed until welcome dismisses
    @State private var showInfoOnboarding = false
    @State private var infoOnboardingStep: Int = 1
    @State private var showReplayNudge = false
    @State private var showReplayOnboarding = false
    @State private var highlightReplayBar = false  // separate from overlay to avoid flash
    @State private var showPuzzleOnboarding = false  // Stage E
    @State private var ctaOnboardingBrighten = false  // Stage B-2 auto-brighten
    @State private var hideTickMarks = OnboardingService.shouldShowStageA  // hidden during A-1/A-2
    @State private var forceFullRing = OnboardingService.shouldShowStageA  // full ring during A-1/A-2
    @State private var hideGoldRing = OnboardingService.shouldShowStageA  // gold hidden during Stage 0 + A-1
    // Focus pull (Stage 0) — start neutral; set to initial values in onAppear
    // to avoid a first-frame layout glitch in the MenuBarExtra popover window.
    @State private var welcomeBlur: CGFloat = 0
    @State private var welcomeDim: Double = 0
    @State private var welcomeScale: CGFloat = 1.0
    @State private var pulseGoldRing = false
    // Open bloom (subtle focus pull on every popover open, post-onboarding)
    private static var bloomEligible: Bool {
        !OnboardingService.shouldShowWelcome && !OnboardingService.shouldShowStageA
    }
    @State private var openBlur: CGFloat = bloomEligible ? ChessClockOpenBloom.blurRadius : 0
    @State private var openDim: Double = bloomEligible ? ChessClockOpenBloom.dimAmount : 0
    @State private var openScale: CGFloat = bloomEligible ? ChessClockOpenBloom.zoomScale : 1.0

    init(clockService: ClockService) {
        self.clockService = clockService
        self._guessService = StateObject(wrappedValue: GuessService(clockService: clockService))
    }

    var body: some View {
        ZStack {
            // MARK: Content layer
            switch viewMode {
            case .clock:
                boardWithRing
            case .info:
                ZStack {
                    // Background tap handler: during B-2 or C, tapping non-button areas dismisses overlay
                    if (showInfoOnboarding && infoOnboardingStep == 2) || showReplayNudge {
                        Color.clear
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if showInfoOnboarding && infoOnboardingStep == 2 {
                                    dismissStageBStep2()
                                } else if showReplayNudge {
                                    dismissStageCOverlay()
                                }
                            }
                    }

                    InfoPanelView(
                        state: clockService.state,
                        guessService: guessService,
                        onBack: {
                            showInfoOnboarding = false
                            ctaOnboardingBrighten = false
                            withAnimation(ChessClockAnimation.smooth) { viewMode = .clock }
                        },
                        onGuess: {
                            if showInfoOnboarding {
                                OnboardingService.dismissStageB()
                                withAnimation(ChessClockAnimation.smooth) { showInfoOnboarding = false }
                            }
                            ctaOnboardingBrighten = false
                            withAnimation(ChessClockAnimation.smooth) { viewMode = .puzzle }
                        },
                        onReplay: {
                            if showReplayNudge {
                                OnboardingService.dismissStageC()
                                withAnimation(ChessClockAnimation.smooth) { showReplayNudge = false }
                            }
                            ctaOnboardingBrighten = false
                            withAnimation(ChessClockAnimation.smooth) { viewMode = .replay }
                        },
                        onSettings: {
                            showInfoOnboarding = false
                            ctaOnboardingBrighten = false
                            withAnimation(ChessClockAnimation.smooth) { viewMode = .settings }
                        },
                        highlightMetadata: showInfoOnboarding && infoOnboardingStep == 1,
                        highlightCTA: (showInfoOnboarding && infoOnboardingStep == 2) || showReplayNudge,
                        onboardingBrighten: ctaOnboardingBrighten
                    )
                }
            case .puzzle:
                GuessMoveView(
                    state: clockService.state,
                    guessService: guessService,
                    onBack: {
                        let shouldNudge = guessService.hasResult
                            && OnboardingService.shouldShowStageC
                            && guessService.stats.totalPlayed >= 1
                        withAnimation(ChessClockAnimation.smooth) { viewMode = .info }
                        if shouldNudge {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                                withAnimation(ChessClockAnimation.smooth) { showReplayNudge = true }
                                // Auto-brighten CTA after 0.5s
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    guard showReplayNudge else { return }
                                    withAnimation(.easeInOut(duration: 0.3)) { ctaOnboardingBrighten = true }
                                }
                            }
                        }
                    },
                    onReplay: { withAnimation(ChessClockAnimation.smooth) { viewMode = .replay } },
                    onFeedback: { correct in
                        puzzleRingTint = correct ? .correct : .wrong
                        puzzleFeedbackSeq += 1
                    },
                    showOnboarding: showPuzzleOnboarding,
                    onDismissOnboarding: {
                        OnboardingService.dismissStageE()
                        withAnimation(ChessClockAnimation.smooth) { showPuzzleOnboarding = false }
                    }
                )
            case .replay:
                GameReplayView(
                    game: clockService.state.game,
                    hour: clockService.state.hour,
                    isFlipped: clockService.state.isFlipped,
                    isActive: isPopoverVisible,
                    onBack: { withAnimation(ChessClockAnimation.smooth) { viewMode = .info } },
                    highlightProgressBar: highlightReplayBar
                )
            case .settings:
                SettingsPlaceholderView(
                    onBack: { withAnimation(ChessClockAnimation.smooth) { viewMode = .info } }
                )
            }

            // MARK: Ring layers
            if viewMode == .clock {
                GoldRingLayerView(minute: clockService.state.minute, second: clockService.state.second, isActive: isPopoverVisible, hourChange: hourChangeActive, hideTickMarks: hideTickMarks, forceFullRing: forceFullRing, hideGoldRing: hideGoldRing, pulseGold: pulseGoldRing)
                    .frame(width: 300, height: 300)
                    .allowsHitTesting(false)
                    .transition(.opacity)
            }

            if viewMode == .puzzle {
                PuzzleRingView(isActive: isPopoverVisible, tintTarget: puzzleRingTint, tintSeq: puzzleFeedbackSeq)
                    .frame(width: 300, height: 300)
                    .allowsHitTesting(false)
                    .transition(.opacity)
            }

            // MARK: Onboarding overlays — all ABOVE content

            // Stage 0: Welcome screen (not skippable)
            if showWelcome {
                WelcomeOverlayView(onDismiss: {
                    dismissWelcome()
                })
                .transition(.opacity)
            }

            // Stage A: first-launch clock tour
            if showOnboarding && viewMode == .clock {
                OnboardingOverlayView(
                    onDismiss: {
                        withAnimation(ChessClockAnimation.smooth) { showOnboarding = false }
                    },
                    onBoardTap: {
                        forceFullRing = false
                        hideTickMarks = false
                        hideGoldRing = false
                        withAnimation(ChessClockAnimation.smooth) {
                            showOnboarding = false
                            viewMode = .info
                        }
                    },
                    onShowRing: {
                        hideGoldRing = false
                    },
                    onReachFinalStep: {
                        forceFullRing = false  // triggers gold fade → clockwise fill animation
                        // Tick marks slide in after fill completes
                        // Fill duration = progress * 5.0s (fixed velocity), plus 0.35s fade phase
                        let progress = Double(clockService.state.minute * 60 + clockService.state.second) / 3600.0
                        let tickDelay = 0.35 + progress * 5.0 + 0.15
                        DispatchQueue.main.asyncAfter(deadline: .now() + tickDelay) {
                            hideTickMarks = false
                            // Gold ring pulse after ticks land (0.5s slide-in)
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                pulseGoldRing = true
                            }
                        }
                    }
                )
                .transition(.opacity)
            }

            // Stage B: info panel onboarding (2-step with spotlight)
            if showInfoOnboarding && viewMode == .info {
                stageBOverlay
                    .transition(.opacity)
                    .animation(ChessClockAnimation.smooth, value: infoOnboardingStep)
            }

            // Stage C: replay nudge after first puzzle (with spotlight on CTA)
            if showReplayNudge && viewMode == .info {
                stageCOverlay
                    .transition(.opacity)
            }

            // Stage D: replay onboarding (with spotlight on progress bar)
            if showReplayOnboarding && viewMode == .replay {
                stageDOverlay
                    .transition(.opacity)
            }
        }
        .frame(width: 300, height: 300)
        .clipShape(RoundedRectangle(cornerRadius: ChessClockRadius.outer))
        .onAppear {
            snapshotFen = clockService.state.fen
            snapshotFlipped = clockService.state.isFlipped
            if showWelcome {
                // Apply focus-pull starting state (blurred/dimmed/zoomed) now
                // that layout is stable — avoids first-frame offset glitch.
                welcomeBlur = ChessClockWelcome.blurRadius
                welcomeDim = ChessClockWelcome.dimAmount
                welcomeScale = ChessClockWelcome.zoomScale
                startFocusPull()
            } else if !OnboardingService.shouldShowStageA {
                // Returning user: animate open bloom to clear
                startOpenBloom()
            }
            if !showWelcome && OnboardingService.shouldShowStageA {
                showOnboarding = true
            }
        }
        .onChange(of: clockService.state.fen) { newFen in
            if !hourChangeActive { snapshotFen = newFen }
        }
        .onChange(of: clockService.state.isFlipped) { newFlipped in
            if !hourChangeActive { snapshotFlipped = newFlipped }
        }
        .onChange(of: clockService.state.hour) { _ in
            guard viewMode == .clock else { return }
            hourChangeActive = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.85) {
                withAnimation(.easeIn(duration: 0.1)) { hourFlash = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    snapshotFen = clockService.state.fen
                    snapshotFlipped = clockService.state.isFlipped
                    withAnimation(.easeOut(duration: 0.2)) { hourFlash = false }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                        hourChangeActive = false
                    }
                }
            }
        }
        .onChange(of: viewMode) { newMode in
            if newMode == .info && OnboardingService.shouldShowStageB {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    withAnimation(ChessClockAnimation.smooth) { showInfoOnboarding = true }
                }
            }
            if newMode == .replay && OnboardingService.shouldShowStageD {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    withAnimation(ChessClockAnimation.smooth) {
                        showReplayOnboarding = true
                        highlightReplayBar = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                        guard showReplayOnboarding else { return }
                        dismissStageD()
                    }
                }
            }
            if newMode == .puzzle && OnboardingService.shouldShowStageE {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    withAnimation(ChessClockAnimation.smooth) { showPuzzleOnboarding = true }
                }
            }
        }
        .background(WindowObserver(
            onBecomeKey: {
                isPopoverVisible = true
                viewMode = .clock
                showInfoOnboarding = false
                infoOnboardingStep = 1
                showReplayNudge = false
                showReplayOnboarding = false
                highlightReplayBar = false
                showWelcome = false
                showPuzzleOnboarding = false
                showOnboarding = false
                ctaOnboardingBrighten = false
                hideTickMarks = false
                forceFullRing = false
                hideGoldRing = false
                pulseGoldRing = false
                // Reset focus pull state
                welcomeBlur = ChessClockWelcome.blurRadius
                welcomeDim = ChessClockWelcome.dimAmount
                welcomeScale = ChessClockWelcome.zoomScale
                if OnboardingService.debugReplay {
                    OnboardingService.resetAll(); showWelcome = true
                    hideTickMarks = true
                    forceFullRing = true
                    hideGoldRing = true
                    openBlur = 0; openDim = 0; openScale = 1.0
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                        startFocusPull()
                    }
                } else if !OnboardingService.shouldShowWelcome && !OnboardingService.shouldShowStageA {
                    // Returning user: reset bloom to initial values, then animate to clear
                    openBlur = ChessClockOpenBloom.blurRadius
                    openDim = ChessClockOpenBloom.dimAmount
                    openScale = ChessClockOpenBloom.zoomScale
                    startOpenBloom()
                } else {
                    openBlur = 0; openDim = 0; openScale = 1.0
                }
                clockService.resume()
            },
            onResignKey: {
                isPopoverVisible = false
                clockService.pause()
            },
            onFloatingResume: {
                isPopoverVisible = true
                clockService.resume()
            }
        ))
    }

    // MARK: - Focus Pull (Stage 0)

    private func startFocusPull() {
        if NSWorkspace.shared.accessibilityDisplayShouldReduceMotion {
            welcomeBlur = 0; welcomeDim = 0; welcomeScale = 1.0
            return
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + ChessClockWelcome.focusDelay) {
            guard showWelcome else { return }
            withAnimation(.easeOut(duration: ChessClockWelcome.blurDuration)) {
                welcomeBlur = 0
            }
            withAnimation(.easeOut(duration: ChessClockWelcome.dimDuration)) {
                welcomeDim = 0
            }
            withAnimation(.easeOut(duration: ChessClockWelcome.scaleDuration)) {
                welcomeScale = 1.0
            }
        }
    }

    // MARK: - Open Bloom (every-open subtle focus pull)

    private func startOpenBloom() {
        guard !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion else {
            openBlur = 0; openDim = 0; openScale = 1.0
            return
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + ChessClockOpenBloom.startDelay) {
            withAnimation(.easeOut(duration: ChessClockOpenBloom.blurDuration)) {
                openBlur = 0
            }
            withAnimation(.easeOut(duration: ChessClockOpenBloom.dimDuration)) {
                openDim = 0
            }
            withAnimation(.easeOut(duration: ChessClockOpenBloom.scaleDuration)) {
                openScale = 1.0
            }
        }
    }

    private func dismissWelcome() {
        withAnimation(ChessClockAnimation.smooth) { showWelcome = false }
        if OnboardingService.shouldShowStageA {
            DispatchQueue.main.asyncAfter(deadline: .now() + ChessClockWelcome.stageADelay) {
                withAnimation(.easeOut(duration: 0.8)) { showOnboarding = true }
            }
        }
    }

    // MARK: - Stage B Overlay

    private var stageBOverlay: some View {
        ZStack {
            // Scrim with spotlight cutout
            if infoOnboardingStep == 1 {
                // Cutout for metadata area (bottom portion: players + event)
                // InfoPanelView: 12pt vPadding top, board ~164+flanking, CTA ~30, then metadata ~85pt at bottom
                // Position: centered x=150, y roughly at 252 (center of bottom metadata block)
                spotlightScrim(cutout: CGRect(x: 6, y: 220, width: 288, height: 66), cornerRadius: ChessClockRadius.pill)
            } else {
                // Cutout for board + CTA area (top portion)
                // Board at top with flanking icons, CTA below it
                // Roughly covers y=12..202
                spotlightScrim(cutout: CGRect(x: 55, y: 13, width: 190, height: 212), cornerRadius: ChessClockRadius.card)
            }

            // Pill — always above scrim
            if infoOnboardingStep == 1 {
                VStack {
                    OnboardingCalloutView(
                        text: "See the players and the event",
                        step: 1,
                        totalSteps: 2,
                        onTap: {}
                    )
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    Spacer()
                }
            } else {
                VStack {
                    Spacer()
                    OnboardingCalloutView(
                        text: "Play the winning moves from this game",
                        step: 2,
                        totalSteps: 2,
                        onTap: {}
                    )
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)
                }
            }
        }
        .frame(width: 300, height: 300)
        .contentShape(Rectangle())
        .onTapGesture { advanceStageB() }
        .allowsHitTesting(infoOnboardingStep == 1)  // Step 2: clicks pass through to CTA
    }

    private func advanceStageB() {
        if infoOnboardingStep < 2 {
            OnboardingService.dismissStageB()  // persist immediately so reopen won't replay
            withAnimation(ChessClockAnimation.smooth) { infoOnboardingStep = 2 }
            // Auto-brighten CTA after 0.5s
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                guard showInfoOnboarding && infoOnboardingStep == 2 else { return }
                withAnimation(.easeInOut(duration: 0.3)) { ctaOnboardingBrighten = true }
            }
        } else {
            dismissStageBStep2()
        }
    }

    /// Dismiss Stage B step 2 overlay — delay unbrighten by 1s for smooth fade.
    private func dismissStageBStep2() {
        withAnimation(ChessClockAnimation.smooth) { showInfoOnboarding = false }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.easeInOut(duration: 0.4)) { ctaOnboardingBrighten = false }
        }
    }

    // MARK: - Stage C Overlay

    private var stageCOverlay: some View {
        ZStack {
            // Spotlight: cutout around CTA button area
            // CTA pill is roughly at y=178..202, centered horizontally, ~80pt wide
            spotlightScrim(cutout: CGRect(x: 99, y: 186, width: 104, height: 38), cornerRadius: ChessClockRadius.card)

            // Pill at top
            VStack {
                OnboardingCalloutView(
                    text: guessService.result?.succeeded == true
                        ? "See how the full game played out"
                        : "Study the full game and the winning line",
                    onTap: {}
                )
                .padding(.horizontal, 20)
                .padding(.top, 16)
                Spacer()
            }
        }
        .frame(width: 300, height: 300)
        .allowsHitTesting(false)  // Clicks pass through to CTA button
    }

    /// Dismiss Stage C overlay — delay unbrighten by 1s for smooth fade.
    private func dismissStageCOverlay() {
        OnboardingService.dismissStageC()
        withAnimation(ChessClockAnimation.smooth) { showReplayNudge = false }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.easeInOut(duration: 0.4)) { ctaOnboardingBrighten = false }
        }
    }

    // MARK: - Stage D Overlay

    private var stageDOverlay: some View {
        ZStack {
            // Spotlight scrim with cutout for progress bar at bottom
            spotlightScrim(cutout: CGRect(x: 12, y: 270, width: 276, height: 20), cornerRadius: 7)

            // Pill — lowered a bit so it doesn't cover the top text
            VStack {
                Spacer().frame(height: 40)
                OnboardingCalloutView(
                    text: "Drag the golden bar or use arrows to scrub",
                    onTap: {}
                )
                .padding(.horizontal, 20)
                Spacer()
            }
        }
        .frame(width: 300, height: 300)
        .contentShape(Rectangle())
        .onTapGesture { dismissStageD() }
    }

    // MARK: - Stage D Dismiss

    /// Two-phase dismiss: remove highlight first (no flash), then animate overlay out.
    private func dismissStageD() {
        OnboardingService.dismissStageD()
        highlightReplayBar = false  // instant — no animation, prevents material flash
        withAnimation(ChessClockAnimation.dramatic) { showReplayOnboarding = false }
    }

    // MARK: - Spotlight Scrim Helper

    /// Creates a dark scrim with a soft-feathered cutout at the given rect.
    private func spotlightScrim(cutout: CGRect, cornerRadius: CGFloat) -> some View {
        Rectangle()
            .fill(Color.black.opacity(0.55))
            .mask {
                Rectangle()
                    .fill(Color.white)
                    .overlay {
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(Color.black)
                            .frame(width: cutout.width, height: cutout.height)
                            .position(x: cutout.midX, y: cutout.midY)
                            .blur(radius: 4)
                            .blendMode(.destinationOut)
                    }
                    .compositingGroup()
            }
    }

    // MARK: - Board + Glance (clock face)

    private var boardWithRing: some View {
        let boardFen = hourChangeActive ? snapshotFen : clockService.state.fen
        let boardFlipped = hourChangeActive ? snapshotFlipped : clockService.state.isFlipped

        return ZStack {
            ZStack {
                // Brown fill behind board: prevents blur edge artifact (Stage 0)
                // and covers ring gap with brown until gold ring fades in (A-2)
                if hideGoldRing {
                    ChessClockWelcome.boardFillColor
                        .frame(width: 300, height: 300)
                }

                BoardView(fen: boardFen, isFlipped: boardFlipped)
                    .frame(width: 280, height: 280)
                    .overlay(
                        RoundedRectangle(cornerRadius: ChessClockRadius.board)
                            .stroke(Color.black, lineWidth: 6)
                            .blur(radius: 4)
                            .mask(RoundedRectangle(cornerRadius: ChessClockRadius.board))
                            .opacity(0.22)
                    )
                    .overlay(
                        Color.white
                            .opacity(hourFlash ? 0.7 : 0)
                            .clipShape(RoundedRectangle(cornerRadius: ChessClockRadius.board))
                    )
            }
            .drawingGroup()
            .blur(radius: showWelcome ? welcomeBlur : (isHovering ? 8 : openBlur))
            .brightness(showWelcome ? welcomeDim : openDim)
            .scaleEffect(showWelcome ? welcomeScale : openScale)
            .animation(.easeInOut(duration: isHovering ? 0.2 : 0.15), value: isHovering)

            if isHovering {
                GlassPillView {
                    VStack(spacing: ChessClockSpace.xs) {
                        Text("\(clockService.state.hour):\(String(format: "%02d", clockService.state.minute)) \(clockService.state.isAM ? "AM" : "PM")")
                            .font(ChessClockType.display)
                            .foregroundStyle(.primary)
                        Text("Mate in \(clockService.state.hour)")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundStyle(.secondary)
                    }
                }
                .transition(.opacity)
                .animation(.easeInOut(duration: 0.15), value: isHovering)
            }
        }
        .frame(width: 300, height: 300)
        .contentShape(Rectangle())
        .onHover { hovering in
            // Suppress hover glance during entire first-launch flow (Stage 0 + gap + Stage A)
            if showWelcome || showOnboarding || OnboardingService.shouldShowStageA {
                isHovering = false; return
            }
            isHovering = hovering
        }
        .onTapGesture {
            // Suppress board tap during entire first-launch flow
            guard !showWelcome && !showOnboarding && !OnboardingService.shouldShowStageA else { return }
            // Snap open bloom if still running
            openBlur = 0; openDim = 0; openScale = 1.0
            withAnimation(ChessClockAnimation.smooth) { viewMode = .info }
        }
    }
}

// MARK: - WindowObserver (P5.2)

private struct WindowObserver: NSViewRepresentable {
    let onBecomeKey: () -> Void
    let onResignKey: () -> Void
    var onFloatingResume: (() -> Void)?

    func makeNSView(context: Context) -> _ObservingView {
        _ObservingView(onBecomeKey: onBecomeKey, onResignKey: onResignKey, onFloatingResume: onFloatingResume)
    }

    func updateNSView(_ nsView: _ObservingView, context: Context) {
        nsView.onBecomeKey = onBecomeKey
        nsView.onResignKey = onResignKey
        nsView.onFloatingResume = onFloatingResume
    }

    final class _ObservingView: NSView {
        var onBecomeKey: (() -> Void)?
        var onResignKey: (() -> Void)?
        var onFloatingResume: (() -> Void)?
        private var becomeKeyObserver: NSObjectProtocol?
        private var resignKeyObserver: NSObjectProtocol?

        init(onBecomeKey: @escaping () -> Void, onResignKey: @escaping () -> Void, onFloatingResume: (() -> Void)?) {
            self.onBecomeKey = onBecomeKey
            self.onResignKey = onResignKey
            self.onFloatingResume = onFloatingResume
            super.init(frame: .zero)
        }
        required init?(coder: NSCoder) { fatalError() }

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            guard let win = window else { return }

            if win.level == .floating {
                // Floating window: keep alive regardless of focus.
                // Resume immediately; only pause on actual window close.
                onFloatingResume?()
                resignKeyObserver = NotificationCenter.default.addObserver(
                    forName: NSWindow.willCloseNotification,
                    object: win,
                    queue: .main
                ) { [weak self] _ in self?.onResignKey?() }
            } else {
                // Popover: reset state on each reopen, pause on blur.
                becomeKeyObserver = NotificationCenter.default.addObserver(
                    forName: NSWindow.didBecomeKeyNotification,
                    object: win,
                    queue: .main
                ) { [weak self] _ in self?.onBecomeKey?() }

                resignKeyObserver = NotificationCenter.default.addObserver(
                    forName: NSWindow.didResignKeyNotification,
                    object: win,
                    queue: .main
                ) { [weak self] _ in self?.onResignKey?() }
            }
        }

        deinit {
            if let obs = becomeKeyObserver { NotificationCenter.default.removeObserver(obs) }
            if let obs = resignKeyObserver { NotificationCenter.default.removeObserver(obs) }
        }
    }
}

#Preview {
    ClockView(clockService: ClockService())
}
