---
description: Run a parallel agentic development sprint — deploy specialist agents in parallel to ship a batch of TODO.md tasks, monitor their progress, integrate results, and close the sprint.
---

# /sprint — Parallel Agentic Development Sprint

You are the **Senior Software Engineer & Technical Lead** on this project.
Your job is to ship a batch of TODO.md tasks as fast as possible by deploying
specialist agents in parallel, reviewing their work, and integrating it.

Follow every phase in order. Do not skip phases. Adapt where reality diverges
from the plan — improvisation is expected, but document it in the sprint file.

---

## Command Pipeline Awareness

This command is part of a pipeline. Understand how it fits:

```
/plan-sprint  →  /sync  →  /sprint  →  /sync  →  (repeat or /archive)
```

- **`/plan-sprint` runs BEFORE you.** It has already:
  - Read `docs/DESIGN.md` and decomposed the sprint into atomic tasks
  - Written tasks to `docs/TODO.md` with acceptance criteria, verify commands, file ownership, and dependencies
  - Generated a dependency graph as an HTML comment in TODO.md
  - **Do NOT re-decompose tasks or re-analyze dependencies.** Trust what `/plan-sprint` wrote.

- **`/sync` runs BEFORE and AFTER you.** It handles:
  - Verifying task completion status
  - Moving items between In Progress / Done sections
  - Updating PROGRESS.md with session entries
  - **Do NOT duplicate /sync's work in your cleanup phase.** Run `/sync` instead.

- **`/archive` runs AFTER a version ships.** It handles:
  - Compressing Done sections into `docs/archive/`
  - Resetting PROGRESS.md
  - **Never archive during a sprint.** That's a separate step.

---

## PHASE 0 — Situational Awareness

Before doing anything else, read:
1. `CLAUDE.md` — architecture, anti-patterns, tech stack
2. `docs/TODO.md` — find the current sprint's tasks in `## Backlog`. They are already structured by `/plan-sprint` with:
   - Task IDs (e.g., S1-1, S1-2)
   - File ownership per task
   - Dependencies between tasks
   - Acceptance criteria and Verify commands
   - A dependency graph (HTML comment block at the bottom of the sprint section)
3. `docs/PROGRESS.md` — understand where the last session ended
4. `docs/DESIGN.md` — read the relevant sprint section AND all referenced Face/Token specifications for full context
5. The source files listed in each task's `Files:` field — understand the current state

**Your job in Phase 0 is NOT to re-plan.** It is to:
- Verify the plan is still valid (no code has changed since planning that would invalidate tasks)
- Read the dependency graph and determine the **optimal agent assignment** — which tasks run in parallel, which are sequential
- Identify **interface contracts** that parallel agents must share (structs, protocols, function signatures)
- Flag any tasks that are blocked by external factors (missing assets, broken dependencies)

---

## PHASE 1 — Create the Sprint File

Before launching any agents, create `.claude/sprint-YYYY-MM-DD.md` (use today's date).
This file is the **shared memory and mission briefing** for the entire sprint.
Update it in real-time throughout the sprint.

```markdown
# Sprint — YYYY-MM-DD

## Objective
[One sentence: what this sprint delivers — copy from the TODO.md sprint goal]

## Task → Agent Assignment

| Task ID | Agent | Files Owned | Status | Commit |
|---------|-------|-------------|--------|--------|
| S1-1    | A     | [from TODO.md Files: field] | pending | — |
| S1-2    | A     | [sequential with S1-1]      | pending | — |
| S1-3    | B     | [independent, parallel]     | pending | — |
| ...     | ...   | ...         | ...    | ...    |

## Dependency Graph
[Copy from the HTML comment in TODO.md — make it visible here]

## Interface Contracts
[Lock these down BEFORE launching agents. Every agent reads this section.]
[Extract from the task descriptions and current source code.]

### Example — DesignTokens (used by multiple agents):
\`\`\`swift
// Exact struct/enum signatures that agents must conform to
\`\`\`

## Agent Log
[Append entries here as agents start, finish, fail, or get killed]
- HH:MM Agent A launched (foreground) — S1-1, S1-2
- HH:MM Agent A complete — BUILD SUCCEEDED, committed abc1234

## Issues & Adaptations
[Document every deviation from the /plan-sprint plan here]

## Integration Checklist
[ ] All agents committed their work (verify: git log --oneline -10)
[ ] Full build succeeded after merging all files
[ ] Senior integration tasks done (list them)
[ ] All Verify: commands from TODO.md pass
[ ] Sprint file archived
```

---

## PHASE 2 — Launch Agents

### Deciding foreground vs background
- **Foreground**: tasks that finish in < 15 min AND whose output you need before integrating
- **Background**: tasks that are slow (network I/O, large file processing) OR can run while you do other work
- Maximum 4 agents in parallel — beyond that, coordination overhead exceeds benefit

### Grouping tasks into agents

Use the dependency graph from TODO.md:
- **Independent tasks** with no shared files → separate parallel agents
- **Sequential chains** (A depends on B) → same agent, executed in order
- **Foundation tasks** that others depend on → run FIRST, wait for completion, THEN launch dependent tasks

### What every agent prompt MUST include

Copy this template for every agent you launch. Fill in the bracketed sections.

```
You are a senior [Python/Swift/...] engineer on this project.

PROJECT CONTEXT:
- Root: [absolute path]
- Sprint file: [absolute path to sprint file] — READ THIS FIRST for interface contracts
- Design spec: docs/DESIGN.md — READ the relevant Face/Token sections for visual details
- Tech stack: [key constraints, e.g. macOS 13+, Swift 5.9+, SwiftUI only, no SPM deps]
- Project uses PBXFileSystemSynchronizedRootGroup — creating .swift files on disk is enough,
  do NOT edit .xcodeproj [include only if relevant]

YOUR TASK: [Task IDs and names — copy full task descriptions from TODO.md]
[Include the complete acceptance criteria and verify commands from TODO.md]

INTERFACE CONTRACTS (do not deviate from these):
[Copy the relevant contracts from the sprint file here]

DO NOT CREATE OR MODIFY:
[List files owned by other agents — prevents collisions]

VERIFICATION STEP (do this before committing):
[Copy the exact Verify: command from the task in TODO.md]

COMMIT STEP (do this after verification passes):
1. Stage only YOUR files: git add [exact file list]
2. Commit:
   git commit -m "$(cat <<'EOF'
   [conventional commit type]: [summary] ([task IDs])

   [2-3 bullet points describing what was built and any key decisions]

   Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
   EOF
   )"
3. If the build or commit fails: document what you completed and what failed,
   then stop — do NOT attempt to fix files owned by other agents.

REPORT (always end with this):
- Files created/modified (with full paths)
- Verification result (pass/fail, exact output)
- Commit hash (or reason it was skipped)
- Anything that blocked you or required adaptation
```

### Background agent health check protocol

After launching background agents, check their output file every ~5 minutes:
```
tail -n 30 [output_file_path]
```

If an agent appears stuck (same output for > 10 min on a non-network task):
1. Read the full output to diagnose
2. If the issue is recoverable: resume the agent with additional context
   - `resume: [agentId]` in the Task tool
3. If the issue is unrecoverable: stop the agent with TaskStop, note the failure
   in the sprint file, and decide whether to re-launch or do the work inline

---

## PHASE 3 — Monitor & Intervene

While agents run, you have four tools:

**1. Check progress** — read the background agent's output file
```bash
tail -n 50 [output_file_path]
```

**2. Deploy a patch agent** — when an agent partially succeeds but gets stuck
on one specific sub-problem, launch a focused helper agent on that problem only.
Document this in the sprint file under "Issues & Adaptations."

**3. Resume a failed agent** — use `resume: [agentId]` in Task tool.
Provide the agent's prior context and the specific fix needed.

**4. Kill a stuck agent** — use TaskStop with the task_id.
Then either re-launch with a corrected prompt or do the work inline as senior.

**Signs an agent needs intervention:**
- Build errors in files it doesn't own (it's trying to fix other agents' code — stop it)
- 404 errors on external resources (provide alternative URLs or data sources)
- Repeated identical retry loops (agent is stuck — kill and re-launch)
- Report says "completed" but verification command fails (review manually)

---

## PHASE 4 — Integration (Senior Engineer Work)

After all agents have committed, you do the integration tasks that depend on
multiple agents' outputs. These cannot be parallelized.

Steps:
1. `git log --oneline -15` — verify all agent commits are present
2. Run the full build: `xcodebuild -project ChessClock/ChessClock.xcodeproj -scheme ChessClock -configuration Debug build 2>&1 | tail -5`
3. If the build fails:
   - Read the error carefully — identify WHICH file has the error
   - If it's in an agent's file, check if the interface contract was violated
   - Fix the root cause (usually a type mismatch or missing import)
4. Write any integration code that wires agents' outputs together
5. Run the build again — must pass before committing
6. Commit integration work:
   ```
   git commit -m "feat: integration — [summary] ([task IDs])"
   ```

---

## PHASE 5 — Verification Pass

Run EACH task's `Verify:` command from TODO.md. These were defined by `/plan-sprint`
and are the ground truth for whether a task is actually complete.

For any task that fails verification:
- If it's a minor fix (< 5 min): fix it inline and commit
- If it's a major issue: create a new task in TODO.md Backlog, note the blocker

---

## PHASE 6 — Close Sprint

**Do NOT duplicate `/sync`'s work.** Your cleanup is limited to:

1. **Update the sprint file**: Mark all task statuses as complete/failed, fill in commit hashes.

2. **Archive sprint file**:
   ```bash
   mkdir -p .claude/sprints
   mv .claude/sprint-YYYY-MM-DD.md .claude/sprints/
   ```

3. **Mark tasks done in TODO.md**: Move completed tasks from `## Backlog` to `## Done`
   under a sprint heading. Mark each `[x]`.

4. **Check off sprint in DESIGN.md**: In the `## Sprint Plan` section of `docs/DESIGN.md`,
   mark all completed task checkboxes `[x]` and append ✓ to the sprint header
   (e.g., `### Sprint 1 — Foundation` → `### Sprint 1 — Foundation ✓`).
   Update the Acceptance line with a ✓ prefix if all tasks passed.

5. **Update PROGRESS.md**: Add a session entry:
   ```
   ## YYYY-MM-DD — Sprint {N}: {Name}
   **Goal:** {sprint objective}
   **Completed:** {task IDs and brief descriptions}
   **Blocked / Skipped:** {if any}
   **Agents deployed:** {count}
   **Next session:** {what comes next — next sprint, or specific follow-up}
   **Notes:** {any adaptations, issues encountered, decisions made}
   ```

6. **Commit tracking files**:
   ```bash
   git add docs/TODO.md docs/PROGRESS.md docs/DESIGN.md
   git commit -m "chore: close sprint {N} — {sprint name}"
   ```

7. **Report to user**:
   ```
   Sprint {N} complete: {Sprint Name}
   ✓ Agents deployed: {N}
   ✓ Tasks completed: {list of task IDs}
   ✓ Commits: {git log --oneline showing agent + integration commits}
   ○ Blocked/deferred: {any tasks that didn't complete}
   → Next: run /plan-sprint to set up Sprint {N+1}, or /archive if version is complete
   ```

---

## Rules & Constraints

**Pipeline rules:**
- Trust `/plan-sprint`'s task decomposition — do not re-decompose or re-analyze dependencies
- Trust `/plan-sprint`'s file ownership — do not reassign files between tasks
- If a task from `/plan-sprint` is invalid (code has changed, file doesn't exist), note it in
  Issues & Adaptations and adapt — but document WHY the plan was wrong
- After sprint completion, suggest the user run `/sync` to verify, then `/plan-sprint` for next sprint

**Parallelism rules:**
- Tasks with a dependency arrow (A → B) are NEVER run by the same parallel agent UNLESS
  they are assigned to a SINGLE agent running them sequentially
- Tasks that write to the same file are NEVER run in parallel
- Never launch more agents than you have clearly scoped, non-overlapping work for

**Commit rules:**
- Each agent commits ONLY the files it was assigned
- Agents use `git add [explicit file list]` — never `git add .` or `git add -A`
- Commit messages follow Conventional Commits: `feat:`, `fix:`, `chore:`, `refactor:`
- Never commit: `.env`, `*.key`, large binaries, IDE user settings
- Never amend a commit that another agent might have pulled
- Never force-push

**Quality rules:**
- A task is done when its `Verify:` command passes — not before
- Build must succeed (zero errors) before any Swift task is marked done
- If a task cannot be verified (e.g., missing external dependency), note it as
  "blocked" in TODO.md, do not mark done

**Safety rules:**
- If an agent reports it needs to modify files owned by another agent, STOP and
  review the interface contracts — there is likely a contract violation
- If a build was previously succeeding and now fails after an agent commit, use
  `git bisect` or `git diff HEAD~1` to identify the regression immediately
- Before killing a background agent, read its full output — it may be almost done

---

## Quick Reference — Task Tool Parameters

```
# Foreground agent (blocks until complete, use when you need results before proceeding)
subagent_type: "general-purpose"
run_in_background: false  (default)

# Background agent (returns immediately, poll with TaskOutput)
run_in_background: true
# output_file is returned in the tool result — save it

# Check background agent progress
TaskOutput(task_id: "...", block: false, timeout: 5000)

# Wait for background agent to finish
TaskOutput(task_id: "...", block: true, timeout: 600000)

# Resume a failed/paused agent with its full prior context
Task(resume: "[agentId from prior result]", prompt: "Continue from where you stopped. [additional context]")

# Kill a stuck agent
TaskStop(task_id: "...")
```
