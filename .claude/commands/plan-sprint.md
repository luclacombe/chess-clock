---
description: Plan the next sprint — read DESIGN.md, decompose tasks into TODO.md backlog with acceptance criteria, verify commands, and file ownership so /sprint can execute automatically.
---

# /plan-sprint — Sprint Planning from Design Spec

You are a **Staff Software Architect** planning the next sprint for the development team.
Your job is to translate the high-level sprint definition in `docs/DESIGN.md` into
concrete, parallelizable tasks in `docs/TODO.md` that `/sprint` can execute without ambiguity.

Every task you write must be so specific that an agent reading ONLY that task
(plus the referenced files) can implement it without asking questions.

---

## PHASE 0 — Determine Which Sprint Is Next

Read these files (in order):

1. **`docs/DESIGN.md`** — find the `## Sprint Plan` section. Each sprint is numbered (1–6).
2. **`docs/TODO.md`** — check the `## Done` section to see which sprints have been completed.
3. **`docs/PROGRESS.md`** — check for any in-progress sprint context.

**Logic:**
- If Done contains "Sprint 1" tasks → next sprint is Sprint 2
- If Done is empty → next sprint is Sprint 1
- If a sprint is partially done (some tasks in Done, some in Backlog/In Progress) → continue that sprint
- The argument `$ARGUMENTS` may specify a sprint number (e.g., `/plan-sprint 3`). If provided, plan that sprint regardless of Done state. If not provided, auto-detect.

---

## PHASE 1 — Read the Sprint Spec

From `docs/DESIGN.md`, extract:
1. The sprint's **goal** (one sentence)
2. The sprint's **task list** (the `- [ ]` items under that sprint)
3. All **screen specifications** referenced by those tasks (the detailed Face sections)
4. All **design tokens** referenced (colors, fonts, sizes, animations)
5. All **technical requirements** (new components, modified components, deleted components)

Also read the **source files** that will be modified. For each file in the sprint's scope:
- Read the current implementation
- Understand what exists vs. what needs to change
- Identify shared interfaces (structs, protocols, function signatures)

---

## PHASE 2 — Decompose into Tasks

Break the sprint into **atomic tasks**. Each task must:

1. **Touch a bounded set of files** — ideally 1–3 files. Never more than 5.
2. **Have clear acceptance criteria** — checkboxes that can be verified mechanically.
3. **Have a Verify command** — a build command, test command, or file check that proves it works.
4. **List file ownership** — which files this task creates or modifies (for collision prevention).
5. **Note dependencies** — which other tasks must complete before this one can start.

### Task Granularity Rules

- **One concern per task.** "Add rounded corners to BoardView AND change piece assets" is two tasks.
- **Token/constant tasks are separate.** Creating `DesignTokens.swift` is its own task — other tasks depend on it.
- **Deletion is a task.** Removing `MoveArrowView.swift` or `ContentView.swift` is explicit.
- **Data prep is a task.** Downloading SVGs, converting assets, updating the asset catalog — explicit.
- **If a task takes > 30 min for one agent, split it.**

### Dependency Classification

For each task, classify it:
- **INDEPENDENT** — can run in parallel with all other tasks
- **DEPENDS ON [task IDs]** — must wait for those tasks to complete
- **BLOCKS [task IDs]** — other tasks are waiting on this one

### Interface Contracts

If two or more tasks will share a struct, protocol, function signature, or file:
- Define the **exact interface** in the task description
- Both tasks must reference the same interface definition
- If one task creates the interface and another consumes it, make that dependency explicit

---

## PHASE 3 — Write to TODO.md

Update `docs/TODO.md` with the planned tasks. Use this exact format:

```markdown
## Backlog

### Sprint {N} — {Sprint Name}

> **Goal:** {one sentence from DESIGN.md}
> **Design spec:** `docs/DESIGN.md` → Sprint {N} section + referenced Face specifications

- [ ] **S{N}-1: {Task Title}** — {one-line description}
  - Files: `{list of files created or modified}`
  - Depends on: {task IDs or "none"}
  - Acceptance:
    - [ ] {criterion 1}
    - [ ] {criterion 2}
    - [ ] {criterion 3}
  - Verify: `{exact command to run}`

- [ ] **S{N}-2: {Task Title}** — {another task}
  - Files: `{...}`
  - Depends on: S{N}-1
  - Acceptance:
    - [ ] {criterion 1}
  - Verify: `{exact command}`
```

### Verify Command Patterns

Use these standard verification patterns:

```bash
# Swift build check
xcodebuild -project ChessClock/ChessClock.xcodeproj -scheme ChessClock -configuration Debug build 2>&1 | tail -5

# Test run
xcodebuild test -project ChessClock/ChessClock.xcodeproj -scheme ChessClock -destination 'platform=macOS' 2>&1 | tail -10

# File existence check
test -f {path} && echo "EXISTS" || echo "MISSING"

# Asset catalog check
ls ChessClock/ChessClock/Assets.xcassets/{name}.imageset/

# Line count / content check (verify something was removed)
grep -c "{pattern}" {file}  # should return 0 if removed
```

---

## PHASE 4 — Generate the Dependency Graph

After writing tasks, append an ASCII dependency graph as a comment block in TODO.md
(or at the bottom of the sprint section). This helps `/sprint` plan parallel execution.

```markdown
<!-- Sprint {N} Dependency Graph
S{N}-1 (tokens) ──► S{N}-3 (board), S{N}-4 (ring), S{N}-5 (formatter)
S{N}-2 (assets) ──► S{N}-3 (board)
S{N}-3, S{N}-4, S{N}-5 are INDEPENDENT of each other after S{N}-1
S{N}-6 (cleanup) is INDEPENDENT
S{N}-7 (frame lock) DEPENDS ON S{N}-3, S{N}-4
-->
```

---

## PHASE 5 — Sanity Checks

Before presenting the plan, verify:

1. **Coverage** — every `- [ ]` item in DESIGN.md's sprint section maps to at least one TODO task
2. **No orphans** — every task has either "Depends on: none" or references a valid task ID
3. **No collisions** — no two INDEPENDENT tasks modify the same file
4. **Build path** — there exists at least one ordering of tasks where each Verify command can pass
5. **Completeness** — the sprint's goal (from DESIGN.md) is achievable if all tasks pass acceptance

---

## PHASE 6 — Report

Present the plan to the user:

```
Sprint {N} planned: {Sprint Name}
Goal: {one sentence}

Tasks: {count}
├── Independent: {list of task IDs that can run in parallel}
├── Sequential chains: {A → B → C}
└── Estimated agents: {recommended number of parallel agents}

Dependency graph:
{ASCII graph}

TODO.md updated with {count} tasks in Backlog.
Run /sync then /sprint to execute.
```

---

## Rules

- **Never invent requirements.** Every task must trace back to a specific line in DESIGN.md.
- **Never skip acceptance criteria.** Every task needs at least one verifiable criterion.
- **Never create circular dependencies.** If A depends on B, B cannot depend on A.
- **Be pessimistic about parallelism.** If two tasks MIGHT conflict, mark them sequential.
- **Include the design token values in task descriptions.** Don't say "use the accent gold color" — say "use `Color(red: 191/255, green: 155/255, blue: 48/255)` (#BF9B30)."
- **Quote exact specs from DESIGN.md** in task acceptance criteria. The agent should not need to read DESIGN.md — the task description should be self-contained.
