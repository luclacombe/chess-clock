import AppKit
import SwiftUI

// MARK: - View mode

private enum ViewMode: Equatable { case clock, info, puzzle, replay, settings }

// MARK: - ClockView

struct ClockView: View {
    @ObservedObject var clockService: ClockService
    @StateObject private var guessService: GuessService
    @State private var showOnboarding = OnboardingService.shouldShowOnboarding
    @State private var viewMode: ViewMode = .clock
    @State private var isHovering = false
    @State private var isPopoverVisible = true
    @State private var puzzleRingTint: TintTarget = .none
    @State private var puzzleFeedbackSeq: Int = 0

    init(clockService: ClockService) {
        self.clockService = clockService
        self._guessService = StateObject(wrappedValue: GuessService(clockService: clockService))
    }

    var body: some View {
        ZStack {
            switch viewMode {
            case .clock:
                boardWithRing
            case .info:
                InfoPanelView(
                    state: clockService.state,
                    guessService: guessService,
                    onBack: { withAnimation(ChessClockAnimation.smooth) { viewMode = .clock } },
                    onGuess: { withAnimation(ChessClockAnimation.smooth) { viewMode = .puzzle } },
                    onReplay: { withAnimation(ChessClockAnimation.smooth) { viewMode = .replay } },
                    onSettings: { withAnimation(ChessClockAnimation.smooth) { viewMode = .settings } }
                )
            case .puzzle:
                GuessMoveView(
                    state: clockService.state,
                    guessService: guessService,
                    onBack: { withAnimation(ChessClockAnimation.smooth) { viewMode = .info } },
                    onReplay: { withAnimation(ChessClockAnimation.smooth) { viewMode = .replay } },
                    onFeedback: { correct in
                        puzzleRingTint = correct ? .correct : .wrong
                        puzzleFeedbackSeq += 1
                    }
                )
            case .replay:
                GameReplayView(
                    game: clockService.state.game,
                    hour: clockService.state.hour,
                    isFlipped: clockService.state.isFlipped,
                    isActive: isPopoverVisible,
                    onBack: { withAnimation(ChessClockAnimation.smooth) { viewMode = .info } }
                )
            case .settings:
                SettingsPlaceholderView(
                    onBack: { withAnimation(ChessClockAnimation.smooth) { viewMode = .info } }
                )
            }

            // Ring layer — only in tree when clock mode (CALayer animations restart on re-insert)
            // Rendered AFTER boardWithRing so tick marks appear above the board surface.
            // allowsHitTesting(false) lets hover/tap events pass through to the board below.
            if viewMode == .clock {
                GoldRingLayerView(minute: clockService.state.minute, second: clockService.state.second, isActive: isPopoverVisible)
                    .frame(width: 300, height: 300)
                    .allowsHitTesting(false)
                    .transition(.opacity)
            }

            // Marble ring — only in tree when puzzle mode
            if viewMode == .puzzle {
                PuzzleRingView(isActive: isPopoverVisible, tintTarget: puzzleRingTint, tintSeq: puzzleFeedbackSeq)
                    .frame(width: 300, height: 300)
                    .allowsHitTesting(false)
                    .transition(.opacity)
            }

            if showOnboarding {
                OnboardingOverlayView {
                    OnboardingService.dismissOnboarding()
                    showOnboarding = false
                }
            }
        }
        .frame(width: 300, height: 300)
        .clipShape(RoundedRectangle(cornerRadius: ChessClockRadius.outer))
        // Reset to clock on popover reopen; pause timer on popover close
        .background(WindowObserver(
            onBecomeKey: {
                isPopoverVisible = true
                viewMode = .clock
                clockService.resume()
            },
            onResignKey: {
                isPopoverVisible = false
                clockService.pause()
            }
        ))
    }

    // MARK: - Board + Glance (clock face)

    private var boardWithRing: some View {
        ZStack {
            // Layer 1: chess board (280×280) — blurs on hover (Glance face)
            BoardView(fen: clockService.state.fen, isFlipped: clockService.state.isFlipped)
                .frame(width: 280, height: 280)
                // Inner shadow: blurred inset stroke — computed once per hour (Equatable board)
                .overlay(
                    RoundedRectangle(cornerRadius: ChessClockRadius.board)
                        .stroke(Color.black, lineWidth: 6)
                        .blur(radius: 4)
                        .mask(RoundedRectangle(cornerRadius: ChessClockRadius.board))
                        .opacity(0.22)
                )
                .drawingGroup()  // Rasterize board + shadow into one texture for hover blur
                .blur(radius: isHovering ? 8 : 0)
                .animation(.easeInOut(duration: isHovering ? 0.2 : 0.15), value: isHovering)

            // Layer 2: glance pill — only in tree when hovering (removes .ultraThinMaterial compositing)
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
        .onHover { isHovering = $0 }
        .onTapGesture { withAnimation(ChessClockAnimation.smooth) { viewMode = .info } }
    }
}

// MARK: - WindowObserver (P5.2)
// Fires onBecomeKey / onResignKey when THIS specific window (our MenuBarExtra popover)
// becomes or resigns the key window. Uses the window identity of the view's own NSWindow.

private struct WindowObserver: NSViewRepresentable {
    let onBecomeKey: () -> Void
    let onResignKey: () -> Void

    func makeNSView(context: Context) -> _ObservingView {
        _ObservingView(onBecomeKey: onBecomeKey, onResignKey: onResignKey)
    }

    func updateNSView(_ nsView: _ObservingView, context: Context) {
        nsView.onBecomeKey = onBecomeKey
        nsView.onResignKey = onResignKey
    }

    final class _ObservingView: NSView {
        var onBecomeKey: (() -> Void)?
        var onResignKey: (() -> Void)?
        private var becomeKeyObserver: NSObjectProtocol?
        private var resignKeyObserver: NSObjectProtocol?

        init(onBecomeKey: @escaping () -> Void, onResignKey: @escaping () -> Void) {
            self.onBecomeKey = onBecomeKey
            self.onResignKey = onResignKey
            super.init(frame: .zero)
        }
        required init?(coder: NSCoder) { fatalError() }

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            if let win = window {
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
