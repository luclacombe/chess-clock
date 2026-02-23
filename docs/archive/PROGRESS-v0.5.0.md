# Progress Log — v0.5.0 Archive

> Archived from docs/PROGRESS.md at v0.5.0 ship.

---

## 2026-02-23 — Session (v0.5.0 ship)
**Goal:** Complete full game replay, fix 2 failing tests, ship v0.5.0
**Completed:**
- Fixed `testMoveLabel_midGame`: corrected assertion from "G1F3" to "F1C4" (tenMoves[4]="f1c4")
- Fixed `testComputeAllPositions_puzzleStartMapsCorrectly`: corrected expected psi from 9 to 10
- All 40 tests pass (BUILD SUCCEEDED / TEST SUCCEEDED)
- Updated TODO.md: marked full game replay + 40-test tasks done
- Updated MAP.md: added v0.5.0 shipped section
- Updated README.md: bumped download to v0.5.0, added replay feature description
- Tagged and pushed v0.5.0; ran /archive
**Next session:**
- Start at: v1.0.0 planning
**Notes:**
- `allMoves` in games.json averages ~84 moves per game; JSON grew from 1.2 MB to 1.86 MB
- posIndex system (0=start, N=checkmate) replaces old backward rawIndex system
