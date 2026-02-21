import SwiftUI

struct OnboardingOverlayView: View {
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.6)
            VStack(spacing: 14) {
                Text("Welcome to Chess Clock")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                Text("The board shows a real game, one move before checkmate.\nThe gold ring traces the minutes in the hour.\nA new puzzle appears every hour.\n\nTap the board to see game info and guess the finishing move.")
                    .font(.callout)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)
                Button("Got it") {
                    onDismiss()
                }
                .buttonStyle(.borderedProminent)
                .padding(.top, 4)
            }
            .padding(20)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
            .padding(20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
