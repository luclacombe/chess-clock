import SwiftUI

// MARK: - FilledRingTrack

/// Draws the filled area between two concentric rounded rects.
/// Use with `FillStyle(eoFill: true)` to punch the inner rect out.
struct FilledRingTrack: Shape {
    func path(in rect: CGRect) -> Path {
        let outerInset = ChessClockSize.ringOuterEdge          // 2pt
        let innerInset = ChessClockSize.ringInnerEdge          // 10pt
        let outerRadius = ChessClockRadius.outer - outerInset  // 18 - 2 = 16pt
        let innerRadius = ChessClockRadius.outer - innerInset  // 18 - 10 = 8pt

        var path = Path()

        // Outer rounded rect (clockwise winding)
        let outerRect = rect.insetBy(dx: outerInset, dy: outerInset)
        path.addRoundedRect(in: outerRect, cornerSize: CGSize(width: outerRadius, height: outerRadius))

        // Inner rounded rect (counter-clockwise winding — even-odd rule punches it out)
        let innerRect = rect.insetBy(dx: innerInset, dy: innerInset)
        path.addRoundedRect(in: innerRect, cornerSize: CGSize(width: innerRadius, height: innerRadius))

        return path
    }
}

// MARK: - ProgressWedge

/// Pie-wedge mask that grows clockwise from 12 o'clock.
/// Use as a `.mask(_:)` over the filled ring gradient layer.
struct ProgressWedge: Shape, Animatable {
    var progress: CGFloat

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    func path(in rect: CGRect) -> Path {
        // Guard: full frame visible when progress >= 1.0
        guard progress < 1.0 else {
            return Path(rect)
        }
        guard progress > 0 else {
            return Path()
        }

        let center = CGPoint(x: rect.midX, y: rect.midY)
        // Use the diagonal half-length so the wedge always covers the ring corners
        let radius = sqrt(rect.width * rect.width + rect.height * rect.height) / 2

        // 12 o'clock = -90°; sweep clockwise.
        // In SwiftUI's coordinate space (y-down), clockwise = increasing angle,
        // so we use clockwise: false (the arc parameter is inverted vs UIKit).
        let startAngle = Angle.degrees(-90)
        let endAngle   = Angle.degrees(-90 + Double(progress) * 360)

        var path = Path()
        path.move(to: center)
        path.addArc(
            center: center,
            radius: radius,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: false
        )
        path.closeSubpath()

        return path
    }
}

// MARK: - MinuteBezelView

struct MinuteBezelView: View {
    let minute: Int
    let second: Int

    /// Continuous progress 0.0 … ~0.9997 — advances every second.
    private var progress: CGFloat { CGFloat(minute * 60 + second) / 3600.0 }

    @State private var shimmerPhase = false

    var body: some View {
        ZStack {
            // Track layer: full ring in muted gray
            FilledRingTrack()
                .fill(ChessClockColor.ringTrack, style: FillStyle(eoFill: true))

            // Fill layer: gold gradient masked by progress wedge + shimmer
            FilledRingTrack()
                .fill(ChessClockColor.ringGradient, style: FillStyle(eoFill: true))
                .mask(ProgressWedge(progress: progress))
                .opacity(shimmerPhase ? 1.0 : ChessClockSize.shimmerMinOpacity)

            // Cardinal tick marks on top
            tickMarks
        }
        .animation(.linear(duration: 1.0), value: second)
        .onAppear {
            withAnimation(ChessClockAnimation.shimmer) {
                shimmerPhase = true
            }
        }
    }

    // MARK: - Tick Marks

    private var tickMarks: some View {
        GeometryReader { geometry in
            let w = geometry.size.width
            let h = geometry.size.height
            let outerEdge = ChessClockSize.ringOuterEdge  // 2pt — tick outer end
            let innerEdge = ChessClockSize.ringInnerEdge  // 10pt — tick inner end
            let tickW = ChessClockSize.tickWidth

            // Top tick (12 o'clock) — vertical, from outerEdge to innerEdge
            tickMark(
                from: CGPoint(x: w / 2, y: outerEdge),
                to:   CGPoint(x: w / 2, y: innerEdge),
                width: tickW
            )

            // Right tick (3 o'clock) — horizontal, from outerEdge to innerEdge
            tickMark(
                from: CGPoint(x: w - outerEdge, y: h / 2),
                to:   CGPoint(x: w - innerEdge, y: h / 2),
                width: tickW
            )

            // Bottom tick (6 o'clock) — vertical, from outerEdge to innerEdge
            tickMark(
                from: CGPoint(x: w / 2, y: h - outerEdge),
                to:   CGPoint(x: w / 2, y: h - innerEdge),
                width: tickW
            )

            // Left tick (9 o'clock) — horizontal, from outerEdge to innerEdge
            tickMark(
                from: CGPoint(x: outerEdge, y: h / 2),
                to:   CGPoint(x: innerEdge, y: h / 2),
                width: tickW
            )
        }
    }

    /// Draws a tick mark: dark halo beneath a white stroke, both with `.butt` lineCap.
    private func tickMark(from: CGPoint, to: CGPoint, width: CGFloat) -> some View {
        ZStack {
            // Dark halo (drawn first, slightly wider)
            Path { path in
                path.move(to: from)
                path.addLine(to: to)
            }
            .stroke(
                Color.black.opacity(0.4),
                style: StrokeStyle(lineWidth: width + 1, lineCap: .butt)
            )

            // White foreground
            Path { path in
                path.move(to: from)
                path.addLine(to: to)
            }
            .stroke(
                Color.white,
                style: StrokeStyle(lineWidth: width, lineCap: .butt)
            )
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 24) {
        ForEach([0, 15, 30, 45, 59], id: \.self) { min in
            VStack(spacing: 4) {
                Text("minute = \(min)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                ZStack {
                    Rectangle()
                        .fill(Color.black.opacity(0.8))
                        .frame(width: 300, height: 300)
                    MinuteBezelView(minute: min, second: 0)
                        .frame(width: 300, height: 300)
                }
            }
        }
    }
    .padding(32)
}
