# TODO Done — Sprint 4.5 (Polish & Header Redesign)

> Archived 2026-02-25

### Sprint 4.5 — Polish & Header Redesign ✓

> **Goal:** Fix tick z-order, balance Detail face layout, improve board interaction visibility, implement auto-hide puzzle header pills, and redesign the result overlay as full-board frosted glass.

- [x] **S4.5-1: ClockView — Tick z-order fix** — Moved GoldRingLayerView after boardWithRing in ZStack. `5f5b5d2`
- [x] **S4.5-2: InfoPanelView — Vertical balance fix** — Removed Spacer(), symmetric .padding(.vertical, 12), alignment: .top. `afea009`
- [x] **S4.5-3: DesignTokens — Interaction color opacity updates** — squareSelected 0.30→0.50, legalDot/legalCapture 0.28→0.55. `cad4eb6`
- [x] **S4.5-4: InteractiveBoardView — Legal dot size increase** — sq*0.32→sq*0.38. `cad4eb6`
- [x] **S4.5-5: GuessMoveView — Auto-hide header pills** — Three-pill HStack (back, info, tries) with auto-hide after 2.5s; persistent pip chevron. `6767efb`
- [x] **S4.5-6: GuessMoveView — Wrong move border flash** — 3pt red strokeBorder at 75% opacity, 0.5s fade; pills reappear for 1.8s. `6767efb`
- [x] **S4.5-7: GuessMoveView — Result overlay frosted glass** — Full-board ultraThinMaterial + 10% tint; no icon; 28pt title; Review→ capsule (0.2s delay); Done plain. `6767efb`
