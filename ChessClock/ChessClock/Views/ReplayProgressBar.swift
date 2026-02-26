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
        // (a) Snap to start when clicking near the left edge
        if clickFraction < 0.08 { return 0 }

        // (b) Raw proportional index
        let rawIndex = Int(round(clickFraction * CGFloat(totalMoves)))

        // (c) Puzzle-start fraction
        let puzzleFraction = CGFloat(puzzleStartPosIndex) / CGFloat(max(totalMoves, 1))

        // (d) Snap to puzzle start when clicking near its marker
        if abs(clickFraction - puzzleFraction) < 0.03 { return puzzleStartPosIndex }

        // (e) Clamped result
        return min(max(rawIndex, 0), totalMoves)
    }

    // MARK: - Body

    var body: some View {
        GeometryReader { geo in
            let availableWidth = geo.size.width
            let barHeight = isHovered
                ? ChessClockSize.progressBarHoverHeight
                : ChessClockSize.progressBarHeight
            let cornerRadius = barHeight / 2
            let fillFraction = CGFloat(posIndex) / CGFloat(max(totalMoves, 1))
            let fillWidth = fillFraction * availableWidth
            let markerX = CGFloat(puzzleStartPosIndex) / CGFloat(max(totalMoves, 1)) * availableWidth

            ZStack(alignment: .leading) {
                // Track
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.white.opacity(0.15))
                    .frame(height: barHeight)

                // Fill
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(zone.color)
                    .frame(width: fillWidth, height: barHeight)
                    .animation(ChessClockAnimation.micro, value: posIndex)

                // Cursor glow
                if isHovered {
                    RadialGradient(
                        colors: [Color.white.opacity(0.25), .clear],
                        center: UnitPoint(x: hoverX / availableWidth, y: 0.5),
                        startRadius: 0,
                        endRadius: ChessClockSize.progressBarGlowRadius
                    )
                    .frame(height: barHeight)
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                }

                // Puzzle-start marker
                Rectangle()
                    .fill(Color.white.opacity(0.35))
                    .frame(width: 1, height: barHeight + 2)
                    .position(x: markerX, y: barHeight / 2)
            }
            .frame(height: barHeight)
            .frame(maxHeight: .infinity)
            .animation(ChessClockAnimation.micro, value: isHovered)
            .contentShape(Rectangle())
            .onTapGesture { location in
                let fraction = location.x / availableWidth
                let target = Self.targetIndex(
                    clickFraction: fraction,
                    totalMoves: totalMoves,
                    puzzleStartPosIndex: puzzleStartPosIndex
                )
                onSeek(target)
            }
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
        .frame(height: ChessClockSize.progressBarHoverHeight)
    }
}
