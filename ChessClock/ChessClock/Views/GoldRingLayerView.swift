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

/// CALayer-based minute ring. Uses Metal compute shader to render animated
/// simplex noise mapped to gold colors at 5 FPS.
///
/// Layer hierarchy:
/// ```
/// FlippedLayerView (isFlipped = true)
///   +- trackLayer: CAShapeLayer              -- gray 15% ring (even-odd, static)
///   +- goldContainer: CALayer                -- masked by progressMask (pie wedge)
///   |   +- noiseLayer: CALayer               -- Metal noise texture, ring-masked, 5 FPS
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

        // MARK: - Gold Container (noise + specular + shadow, masked by progress)
        let goldContainer = CALayer()
        goldContainer.frame = bounds
        goldContainer.contentsScale = scale
        view.layer!.addSublayer(goldContainer)
        coord.goldContainer = goldContainer

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

        // Create renderer and render initial frame
        let renderer = GoldNoiseRenderer()
        coord.renderer = renderer
        if let image = renderer?.renderFrame(size: bounds.size) {
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            noiseLayer.contents = image
            CATransaction.commit()
        }

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

        // MARK: - Noise Animation Timer
        let reduceMotion = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
        coord.reduceMotion = reduceMotion

        if !reduceMotion {
            let timer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [weak coord] _ in
                guard let coord = coord,
                      let renderer = coord.renderer,
                      let noiseLayer = coord.noiseLayer else { return }
                if let image = renderer.renderFrame(size: bounds.size) {
                    CATransaction.begin()
                    CATransaction.setDisableActions(true)
                    noiseLayer.contents = image
                    CATransaction.commit()
                }
            }
            RunLoop.main.add(timer, forMode: .common)
            coord.noiseTimer = timer
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
        var noiseLayer: CALayer?
        var renderer: GoldNoiseRenderer?
        var noiseTimer: Timer?
        var progressMask: CAShapeLayer?
        var lastMinute: Int = -1
        var lastSecond: Int = -1
        var reduceMotion: Bool = false

        deinit {
            noiseTimer?.invalidate()
        }
    }

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
