import SwiftUI

struct ClockView: View {
    @ObservedObject var clockService: ClockService
    @State private var showOnboarding = OnboardingService.shouldShowOnboarding

    var body: some View {
        VStack(spacing: 10) {
            // Board with minute-ring traced around its perimeter
            // isFlipped: true in PM hours — board shown from Black's perspective
            BoardView(fen: clockService.state.fen, isFlipped: clockService.state.isFlipped)
                .overlay(
                    GeometryReader { geo in
                        MinuteSquareRingView(
                            minute: clockService.state.minute,
                            boardSize: geo.size.width
                        )
                    }
                )

            // Game metadata strip
            GameInfoView(game: clockService.state.game)
        }
        .padding(12)
        .frame(minWidth: 300, minHeight: 380)
        .overlay(
            Group {
                if showOnboarding {
                    OnboardingOverlayView {
                        OnboardingService.dismissOnboarding()
                        showOnboarding = false
                    }
                }
            }
        )
    }
}

#Preview {
    ClockView(clockService: ClockService())
}
