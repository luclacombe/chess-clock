# Progress Log

> Append a new entry at the start of each development session.
> Run `/sync` to auto-update this file.

---

## 2026-02-23 — Sprint 1: Foundation
**Goal:** Ship the visual atoms that everything else builds on.
**Completed:**
- S1-1 DesignTokens.swift — all color, type, spacing, radius, dimension, animation constants
- S1-2 Merida SVGs — 12 SVGs from Lichess replace cburnett PNGs
- S1-3 BoardView 6pt corner radius
- S1-4 MinuteBezelView — custom RingShape, gold fill, gray track, 4 tick marks, animated
- S1-5 PlayerNameFormatter — PGN name inversion, initial handling, ELO formatting
- S1-6 ClockView locked to 300×300, MinuteBezelView wired in, padding removed
- S1-7 ContentView.swift deleted (legacy)
- S1-8 MoveArrowView.swift deleted, GameReplayView cleaned, 8 arrow tests removed
**Blocked / Skipped:** None
**Agents deployed:** 5 (Agent A: S1-1, Agent B: S1-2 partial, Agent C: S1-3/5/7, Agent D: S1-8, Agent E: S1-4)
**Next session:** Run `/plan-sprint` to set up Sprint 2 (Clock + Glance)
**Notes:**
- Agents B/C/D had Bash permission denied for curl/verification/commit; Senior handled those steps
- All tests pass (32 GameReplayView + others), BUILD SUCCEEDED
- 6 commits: 050ed42, c2f9f69, 43cf99d, 3c8c260, bd1979f, 4d8163d

---

## 2026-02-23 — Session (v0.5.1 patch)
**Goal:** Fix replay start position bug + GitHub Latest release badge
**Completed:**
- Fixed `puzzleStartPosIndex` formula: `positions.count - 1` → `positions.count - 2`
- Updated `testComputeAllPositions_puzzleStartMapsCorrectly` to match corrected formula (psi=9, not 10)
- All 40 tests pass (CODE_SIGN_IDENTITY="" workaround for transient keychain lock)
- Tagged v0.5.1 and pushed; created `gh release create v0.5.1 --latest` → GitHub now shows v0.5.1 Latest
- Updated README download link, TODO Done section, MAP.md patch note
**Next session:**
- Start at: v0.6.0 planning
**Notes:**
- The psi bug was subtle: for hour 1, psi=N pointed to checkmate (after your move); correct is N-1 (before your move, showing opponent's context arrow)
- Codesign intermittently fails in xcodebuild test; use CODE_SIGN_IDENTITY="" workaround if it recurs

---

## Template

```
## YYYY-MM-DD — Session N
**Goal:** [What we set out to do]
**Completed:**
- [Task ID] Description of what was done
**Blocked / Skipped:**
- [Task ID] Reason
**Next session:**
- Start at: [Task ID] [Task name]
**Notes:**
- [Any context to carry forward]
```

---
