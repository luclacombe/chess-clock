import AppKit
import SwiftUI

/// Stage 0: Cinematic "focus pull" welcome — transparent overlay with
/// floating bokeh gold motes and a tagline that fades in then out.
/// The board blur/dim/scale is driven by ClockView (focus-pull modifiers).
struct WelcomeOverlayView: View {
    let onDismiss: () -> Void

    @State private var dismissed = false
    @State private var motesOpacity: Double = 1.0
    @State private var taglineOpacity: Double = 0

    private var reduceMotion: Bool {
        NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
    }

    var body: some View {
        ZStack {
            // Gold bokeh motes
            if !reduceMotion {
                motesLayer
                    .opacity(motesOpacity)
            }

            // Tagline with dark halo for legibility against board
            if !reduceMotion {
                Text("Every board tells the time")
                    .font(.system(size: ChessClockWelcome.taglineSize, weight: .light, design: .serif))
                    .kerning(ChessClockWelcome.taglineKerning)
                    .foregroundStyle(ChessClockWelcome.taglineColor)
                    .shadow(color: .black.opacity(0.95), radius: 3, y: 1)
                    .shadow(color: .black.opacity(0.8), radius: 8)
                    .shadow(color: .black.opacity(0.5), radius: 16)
                    .shadow(color: .black.opacity(0.25), radius: 30)
                    .opacity(taglineOpacity)
            }
        }
        .frame(width: 300, height: 300)
        .contentShape(Rectangle())
        .onTapGesture { }  // Swallow taps — Stage 0 is not skippable
        .onAppear {
            OnboardingService.dismissWelcome()
            if reduceMotion {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    dismiss()
                }
                return
            }
            scheduleTimeline()
        }
    }

    // MARK: - Motes Layer

    private var motesLayer: some View {
        ZStack {
            ForEach(0..<ChessClockWelcome.moteCount, id: \.self) { index in
                DustMoteView(index: index)
            }
        }
        .frame(width: 280, height: 280)
    }

    // MARK: - Timeline

    private func scheduleTimeline() {
        // Tagline fade in
        DispatchQueue.main.asyncAfter(deadline: .now() + ChessClockWelcome.taglineFadeInAt) {
            guard !dismissed else { return }
            withAnimation(.easeOut(duration: ChessClockWelcome.taglineFadeInDuration)) {
                taglineOpacity = 1.0
            }
        }

        // Motes group safety cutoff (most fade individually before this)
        DispatchQueue.main.asyncAfter(deadline: .now() + ChessClockWelcome.motesCutoffAt) {
            guard !dismissed else { return }
            withAnimation(.easeInOut(duration: ChessClockWelcome.motesCutoffDuration)) {
                motesOpacity = 0
            }
        }

        // Tagline fade out
        DispatchQueue.main.asyncAfter(deadline: .now() + ChessClockWelcome.taglineFadeOutAt) {
            guard !dismissed else { return }
            withAnimation(.easeInOut(duration: ChessClockWelcome.taglineFadeOutDuration)) {
                taglineOpacity = 0
            }
        }

        // Auto-dismiss
        DispatchQueue.main.asyncAfter(deadline: .now() + ChessClockWelcome.autoDismissDelay) {
            dismiss()
        }
    }

    // MARK: - Dismiss

    private func dismiss() {
        guard !dismissed else { return }
        dismissed = true
        onDismiss()
    }
}

// MARK: - DustMoteView

/// A single floating bokeh circle with unique size, opacity, color, blur,
/// position, and lifespan — deterministic per index for stable renders.
private struct DustMoteView: View {
    let index: Int

    @State private var visible = false
    @State private var drifted = false

    // Per-mote tables — randomized (seed=42), precomputed for stable renders
    private static let sizes: [CGFloat] = [19.7, 5.6, 11.3, 10.1, 21.9, 20.6, 25.5, 7.0, 14.7, 5.7]
    private static let blurs: [CGFloat] = [7.2, 2.5, 3.5, 3.6, 10.8, 9.5, 9.3, 3.3, 8.0, 1.7]
    private static let opacities: [Double] = [0.43, 0.39, 0.25, 0.18, 0.48, 0.25, 0.16, 0.16, 0.44, 0.35]
    private static let xPositions: [CGFloat] = [104.2, 167.0, 173.5, 205.6, 38.6, 268.8, 205.9, 84.2, 42.5, 251.0]
    private static let yPositions: [CGFloat] = [191.0, 55.1, 209.9, 107.1, 49.0, 137.6, 246.9, 54.8, 215.6, 244.3]
    private static let spawnDelays: [Double] = [0.3, 0.17, 0.21, 0.75, 0.52, 0.49, 0.14, 0.58, 0.13, 0.3]
    private static let driftDurations: [Double] = [2.8, 2.2, 2.1, 2.3, 2.5, 2.4, 1.6, 1.3, 1.7, 1.6]
    private static let driftAmounts: [CGFloat] = [25.3, 43.6, 41.9, 27.9, 36.4, 29.9, 42.9, 31.5, 26.6, 26.2]
    private static let fadeIns: [Double] = [0.8, 0.6, 0.8, 0.9, 0.7, 0.6, 1.0, 0.8, 0.5, 0.5]
    private static let colorShifts: [(r: Double, g: Double, b: Double)] = [
        (-0.029, 0.02, 0.031),
        (0.002, -0.025, -0.006),
        (0.06, 0.012, 0.047),
        (0.046, -0.029, 0.025),
        (0.028, 0.013, -0.016),
        (0.024, -0.021, -0.001),
        (0.005, 0.046, 0.039),
        (-0.014, 0.01, -0.024),
        (0.051, 0.04, -0.013),
        (0.024, 0.019, -0.026),
    ]

    private var size: CGFloat { Self.sizes[index % Self.sizes.count] }
    private var blurRadius: CGFloat { Self.blurs[index % Self.blurs.count] }
    private var peakOpacity: Double { Self.opacities[index % Self.opacities.count] }
    private var startX: CGFloat { Self.xPositions[index % Self.xPositions.count] }
    private var startY: CGFloat { Self.yPositions[index % Self.yPositions.count] }
    private var spawnDelay: Double { Self.spawnDelays[index % Self.spawnDelays.count] }
    private var driftDuration: Double { Self.driftDurations[index % Self.driftDurations.count] }
    private var driftAmount: CGFloat { Self.driftAmounts[index % Self.driftAmounts.count] }
    private var fadeInDuration: Double { Self.fadeIns[index % Self.fadeIns.count] }

    private var moteColor: Color {
        let s = Self.colorShifts[index % Self.colorShifts.count]
        return Color(
            red: 191/255 + s.r,
            green: 155/255 + s.g,
            blue: 48/255 + s.b
        )
    }

    var body: some View {
        Circle()
            .fill(moteColor)
            .frame(width: size, height: size)
            .blur(radius: blurRadius)
            .shadow(color: moteColor.opacity(0.4), radius: blurRadius * 0.6)
            .opacity(visible ? (drifted ? 0 : peakOpacity) : 0)
            .offset(x: startX - 140, y: (startY + (drifted ? -driftAmount : 0)) - 140)
            .onAppear {
                // Phase 1: fade in
                withAnimation(.easeOut(duration: fadeInDuration).delay(spawnDelay)) {
                    visible = true
                }
                // Phase 2: drift up + fade out (starts shortly after fade-in begins)
                let driftDelay = spawnDelay + fadeInDuration * 0.3
                withAnimation(.easeInOut(duration: driftDuration).delay(driftDelay)) {
                    drifted = true
                }
            }
    }
}
