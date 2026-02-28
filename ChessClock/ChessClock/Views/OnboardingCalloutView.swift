import SwiftUI

/// Reusable onboarding callout pill — "Gold Ember" design.
/// Fully opaque dark espresso base with gold border, gold-tinted top gleam,
/// and a warm golden outer glow. Looks identical on every scrim level.
/// Always rendered ABOVE scrim layers by the caller's ZStack ordering.
struct OnboardingCalloutView: View {
    let text: String
    var subtext: String? = nil
    var step: Int = 0
    var totalSteps: Int = 0
    let onTap: () -> Void

    // MARK: - Pill palette (fully opaque, no transparency)

    /// Dark espresso — warm enough to belong, dark enough to contrast with board squares.
    private static let base = Color(red: 0.10, green: 0.08, blue: 0.06)

    /// Warm cream — desaturated gold-white that harmonizes with the glow.
    private static let textPrimary = Color(red: 0.94, green: 0.89, blue: 0.78)
    private static let textSecondary = Color(red: 0.94, green: 0.89, blue: 0.78).opacity(0.55)

    var body: some View {
        VStack(spacing: 6) {
            Text(text)
                .font(.system(size: 12.5, weight: .regular))
                .foregroundStyle(Self.textPrimary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            if let subtext {
                Text(subtext)
                    .font(ChessClockType.caption)
                    .foregroundStyle(Self.textSecondary)
                    .multilineTextAlignment(.center)
            }

            if totalSteps > 0 {
                HStack(spacing: 6) {
                    ForEach(1...totalSteps, id: \.self) { i in
                        Circle()
                            .fill(i <= step ? ChessClockColor.accentGold : Self.textPrimary.opacity(0.25))
                            .frame(width: 6, height: 6)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background {
            ZStack {
                // Base — solid dark espresso, fully opaque
                RoundedRectangle(cornerRadius: ChessClockRadius.card)
                    .fill(Self.base)

                // 3D depth — gold-warm top to darker bottom
                RoundedRectangle(cornerRadius: ChessClockRadius.card)
                    .fill(
                        LinearGradient(
                            colors: [
                                ChessClockColor.accentGoldLight.opacity(0.06),
                                Color.clear,
                                Color.black.opacity(0.15)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                // Top-edge gleam — concentrated gold highlight
                RoundedRectangle(cornerRadius: ChessClockRadius.card)
                    .fill(
                        LinearGradient(
                            colors: [ChessClockColor.accentGoldLight.opacity(0.12), Color.clear],
                            startPoint: .top,
                            endPoint: UnitPoint(x: 0.5, y: 0.35)
                        )
                    )

                // Gold border — crisp edge for the glow to anchor to
                RoundedRectangle(cornerRadius: ChessClockRadius.card)
                    .strokeBorder(ChessClockColor.accentGold.opacity(0.30), lineWidth: 0.75)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: ChessClockRadius.card))
        // Surface warmth — pill itself feels slightly lit
        .brightness(0.05)
        // Gold outer glow — warm halo
        .shadow(color: ChessClockColor.accentGold.opacity(0.38), radius: 28, x: 0, y: 0)
        // Tighter inner glow for definition
        .shadow(color: ChessClockColor.accentGold.opacity(0.18), radius: 8, x: 0, y: 0)
        // Grounding shadow — keeps it from floating away
        .shadow(color: .black.opacity(0.4), radius: 10, x: 0, y: 4)
    }
}
