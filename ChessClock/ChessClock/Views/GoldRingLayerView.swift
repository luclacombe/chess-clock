import AppKit
import QuartzCore
import SwiftUI

// MARK: - GoldRingLayerView

/// CALayer-based minute ring replacing the SwiftUI MinuteBezelView.
/// Runs all animations in the Core Animation render server for <0.5% CPU.
struct GoldRingLayerView: NSViewRepresentable {
    let minute: Int
    let second: Int

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeNSView(context: Context) -> NSView {
        let view = NSView(frame: NSRect(x: 0, y: 0, width: 300, height: 300))
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
        coord.trackLayer = trackLayer

        // MARK: - Gold Container (gradient + specular + shadow, masked by progress)
        let goldContainer = CALayer()
        goldContainer.frame = bounds
        goldContainer.contentsScale = scale
        view.layer!.addSublayer(goldContainer)
        coord.goldContainer = goldContainer

        // Conic gradient
        let gradientLayer = CAGradientLayer()
        gradientLayer.type = .conic
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.5)
        gradientLayer.colors = Self.gradientColors
        gradientLayer.locations = Self.baseLocations.map { NSNumber(value: $0) }
        gradientLayer.frame = bounds
        gradientLayer.contentsScale = scale

        // Mask gradient to ring shape
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
        let specularLayer = CAShapeLayer()
        specularLayer.path = Self.stripPath(in: bounds, outerInset: 9, innerInset: 10)
        specularLayer.fillColor = CGColor(red: 1, green: 1, blue: 1, alpha: 0.20)
        specularLayer.fillRule = .evenOdd
        specularLayer.frame = bounds
        specularLayer.contentsScale = scale
        goldContainer.addSublayer(specularLayer)
        coord.specularLayer = specularLayer

        // Shadow strip (outer edge strip: 2pt to 3pt inset)
        let shadowStripLayer = CAShapeLayer()
        shadowStripLayer.path = Self.stripPath(in: bounds, outerInset: 2, innerInset: 3)
        shadowStripLayer.fillColor = CGColor(red: 0, green: 0, blue: 0, alpha: 0.08)
        shadowStripLayer.fillRule = .evenOdd
        shadowStripLayer.frame = bounds
        shadowStripLayer.contentsScale = scale
        goldContainer.addSublayer(shadowStripLayer)
        coord.shadowStripLayer = shadowStripLayer

        // Progress mask on gold container
        let progress = Self.computeProgress(minute: minute, second: second)
        let progressMask = CAShapeLayer()
        progressMask.path = Self.wedgePath(progress: progress, in: bounds)
        progressMask.fillColor = CGColor(gray: 1, alpha: 1)
        progressMask.frame = bounds
        progressMask.contentsScale = scale
        goldContainer.mask = progressMask
        coord.progressMask = progressMask

        // MARK: - Glow Tip Container (also masked by progress)
        let glowContainer = CALayer()
        glowContainer.frame = bounds
        glowContainer.contentsScale = scale
        view.layer!.addSublayer(glowContainer)
        coord.glowContainer = glowContainer

        // Glow tip progress mask (separate copy)
        let glowProgressMask = CAShapeLayer()
        glowProgressMask.path = Self.wedgePath(progress: progress, in: bounds)
        glowProgressMask.fillColor = CGColor(gray: 1, alpha: 1)
        glowProgressMask.frame = bounds
        glowProgressMask.contentsScale = scale
        glowContainer.mask = glowProgressMask
        coord.glowProgressMask = glowProgressMask

        // Glow tip dot
        let glowTipLayer = CALayer()
        glowTipLayer.frame = CGRect(x: 0, y: 0, width: 16, height: 16)
        glowTipLayer.backgroundColor = Self.accentGoldLightCG
        glowTipLayer.cornerRadius = 8
        glowTipLayer.shadowColor = Self.accentGoldLightCG
        glowTipLayer.shadowRadius = 10
        glowTipLayer.shadowOpacity = 0.8
        glowTipLayer.shadowOffset = .zero
        glowTipLayer.contentsScale = scale
        let tipPos = Self.pointAlongRingPath(progress: progress, bounds: bounds)
        glowTipLayer.position = tipPos
        glowContainer.addSublayer(glowTipLayer)
        coord.glowTipLayer = glowTipLayer

        // Tip breathing animation
        let breathe = CABasicAnimation(keyPath: "shadowRadius")
        breathe.fromValue = 6
        breathe.toValue = 12
        breathe.duration = 2.0
        breathe.autoreverses = true
        breathe.repeatCount = .infinity
        breathe.isRemovedOnCompletion = false
        glowTipLayer.add(breathe, forKey: "breathe")

        // MARK: - Tick Marks (always on top, not masked by progress)
        let ticksLayer = Self.makeTicksLayer(in: bounds, scale: scale)
        view.layer!.addSublayer(ticksLayer)
        coord.ticksLayer = ticksLayer

        // MARK: - S4R-2: Continuous animations (added once, never re-added)
        // Gradient rotation: 120s full turn
        let rotation = CABasicAnimation(keyPath: "transform.rotation.z")
        rotation.fromValue = 0
        rotation.toValue = 2 * Double.pi
        rotation.duration = 120.0
        rotation.repeatCount = .infinity
        rotation.isRemovedOnCompletion = false
        gradientLayer.add(rotation, forKey: "rotation")

        // Shimmer: shift gradient stop locations back and forth
        let shimmer = CABasicAnimation(keyPath: "locations")
        shimmer.fromValue = Self.baseLocations.map { NSNumber(value: $0) }
        shimmer.toValue = Self.shimmeredLocations.map { NSNumber(value: $0) }
        shimmer.duration = 5.0
        shimmer.autoreverses = true
        shimmer.repeatCount = .infinity
        shimmer.isRemovedOnCompletion = false
        gradientLayer.add(shimmer, forKey: "shimmer")

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
            coord.glowProgressMask?.path = newWedge
            CATransaction.commit()
        } else if minute != coord.lastMinute || second != coord.lastSecond {
            // Spring animation for progress advance
            let spring = CASpringAnimation(keyPath: "path")
            spring.mass = 0.5
            spring.stiffness = 300
            spring.damping = 15
            spring.fromValue = coord.progressMask?.path
            spring.toValue = newWedge
            spring.fillMode = .forwards
            spring.isRemovedOnCompletion = false
            coord.progressMask?.add(spring, forKey: "progressSpring")
            coord.progressMask?.path = newWedge

            // Same spring for the glow container mask
            let glowSpring = CASpringAnimation(keyPath: "path")
            glowSpring.mass = 0.5
            glowSpring.stiffness = 300
            glowSpring.damping = 15
            glowSpring.fromValue = coord.glowProgressMask?.path
            glowSpring.toValue = newWedge
            glowSpring.fillMode = .forwards
            glowSpring.isRemovedOnCompletion = false
            coord.glowProgressMask?.add(glowSpring, forKey: "progressSpring")
            coord.glowProgressMask?.path = newWedge
        }

        // Update glow tip position
        let tipPos = Self.pointAlongRingPath(progress: progress, bounds: bounds)
        CATransaction.begin()
        CATransaction.setAnimationDuration(0.3)
        coord.glowTipLayer?.position = tipPos
        CATransaction.commit()

        coord.lastMinute = minute
        coord.lastSecond = second
    }

    // MARK: - Coordinator

    final class Coordinator {
        var trackLayer: CAShapeLayer?
        var goldContainer: CALayer?
        var gradientLayer: CAGradientLayer?
        var specularLayer: CAShapeLayer?
        var shadowStripLayer: CAShapeLayer?
        var progressMask: CAShapeLayer?
        var glowContainer: CALayer?
        var glowProgressMask: CAShapeLayer?
        var glowTipLayer: CALayer?
        var ticksLayer: CALayer?
        var lastMinute: Int = -1
        var lastSecond: Int = -1
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

    /// Shifted locations for shimmer animation — each stop shifted +-0.03 to 0.05
    private static let shimmeredLocations: [Double] = [
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

    // MARK: - Ring Perimeter Point

    /// Analytically walks the rounded-rect ring perimeter (centerline at 6pt inset, 12pt corner radius).
    /// progress = 0 is top-center (12 o'clock), increases clockwise.
    static func pointAlongRingPath(progress: CGFloat, bounds: CGRect) -> CGPoint {
        let inset: CGFloat = 6
        let r: CGFloat = 12

        let left   = bounds.minX + inset
        let right  = bounds.maxX - inset
        let top    = bounds.minY + inset
        let bottom = bounds.maxY - inset
        let midX   = bounds.midX

        // Segment lengths (starting from top-center, clockwise):
        // 1. Top-right straight: midX to (right - r)
        let topRightLen = (right - r) - midX
        // 2. Top-right arc: quarter circle radius r
        let arcLen = .pi / 2 * r
        // 3. Right straight: (top + r) to (bottom - r)
        let rightLen = (bottom - r) - (top + r)
        // 4. Bottom-right arc
        // 5. Bottom straight: (right - r) to (left + r)
        let bottomLen = (right - r) - (left + r)
        // 6. Bottom-left arc
        // 7. Left straight: (bottom - r) to (top + r)
        let leftLen = (bottom - r) - (top + r)
        // 8. Top-left arc
        // 9. Top-left straight: (left + r) to midX
        let topLeftLen = midX - (left + r)

        let totalLen = topRightLen + arcLen + rightLen + arcLen + bottomLen + arcLen + leftLen + arcLen + topLeftLen
        var d = (Double(progress) * totalLen).truncatingRemainder(dividingBy: totalLen)
        if d < 0 { d += totalLen }

        // Segment 1: top-right straight
        if d <= topRightLen {
            return CGPoint(x: midX + d, y: top)
        }
        d -= topRightLen

        // Segment 2: top-right arc (center: right - r, top + r)
        if d <= arcLen {
            let angle = -(.pi / 2) + d / r  // from -90deg toward 0deg
            return CGPoint(x: (right - r) + r * cos(angle),
                           y: (top + r) + r * sin(angle))
        }
        d -= arcLen

        // Segment 3: right straight (downward)
        if d <= rightLen {
            return CGPoint(x: right, y: (top + r) + d)
        }
        d -= rightLen

        // Segment 4: bottom-right arc (center: right - r, bottom - r)
        if d <= arcLen {
            let angle = 0 + d / r  // from 0deg toward 90deg
            return CGPoint(x: (right - r) + r * cos(angle),
                           y: (bottom - r) + r * sin(angle))
        }
        d -= arcLen

        // Segment 5: bottom straight (leftward)
        if d <= bottomLen {
            return CGPoint(x: (right - r) - d, y: bottom)
        }
        d -= bottomLen

        // Segment 6: bottom-left arc (center: left + r, bottom - r)
        if d <= arcLen {
            let angle = .pi / 2 + d / r  // from 90deg toward 180deg
            return CGPoint(x: (left + r) + r * cos(angle),
                           y: (bottom - r) + r * sin(angle))
        }
        d -= arcLen

        // Segment 7: left straight (upward)
        if d <= leftLen {
            return CGPoint(x: left, y: (bottom - r) - d)
        }
        d -= leftLen

        // Segment 8: top-left arc (center: left + r, top + r)
        if d <= arcLen {
            let angle = .pi + d / r  // from 180deg toward 270deg
            return CGPoint(x: (left + r) + r * cos(angle),
                           y: (top + r) + r * sin(angle))
        }
        d -= arcLen

        // Segment 9: top-left straight (rightward, back to start)
        return CGPoint(x: (left + r) + d, y: top)
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

            // Top layer: dimmer stroke (0.45 opacity white) — overlaps inner half for gradient effect
            // Compute midpoint for the dim overlay
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
