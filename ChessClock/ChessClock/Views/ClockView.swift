import SwiftUI

struct ClockView: View {
    @ObservedObject var clockService: ClockService

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
    }
}

#Preview {
    ClockView(clockService: ClockService())
}
