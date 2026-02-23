import SwiftUI

/// Reusable frosted-glass container used for overlay pills (hover text, badges, etc.).
/// Features a glass-edge inner stroke and layered shadows for depth against blurred backgrounds.
struct GlassPillView<Content: View>: View {
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(.horizontal, ChessClockSpace.xl)
            .padding(.vertical, ChessClockSpace.lg)
            .background {
                RoundedRectangle(cornerRadius: ChessClockRadius.pill)
                    .fill(.ultraThinMaterial)
                    .overlay {
                        // Top-edge specular highlight
                        LinearGradient(
                            colors: [Color.white.opacity(0.15), .clear],
                            startPoint: .top,
                            endPoint: .center
                        )
                        .clipShape(RoundedRectangle(cornerRadius: ChessClockRadius.pill))
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: ChessClockRadius.pill)
                            .strokeBorder(Color.white.opacity(0.30), lineWidth: 0.5)
                    }
            }
            .clipShape(RoundedRectangle(cornerRadius: ChessClockRadius.pill))
            .shadow(color: .black.opacity(0.25), radius: 12, x: 0, y: 4)
            .shadow(color: .black.opacity(0.10), radius: 2, x: 0, y: 1)
    }
}
