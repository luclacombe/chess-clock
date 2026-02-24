# Sprint: Performance Audit & Optimization (2026-02-24)

## Status: IN PROGRESS

## Problem
- 50% CPU, 128MB RAM, 126 idle wake-ups for a 300x300 menu bar clock
- Stop-motion ring animation

## Targets
- <2% CPU idle, <5% CPU active, <50MB memory, 0 idle wake-ups when closed

---

## Phase 1: Kill the 50% CPU Core
- [ ] **P1A** Gate MinuteBezelView on visibility (ClockView.swift)
- [ ] **P1B** Rewrite energy pulse system — single animated pulse (MinuteBezelView.swift)
- [ ] **P1C** Fix stop-motion animation (automatic with P1B)

## Phase 2: Eliminate Timer Waste
- [ ] **P2A** Share single ClockService instance (FloatingWindowManager.swift, ChessClockApp.swift)
- [ ] **P2B** Pause timer when popover hidden (ClockService.swift, ClockView.swift)
- [ ] **P2C** Cache GameScheduler resolution (ClockService.swift)

## Phase 3: View Tree Optimization
- [ ] **P3A** drawingGroup before board blur (ClockView.swift)
- [ ] **P3B** Conditionally include GlassPillView (ClockView.swift)
- [ ] **P3C** Make BoardView Equatable (BoardView.swift)
- [ ] **P3D** Simplify GuessService hour-check (GuessService.swift)
- [ ] **P3E** Cache legal moves in InteractiveBoardView (InteractiveBoardView.swift)

## Phase 4: Documentation
- [ ] **P4A** Add performance rules to DESIGN.md
- [ ] **P4B** Add performance anti-patterns to CLAUDE.md
