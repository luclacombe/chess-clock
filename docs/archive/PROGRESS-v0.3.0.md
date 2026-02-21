# Progress Log

> Append a new entry at the start of each development session.
> Run `/sync` to auto-update this file.

---

## 2026-02-21 — v0.3.0 Release Session
**Goal:** Build and ship the "Guess Move" interactive feature + simplified UI + hourly game rotation
**Completed:**
- [UI-1/2/3] Simplified ClockView to board+ring default; hover hint; tap → InfoPanelView; updated onboarding text
- [SCHED-1] Hourly game rotation (new game every hour)
- [SCHED-2] Fixed critical bug: fenIndex was hardcoded to 0; restored `fenIndex = hour12 - 1` so the clock correctly shows N moves before checkmate at hour N
- [DATA-1] Added `finalMove` UCI field to Python pipeline, rebuilt games.json (588 games)
- [FEAT-1–8] Full Guess Move feature: ChessRules engine, GuessService, GuessMoveWindowManager, InfoPanelView, InteractiveBoardView, PromotionPickerView, GuessMoveView, MoveResultView
- [TEST-1–3] 48 tests total, all passing
- [REL] Bumped MARKETING_VERSION to 0.3, tagged and released v0.3.0
**Blocked / Skipped:** None
**Next session:**
- Review MAP.md for v1.0.0 scope (UI overhaul, app icon, animations)
**Notes:**
- GuessMoveView always uses positions[0] for the interactive board (finalMove is only legal from that position)
- The clock board uses positions[hour-1]; the puzzle always shows the mate-in-1 board regardless

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
