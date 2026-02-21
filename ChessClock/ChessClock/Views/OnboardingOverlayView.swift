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
                Text("The hour = how many moves until this game ended.\nThe ring = minutes elapsed in the hour.")
                    .font(.callout)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)
                Button("Dismiss") {
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
