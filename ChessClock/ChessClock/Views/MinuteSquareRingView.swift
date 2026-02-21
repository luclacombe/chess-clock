import SwiftUI

// MARK: - Shape

struct MinuteRingShape: Shape {
    var progress: Double  // 0.0 to 1.0

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let perimeter = 2 * (rect.width + rect.height)
        let distance = progress * perimeter

        if distance <= 0 { return path }

        path.move(to: CGPoint(x: rect.minX, y: rect.minY))

        var remaining = distance

        // Segment 1: top-left → top-right
        if remaining > 0 {
            let d = min(remaining, rect.width)
            path.addLine(to: CGPoint(x: rect.minX + d, y: rect.minY))
            remaining -= d
        }
        // Segment 2: top-right → bottom-right
        if remaining > 0 {
            let d = min(remaining, rect.height)
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + d))
            remaining -= d
        }
        // Segment 3: bottom-right → bottom-left
        if remaining > 0 {
            let d = min(remaining, rect.width)
            path.addLine(to: CGPoint(x: rect.maxX - d, y: rect.maxY))
            remaining -= d
        }
        // Segment 4: bottom-left → top-left
        if remaining > 0 {
            let d = min(remaining, rect.height)
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - d))
        }

        return path
    }
}

// MARK: - View

struct MinuteSquareRingView: View {
    let minute: Int       // 0–59
    let boardSize: CGFloat

    var body: some View {
        let progress = Double(minute) / 60.0
        MinuteRingShape(progress: progress)
            .stroke(
                Color(red: 1.0, green: 0.76, blue: 0.0),
                style: StrokeStyle(lineWidth: 5, lineCap: .square, lineJoin: .miter)
            )
            .frame(width: boardSize, height: boardSize)
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
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        .frame(width: 200, height: 200)
                    MinuteSquareRingView(minute: min, boardSize: 200)
                }
            }
        }
    }
    .padding(32)
}
