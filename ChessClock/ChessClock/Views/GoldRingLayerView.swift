import AppKit
import QuartzCore
import SwiftUI

// MARK: - Flipped NSView (y-down to match SwiftUI coordinate system)

/// NSView subclass with `isFlipped = true` so the layer coordinate system
/// has origin at top-left (y-down), matching SwiftUI and all the path math.
private final class FlippedLayerView: NSView {
    override var isFlipped: Bool { true }
}

// MARK: - GoldRingLayerView

/// CALayer-based minute ring. Runs all animations in the Core Animation
/// render server for <0.5% CPU.
///
/// Layer hierarchy:
/// ```
/// FlippedLayerView (isFlipped = true)
///   +- trackLayer: CAShapeLayer              -- gray 15% ring (even-odd, static)
///   +- goldContainer: CALayer                -- masked by progressMask (pie wedge)
///   |   +- gradientLayer: CAGradientLayer    -- .conic, 17 gold stops, ring-masked, locations drift
///   |   +- specularStrip: CAShapeLayer       -- white 20% inner highlight (static)
///   |   +- shadowStrip: CAShapeLayer         -- black 8% outer shadow (static)
///   +- ticksLayer: CALayer                   -- 4 cardinal ticks (static, always on top)
/// ```
struct GoldRingLayerView: NSViewRepresentable {
    let minute: Int
    let second: Int

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeNSView(context: Context) -> NSView {
        let view = FlippedLayerView(frame: NSRect(x: 0, y: 0, width: 300, height: 300))
        view.wantsLayer = true
        view.layer?.masksToBounds = false

        let scale = NSScreen.main?.backingScaleFactor ?? 2.0
        let bounds = CGRect(x: 0, y: 0, width: 300, height: 300)
        let coord = context.coordinator

        // MARK: - Track Layer (static gray ring)
        let trackLayer = CAShapeLayer()
        trackLayer.path = Self.ringPath(in: bounds)
        trackLayer.fillColor = CGColor(gray: 0.5, alpha: 0.15)
        trackLayer.fillRule = .evenOdd
        trackLayer.contentsScale = scale
        trackLayer.frame = bounds
        view.layer!.addSublayer(trackLayer)

        // MARK: - Gold Container (gradient + specular + shadow, masked by progress)
        let goldContainer = CALayer()
        goldContainer.frame = bounds
        goldContainer.contentsScale = scale
        view.layer!.addSublayer(goldContainer)
        coord.goldContainer = goldContainer

        // Conic gradient filling full 300x300 bounds, clipped to ring by its own mask
        let gradientLayer = CAGradientLayer()
        gradientLayer.type = .conic
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.5)
        gradientLayer.colors = Self.gradientColors
        gradientLayer.locations = Self.baseLocations.map { NSNumber(value: $0) }
        gradientLayer.frame = bounds
        gradientLayer.contentsScale = scale

        // Ring-shaped mask applied directly to gradientLayer (clips conic fill to 8pt band)
        let gradientRingMask = CAShapeLayer()
        gradientRingMask.path = Self.ringPath(in: bounds)
        gradientRingMask.fillRule = .evenOdd
        gradientRingMask.fillColor = CGColor(gray: 1, alpha: 1)
        gradientRingMask.frame = bounds
        gradientRingMask.contentsScale = scale
        gradientLayer.mask = gradientRingMask

        goldContainer.addSublayer(gradientLayer)
        coord.gradientLayer = gradientLayer

        // Specular highlight (inner edge strip: 9pt to 10pt inset)
        let specularStrip = CAShapeLayer()
        specularStrip.path = Self.stripPath(in: bounds, outerInset: 9, innerInset: 10)
        specularStrip.fillColor = CGColor(red: 1, green: 1, blue: 1, alpha: 0.20)
        specularStrip.fillRule = .evenOdd
        specularStrip.frame = bounds
        specularStrip.contentsScale = scale
        goldContainer.addSublayer(specularStrip)

        // Shadow strip (outer edge strip: 2pt to 3pt inset)
        let shadowStrip = CAShapeLayer()
        shadowStrip.path = Self.stripPath(in: bounds, outerInset: 2, innerInset: 3)
        shadowStrip.fillColor = CGColor(red: 0, green: 0, blue: 0, alpha: 0.08)
        shadowStrip.fillRule = .evenOdd
        shadowStrip.frame = bounds
        shadowStrip.contentsScale = scale
        goldContainer.addSublayer(shadowStrip)

        // Progress mask on gold container (pie wedge)
        let progress = Self.computeProgress(minute: minute, second: second)
        let progressMask = CAShapeLayer()
        progressMask.path = Self.wedgePath(progress: progress, in: bounds)
        progressMask.fillColor = CGColor(gray: 1, alpha: 1)
        progressMask.frame = bounds
        progressMask.contentsScale = scale
        goldContainer.mask = progressMask
        coord.progressMask = progressMask

        // MARK: - Tick Marks (always on top, not masked by progress)
        let ticksLayer = Self.makeTicksLayer(in: bounds, scale: scale)
        view.layer!.addSublayer(ticksLayer)

        // MARK: - Color Drift Animation (S4F-2)
        let reduceMotion = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
        coord.reduceMotion = reduceMotion

        if !reduceMotion {
            let drift = CABasicAnimation(keyPath: "locations")
            drift.fromValue = Self.baseLocations.map { NSNumber(value: $0) }
            drift.toValue = Self.driftedLocations.map { NSNumber(value: $0) }
            drift.duration = 12.0
            drift.autoreverses = true
            drift.repeatCount = .infinity
            drift.isRemovedOnCompletion = false
            gradientLayer.add(drift, forKey: "colorDrift")
        }

        coord.lastMinute = minute
        coord.lastSecond = second

        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        let coord = context.coordinator
        let bounds = CGRect(x: 0, y: 0, width: 300, height: 300)
        let progress = Self.computeProgress(minute: minute, second: second)

        let isHourRollback = (minute == 0 && second == 0)
        let newWedge = Self.wedgePath(progress: progress, in: bounds)

        if isHourRollback {
            // At hour rollback, snap directly without animation
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            coord.progressMask?.path = newWedge
            CATransaction.commit()
        } else if minute != coord.lastMinute || second != coord.lastSecond {
            // 0.3s ease for progress advance
            CATransaction.begin()
            CATransaction.setAnimationDuration(0.3)
            CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: .easeInEaseOut))
            coord.progressMask?.path = newWedge
            CATransaction.commit()
        }

        coord.lastMinute = minute
        coord.lastSecond = second
    }

    // MARK: - Coordinator

    final class Coordinator {
        var goldContainer: CALayer?
        var gradientLayer: CAGradientLayer?
        var progressMask: CAShapeLayer?
        var lastMinute: Int = -1
        var lastSecond: Int = -1
        var reduceMotion: Bool = false
    }

    // MARK: - Color Constants (CGColor)

    private static let accentGoldLightCG = CGColor(red: 212/255, green: 185/255, blue: 78/255, alpha: 1)
    private static let accentGoldCoolCG  = CGColor(red: 155/255, green: 125/255, blue: 40/255, alpha: 1)
    private static let accentGoldWarmCG  = CGColor(red: 220/255, green: 190/255, blue: 90/255, alpha: 1)
    private static let accentGoldCG      = CGColor(red: 191/255, green: 155/255, blue: 48/255, alpha: 1)
    private static let accentGoldDeepCG  = CGColor(red: 138/255, green: 111/255, blue: 31/255, alpha: 1)

    private static let gradientColors: [CGColor] = [
        accentGoldLightCG, // 0.00
        accentGoldCoolCG,  // 0.06
        accentGoldWarmCG,  // 0.13
        accentGoldCG,      // 0.19
        accentGoldDeepCG,  // 0.25
        accentGoldWarmCG,  // 0.31
        accentGoldCoolCG,  // 0.38
        accentGoldLightCG, // 0.44
        accentGoldDeepCG,  // 0.50
        accentGoldWarmCG,  // 0.56
        accentGoldCG,      // 0.63
        accentGoldCoolCG,  // 0.69
        accentGoldLightCG, // 0.75
        accentGoldDeepCG,  // 0.81
        accentGoldWarmCG,  // 0.88
        accentGoldCG,      // 0.94
        accentGoldLightCG, // 1.00
    ]

    private static let baseLocations: [Double] = [
        0.00, 0.06, 0.13, 0.19, 0.25, 0.31, 0.38, 0.44,
        0.50, 0.56, 0.63, 0.69, 0.75, 0.81, 0.88, 0.94, 1.00
    ]

    /// Drifted locations for color drift animation -- each interior stop shifted +-0.03 to 0.05
    private static let driftedLocations: [Double] = [
        0.00, 0.10, 0.10, 0.22, 0.22, 0.35, 0.34, 0.48,
        0.47, 0.60, 0.59, 0.73, 0.72, 0.84, 0.84, 0.97, 1.00
    ]

    // MARK: - Path Helpers

    /// Progress fraction from minute + second
    private static func computeProgress(minute: Int, second: Int) -> CGFloat {
        CGFloat(minute * 60 + second) / 3600.0
    }

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

    /// Thin strip path between two insets -- used for specular highlight and outer shadow
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

    /// Pie-wedge path from center, starting at -90deg (12 o'clock), sweeping clockwise
    private static func wedgePath(progress: CGFloat, in bounds: CGRect) -> CGPath {
        guard progress > 0 else {
            return CGMutablePath()
        }
        if progress >= 1.0 {
            return CGPath(rect: bounds, transform: nil)
        }

        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let radius = sqrt(bounds.width * bounds.width + bounds.height * bounds.height) / 2

        let startAngle: CGFloat = -.pi / 2
        let endAngle: CGFloat = startAngle + CGFloat(progress) * 2 * .pi

        let path = CGMutablePath()
        path.move(to: center)
        path.addLine(to: CGPoint(
            x: center.x + radius * cos(startAngle),
            y: center.y + radius * sin(startAngle)
        ))
        // CGPath arc: clockwise in default (y-down) coordinate = clockwise visually in flipped
        // Core Animation uses y-up, so clockwise: false = visual clockwise
        path.addArc(center: center, radius: radius,
                     startAngle: startAngle, endAngle: endAngle,
                     clockwise: false)
        path.closeSubpath()
        return path
    }

    // MARK: - Tick Marks

    /// Creates the 4 cardinal tick marks as a sublayer group
    private static func makeTicksLayer(in bounds: CGRect, scale: CGFloat) -> CALayer {
        let container = CALayer()
        container.frame = bounds
        container.contentsScale = scale

        let w = bounds.width
        let h = bounds.height
        let outerEdge: CGFloat = 2     // tick outer end
        let innerEnd: CGFloat = 13     // 3pt past ring inner edge (10 + 3)
        let tickW: CGFloat = 2.5

        struct TickDef {
            let from: CGPoint
            let to: CGPoint
        }

        let ticks: [TickDef] = [
            // Top (12 o'clock)
            TickDef(from: CGPoint(x: w / 2, y: outerEdge),
                    to: CGPoint(x: w / 2, y: innerEnd)),
            // Right (3 o'clock)
            TickDef(from: CGPoint(x: w - outerEdge, y: h / 2),
                    to: CGPoint(x: w - innerEnd, y: h / 2)),
            // Bottom (6 o'clock)
            TickDef(from: CGPoint(x: w / 2, y: h - outerEdge),
                    to: CGPoint(x: w / 2, y: h - innerEnd)),
            // Left (9 o'clock)
            TickDef(from: CGPoint(x: outerEdge, y: h / 2),
                    to: CGPoint(x: innerEnd, y: h / 2)),
        ]

        for tick in ticks {
            let tickPath = CGMutablePath()
            tickPath.move(to: tick.from)
            tickPath.addLine(to: tick.to)

            // Bottom layer: brighter stroke (0.85 opacity white)
            let brightStroke = CAShapeLayer()
            brightStroke.path = tickPath
            brightStroke.strokeColor = CGColor(red: 1, green: 1, blue: 1, alpha: 0.85)
            brightStroke.lineWidth = tickW
            brightStroke.lineCap = .butt
            brightStroke.fillColor = nil
            brightStroke.contentsScale = scale
            brightStroke.shadowColor = CGColor(red: 0, green: 0, blue: 0, alpha: 0.40)
            brightStroke.shadowRadius = 1.5
            brightStroke.shadowOpacity = 1.0
            brightStroke.shadowOffset = .zero
            container.addSublayer(brightStroke)

            // Top layer: dimmer stroke (0.45 opacity white) -- overlaps inner half for gradient effect
            let midPoint = CGPoint(x: (tick.from.x + tick.to.x) / 2,
                                   y: (tick.from.y + tick.to.y) / 2)
            let dimPath = CGMutablePath()
            dimPath.move(to: midPoint)
            dimPath.addLine(to: tick.to)

            let dimStroke = CAShapeLayer()
            dimStroke.path = dimPath
            dimStroke.strokeColor = CGColor(red: 1, green: 1, blue: 1, alpha: 0.45)
            dimStroke.lineWidth = tickW
            dimStroke.lineCap = .butt
            dimStroke.fillColor = nil
            dimStroke.contentsScale = scale
            container.addSublayer(dimStroke)
        }

        return container
    }
}
