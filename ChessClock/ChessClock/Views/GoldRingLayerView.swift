import AppKit
import IOSurface
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
///   +- goldContainer: CALayer                -- masked by progressMask (stroked centerline + semicircle tip)
///   |   +- noiseLayer: CALayer               -- Metal noise texture, ring-masked, 5 FPS
///   |   +- specularStrip: CAShapeLayer       -- white 20% inner highlight (static)
///   |   +- shadowStrip: CAShapeLayer         -- black 8% outer shadow (static)
///   +- ticksLayer: CALayer                   -- 4 cardinal ticks (12/3/6/9, static, always on top)
/// ```
struct GoldRingLayerView: NSViewRepresentable {
    let minute: Int
    let second: Int
    let isActive: Bool

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

        // Create renderer and render initial frame (async IOSurface)
        let renderer = GoldNoiseRenderer()
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

        if !reduceMotion && isActive {
            let timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 15.0, repeats: true) { [weak coord] _ in
                guard let coord = coord,
                      let renderer = coord.renderer else { return }
                renderer.renderFrame { [weak coord] surface in
                    DispatchQueue.main.async {
                        guard let coord = coord else { return }
                        CATransaction.begin()
                        CATransaction.setDisableActions(true)
                        coord.noiseLayer?.contents = surface
                        CATransaction.commit()
                    }
                }
            }
            RunLoop.main.add(timer, forMode: .common)
            coord.noiseTimer = timer
        }

        coord.lastMinute = minute
        coord.lastSecond = second
        coord.lastIsActive = isActive

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

        // Timer lifecycle: start/stop based on isActive
        if isActive != coord.lastIsActive {
            coord.lastIsActive = isActive
            if isActive && !coord.reduceMotion {
                // Restart timer
                if coord.noiseTimer == nil {
                    let timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 15.0, repeats: true) { [weak coord] _ in
                        guard let coord = coord,
                              let renderer = coord.renderer else { return }
                        renderer.renderFrame { [weak coord] surface in
                            DispatchQueue.main.async {
                                guard let coord = coord else { return }
                                CATransaction.begin()
                                CATransaction.setDisableActions(true)
                                coord.noiseLayer?.contents = surface
                                CATransaction.commit()
                            }
                        }
                    }
                    RunLoop.main.add(timer, forMode: .common)
                    coord.noiseTimer = timer
                }
            } else if !isActive {
                // Stop timer
                coord.noiseTimer?.invalidate()
                coord.noiseTimer = nil
            }
        }
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
        var lastIsActive: Bool = true
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

    /// Progress mask: stroked centerline path with butt caps (flat at 12 o'clock)
    /// plus a semicircle cap at the leading edge only.
    private static func wedgePath(progress: CGFloat, in bounds: CGRect) -> CGPath {
        guard progress > 0 else { return CGMutablePath() }
        if progress >= 1.0 { return CGPath(rect: bounds, transform: nil) }

        let (centerline, endTangent) = partialCenterlinePath(progress: progress, in: bounds)

        // Butt caps: flat at 12 o'clock (no overflow), flat at leading edge
        let stroked = centerline.copy(
            strokingWithWidth: ChessClockSize.ringStroke,  // 8pt
            lineCap: .butt,
            lineJoin: .round,
            miterLimit: 1
        )

        // Add semicircle cap at leading edge only
        let capR = ChessClockSize.ringStroke / 2  // 4pt
        let endPoint = centerline.currentPoint
        let capStart = endTangent - .pi / 2  // perpendicular: one side of ring
        let capEnd = endTangent + .pi / 2    // perpendicular: other side of ring

        let combined = CGMutablePath()
        combined.addPath(stroked)
        combined.addArc(center: endPoint, radius: capR,
                        startAngle: capStart, endAngle: capEnd,
                        clockwise: false)
        combined.closeSubpath()

        return combined
    }

    /// Builds a CGPath tracing the ring centerline (6pt inset, 12pt corner radius)
    /// clockwise from top-center to the given `progress` (0→1) position.
    /// Returns the path and the tangent angle (radians) at the endpoint.
    private static func partialCenterlinePath(progress: CGFloat, in bounds: CGRect) -> (path: CGMutablePath, endTangent: CGFloat) {
        let inset: CGFloat = 6
        let r: CGFloat = ChessClockRadius.outer - inset  // 12pt
        let rect = bounds.insetBy(dx: inset, dy: inset)

        let left = rect.minX, right = rect.maxX
        let top = rect.minY, bottom = rect.maxY

        let halfTop = rect.width / 2 - r       // ~132pt
        let straightLen = rect.height - 2 * r   // ~264pt
        let fullTop = rect.width - 2 * r        // ~264pt
        let arcLen = CGFloat.pi * r / 2          // ~18.85pt

        let segLengths: [CGFloat] = [
            halfTop, arcLen, straightLen, arcLen,
            fullTop, arcLen, straightLen, arcLen, halfTop
        ]
        let totalPerimeter = segLengths.reduce(0, +)
        let targetDist = progress * totalPerimeter

        let path = CGMutablePath()
        path.move(to: CGPoint(x: rect.midX, y: top))

        var endTangent: CGFloat = 0  // rightward (default for segment 0)
        var remaining = targetDist
        for (i, segLen) in segLengths.enumerated() {
            guard remaining > 1e-6 else { break }
            let consume = min(remaining, segLen)
            let t = segLen > 1e-6 ? consume / segLen : 0

            switch i {
            case 0: // Top right half → going right
                path.addLine(to: CGPoint(x: rect.midX + t * halfTop, y: top))
                endTangent = 0
            case 1: // Top-right corner arc
                let endAngle = -.pi / 2 + t * .pi / 2
                path.addArc(center: CGPoint(x: right - r, y: top + r), radius: r,
                            startAngle: -.pi / 2, endAngle: endAngle,
                            clockwise: false)
                endTangent = endAngle + .pi / 2
            case 2: // Right side → going down
                path.addLine(to: CGPoint(x: right, y: top + r + t * straightLen))
                endTangent = .pi / 2
            case 3: // Bottom-right corner arc
                let endAngle = t * .pi / 2
                path.addArc(center: CGPoint(x: right - r, y: bottom - r), radius: r,
                            startAngle: 0, endAngle: endAngle,
                            clockwise: false)
                endTangent = endAngle + .pi / 2
            case 4: // Bottom → going left
                path.addLine(to: CGPoint(x: right - r - t * fullTop, y: bottom))
                endTangent = .pi
            case 5: // Bottom-left corner arc
                let endAngle = .pi / 2 + t * .pi / 2
                path.addArc(center: CGPoint(x: left + r, y: bottom - r), radius: r,
                            startAngle: .pi / 2, endAngle: endAngle,
                            clockwise: false)
                endTangent = endAngle + .pi / 2
            case 6: // Left side → going up
                path.addLine(to: CGPoint(x: left, y: bottom - r - t * straightLen))
                endTangent = -.pi / 2
            case 7: // Top-left corner arc
                let endAngle = .pi + t * .pi / 2
                path.addArc(center: CGPoint(x: left + r, y: top + r), radius: r,
                            startAngle: .pi, endAngle: endAngle,
                            clockwise: false)
                endTangent = endAngle + .pi / 2
            case 8: // Top left half → going right
                path.addLine(to: CGPoint(x: left + r + t * halfTop, y: top))
                endTangent = 0
            default:
                break
            }

            remaining -= segLen
        }

        return (path, endTangent)
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
        let innerEdge: CGFloat = 10    // ring inner edge
        let innerEnd: CGFloat = 14     // 4pt past ring inner edge (10 + 4), 12pt total
        let tickW: CGFloat = ChessClockSize.tickWidth

        struct TickDef {
            let from: CGPoint
            let to: CGPoint
            let boardFrom: CGPoint  // ring inner edge point (shadow starts here)
        }

        let ticks: [TickDef] = [
            // Top (12 o'clock)
            TickDef(from: CGPoint(x: w / 2, y: outerEdge),
                    to: CGPoint(x: w / 2, y: innerEnd),
                    boardFrom: CGPoint(x: w / 2, y: innerEdge)),
            // Right (3 o'clock)
            TickDef(from: CGPoint(x: w - outerEdge, y: h / 2),
                    to: CGPoint(x: w - innerEnd, y: h / 2),
                    boardFrom: CGPoint(x: w - innerEdge, y: h / 2)),
            // Bottom (6 o'clock)
            TickDef(from: CGPoint(x: w / 2, y: h - outerEdge),
                    to: CGPoint(x: w / 2, y: h - innerEnd),
                    boardFrom: CGPoint(x: w / 2, y: h - innerEdge)),
            // Left (9 o'clock)
            TickDef(from: CGPoint(x: outerEdge, y: h / 2),
                    to: CGPoint(x: innerEnd, y: h / 2),
                    boardFrom: CGPoint(x: innerEdge, y: h / 2)),
        ]

        for tick in ticks {
            let tickPath = CGMutablePath()
            tickPath.move(to: tick.from)
            tickPath.addLine(to: tick.to)

            // Lowest layer: board-surface shadow (from ring inner edge into board)
            let boardPortionPath = CGMutablePath()
            boardPortionPath.move(to: tick.boardFrom)
            boardPortionPath.addLine(to: tick.to)

            let boardShadow = CAShapeLayer()
            boardShadow.path = boardPortionPath
            boardShadow.strokeColor = CGColor(red: 1, green: 1, blue: 1, alpha: 0.01)
            boardShadow.lineWidth = tickW
            boardShadow.lineCap = .butt
            boardShadow.fillColor = nil
            boardShadow.contentsScale = scale
            boardShadow.shadowColor = CGColor(red: 0, green: 0, blue: 0, alpha: 0.30)
            boardShadow.shadowRadius = 2.0
            boardShadow.shadowOpacity = 1.0
            boardShadow.shadowOffset = .zero
            container.addSublayer(boardShadow)

            // Middle layer: brighter stroke (0.85 opacity white)
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

            // Top layer: tapered gradient stroke (0.45 → 0.20) over inner half
            let midPoint = CGPoint(x: (tick.from.x + tick.to.x) / 2,
                                   y: (tick.from.y + tick.to.y) / 2)
            let dimPath = CGMutablePath()
            dimPath.move(to: midPoint)
            dimPath.addLine(to: tick.to)

            let gradLayer = CAGradientLayer()
            gradLayer.type = .axial
            gradLayer.frame = bounds
            gradLayer.colors = [
                CGColor(red: 1, green: 1, blue: 1, alpha: 0.45),
                CGColor(red: 1, green: 1, blue: 1, alpha: 0.20)
            ]
            // Normalized start/end points within bounds
            if midPoint.x == tick.to.x {
                // Vertical tick (top or bottom)
                gradLayer.startPoint = CGPoint(x: 0.5, y: midPoint.y / h)
                gradLayer.endPoint   = CGPoint(x: 0.5, y: tick.to.y / h)
            } else {
                // Horizontal tick (left or right)
                gradLayer.startPoint = CGPoint(x: midPoint.x / w, y: 0.5)
                gradLayer.endPoint   = CGPoint(x: tick.to.x / w, y: 0.5)
            }

            // Mask to the stroke path so only the line pixels receive the gradient
            let maskLayer = CAShapeLayer()
            maskLayer.path = dimPath
            maskLayer.strokeColor = CGColor(red: 1, green: 1, blue: 1, alpha: 1.0)
            maskLayer.lineWidth = tickW
            maskLayer.lineCap = .butt
            maskLayer.fillColor = nil
            gradLayer.mask = maskLayer

            container.addSublayer(gradLayer)
        }

        return container
    }
}
