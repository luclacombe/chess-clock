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
    var hourChange: Bool = false
    var hideTickMarks: Bool = false
    var forceFullRing: Bool = false

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

        // Progress mask on gold container (pie wedge, or full rect when forceFullRing)
        let progress = Self.computeProgress(minute: minute, second: second)
        let progressMask = CAShapeLayer()
        if forceFullRing {
            progressMask.path = CGPath(rect: bounds, transform: nil)
            coord.lastForceFullRing = true
        } else {
            progressMask.path = Self.wedgePath(progress: progress, in: bounds)
        }
        progressMask.fillColor = CGColor(gray: 1, alpha: 1)
        progressMask.frame = bounds
        progressMask.contentsScale = scale
        goldContainer.mask = progressMask
        coord.progressMask = progressMask

        // MARK: - Tick Marks (always on top, not masked by progress)
        let ticksLayer = Self.makeTicksLayer(in: bounds, scale: scale)
        view.layer!.addSublayer(ticksLayer)
        coord.ticksLayer = ticksLayer
        coord.tickGroups = ticksLayer.sublayers ?? []
        coord.lastHideTickMarks = hideTickMarks

        // Initial state: hidden + offset during onboarding A-1/A-2
        if hideTickMarks {
            let offsets = Self.tickSlideOffsets
            for (i, group) in coord.tickGroups.enumerated() {
                group.opacity = 0
                group.transform = CATransform3DMakeTranslation(offsets[i].x, offsets[i].y, 0)
            }
        }

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

        // Force full ring → fill animation (onboarding A-3)
        if forceFullRing && !coord.lastForceFullRing {
            // Snap to full (e.g. debugReplay reset)
            coord.lastForceFullRing = true
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            coord.progressMask?.path = CGPath(rect: bounds, transform: nil)
            CATransaction.commit()
        } else if !forceFullRing && coord.lastForceFullRing && !coord.fillAnimating {
            coord.lastForceFullRing = false
            coord.fillAnimating = true
            let targetProgress = progress

            // Phase 1: Fade out gold noise (0.3s)
            CATransaction.begin()
            CATransaction.setAnimationDuration(0.3)
            CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: .easeInEaseOut))
            coord.goldContainer?.opacity = 0
            CATransaction.commit()

            // Phase 2: After fade, snap mask to empty + restore opacity, then fill
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak coord] in
                guard let coord = coord else { return }

                CATransaction.begin()
                CATransaction.setDisableActions(true)
                coord.progressMask?.path = CGMutablePath()
                coord.goldContainer?.opacity = 1
                CATransaction.commit()

                // Phase 3: Frame-by-frame clockwise fill from 0 → target (fixed velocity)
                let fullRingDuration: Double = 3.0  // seconds for a complete ring fill
                let fillDuration = Double(targetProgress) * fullRingDuration
                let fillStart = CACurrentMediaTime()

                let timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { [weak coord] timer in
                    guard let coord = coord else { timer.invalidate(); return }
                    let elapsed = CACurrentMediaTime() - fillStart
                    let t = min(elapsed / fillDuration, 1.0)
                    let currentProgress = t * targetProgress

                    CATransaction.begin()
                    CATransaction.setDisableActions(true)
                    coord.progressMask?.path = Self.wedgePath(progress: currentProgress, in: bounds)
                    CATransaction.commit()

                    if t >= 1.0 {
                        timer.invalidate()
                        coord.fillTimer = nil
                        coord.fillAnimating = false
                    }
                }
                RunLoop.main.add(timer, forMode: .common)
                coord.fillTimer = timer
            }
        }

        // Hour-change animation: sweep to full (0.3s) → drain clockwise (3s)
        if hourChange && !coord.lastHourChange && !coord.hourAnimating {
            coord.hourAnimating = true

            // Phase 1: sweep to full (0.3s)
            let fullWedge = CGPath(rect: bounds, transform: nil)
            CATransaction.begin()
            CATransaction.setAnimationDuration(0.3)
            CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: .easeInEaseOut))
            coord.progressMask?.path = fullWedge
            CATransaction.commit()

            // Phase 2: drain clockwise over 2.5s using frame-by-frame even-odd masking.
            // The drain wedge grows clockwise from 12 o'clock (using existing wedgePath),
            // subtracted from the full rect via even-odd fill rule → remaining fill shrinks.
            // Cubic ease-in: starts slow, accelerates noticeably toward the end.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak coord] in
                guard let coord = coord else { return }
                coord.progressMask?.fillRule = .evenOdd

                let drainDuration: Double = 2.5
                let drainStart = CACurrentMediaTime()

                let timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { [weak coord] timer in
                    guard let coord = coord else { timer.invalidate(); return }
                    let elapsed = CACurrentMediaTime() - drainStart
                    let t = min(elapsed / drainDuration, 1.0)
                    // Cubic ease-in: slow start, accelerating finish
                    let eased = t * t * t

                    let composite = CGMutablePath()
                    composite.addRect(bounds)
                    if eased > 0.001 {
                        composite.addPath(Self.wedgePath(progress: CGFloat(eased), in: bounds))
                    }

                    CATransaction.begin()
                    CATransaction.setDisableActions(true)
                    coord.progressMask?.path = composite
                    CATransaction.commit()

                    if t >= 1.0 {
                        timer.invalidate()
                        coord.drainTimer = nil
                        // Reset to normal non-zero winding fill rule, empty mask
                        coord.progressMask?.fillRule = .nonZero
                        let emptyPath = CGMutablePath()
                        CATransaction.begin()
                        CATransaction.setDisableActions(true)
                        coord.progressMask?.path = emptyPath
                        CATransaction.commit()
                        coord.hourAnimating = false
                    }
                }
                RunLoop.main.add(timer, forMode: .common)
                coord.drainTimer = timer
            }

            coord.lastHourChange = hourChange
            coord.lastMinute = minute
            coord.lastSecond = second
        } else if !coord.hourAnimating && !coord.fillAnimating && !forceFullRing {
            // Normal progress updates (skip during hour-change, fill, or forced-full)
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

        coord.lastHourChange = hourChange

        // Tick mark visibility (onboarding: hidden during A-1/A-2, slide in on A-3)
        if hideTickMarks != coord.lastHideTickMarks {
            coord.lastHideTickMarks = hideTickMarks
            let offsets = Self.tickSlideOffsets
            CATransaction.begin()
            CATransaction.setAnimationDuration(hideTickMarks ? 0.0 : 0.5)
            CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: .easeOut))
            for (i, group) in coord.tickGroups.enumerated() {
                if hideTickMarks {
                    group.opacity = 0
                    group.transform = CATransform3DMakeTranslation(offsets[i].x, offsets[i].y, 0)
                } else {
                    group.opacity = 1
                    group.transform = CATransform3DIdentity
                }
            }
            CATransaction.commit()
        }

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
        var ticksLayer: CALayer?
        var tickGroups: [CALayer] = []
        var renderer: GoldNoiseRenderer?
        var noiseTimer: Timer?
        var drainTimer: Timer?
        var progressMask: CAShapeLayer?
        var lastMinute: Int = -1
        var lastSecond: Int = -1
        var lastIsActive: Bool = true
        var lastHourChange: Bool = false
        var lastHideTickMarks: Bool = false
        var lastForceFullRing: Bool = false
        var hourAnimating: Bool = false
        var fillAnimating: Bool = false
        var fillTimer: Timer?
        var reduceMotion: Bool = false

        deinit {
            noiseTimer?.invalidate()
            drainTimer?.invalidate()
            fillTimer?.invalidate()
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

    /// Progress mask built as a single closed ring-segment path:
    /// outer edge forward → semicircle cap → inner edge backward → close at 12 o'clock.
    /// No separate subpaths, no seam gaps, works on all edges and corners.
    private static func wedgePath(progress: CGFloat, in bounds: CGRect) -> CGPath {
        guard progress > 0 else { return CGMutablePath() }
        if progress >= 1.0 { return CGPath(rect: bounds, transform: nil) }

        // Ring edge rects and corner radii
        let outerInset: CGFloat = 2
        let innerInset: CGFloat = 10
        let clInset: CGFloat = 6
        let outerR = ChessClockRadius.outer - outerInset  // 16
        let innerR = ChessClockRadius.outer - innerInset   // 8
        let clR = ChessClockRadius.outer - clInset          // 12
        let capR = ChessClockSize.ringStroke / 2             // 4
        let outerRect = bounds.insetBy(dx: outerInset, dy: outerInset)
        let innerRect = bounds.insetBy(dx: innerInset, dy: innerInset)
        let clRect = bounds.insetBy(dx: clInset, dy: clInset)

        // Map progress to segment index + fraction using centerline perimeter
        let (segIdx, segT) = progressToSegment(progress: progress, rect: clRect, r: clR)

        let path = CGMutablePath()

        // 1. Start at outer edge, 12 o'clock
        path.move(to: CGPoint(x: outerRect.midX, y: outerRect.minY))

        // 2. Trace outer edge clockwise to (segIdx, segT)
        addEdgeForward(to: path, rect: outerRect, r: outerR, endSeg: segIdx, endT: segT)

        // 3. Semicircle cap from outer to inner endpoint (bulges forward)
        let capCenter = pointOnEdge(rect: clRect, r: clR, seg: segIdx, t: segT)
        let tangent = tangentAngle(seg: segIdx, t: segT)
        path.addArc(center: capCenter, radius: capR,
                    startAngle: tangent - .pi / 2,
                    endAngle: tangent + .pi / 2,
                    clockwise: false)

        // 4. Trace inner edge counterclockwise back to 12 o'clock
        addEdgeReverse(to: path, rect: innerRect, r: innerR, fromSeg: segIdx, fromT: segT)

        // 5. Close: gentle leftward curve from inner 12 o'clock to outer 12 o'clock
        //    (subtle butt rounding — ~1pt bulge, stays within half tick width)
        let buttTop = CGPoint(x: outerRect.midX, y: outerRect.minY)
        let buttMidY = (outerRect.minY + innerRect.minY) / 2
        path.addQuadCurve(to: buttTop,
                          control: CGPoint(x: outerRect.midX - 1.0, y: buttMidY))

        return path
    }

    // MARK: - Ring Segment Helpers

    /// 9 perimeter segments clockwise from top-center:
    /// 0: top-right half, 1: TR corner arc, 2: right side, 3: BR corner arc,
    /// 4: bottom, 5: BL corner arc, 6: left side, 7: TL corner arc, 8: top-left half

    /// Maps progress (0→1) to a segment index and fraction using centerline arc lengths.
    private static func progressToSegment(progress: CGFloat, rect: CGRect, r: CGFloat) -> (seg: Int, t: CGFloat) {
        let halfTop = rect.width / 2 - r
        let straight = rect.height - 2 * r
        let fullTop = rect.width - 2 * r
        let arc = CGFloat.pi * r / 2
        let lengths: [CGFloat] = [halfTop, arc, straight, arc, fullTop, arc, straight, arc, halfTop]
        let total = lengths.reduce(0, +)
        let target = progress * total

        var remaining = target
        for (i, len) in lengths.enumerated() {
            if remaining <= len + 1e-6 {
                return (i, len > 1e-6 ? min(remaining / len, 1.0) : 0)
            }
            remaining -= len
        }
        return (8, 1.0)
    }

    /// Point on a rounded rect edge at (segment, t).
    private static func pointOnEdge(rect: CGRect, r: CGFloat, seg: Int, t: CGFloat) -> CGPoint {
        let left = rect.minX, right = rect.maxX, top = rect.minY, bottom = rect.maxY
        let halfTop = rect.width / 2 - r
        let straight = rect.height - 2 * r
        let fullTop = rect.width - 2 * r

        switch seg {
        case 0: return CGPoint(x: rect.midX + t * halfTop, y: top)
        case 1:
            let a = -.pi / 2 + t * .pi / 2
            return CGPoint(x: right - r + r * cos(a), y: top + r + r * sin(a))
        case 2: return CGPoint(x: right, y: top + r + t * straight)
        case 3:
            let a = t * .pi / 2
            return CGPoint(x: right - r + r * cos(a), y: bottom - r + r * sin(a))
        case 4: return CGPoint(x: right - r - t * fullTop, y: bottom)
        case 5:
            let a = .pi / 2 + t * .pi / 2
            return CGPoint(x: left + r + r * cos(a), y: bottom - r + r * sin(a))
        case 6: return CGPoint(x: left, y: bottom - r - t * straight)
        case 7:
            let a = CGFloat.pi + t * .pi / 2
            return CGPoint(x: left + r + r * cos(a), y: top + r + r * sin(a))
        case 8: return CGPoint(x: left + r + t * halfTop, y: top)
        default: return CGPoint(x: rect.midX, y: top)
        }
    }

    /// Tangent angle (radians) at a segment position. Same for all concentric edges.
    private static func tangentAngle(seg: Int, t: CGFloat) -> CGFloat {
        switch seg {
        case 0, 8: return 0                          // rightward
        case 1:    return t * .pi / 2                 // 0 → π/2
        case 2:    return .pi / 2                     // downward
        case 3:    return .pi / 2 + t * .pi / 2      // π/2 → π
        case 4:    return .pi                         // leftward
        case 5:    return .pi + t * .pi / 2           // π → 3π/2
        case 6:    return -.pi / 2                    // upward
        case 7:    return .pi + .pi / 2 + t * .pi / 2 // 3π/2 → 2π
        default:   return 0
        }
    }

    /// Traces a rounded rect edge clockwise from 12 o'clock to (endSeg, endT).
    private static func addEdgeForward(to path: CGMutablePath, rect: CGRect, r: CGFloat,
                                       endSeg: Int, endT: CGFloat) {
        let left = rect.minX, right = rect.maxX, top = rect.minY, bottom = rect.maxY
        let halfTop = rect.width / 2 - r
        let straight = rect.height - 2 * r
        let fullTop = rect.width - 2 * r

        for seg in 0...endSeg {
            let t = (seg == endSeg) ? endT : 1.0
            guard t > 1e-8 else { continue }

            switch seg {
            case 0: path.addLine(to: CGPoint(x: rect.midX + t * halfTop, y: top))
            case 1: path.addArc(center: CGPoint(x: right - r, y: top + r), radius: r,
                                startAngle: -.pi / 2, endAngle: -.pi / 2 + t * .pi / 2, clockwise: false)
            case 2: path.addLine(to: CGPoint(x: right, y: top + r + t * straight))
            case 3: path.addArc(center: CGPoint(x: right - r, y: bottom - r), radius: r,
                                startAngle: 0, endAngle: t * .pi / 2, clockwise: false)
            case 4: path.addLine(to: CGPoint(x: right - r - t * fullTop, y: bottom))
            case 5: path.addArc(center: CGPoint(x: left + r, y: bottom - r), radius: r,
                                startAngle: .pi / 2, endAngle: .pi / 2 + t * .pi / 2, clockwise: false)
            case 6: path.addLine(to: CGPoint(x: left, y: bottom - r - t * straight))
            case 7: path.addArc(center: CGPoint(x: left + r, y: top + r), radius: r,
                                startAngle: .pi, endAngle: .pi + t * .pi / 2, clockwise: false)
            case 8: path.addLine(to: CGPoint(x: left + r + t * halfTop, y: top))
            default: break
            }
        }
    }

    /// Traces a rounded rect edge counterclockwise from (fromSeg, fromT) back to 12 o'clock.
    private static func addEdgeReverse(to path: CGMutablePath, rect: CGRect, r: CGFloat,
                                       fromSeg: Int, fromT: CGFloat) {
        let left = rect.minX, right = rect.maxX, top = rect.minY, bottom = rect.maxY

        for seg in stride(from: fromSeg, through: 0, by: -1) {
            let t = (seg == fromSeg) ? fromT : 1.0
            guard t > 1e-8 else { continue }

            // Each case traces from position (seg, t) back to position (seg, 0)
            switch seg {
            case 0: path.addLine(to: CGPoint(x: rect.midX, y: top))
            case 1: path.addArc(center: CGPoint(x: right - r, y: top + r), radius: r,
                                startAngle: -.pi / 2 + t * .pi / 2, endAngle: -.pi / 2, clockwise: true)
            case 2: path.addLine(to: CGPoint(x: right, y: top + r))
            case 3: path.addArc(center: CGPoint(x: right - r, y: bottom - r), radius: r,
                                startAngle: t * .pi / 2, endAngle: 0, clockwise: true)
            case 4: path.addLine(to: CGPoint(x: right - r, y: bottom))
            case 5: path.addArc(center: CGPoint(x: left + r, y: bottom - r), radius: r,
                                startAngle: .pi / 2 + t * .pi / 2, endAngle: .pi / 2, clockwise: true)
            case 6: path.addLine(to: CGPoint(x: left, y: bottom - r))
            case 7: path.addArc(center: CGPoint(x: left + r, y: top + r), radius: r,
                                startAngle: .pi + t * .pi / 2, endAngle: .pi, clockwise: true)
            case 8: path.addLine(to: CGPoint(x: left + r, y: top))
            default: break
            }
        }
    }

    // MARK: - Tick Marks

    /// Slide offsets for tick reveal animation: top↑, right→, bottom↓, left←
    private static let tickSlideOffsets: [CGPoint] = [
        CGPoint(x: 0, y: -8),
        CGPoint(x: 8, y: 0),
        CGPoint(x: 0, y: 8),
        CGPoint(x: -8, y: 0),
    ]

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
            // Per-tick container for directional slide animation
            let tickGroup = CALayer()
            tickGroup.frame = bounds
            tickGroup.contentsScale = scale

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
            tickGroup.addSublayer(boardShadow)

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
            tickGroup.addSublayer(brightStroke)

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

            tickGroup.addSublayer(gradLayer)
            container.addSublayer(tickGroup)
        }

        return container
    }
}
