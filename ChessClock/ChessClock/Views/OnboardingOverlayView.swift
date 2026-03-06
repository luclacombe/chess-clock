import SwiftUI

/// Stage A: 3-step progressive tour on the clock face (first launch).
/// Uses spotlight dimming (mask + destinationOut) to highlight board or ring per step.
/// Tap anywhere to advance. All pills at top. Step 3 is 1-click dismiss+navigate.
struct OnboardingOverlayView: View {
    let onDismiss: () -> Void
    let onBoardTap: () -> Void
    var onShowRing: (() -> Void)? = nil
    var onReachFinalStep: (() -> Void)? = nil

    @State private var step: Int = 1
    @State private var boardPulse: Bool = false
    @State private var visible: Bool = false

    var body: some View {
        ZStack {
            // Spotlight scrim layer
            spotlightScrim
                .opacity(visible ? 1 : 0)

            // Callout pill at BOTTOM — always above scrim
            VStack {
                Spacer()

                OnboardingCalloutView(
                    text: calloutText,
                    step: step,
                    totalSteps: 3,
                    onTap: { advance() }
                )
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
                .id(step)
            }
            .opacity(visible ? 1 : 0)
        }
        .frame(width: 300, height: 300)
        .contentShape(Rectangle())
        .onTapGesture { advance() }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) { visible = true }
        }
        .onChange(of: step) { newStep in
            if newStep == 3 {
                withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                    boardPulse = true
                }
            }
        }
    }

    // MARK: - Spotlight Scrim

    @ViewBuilder
    private var spotlightScrim: some View {
        switch step {
        case 1:
            // Board spotlight — darken ring extra dark, board bright, crisp edge
            Rectangle()
                .fill(Color.black.opacity(0.72))
                .mask {
                    Rectangle()
                        .fill(Color.white)
                        .overlay {
                            RoundedRectangle(cornerRadius: ChessClockRadius.board)
                                .fill(Color.black)
                                .frame(width: 280, height: 280)
                                .blendMode(.destinationOut)
                        }
                        .compositingGroup()
                }
        case 2:
            // Ring spotlight — darken board EXTRA dark so ring pops
            Rectangle()
                .fill(Color.black.opacity(0.72))
                .mask {
                    Rectangle()
                        .fill(Color.white)
                        .overlay {
                            RingAnnulusShape()
                                .fill(Color.black, style: FillStyle(eoFill: true))
                                .frame(width: 300, height: 300)
                                .blendMode(.destinationOut)
                        }
                        .compositingGroup()
                }
        default:
            // Step 3 — no scrim, board is fully visible
            Color.clear
        }
    }

    private var calloutText: String {
        switch step {
        case 1: return "Every hour, a real game\nThe board shows the hour"
        case 2: return "The ring shows the minutes"
        case 3: return "Tap anywhere for game details"
        default: return ""
        }
    }

    private func advance() {
        guard visible else { return }
        if step < 3 {
            withAnimation(.easeInOut(duration: 0.8)) {
                step += 1
            }
            if step == 2 { onShowRing?() }
            if step == 3 { onReachFinalStep?() }
        } else {
            OnboardingService.dismissStageA()
            onDismiss()
            onBoardTap()
        }
    }

    /// Board pulse scale — exposed for ClockView to read.
    var pulseScale: CGFloat {
        boardPulse ? 1.015 : 1.0
    }
}

// MARK: - Ring Annulus Shape

/// A ring shape: outer rounded rect (300×300) minus inner rounded rect (280×280), centered.
private struct RingAnnulusShape: Shape {
    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let outerSize = CGSize(width: 300, height: 300)
        let innerSize = CGSize(width: 280, height: 280)

        let outerRect = CGRect(
            x: center.x - outerSize.width / 2,
            y: center.y - outerSize.height / 2,
            width: outerSize.width,
            height: outerSize.height
        )
        let innerRect = CGRect(
            x: center.x - innerSize.width / 2,
            y: center.y - innerSize.height / 2,
            width: innerSize.width,
            height: innerSize.height
        )

        var path = Path()
        path.addRoundedRect(in: outerRect, cornerSize: CGSize(width: ChessClockRadius.outer, height: ChessClockRadius.outer))
        path.addRoundedRect(in: innerRect, cornerSize: CGSize(width: ChessClockRadius.board, height: ChessClockRadius.board))
        return path
    }
}
