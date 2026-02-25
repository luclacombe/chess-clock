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
///   +- goldContainer: CALayer                -- masked by progressMask (pie wedge)
///   |   +- noiseLayer: CALayer               -- Metal noise texture, ring-masked, 5 FPS
///   |   +- specularStrip: CAShapeLayer       -- white 20% inner highlight (static)
///   |   +- shadowStrip: CAShapeLayer         -- black 8% outer shadow (static)
///   +- ticksLayer: CALayer                   -- 4 cardinal ticks (static, always on top)
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

    /// Pie-wedge path from center, starting at -90deg (12 o'clock), sweeping clockwise,
    /// with a semicircle cap at the leading edge for a smooth rounded tip.
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

        // Add semicircle cap at the leading edge
        let capRadius: CGFloat = ChessClockSize.ringStroke / 2  // 4pt
        let (capCenter, tangent) = ringCenterlinePoint(at: progress, in: bounds)

        // Semicircle perpendicular to ring tangent, on the leading (forward) side
        // tangent points in the direction of travel; the semicircle bulges forward
        let capStart = tangent - .pi / 2  // perpendicular: inner edge of ring
        let capEnd = tangent + .pi / 2    // perpendicular: outer edge of ring

        let capPath = CGMutablePath()
        capPath.move(to: CGPoint(x: capCenter.x + capRadius * cos(capStart),
                                 y: capCenter.y + capRadius * sin(capStart)))
        // Arc from inner edge to outer edge, going forward (clockwise in y-down = false)
        capPath.addArc(center: capCenter, radius: capRadius,
                       startAngle: capStart, endAngle: capEnd,
                       clockwise: false)
        capPath.closeSubpath()

        // Combine wedge + cap using union via even-odd addition
        let combined = CGMutablePath()
        combined.addPath(path)
        combined.addPath(capPath)
        return combined
    }

    // MARK: - Rounded Rect Perimeter Helpers

    /// Computes the intersection point of a ray from the center of `rect` at angle `angleDeg`
    /// (0° = straight up, clockwise) with a rounded rectangle defined by `rect` and `cornerRadius`.
    private static func roundedRectPoint(in rect: CGRect, cornerRadius r: CGFloat, angleDeg: CGFloat) -> CGPoint {
        let cx = rect.midX
        let cy = rect.midY

        // Convert angle: 0° = up, clockwise → standard math angle (0° = right, CCW)
        let radians = (angleDeg - 90) * .pi / 180.0
        let dx = cos(radians)
        let dy = sin(radians)

        // Rect edges
        let left   = rect.minX
        let right  = rect.maxX
        let top    = rect.minY
        let bottom = rect.maxY

        // Corner circle centers
        let tlCenter = CGPoint(x: left + r,  y: top + r)
        let trCenter = CGPoint(x: right - r, y: top + r)
        let brCenter = CGPoint(x: right - r, y: bottom - r)
        let blCenter = CGPoint(x: left + r,  y: bottom - r)

        // Ray from (cx, cy) in direction (dx, dy): P = (cx + t*dx, cy + t*dy)
        // Find intersection with each straight edge and each corner arc, take the closest valid one.

        var bestT: CGFloat = .greatestFiniteMagnitude
        var bestPoint = CGPoint(x: cx, y: cy)

        // Helper: intersect ray with axis-aligned line segment
        func intersectHorizontal(y: CGFloat, xMin: CGFloat, xMax: CGFloat) {
            guard abs(dy) > 1e-12 else { return }
            let t = (y - cy) / dy
            guard t > 1e-6 else { return }
            let x = cx + t * dx
            if x >= xMin - 1e-6 && x <= xMax + 1e-6 && t < bestT {
                bestT = t
                bestPoint = CGPoint(x: x, y: y)
            }
        }

        func intersectVertical(x: CGFloat, yMin: CGFloat, yMax: CGFloat) {
            guard abs(dx) > 1e-12 else { return }
            let t = (x - cx) / dx
            guard t > 1e-6 else { return }
            let y = cy + t * dy
            if y >= yMin - 1e-6 && y <= yMax + 1e-6 && t < bestT {
                bestT = t
                bestPoint = CGPoint(x: x, y: y)
            }
        }

        // Straight edges (excluding corner arcs)
        intersectHorizontal(y: top,    xMin: left + r, xMax: right - r)  // Top
        intersectHorizontal(y: bottom, xMin: left + r, xMax: right - r)  // Bottom
        intersectVertical(x: left,  yMin: top + r, yMax: bottom - r)     // Left
        intersectVertical(x: right, yMin: top + r, yMax: bottom - r)     // Right

        // Corner arcs: intersect ray with circle of radius r centered at each corner center
        for center in [tlCenter, trCenter, brCenter, blCenter] {
            // Solve |P(t) - center|^2 = r^2
            let ox = cx - center.x
            let oy = cy - center.y
            let a = dx * dx + dy * dy  // always 1 for unit direction, but keep general
            let b = 2 * (ox * dx + oy * dy)
            let c = ox * ox + oy * oy - r * r
            let disc = b * b - 4 * a * c
            guard disc >= 0 else { continue }
            let sqrtDisc = sqrt(disc)
            for t in [(-b - sqrtDisc) / (2 * a), (-b + sqrtDisc) / (2 * a)] {
                guard t > 1e-6 && t < bestT else { continue }
                let px = cx + t * dx
                let py = cy + t * dy
                // Verify point is in the corner's quadrant
                let inCorner: Bool
                if center.x == tlCenter.x && center.y == tlCenter.y {
                    inCorner = px <= center.x + 1e-6 && py <= center.y + 1e-6
                } else if center.x == trCenter.x && center.y == trCenter.y {
                    inCorner = px >= center.x - 1e-6 && py <= center.y + 1e-6
                } else if center.x == brCenter.x && center.y == brCenter.y {
                    inCorner = px >= center.x - 1e-6 && py >= center.y - 1e-6
                } else {
                    inCorner = px <= center.x + 1e-6 && py >= center.y - 1e-6
                }
                if inCorner {
                    bestT = t
                    bestPoint = CGPoint(x: px, y: py)
                }
            }
        }

        return bestPoint
    }

    // MARK: - Ring Centerline Perimeter Parameterization

    /// Returns the (point, tangentAngle) on the ring centerline (6pt inset, 12pt corner radius)
    /// at a given `progress` (0→1), starting at top-center and going clockwise.
    /// `tangentAngle` is in radians, 0 = rightward, π/2 = downward (screen coords, y-down).
    private static func ringCenterlinePoint(at progress: CGFloat, in bounds: CGRect) -> (point: CGPoint, tangentAngle: CGFloat) {
        let inset: CGFloat = 6
        let r: CGFloat = ChessClockRadius.outer - inset  // 12pt
        let rect = bounds.insetBy(dx: inset, dy: inset)  // 288×288, origin (6,6)

        let left   = rect.minX
        let right  = rect.maxX
        let top    = rect.minY
        let bottom = rect.maxY

        // Perimeter segments clockwise from top-center (150, 6):
        // 1. Top right half straight: (midX, top) → (right - r, top)  length = midX - (left + r) = 144 - 12 = 132
        // 2. Top-right corner arc: center (right - r, top + r), -90° → 0°, length = πr/2
        // 3. Right straight: (right, top + r) → (right, bottom - r), length = 288 - 2*12 = 264
        // 4. Bottom-right corner arc: center (right - r, bottom - r), 0° → 90°, length = πr/2
        // 5. Bottom straight: (right - r, bottom) → (left + r, bottom), length = 264
        // 6. Bottom-left corner arc: center (left + r, bottom - r), 90° → 180°, length = πr/2
        // 7. Left straight: (left, bottom - r) → (left, top + r), length = 264
        // 8. Top-left corner arc: center (left + r, top + r), 180° → 270°, length = πr/2
        // 9. Top left half straight: (left + r, top) → (midX, top), length = 132

        let halfTop = rect.width / 2 - r          // 132
        let straightLen = rect.height - 2 * r     // 264
        let fullTop = rect.width - 2 * r          // 264
        let arcLen = .pi * r / 2                   // πr/2 ≈ 18.85

        let segments: [CGFloat] = [
            halfTop,      // 0: top right half
            arcLen,       // 1: top-right corner
            straightLen,  // 2: right straight
            arcLen,       // 3: bottom-right corner
            fullTop,      // 4: bottom straight
            arcLen,       // 5: bottom-left corner
            straightLen,  // 6: left straight
            arcLen,       // 7: top-left corner
            halfTop       // 8: top left half
        ]

        let totalPerimeter = segments.reduce(0, +)
        let dist = progress * totalPerimeter

        // Walk segments to find which one we're in
        var remaining = dist
        for (i, segLen) in segments.enumerated() {
            if remaining <= segLen + 1e-6 {
                let t = segLen > 0 ? min(remaining / segLen, 1.0) : 0
                switch i {
                case 0: // Top right half straight → going right
                    let x = rect.midX + t * halfTop
                    return (CGPoint(x: x, y: top), 0) // tangent: rightward
                case 1: // Top-right corner arc
                    let cx = right - r
                    let cy = top + r
                    let angle = -.pi / 2 + t * (.pi / 2) // -90° → 0°
                    let px = cx + r * cos(angle)
                    let py = cy + r * sin(angle)
                    let tangent = angle + .pi / 2  // perpendicular to radius, clockwise
                    return (CGPoint(x: px, y: py), tangent)
                case 2: // Right straight → going down
                    let y = top + r + t * straightLen
                    return (CGPoint(x: right, y: y), .pi / 2)
                case 3: // Bottom-right corner arc
                    let cx = right - r
                    let cy = bottom - r
                    let angle = 0 + t * (.pi / 2)  // 0° → 90°
                    let px = cx + r * cos(angle)
                    let py = cy + r * sin(angle)
                    let tangent = angle + .pi / 2
                    return (CGPoint(x: px, y: py), tangent)
                case 4: // Bottom straight → going left
                    let x = right - r - t * fullTop
                    return (CGPoint(x: x, y: bottom), .pi)
                case 5: // Bottom-left corner arc
                    let cx = left + r
                    let cy = bottom - r
                    let angle = .pi / 2 + t * (.pi / 2)  // 90° → 180°
                    let px = cx + r * cos(angle)
                    let py = cy + r * sin(angle)
                    let tangent = angle + .pi / 2
                    return (CGPoint(x: px, y: py), tangent)
                case 6: // Left straight → going up
                    let y = bottom - r - t * straightLen
                    return (CGPoint(x: left, y: y), -.pi / 2)
                case 7: // Top-left corner arc
                    let cx = left + r
                    let cy = top + r
                    let angle = .pi + t * (.pi / 2)  // 180° → 270°
                    let px = cx + r * cos(angle)
                    let py = cy + r * sin(angle)
                    let tangent = angle + .pi / 2
                    return (CGPoint(x: px, y: py), tangent)
                case 8: // Top left half straight → going right
                    let x = left + r + t * halfTop
                    return (CGPoint(x: x, y: top), 0)
                default:
                    break
                }
            }
            remaining -= segLen
        }

        // Fallback: top-center
        return (CGPoint(x: rect.midX, y: top), 0)
    }

    // MARK: - Tick Marks

    /// Creates the 4 cardinal tick marks + 8 minor tick marks as a sublayer group
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

        // MARK: Minor Tick Marks (8 intermediate ticks at 30° intervals)
        let minorAngles: [CGFloat] = [30, 60, 120, 150, 210, 240, 300, 330]
        let outerInset: CGFloat = ChessClockSize.ringOuterEdge  // 2pt
        let midInset: CGFloat = outerInset + ChessClockSize.minorTickLength  // 6pt
        let outerCornerR: CGFloat = ChessClockRadius.outer - outerInset   // 16pt
        let midCornerR: CGFloat = ChessClockRadius.outer - midInset       // 12pt

        let outerRect = bounds.insetBy(dx: outerInset, dy: outerInset)
        let midRect = bounds.insetBy(dx: midInset, dy: midInset)

        for angle in minorAngles {
            let from = roundedRectPoint(in: outerRect, cornerRadius: outerCornerR, angleDeg: angle)
            let to = roundedRectPoint(in: midRect, cornerRadius: midCornerR, angleDeg: angle)

            let path = CGMutablePath()
            path.move(to: from)
            path.addLine(to: to)

            let layer = CAShapeLayer()
            layer.path = path
            layer.strokeColor = CGColor(red: 1, green: 1, blue: 1, alpha: 0.40)
            layer.lineWidth = ChessClockSize.minorTickWidth
            layer.lineCap = .butt
            layer.fillColor = nil
            layer.contentsScale = scale
            layer.shadowColor = CGColor(red: 0, green: 0, blue: 0, alpha: 0.25)
            layer.shadowRadius = 1.0
            layer.shadowOpacity = 1.0
            layer.shadowOffset = .zero
            container.addSublayer(layer)
        }

        return container
    }
}
