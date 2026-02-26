import AppKit
import IOSurface
import QuartzCore
import SwiftUI

// MARK: - Flipped NSView

private final class ReplayFlippedLayerView: NSView {
    override var isFlipped: Bool { true }
}

// MARK: - ReplayBackgroundView

/// CALayer-based animated marble noise background for replay mode.
/// Uses the same Metal compute shader as PuzzleRingView but renders full-rect
/// (no ring mask) with a dark scrim overlay for text readability.
///
/// Layer hierarchy:
/// ```
/// ReplayFlippedLayerView (isFlipped = true)
///   +- noiseLayer: CALayer     -- Metal noise texture, 300x300, 10 FPS
///   +- scrimLayer: CALayer     -- dark overlay (70% black) for contrast
/// ```
struct ReplayBackgroundView: NSViewRepresentable {
    let isActive: Bool

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeNSView(context: Context) -> NSView {
        let view = ReplayFlippedLayerView(frame: NSRect(x: 0, y: 0, width: 300, height: 300))
        view.wantsLayer = true
        view.layer?.masksToBounds = true

        let scale = NSScreen.main?.backingScaleFactor ?? 2.0
        let bounds = CGRect(x: 0, y: 0, width: 300, height: 300)
        let coord = context.coordinator

        // Noise texture layer — full 300x300
        let noiseLayer = CALayer()
        noiseLayer.frame = bounds
        noiseLayer.contentsScale = scale
        noiseLayer.contentsGravity = .resize
        view.layer!.addSublayer(noiseLayer)
        coord.noiseLayer = noiseLayer

        // Create renderer: warm marble-gold, smaller blobs, moderate drift
        let renderer = GoldNoiseRenderer(width: 3200, height: 3200)
        renderer?.colorScheme = 1.0   // marble brown (chess board tones)
        renderer?.scale = 0.001      // large blobs
        renderer?.speed = 0.20       // gentle drift
        coord.renderer = renderer

        // Render initial frame
        renderer?.renderFrame { [weak coord] surface in
            DispatchQueue.main.async {
                guard let coord = coord else { return }
                CATransaction.begin()
                CATransaction.setDisableActions(true)
                coord.noiseLayer?.contents = surface
                CATransaction.commit()
            }
        }

        // Dark scrim for text readability
        let scrimLayer = CALayer()
        scrimLayer.frame = bounds
        scrimLayer.backgroundColor = CGColor(gray: 0, alpha: 0.56)
        scrimLayer.contentsScale = scale
        view.layer!.addSublayer(scrimLayer)

        // Timer lifecycle
        let reduceMotion = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
        coord.reduceMotion = reduceMotion

        if !reduceMotion && isActive {
            coord.startTimer()
        }

        coord.lastIsActive = isActive

        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        let coord = context.coordinator

        if isActive != coord.lastIsActive {
            coord.lastIsActive = isActive
            if isActive && !coord.reduceMotion {
                if coord.noiseTimer == nil {
                    coord.startTimer()
                }
            } else if !isActive {
                coord.noiseTimer?.invalidate()
                coord.noiseTimer = nil
            }
        }
    }

    // MARK: - Coordinator

    final class Coordinator {
        var renderer: GoldNoiseRenderer?
        var noiseLayer: CALayer?
        var noiseTimer: Timer?
        var lastIsActive: Bool = true
        var reduceMotion: Bool = false

        deinit {
            noiseTimer?.invalidate()
        }

        func startTimer() {
            let timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 12.0, repeats: true) { [weak self] _ in
                guard let self = self,
                      let renderer = self.renderer else { return }

                renderer.renderFrame { [weak self] surface in
                    DispatchQueue.main.async {
                        guard let self = self else { return }
                        CATransaction.begin()
                        CATransaction.setDisableActions(true)
                        self.noiseLayer?.contents = surface
                        CATransaction.commit()
                    }
                }
            }
            RunLoop.main.add(timer, forMode: .common)
            noiseTimer = timer
        }
    }
}
