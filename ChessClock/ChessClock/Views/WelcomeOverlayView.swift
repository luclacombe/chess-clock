import SwiftUI

/// Stage 0: Welcome screen shown on first launch before Stage A.
/// Elegant entrance animation, centered text, auto-dismisses after 3s or on tap.
struct WelcomeOverlayView: View {
    let onDismiss: () -> Void

    @State private var dismissed = false
    // Entrance animation states
    @State private var titleOpacity: Double = 0
    @State private var titleOffset: CGFloat = 8
    @State private var subtitleOpacity: Double = 0
    @State private var subtitleOffset: CGFloat = 6
    @State private var scrimOpacity: Double = 0
    @State private var dividerScale: CGFloat = 0
    // Exit animation
    @State private var exitProgress: Double = 0

    var body: some View {
        ZStack {
            // Backdrop: dark scrim with blur
            Color.black
                .opacity(scrimOpacity * 0.55 * (1.0 - exitProgress))

            Rectangle()
                .fill(.ultraThinMaterial)
                .opacity(scrimOpacity * (1.0 - exitProgress))

            // Content
            VStack(spacing: 0) {
                Text("Chess Clock")
                    .font(.system(size: 24, weight: .semibold, design: .default))
                    .foregroundStyle(.primary)
                    .opacity(titleOpacity * (1.0 - exitProgress))
                    .offset(y: titleOffset + exitProgress * -12)

                // Thin gold divider
                Rectangle()
                    .fill(ChessClockColor.accentGold.opacity(0.5))
                    .frame(width: 40 * dividerScale, height: 0.5)
                    .opacity((1.0 - exitProgress))
                    .padding(.vertical, 10)

                Text("Every board tells the time")
                    .font(.system(size: 13, weight: .regular, design: .default))
                    .foregroundStyle(.secondary)
                    .opacity(subtitleOpacity * (1.0 - exitProgress))
                    .offset(y: subtitleOffset + exitProgress * -8)
            }
        }
        .frame(width: 300, height: 300)
        .contentShape(Rectangle())
        .onTapGesture { dismiss() }
        .onAppear {
            // Staggered entrance
            withAnimation(.easeOut(duration: 0.5)) {
                scrimOpacity = 1.0
            }
            withAnimation(.easeOut(duration: 0.7).delay(0.15)) {
                titleOpacity = 1.0
                titleOffset = 0
            }
            withAnimation(.easeOut(duration: 0.5).delay(0.35)) {
                dividerScale = 1.0
            }
            withAnimation(.easeOut(duration: 0.7).delay(0.5)) {
                subtitleOpacity = 1.0
                subtitleOffset = 0
            }
            // Auto-dismiss after 3s
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                dismiss()
            }
        }
    }

    private func dismiss() {
        guard !dismissed else { return }
        dismissed = true
        OnboardingService.dismissWelcome()
        withAnimation(.easeInOut(duration: 0.5)) {
            exitProgress = 1.0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            onDismiss()
        }
    }
}
