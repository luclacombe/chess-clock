# Sprint — 2026-02-23

## Objective
Fix ring rendering artifacts (lineCap bleed, corner gaps, flat appearance, weak shimmer) and repair Detail face layout (clipped buttons, overflowing text, visible ring).

## Task → Agent Assignment

| Task ID | Agent | Files Owned | Status | Commit |
|---------|-------|-------------|--------|--------|
| S3.75-1 | Senior | DesignTokens.swift | pending | — |
| S3.75-2 | Agent A | MinuteBezelView.swift | pending | — |
| S3.75-3 | Agent B | BoardView.swift | pending | — |
| S3.75-4 | Agent C | InfoPanelView.swift | pending | — |
| S3.75-5 | Agent B | ClockView.swift | pending | — |
| S3.75-6 | Senior | docs/DESIGN.md | pending | — |

## Dependency Graph
```
S3.75-1 (tokens) ──► S3.75-2 (ring rewrite), S3.75-4 (info panel layout)
S3.75-3 (board bevel) is INDEPENDENT
S3.75-5 (hide ring in detail) is INDEPENDENT
S3.75-2, S3.75-3, S3.75-4, S3.75-5 are INDEPENDENT of each other (all touch different files)
S3.75-6 (docs) DEPENDS ON S3.75-1, S3.75-2, S3.75-3, S3.75-4, S3.75-5
```

Execution order:
- Phase 1: S3.75-1 (Senior) + S3.75-3 (Agent B) + S3.75-5 (Agent B) in parallel
- Phase 2: S3.75-2 (Agent A) + S3.75-4 (Agent C) after S3.75-1 completes
- Phase 3: S3.75-6 (Senior) after all tasks complete

## Interface Contracts

### DesignTokens (S3.75-1 adds, other tasks consume)
```swift
// New colors
static let accentGoldLight = Color(red: 212/255, green: 185/255, blue: 78/255)
static let accentGoldDeep  = Color(red: 138/255, green: 111/255, blue: 31/255)
static let ringGradient    = LinearGradient(colors: [accentGoldLight, accentGoldDeep], startPoint: .topLeading, endPoint: .bottomTrailing)

// Updated animation
static let shimmer = Animation.easeInOut(duration: 1.8).repeatForever(autoreverses: true)

// New dimensions
static let shimmerMinOpacity: CGFloat = 0.50
static let boardDetail: CGFloat = 176  // changed from 196
static let ringOuterEdge: CGFloat = 2  // ringInset − ringStroke/2 = 6 − 4
static let ringInnerEdge: CGFloat = 10 // ringInset + ringStroke/2 = 6 + 4
```

## Agent Log

## Issues & Adaptations

## Integration Checklist
- [ ] All agents committed their work
- [ ] Full build succeeded after merging all files
- [ ] Senior integration tasks done
- [ ] All Verify commands from TODO.md pass
- [ ] Sprint file archived
