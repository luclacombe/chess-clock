import AppKit
import IOSurface
import QuartzCore
import SwiftUI

// MARK: - Tint Target (file-scope for ClockView access)

/// Tint target for puzzle ring feedback: none (pure marble), wrong (red), correct (green).
enum TintTarget: Equatable {
    case none, wrong, correct
}

// MARK: - Flipped NSView (y-down to match SwiftUI coordinate system)

/// NSView subclass with `isFlipped = true` so the layer coordinate system
/// has origin at top-left (y-down), matching SwiftUI and all the path math.
private final class PuzzleFlippedLayerView: NSView {
    override var isFlipped: Bool { true }
}

// MARK: - PuzzleRingView

/// CALayer-based decorative marble noise ring for puzzle mode.
/// Uses Metal compute shader to render animated simplex noise mapped to marble colors.
/// Supports smooth color-tint transitions for wrong/correct feedback via a phase-based state machine.
///
/// Layer hierarchy:
/// ```
/// PuzzleFlippedLayerView (isFlipped = true)
///   +- boardShadowLayer: CAShapeLayer        -- inner shadow for ring depth (first sublayer)
///   +- goldContainer: CALayer                -- always fully visible (no progress mask)
///   |   +- noiseLayer: CALayer               -- Metal noise texture, ring-masked, 15 FPS
///   |   +- specularStrip: CAShapeLayer       -- white 15% inner highlight (static)
///   |   +- shadowStrip: CAShapeLayer         -- black 6% outer shadow (static)
/// ```
struct PuzzleRingView: NSViewRepresentable {
    let isActive: Bool
    let tintTarget: TintTarget
    let tintSeq: Int

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeNSView(context: Context) -> NSView {
        let view = PuzzleFlippedLayerView(frame: NSRect(x: 0, y: 0, width: 300, height: 300))
        view.wantsLayer = true
        view.layer?.masksToBounds = false

        let scale = NSScreen.main?.backingScaleFactor ?? 2.0
        let bounds = CGRect(x: 0, y: 0, width: 300, height: 300)
        let coord = context.coordinator

        // MARK: - Board Shadow Layer (first sublayer — behind everything)
        let boardShadowLayer = CAShapeLayer()
        let innerInset: CGFloat = 10
        let innerRadius: CGFloat = ChessClockRadius.outer - innerInset // 8pt
        let innerRect = bounds.insetBy(dx: innerInset, dy: innerInset)
        let shadowPath = CGMutablePath()
        shadowPath.addRoundedRect(in: innerRect, cornerWidth: innerRadius, cornerHeight: innerRadius)
        boardShadowLayer.path = shadowPath
        boardShadowLayer.strokeColor = CGColor(gray: 0, alpha: 0.01)
        boardShadowLayer.lineWidth = 1
        boardShadowLayer.fillColor = nil
        boardShadowLayer.shadowColor = CGColor(gray: 0, alpha: 0.25)
        boardShadowLayer.shadowRadius = 3.0
        boardShadowLayer.shadowOpacity = 1.0
        boardShadowLayer.shadowOffset = .zero
        boardShadowLayer.frame = bounds
        boardShadowLayer.contentsScale = scale
        view.layer!.addSublayer(boardShadowLayer)

        // MARK: - Gold Container (noise + specular + shadow, full ring always visible)
        let goldContainer = CALayer()
        goldContainer.frame = bounds
        goldContainer.contentsScale = scale
        view.layer!.addSublayer(goldContainer)

        // Noise texture layer filling full 300x300 bounds, clipped to ring by its own mask
        let noiseLayer = CALayer()
        noiseLayer.frame = bounds
        noiseLayer.contentsScale = scale
        noiseLayer.contentsGravity = .resize

        // Ring-shaped mask applied directly to noiseLayer (clips noise to 8pt band)
        let noiseRingMask = CAShapeLayer()
        noiseRingMask.path = Self.ringPath(in: bounds)
        noiseRingMask.fillRule = .evenOdd
        noiseRingMask.fillColor = CGColor(gray: 1, alpha: 1)
        noiseRingMask.frame = bounds
        noiseRingMask.contentsScale = scale
        noiseLayer.mask = noiseRingMask

        goldContainer.addSublayer(noiseLayer)
        coord.noiseLayer = noiseLayer

        // Create renderer with marble color scheme and render initial frame
        let renderer = GoldNoiseRenderer()
        renderer?.colorScheme = 1.0 // marble
        coord.renderer = renderer
        renderer?.renderFrame { [weak coord] surface in
            DispatchQueue.main.async {
                guard let coord = coord else { return }
                CATransaction.begin()
                CATransaction.setDisableActions(true)
                coord.noiseLayer?.contents = surface
                CATransaction.commit()
            }
        }

        // Specular highlight (inner edge strip: 9pt to 10pt inset)
        let specularStrip = CAShapeLayer()
        specularStrip.path = Self.stripPath(in: bounds, outerInset: 9, innerInset: 10)
        specularStrip.fillColor = CGColor(red: 1, green: 1, blue: 1, alpha: 0.15)
        specularStrip.fillRule = .evenOdd
        specularStrip.frame = bounds
        specularStrip.contentsScale = scale
        goldContainer.addSublayer(specularStrip)

        // Shadow strip (outer edge strip: 2pt to 3pt inset)
        let shadowStrip = CAShapeLayer()
        shadowStrip.path = Self.stripPath(in: bounds, outerInset: 2, innerInset: 3)
        shadowStrip.fillColor = CGColor(red: 0, green: 0, blue: 0, alpha: 0.06)
        shadowStrip.fillRule = .evenOdd
        shadowStrip.frame = bounds
        shadowStrip.contentsScale = scale
        goldContainer.addSublayer(shadowStrip)

        // MARK: - Noise Animation Timer
        let reduceMotion = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
        coord.reduceMotion = reduceMotion

        if !reduceMotion && isActive {
            coord.startTimer()
        }

        coord.lastIsActive = isActive
        coord.lastTintSeq = tintSeq

        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        let coord = context.coordinator

        // Timer lifecycle: start/stop based on isActive
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

        // Tint event dispatch: react to tintSeq changes
        if tintSeq != coord.lastTintSeq && tintTarget != .none {
            coord.lastTintSeq = tintSeq

            // Extract target color RGB
            let rgb: (CGFloat, CGFloat, CGFloat)
            switch tintTarget {
            case .wrong:
                rgb = (ChessClockColor.ringTintWrong.r,
                       ChessClockColor.ringTintWrong.g,
                       ChessClockColor.ringTintWrong.b)
            case .correct:
                rgb = (ChessClockColor.ringTintCorrect.r,
                       ChessClockColor.ringTintCorrect.g,
                       ChessClockColor.ringTintCorrect.b)
            case .none:
                return
            }

            coord.currentTargetR = Float(rgb.0)
            coord.currentTargetG = Float(rgb.1)
            coord.currentTargetB = Float(rgb.2)

            // Dispatch state transition based on current phase
            coord.dispatchTintEvent(newTarget: tintTarget)
        } else if tintSeq != coord.lastTintSeq {
            coord.lastTintSeq = tintSeq
        }
    }

    // MARK: - Coordinator

    final class Coordinator {
        var renderer: GoldNoiseRenderer?
        var noiseLayer: CALayer?
        var noiseTimer: Timer?
        var lastTintSeq: Int = -1
        var lastIsActive: Bool = true
        var reduceMotion: Bool = false

        // Tint state machine
        var currentPhase: TintPhase = .idle
        var phaseStartTime: CFTimeInterval = 0
        var currentTintStrength: Float = 0
        var phaseStartStrength: Float = 0
        var currentTargetR: Float = 0
        var currentTargetG: Float = 0
        var currentTargetB: Float = 0

        /// Tint animation phases
        enum TintPhase {
            case idle
            case rampUp(target: TintTarget)
            case holding(color: TintTarget)
            case rampDown
            case pulseDip(color: TintTarget)
            case pulseRecover(color: TintTarget)
        }

        deinit {
            noiseTimer?.invalidate()
        }

        /// Start the 15 FPS noise timer
        func startTimer() {
            let timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 15.0, repeats: true) { [weak self] _ in
                guard let self = self,
                      let renderer = self.renderer else { return }

                // Update tint from state machine before rendering
                self.updateTintFromPhase()

                // Apply tint values to renderer
                renderer.tintR = self.currentTargetR
                renderer.tintG = self.currentTargetG
                renderer.tintB = self.currentTargetB
                renderer.tintStrength = self.currentTintStrength

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

        /// Evaluate current phase, interpolate tintStrength, and advance phase if complete.
        func updateTintFromPhase() {
            let now = CACurrentMediaTime()
            let elapsed = now - phaseStartTime

            switch currentPhase {
            case .idle:
                currentTintStrength = 0

            case .rampUp:
                let duration = ChessClockTiming.feedbackRampUp
                let progress = Float(min(1.0, elapsed / duration))
                let peak = ChessClockTiming.feedbackTintPeak
                currentTintStrength = phaseStartStrength + (peak - phaseStartStrength) * progress
                if progress >= 1.0 {
                    currentTintStrength = peak
                    transitionToHolding()
                }

            case .holding(let color):
                let duration = ChessClockTiming.feedbackHold
                currentTintStrength = ChessClockTiming.feedbackTintPeak
                if elapsed >= duration {
                    // Hold complete → ramp down
                    phaseStartTime = now
                    phaseStartStrength = currentTintStrength
                    currentPhase = .rampDown
                    _ = color // suppress unused warning
                }

            case .rampDown:
                let duration = ChessClockTiming.feedbackRampDown
                let progress = Float(min(1.0, elapsed / duration))
                let peak = ChessClockTiming.feedbackTintPeak
                currentTintStrength = peak + (0 - peak) * progress
                if progress >= 1.0 {
                    currentTintStrength = 0
                    currentPhase = .idle
                }

            case .pulseDip(let color):
                let duration = ChessClockTiming.pulseDipDuration
                let progress = Float(min(1.0, elapsed / duration))
                let peak = ChessClockTiming.feedbackTintPeak
                let floor = ChessClockTiming.pulseDipFloor
                currentTintStrength = peak + (floor - peak) * progress
                if progress >= 1.0 {
                    currentTintStrength = floor
                    // Transition to pulse recover
                    phaseStartTime = now
                    phaseStartStrength = floor
                    currentPhase = .pulseRecover(color: color)
                }

            case .pulseRecover(let color):
                let duration = ChessClockTiming.pulseDipDuration
                let progress = Float(min(1.0, elapsed / duration))
                let floor = ChessClockTiming.pulseDipFloor
                let peak = ChessClockTiming.feedbackTintPeak
                currentTintStrength = floor + (peak - floor) * progress
                if progress >= 1.0 {
                    currentTintStrength = peak
                    // Back to holding with timer reset
                    phaseStartTime = now
                    currentPhase = .holding(color: color)
                }
            }
        }

        /// Transition to holding phase for the current target
        private func transitionToHolding() {
            let now = CACurrentMediaTime()
            // Determine color from the current rampUp target
            let color: TintTarget
            switch currentPhase {
            case .rampUp(let target):
                color = target
            default:
                color = .none
            }
            phaseStartTime = now
            currentPhase = .holding(color: color)
        }

        /// Dispatch a tint event based on the current phase and new target
        func dispatchTintEvent(newTarget: TintTarget) {
            let now = CACurrentMediaTime()

            switch currentPhase {
            case .idle:
                // idle + any color → rampUp
                phaseStartStrength = currentTintStrength
                phaseStartTime = now
                currentPhase = .rampUp(target: newTarget)

            case .rampUp(let existing):
                if existing == newTarget {
                    // Same target → no-op
                    return
                }
                // Different target → rampUp from current strength
                phaseStartStrength = currentTintStrength
                phaseStartTime = now
                currentPhase = .rampUp(target: newTarget)

            case .holding(let existing):
                if existing == newTarget {
                    // Same target → pulse dip
                    phaseStartTime = now
                    currentPhase = .pulseDip(color: newTarget)
                } else {
                    // Different target → rampUp from current strength
                    phaseStartStrength = currentTintStrength
                    phaseStartTime = now
                    currentPhase = .rampUp(target: newTarget)
                }

            case .rampDown:
                // rampDown + any color → rampUp from current strength
                phaseStartStrength = currentTintStrength
                phaseStartTime = now
                currentPhase = .rampUp(target: newTarget)

            case .pulseDip(let existing):
                if existing == newTarget {
                    // Same target → no-op
                    return
                }
                // Different target → rampUp from current strength
                phaseStartStrength = currentTintStrength
                phaseStartTime = now
                currentPhase = .rampUp(target: newTarget)

            case .pulseRecover(let existing):
                if existing == newTarget {
                    // Same target → no-op
                    return
                }
                // Different target → rampUp from current strength
                phaseStartStrength = currentTintStrength
                phaseStartTime = now
                currentPhase = .rampUp(target: newTarget)
            }
        }
    }

    // MARK: - Path Helpers

    /// Even-odd ring path: outer rounded rect (2pt inset) minus inner rounded rect (10pt inset)
    private static func ringPath(in bounds: CGRect) -> CGPath {
        let outerInset: CGFloat = 2
        let innerInset: CGFloat = 10
        let outerRadius: CGFloat = ChessClockRadius.outer - outerInset   // 16pt
        let innerRadius: CGFloat = ChessClockRadius.outer - innerInset   // 8pt

        let outerRect = bounds.insetBy(dx: outerInset, dy: outerInset)
        let innerRect = bounds.insetBy(dx: innerInset, dy: innerInset)

        let path = CGMutablePath()
        path.addRoundedRect(in: outerRect, cornerWidth: outerRadius, cornerHeight: outerRadius)
        path.addRoundedRect(in: innerRect, cornerWidth: innerRadius, cornerHeight: innerRadius)
        return path
    }

    /// Thin strip path between two insets — used for specular highlight and outer shadow
    private static func stripPath(in bounds: CGRect, outerInset: CGFloat, innerInset: CGFloat) -> CGPath {
        let outerRadius = ChessClockRadius.outer - outerInset
        let innerRadius = ChessClockRadius.outer - innerInset

        let outerRect = bounds.insetBy(dx: outerInset, dy: outerInset)
        let innerRect = bounds.insetBy(dx: innerInset, dy: innerInset)

        let path = CGMutablePath()
        path.addRoundedRect(in: outerRect, cornerWidth: outerRadius, cornerHeight: outerRadius)
        path.addRoundedRect(in: innerRect, cornerWidth: innerRadius, cornerHeight: innerRadius)
        return path
    }
}
