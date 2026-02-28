### Sprint 6.5 — Replay Face: Board-First Two Overlays Redesign ✓

> **Goal:** Redesign GameReplayView with a minimal "board-first" layout: always-visible back pill with player names (top-left), slim navigation strip with zone + SAN + counter + arrows (bottom), interactive zone-colored progress bar with snap zones and hover glow, and focus/keyboard bug fixes.

- [x] **S6.5-1: Update DESIGN.md — Replay Face redesign spec** — Face 5 rewritten with board-first two overlays design, Copy Guide updated, Cmd+Arrow shortcuts added, Sprint 6.5 in Sprint Plan. `c70c308`
- [x] **S6.5-2: Design tokens for replay progress bar** — progressBarHeight (3pt), progressBarHoverHeight (5pt), progressBarGlowRadius (20pt) added to ChessClockSize. `62f7a95`
- [x] **S6.5-3: ReplayProgressBar — Interactive zone-colored scrubber** — New view with zone-colored fill, puzzle-start marker, click-to-seek with snap zones, hover thickening + radial cursor glow. `ab536b0`
- [x] **S6.5-4: Rewrite GameReplayView — Board-First Two Overlays** — Always-visible back pill, slim nav strip with ReplayProgressBar, focus ring fix, keyboard on hover, Cmd+Arrow jumps. Deleted ~130 lines of auto-hide/pip/5-button nav. `da890bd`
- [x] **S6.5-5: Verify build + all tests pass** — BUILD SUCCEEDED, 150 tests passed (including all 32 GameReplayViewTests), zero warnings.
