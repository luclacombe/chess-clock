import SwiftUI

struct ClockView: View {
    @ObservedObject var clockService: ClockService
    @State private var showOnboarding = OnboardingService.shouldShowOnboarding

    var body: some View {
        VStack(spacing: 10) {
            // Board with minute-ring traced around its perimeter
            BoardView(fen: clockService.state.fen)
                .overlay(
                    GeometryReader { geo in
                        MinuteSquareRingView(
                            minute: clockService.state.minute,
                            boardSize: geo.size.width
                        )
                    }
                )

            // AM/PM indicator
            AMPMView(isAM: clockService.state.isAM)

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
