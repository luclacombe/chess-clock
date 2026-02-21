import SwiftUI

struct ClockView: View {
    @ObservedObject var clockService: ClockService
    @StateObject private var guessService: GuessService
    @State private var showOnboarding = OnboardingService.shouldShowOnboarding
    @State private var showInfo = false
    @State private var isHovering = false

    init(clockService: ClockService) {
        self.clockService = clockService
        // GuessService needs the ClockService to monitor hour changes
        self._guessService = StateObject(wrappedValue: GuessService(clockService: clockService))
    }

    var body: some View {
        ZStack {
            if showInfo {
                InfoPanelView(state: clockService.state, guessService: guessService) {
                    showInfo = false
                }
            } else {
                boardWithRing
            }

            if showOnboarding {
                OnboardingOverlayView {
                    OnboardingService.dismissOnboarding()
                    showOnboarding = false
                }
            }
        }
        .padding(12)
        .frame(width: 312, height: 332)
    }

    // MARK: - Board + ring (default view)

    private var boardWithRing: some View {
        ZStack {
            BoardView(fen: clockService.state.fen, isFlipped: clockService.state.isFlipped)
                .overlay(
                    GeometryReader { geo in
                        MinuteSquareRingView(
                            minute: clockService.state.minute,
                            boardSize: geo.size.width
                        )
                    }
                )

            // Hover hint
            if isHovering {
                VStack {
                    Spacer()
                    Text("Click for more info")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.black.opacity(0.65))
                        .cornerRadius(6)
                        .padding(.bottom, 8)
                }
            }
        }
        .contentShape(Rectangle())
        .onHover { isHovering = $0 }
        .onTapGesture { showInfo = true }
    }
}

#Preview {
    ClockView(clockService: ClockService())
}
