import SwiftUI

// MARK: - RingShape

/// Traces a rounded-rectangle path starting at top-center going clockwise.
/// Designed to be used with `.trim(from:to:)` for progressive fill.
struct RingShape: Shape {
    func path(in rect: CGRect) -> Path {
        let inset = ChessClockSize.ringInset
        let r: CGFloat = 7
        let insetRect = rect.insetBy(dx: inset, dy: inset)

        var path = Path()

        // Start at top-center
        path.move(to: CGPoint(x: insetRect.midX, y: insetRect.minY))

        // Top edge → top-right corner start
        path.addLine(to: CGPoint(x: insetRect.maxX - r, y: insetRect.minY))

        // Top-right corner: -90° → 0°
        path.addArc(
            center: CGPoint(x: insetRect.maxX - r, y: insetRect.minY + r),
            radius: r,
            startAngle: .degrees(-90),
            endAngle: .degrees(0),
            clockwise: false
        )

        // Right edge → bottom-right corner start
        path.addLine(to: CGPoint(x: insetRect.maxX, y: insetRect.maxY - r))

        // Bottom-right corner: 0° → 90°
        path.addArc(
            center: CGPoint(x: insetRect.maxX - r, y: insetRect.maxY - r),
            radius: r,
            startAngle: .degrees(0),
            endAngle: .degrees(90),
            clockwise: false
        )

        // Bottom edge → bottom-left corner start
        path.addLine(to: CGPoint(x: insetRect.minX + r, y: insetRect.maxY))

        // Bottom-left corner: 90° → 180°
        path.addArc(
            center: CGPoint(x: insetRect.minX + r, y: insetRect.maxY - r),
            radius: r,
            startAngle: .degrees(90),
            endAngle: .degrees(180),
            clockwise: false
        )

        // Left edge → top-left corner start
        path.addLine(to: CGPoint(x: insetRect.minX, y: insetRect.minY + r))

        // Top-left corner: 180° → 270°
        path.addArc(
            center: CGPoint(x: insetRect.minX + r, y: insetRect.minY + r),
            radius: r,
            startAngle: .degrees(180),
            endAngle: .degrees(270),
            clockwise: false
        )

        // Back to top-center (do NOT close — keep open for trim)
        path.addLine(to: CGPoint(x: insetRect.midX, y: insetRect.minY))

        return path
    }
}

// MARK: - MinuteBezelView

struct MinuteBezelView: View {
    let minute: Int

    /// Progress from 0.0 to ~0.983 (59/60)
    private var progress: CGFloat { CGFloat(minute) / 60.0 }

    var body: some View {
        ZStack {
            // Track layer: full ring in gray
            RingShape()
                .stroke(
                    ChessClockColor.ringTrack,
                    style: StrokeStyle(
                        lineWidth: ChessClockSize.ringStroke,
                        lineCap: .round
                    )
                )

            // Fill layer: trimmed ring in gold
            RingShape()
                .trim(from: 0, to: progress)
                .stroke(
                    ChessClockColor.accentGold,
                    style: StrokeStyle(
                        lineWidth: ChessClockSize.ringStroke,
                        lineCap: .round
                    )
                )

            // Cardinal tick marks
            GeometryReader { geometry in
                let w = geometry.size.width
                let h = geometry.size.height
                let tickLen = ChessClockSize.tickLength
                let tickW = ChessClockSize.tickWidth

                // Top tick (12 o'clock) — always gold
                Path { path in
                    path.move(to: CGPoint(x: w / 2, y: 0))
                    path.addLine(to: CGPoint(x: w / 2, y: tickLen))
                }
                .stroke(
                    ChessClockColor.accentGold,
                    style: StrokeStyle(lineWidth: tickW, lineCap: .round)
                )

                // Right tick (3 o'clock) — gold when progress >= 0.25
                Path { path in
                    path.move(to: CGPoint(x: w, y: h / 2))
                    path.addLine(to: CGPoint(x: w - tickLen, y: h / 2))
                }
                .stroke(
                    progress >= 0.25 ? ChessClockColor.accentGold : Color.gray.opacity(0.40),
                    style: StrokeStyle(lineWidth: tickW, lineCap: .round)
                )

                // Bottom tick (6 o'clock) — gold when progress >= 0.50
                Path { path in
                    path.move(to: CGPoint(x: w / 2, y: h))
                    path.addLine(to: CGPoint(x: w / 2, y: h - tickLen))
                }
                .stroke(
                    progress >= 0.50 ? ChessClockColor.accentGold : Color.gray.opacity(0.40),
                    style: StrokeStyle(lineWidth: tickW, lineCap: .round)
                )

                // Left tick (9 o'clock) — gold when progress >= 0.75
                Path { path in
                    path.move(to: CGPoint(x: 0, y: h / 2))
                    path.addLine(to: CGPoint(x: tickLen, y: h / 2))
                }
                .stroke(
                    progress >= 0.75 ? ChessClockColor.accentGold : Color.gray.opacity(0.40),
                    style: StrokeStyle(lineWidth: tickW, lineCap: .round)
                )
            }
        }
        .animation(ChessClockAnimation.ring, value: minute)
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
                    MinuteBezelView(minute: min)
                        .frame(width: 300, height: 300)
                }
            }
        }
    }
    .padding(32)
}
