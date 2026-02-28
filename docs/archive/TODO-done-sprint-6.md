### Sprint 6 — Replay Face Overhaul + Ring Polish + Settings Placeholder ✓

> **Goal:** Rewrite `GameReplayView` to match the visual language from Sprint 4–5 (ZStack overlay architecture, pill system, design tokens). Build `SANFormatter`. Add minor tick marks and semicircle ring tip to the gold minute ring. Wire the settings gear icon to a placeholder screen.

- [x] **S6-1: SANFormatter** — New service that converts UCI move strings to Standard Algebraic Notation for the replay nav overlay. `b9ed3b8`
- [x] **S6-2: ReplayZone update** — Expand the `ReplayZone` enum with a `.checkmate` case and update labels to match DESIGN.md naming. `fd1571c`
- [x] **S6-3: GameReplayView layout rewrite** — Replace VStack root with ZStack overlay architecture matching GuessMoveView pattern. `fd1571c`
- [x] **S6-4: Replay header pills** — Two-pill HStack overlaid on board top with auto-hide behavior, matching GuessMoveView's exact pill pattern. `fd1571c`
- [x] **S6-5: Nav overlay** — Bottom overlay on board with 5-button navigation, SAN move label, and position counter. `78dca57`
- [x] **S6-6: Keyboard + focus cleanup** — Ensure arrow keys work immediately without tab-focusing, remove all blue focus rings from replay view. `78dca57`
- [x] **S6-7: Minor tick marks on gold ring** — Add 8 intermediate tick marks for a total of 12 evenly spaced marks (every 30°), resembling a traditional watch dial. `3261c37`
- [x] **S6-8: Semicircle ring tip** — Replace the sharp radial leading edge of the progress fill with a smooth semicircle cap for a "snake body" appearance. `3261c37`
- [x] **S6-9: Settings placeholder screen** — Wire the gear icon in InfoPanelView to navigate to a "Coming Soon" placeholder, add `.settings` ViewMode case. `2157ef0`
