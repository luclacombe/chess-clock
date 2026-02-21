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

## PHASE 0 — Situational Awareness

Before doing anything else, read:
1. `CLAUDE.md` — architecture, anti-patterns, tech stack
2. `TODO.md` — find the first N tasks in `## Backlog` that are ready to start
3. `PROGRESS.md` — understand where the last session ended
4. Any files mentioned in the tasks you are about to work on

Then answer these questions internally:
- What are the MUST HAVE tasks next in order?
- Which tasks are **truly independent** (different files, no shared state)?
- Which tasks produce **outputs that other tasks consume**?
- What **interface contracts** (structs, function signatures, file schemas) must
  be agreed on upfront so parallel agents don't make conflicting assumptions?

---

## PHASE 1 — Create the Sprint File

Before launching any agents, create `.claude/sprint-YYYY-MM-DD.md` (use today's date).
This file is the **shared memory and mission briefing** for the entire sprint.
Update it in real-time throughout the sprint.

```markdown
# Sprint — YYYY-MM-DD

## Objective
[One sentence: what this sprint delivers]

## Task → Agent Assignment

| Task ID | Agent | Files Owned | Status | Commit |
|---------|-------|-------------|--------|--------|
| P2-1    | B     | Models/ChessGame.swift, Services/GameLibrary.swift | pending | — |
| ...     | ...   | ...         | ...    | ...    |

## Dependency Graph
[ASCII tree showing which tasks block which]
Example:
  P1-1 → P1-2 → P1-3 ──► (senior) P1-4
  P2-1 → P2-2                              ┐
  P2-4 → P2-5                              ├──► (senior) P2-9 → P2-10
  P2-6, P2-7, P2-8 (independent)           ┘

## Interface Contracts
[Lock these down BEFORE launching agents. Every agent reads this section.]

### Example — ChessGame struct (used by Agents B and D):
\`\`\`swift
struct ChessGame: Codable {
    let white: String
    let black: String
    let whiteElo: String   // "?" if unknown
    let blackElo: String
    let tournament: String
    let year: Int
    let positions: [String]  // exactly 12 FEN strings
}
\`\`\`

### Example — games.json schema:
\`\`\`json
{ "white": "...", "black": "...", "whiteElo": "...", "blackElo": "...",
  "tournament": "...", "year": 2018,
  "positions": ["fen_1_move_before_checkmate", ..., "fen_12_moves_before_checkmate"] }
\`\`\`

## Agent Log
[Append entries here as agents start, finish, fail, or get killed]
- HH:MM Agent B launched (foreground) — P2-1, P2-2, P2-3
- HH:MM Agent B complete — BUILD SUCCEEDED, committed abc1234
- HH:MM Agent C failed — BoardPosition parse error, resuming with agentId xyz

## Issues & Adaptations
[Document every deviation from the plan here]

## Integration Checklist
[ ] All agents committed their work (verify: git log --oneline -10)
[ ] Full build succeeded after merging all files
[ ] Senior integration tasks done (list them)
[ ] All task IDs marked done in TODO.md
[ ] PROGRESS.md updated
[ ] Sprint file archived (rename to .claude/sprints/sprint-YYYY-MM-DD.md)
```

---

## PHASE 2 — Launch Agents

### Deciding foreground vs background
- **Foreground**: tasks that finish in < 15 min AND whose output you need before integrating
- **Background**: tasks that are slow (network I/O, large file processing) OR can run while you do other work
- Maximum 4 agents in parallel — beyond that, coordination overhead exceeds benefit

### What every agent prompt MUST include

Copy this template for every agent you launch. Fill in the bracketed sections.

```
You are a senior [Python/Swift/...] engineer on this project.

PROJECT CONTEXT:
- Root: [absolute path]
- Sprint file: [absolute path to sprint file] — READ THIS FIRST for interface contracts
- Tech stack: [key constraints, e.g. macOS 13+, Swift 5.9+, SwiftUI only, no SPM deps]
- Project uses PBXFileSystemSynchronizedRootGroup — creating .swift files on disk is enough,
  do NOT edit .xcodeproj [include only if relevant]

YOUR TASK: [Task IDs and names]
[Full spec for each task — exact file paths, acceptance criteria, verification commands]

INTERFACE CONTRACTS (do not deviate from these):
[Copy the relevant contracts from the sprint file here]

DO NOT CREATE OR MODIFY:
[List files owned by other agents — prevents collisions]

VERIFICATION STEP (do this before committing):
[Exact verification command, e.g. xcodebuild build | grep BUILD or python3 verify.py]

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
2. Run the full build: `xcodebuild ... build 2>&1 | grep -E "error:|BUILD SUCCEEDED|BUILD FAILED"`
3. If the build fails:
   - Read the error carefully — identify WHICH file has the error
   - If it's in an agent's file, check if the interface contract was violated
   - Fix the root cause (usually a type mismatch or missing import)
4. Write the integration files (ClockView.swift, App entry point, etc.)
5. Run the build again — must pass before committing
6. Commit integration work:
   ```
   git commit -m "feat: integration — [summary] ([task IDs])"
   ```

---

## PHASE 5 — Verification Pass

Before closing the sprint, verify EACH completed task against its acceptance criteria
in TODO.md. Run the listed `Verify:` commands. Do not mark tasks done by assumption.

For any task that fails verification:
- If it's a minor fix (< 5 min): fix it inline and amend the relevant commit
- If it's a major issue: create a new task in TODO.md Backlog, note the blocker

---

## PHASE 6 — Cleanup & Close

1. **Update TODO.md**: Mark completed tasks `[x]` with date. Move them to `## Done`.
   Update `## In Progress` to reflect actual state.

2. **Update PROGRESS.md**: Add session entry with goal, completed tasks, blockers,
   adaptations made, next session start point.

3. **Archive sprint file**:
   ```bash
   mkdir -p .claude/sprints
   mv .claude/sprint-YYYY-MM-DD.md .claude/sprints/
   ```

4. **Final commit** (tracking files only):
   ```
   git add TODO.md PROGRESS.md
   git commit -m "chore: update task tracking — [phase] complete"
   git push origin main
   ```

5. **Report to user**:
   ```
   Sprint complete.
   ✓ Agents deployed: N
   ✓ Tasks completed: [list of task IDs]
   ✓ Commits: [git log --oneline showing agent + integration commits]
   ○ Blocked/deferred: [any tasks that didn't complete]
   → Next sprint: [next task ID and name]
   ```

---

## Rules & Constraints

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
