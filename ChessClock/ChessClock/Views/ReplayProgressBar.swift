import SwiftUI

struct ReplayProgressBar: View {
    let posIndex: Int
    let totalMoves: Int
    let puzzleStartPosIndex: Int
    let zone: ReplayZone
    let onSeek: (Int) -> Void

    @State private var isHovered: Bool = false
    @State private var hoverX: CGFloat = 0

    // MARK: - Snap-zone seek logic

    static func targetIndex(
        clickFraction: CGFloat,
        totalMoves: Int,
        puzzleStartPosIndex: Int
    ) -> Int {
        // (a) Snap to move 0 when clicking in the left 1/5
        if clickFraction < 0.10 { return 0 }

        // (b) Snap to puzzle start when clicking near the boundary
        if abs(clickFraction - contextVisualEnd) < 0.03 { return puzzleStartPosIndex }

        // (c) Reverse the visual 4/5 + 1/5 mapping
        let psi = CGFloat(puzzleStartPosIndex)
        let total = CGFloat(max(totalMoves, 1))
        let rawIndex: Int
        if clickFraction <= contextVisualEnd {
            // Context region: visual 0…0.8 → logical 0…puzzleStart
            rawIndex = Int(round((clickFraction / contextVisualEnd) * psi))
        } else {
            // Puzzle region: visual 0.8…1.0 → logical puzzleStart…totalMoves
            let puzzleProgress = (clickFraction - puzzleVisualStart) / (1.0 - puzzleVisualStart)
            rawIndex = Int(round(psi + puzzleProgress * (total - psi)))
        }

        // (d) Clamped result
        return min(max(rawIndex, 0), totalMoves)
    }

    // MARK: - Visual layout constants

    /// Context zone takes the left 4/5, puzzle zone the right 1/5.
    private static let contextVisualEnd: CGFloat = 7.0 / 10.0
    private static let puzzleVisualStart: CGFloat = 7.0 / 10.0

    // MARK: - Derived values

    /// Maps a logical position index to a visual bar fraction using the 4/5 + 1/5 split.
    private func visualFraction(for index: Int) -> CGFloat {
        let psi = CGFloat(puzzleStartPosIndex)
        let total = CGFloat(max(totalMoves, 1))
        let idx = CGFloat(index)

        if idx <= psi {
            // Context region: 0…puzzleStart maps to 0…0.8
            return (idx / max(psi, 1)) * Self.contextVisualEnd
        } else {
            // Puzzle region: puzzleStart…totalMoves maps to 0.8…1.0
            let puzzleProgress = (idx - psi) / (total - psi)
            return Self.puzzleVisualStart + puzzleProgress * (1.0 - Self.puzzleVisualStart)
        }
    }

    private var fillFraction: CGFloat {
        visualFraction(for: posIndex)
    }

    private var puzzleFraction: CGFloat {
        Self.contextVisualEnd
    }

    private var barHeight: CGFloat {
        isHovered
            ? ChessClockSize.progressBarThickHoverHeight
            : ChessClockSize.progressBarThickHeight
    }

    // MARK: - Body

    var body: some View {
        GeometryReader { geo in
            let barWidth = geo.size.width

            ZStack(alignment: .leading) {
                // 1. Track background
                Rectangle()
                    .fill(Color.white.opacity(0.10))

                // 2. Inner shadow — recessed depth
                Rectangle()
                    .fill(Color.black.opacity(0.3))
                    .blur(radius: 2)
                    .offset(y: 1)

                // 3. Zone segments — context + puzzle (gold zone starts 12pt early to cover fill fade)
                ZStack(alignment: .leading) {
                    // Gray base — full width
                    Rectangle()
                        .fill(Color.gray.opacity(0.25))

                    // Gold zone — starts 12pt before the visual boundary
                    HStack(spacing: 0) {
                        LinearGradient(
                            colors: [
                                Color(red: 0.80, green: 0.62, blue: 0.11).opacity(0),
                                Color(red: 0.80, green: 0.62, blue: 0.11).opacity(0.45)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(width: 12)

                        Rectangle()
                            .fill(Color(red: 0.80, green: 0.62, blue: 0.11).opacity(0.45))
                    }
                    .offset(x: max(0, barWidth * Self.contextVisualEnd - 12))
                }

                // 4. Fill (soft right edge except at checkmate where bar is fully filled)
                if zone == .checkmate {
                    Rectangle()
                        .fill(zone.color)
                        .animation(ChessClockAnimation.micro, value: posIndex)
                } else {
                    Rectangle()
                        .fill(zone.color)
                        .frame(width: fillFraction * barWidth)
                        .mask(
                            HStack(spacing: 0) {
                                Rectangle()
                                LinearGradient(colors: [.white, .clear], startPoint: .leading, endPoint: .trailing)
                                    .frame(width: 10)
                            }
                        )
                        .animation(ChessClockAnimation.micro, value: posIndex)
                }

                // 5. Halftone cursor (hover only)
                if isHovered {
                    HalftoneCanvasView(
                        hoverX: hoverX,
                        barWidth: barWidth,
                        barHeight: barHeight
                    )
                    .blur(radius: 0.5)
                    .opacity(0.5)
                    .blendMode(.screen)
                }

                // 6. Glass overlay
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .opacity(0.15)

                // 7. Capsule border (as overlay on the ZStack)
            }
            .frame(height: barHeight)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
            )
            .frame(maxHeight: .infinity)
            .animation(ChessClockAnimation.micro, value: isHovered)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        isHovered = true
                        hoverX = max(0, min(barWidth, value.location.x))
                        let fraction = max(0, min(1, value.location.x / barWidth))
                        let target = Self.targetIndex(
                            clickFraction: fraction,
                            totalMoves: totalMoves,
                            puzzleStartPosIndex: puzzleStartPosIndex
                        )
                        onSeek(target)
                    }
                    .onEnded { _ in
                        isHovered = false
                    }
            )
            .onContinuousHover { phase in
                switch phase {
                case .active(let loc):
                    isHovered = true
                    hoverX = loc.x
                case .ended:
                    isHovered = false
                }
            }
        }
        .frame(height: ChessClockSize.progressBarThickHoverHeight)
    }
}

// MARK: - Halftone Canvas

/// Draws a circular dot pattern that brightens content around the hover position.
private struct HalftoneCanvasView: View {
    let hoverX: CGFloat
    let barWidth: CGFloat
    let barHeight: CGFloat

    var body: some View {
        Canvas { context, size in
            let spacing = ChessClockSize.halftoneDotSpacing
            let radius = ChessClockSize.halftoneRadius
            let maxDotRadius: CGFloat = 1.5
            let centerY = size.height / 2

            // Grid bounds (only draw within the bar)
            let minCol = max(0, Int((hoverX - radius) / spacing))
            let maxCol = min(Int(size.width / spacing), Int((hoverX + radius) / spacing))
            let minRow = 0
            let maxRow = Int(size.height / spacing)

            for col in minCol...maxCol {
                for row in minRow...maxRow {
                    let dotX = CGFloat(col) * spacing + spacing / 2
                    let dotY = CGFloat(row) * spacing + spacing / 2

                    let dx = dotX - hoverX
                    let dy = dotY - centerY
                    let dist = sqrt(dx * dx + dy * dy)

                    guard dist < radius else { continue }

                    // Quadratic falloff: larger dots near center, shrinking to 0 at edge
                    let t = dist / radius
                    let dotRadius = maxDotRadius * (1 - t * t)
                    guard dotRadius > 0.1 else { continue }

                    let rect = CGRect(
                        x: dotX - dotRadius,
                        y: dotY - dotRadius,
                        width: dotRadius * 2,
                        height: dotRadius * 2
                    )
                    context.fill(
                        Path(ellipseIn: rect),
                        with: .color(.white)
                    )
                }
            }
        }
    }
}
