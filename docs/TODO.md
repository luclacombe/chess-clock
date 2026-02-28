# TODO — Chess Clock

> This is the **source of truth** for all development tasks.
> Never mark an item done without verifying its acceptance criteria.
> Run `/sync` at the start and end of every session.

---

## In Progress

_Nothing in progress._

---

## Backlog

- [ ] **S7-4: Face transition audit** — Verify every transition in the Interaction Specification table. All use `withAnimation(ChessClockAnimation.smooth)` (0.4s easeInOut) for ViewMode changes.
- [ ] **S7-5: Performance audit** — Profile each face 60s. Clock idle <0.5% CPU. Popover closed: 0% CPU. Verify `isActive` pauses, timer lifecycle, CALayer panel survival.
- [ ] **S7-6: Accessibility + reduced motion** — VoiceOver labels on all interactive elements. Reduced motion: disable continuous animations, simple fades instead of springs, instant blur toggle.

---

## Done

- [x] **S7-1: BorderlessPanel** — Borderless NSPanel subclass, 300×300, draggable, hover close+minimize buttons, system shadow
- [x] **S7-2: Onboarding refresh** — Copy Guide text, "Continue" gold capsule, 12pt card radius, "Don't show again" checkbox
- [x] **S7-3: Hour-change animation** — Ring sweep→drain (2.5s cubic ease-in), white flash hides board swap, ~3.1s total
- [x] **OB-1: Onboarding redesign** — Progressive 4-stage onboarding replacing single modal. Stage A: 3-step clock tour (position, ring, tap). Stage B: 2-step info panel tour (players, puzzle CTA). Stage C: replay nudge after first puzzle. Stage D: replay scrub hint with auto-dismiss. Reusable OnboardingCalloutView glass pill. Gold glow highlights on InfoPanelView and GameReplayView.

_Sprint 6.5 (POST) tasks archived to docs/archive/TODO-done-sprint-6.5-post.md_
_Sprint 6.5 tasks archived to docs/archive/TODO-done-sprint-6.5.md_
_Sprint 6 tasks archived to docs/archive/TODO-done-sprint-6.md_
_Sprint 5 tasks archived to docs/archive/TODO-done-sprint-5.md_
_Sprint 4.5 tasks archived to docs/archive/TODO-done-sprint-4.5.md_
_Sprint 4 tasks archived to docs/archive/TODO-done-sprint-4.md_
_Sprint 4P tasks archived to docs/archive/TODO-done-sprint-4P.md_
_Sprint 4 ring tasks archived to docs/archive/TODO-done-sprint-4-ring.md_
_Sprint 3.95 tasks archived to docs/archive/TODO-done-sprint-3.95.md_
_v0.5.1 tasks archived to docs/archive/TODO-done-v0.5.1.md_
_Sprint 1 tasks archived to docs/archive/TODO-done-sprint-1.md_
_Sprint 2 tasks archived to docs/archive/TODO-done-sprint-2.md_
_Sprint 3 tasks archived to docs/archive/TODO-done-sprint-3.md_
_Sprint 3.5 tasks archived to docs/archive/TODO-done-sprint-3.5.md_
_Sprint 3.75 tasks archived to docs/archive/TODO-done-sprint-3.75.md_
_Sprint 3.9 tasks archived to docs/archive/TODO-done-sprint-3.9.md_
_v0.1.0 tasks archived to docs/archive/TODO-done-v0.1.0.md_
_v0.2.0 tasks archived to docs/archive/TODO-done-v0.2.0.md_
_v0.3.0 tasks archived to docs/archive/TODO-done-v0.3.0.md_
_v0.4.0 tasks archived to docs/archive/TODO-done-v0.4.0.md_
_v0.5.0 tasks archived to docs/archive/TODO-done-v0.5.0.md_

---

## Notes

- Do not reorder Backlog items without a good reason — the order reflects dependencies
- Do not mark a task done without verifying its acceptance criteria
- If a task is blocked, note the blocker inline and move to the next unblocked task
