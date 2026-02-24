# docs/ — Project Planning & Tracking

All planning, tracking, and decision documents live here. None of these are shipped in the app.

---

## File Guide

| File | Purpose | Read when |
|---|---|---|
| `TODO.md` | Active task tracker — source of truth for all dev work | Every session start; /sync reads and writes it |
| `PROGRESS.md` | Session-by-session log | /sync appends to it each session |
| `DESIGN.md` | v1.0 UI design spec — all screens, tokens, copy, animations | Before implementing any Sprint 1–6 task |
| `DECISIONS.md` | Architecture decision records (ADRs) — permanent, never delete | Before making a non-obvious technical choice |
| `MAP.md` | Feature roadmap: shipped version summaries + future feature backlog | Planning or scoping features |
| `FUTURE.md` | Long-term ideas parking lot — append-only, nothing here is scheduled | Brainstorming only |
| `archive/` | Archived TODO Done sections, PROGRESS logs, and specs from shipped versions | Historical reference |

---

## Housekeeping Rules

- **DESIGN.md** — the single source of truth for the current v1.0 sprint; update it before writing code, not after
- **DECISIONS.md** — never archive; mark reversed decisions `[SUPERSEDED]` instead
- **FUTURE.md** — never archive; append-only
- **MAP.md** — remove completed version's section when archiving; keep future sections
- **TODO.md / PROGRESS.md** — reset at each version ship via `/archive`
- **archive/** — files go in but never come out
