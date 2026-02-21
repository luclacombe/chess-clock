---
description: Review session progress — verify in-progress tasks, move completed items to Done, and update PROGRESS.md. Run at the start and end of every development session.
---

# /sync — Session Progress Review

Run this command at the **start and end of every development session**.

## Steps to Follow (in order)

1. **Read `docs/TODO.md`** — identify every item currently marked as `in_progress` or recently worked on

2. **For each in-progress item**, check its acceptance criteria:
   - Run the listed `Verify:` command if one is specified
   - Check if the files mentioned in the criteria actually exist and are non-empty
   - Check git status to see what was actually changed

3. **Determination:**
   - If ALL criteria pass → move the item from `## In Progress` to `## Done` in `docs/TODO.md`, adding the completion date in the format `(completed YYYY-MM-DD)`
   - If ANY criteria fail → leave it in `## In Progress`, note what specifically is missing

4. **Next task:** Identify the first item in `## Backlog` and confirm it is ready to start (no blocking dependencies)

5. **Update `docs/PROGRESS.md`:** Append a new session entry using this format:
   ```
   ## YYYY-MM-DD — Session N
   **Goal:** [what was attempted]
   **Completed:** [task IDs and brief description]
   **Blocked / Skipped:** [if any]
   **Next session:** Start at [task ID] [task name]
   **Notes:** [context to carry forward]
   ```

6. **Doc housekeeping check** — run these checks silently and include results in the sync report:
   - Scan `## Backlog` sections for any `[x]` checked items. If found, flag: "Stale [x] items in Backlog — move to Done or delete"
   - Check if all items in the current version's backlog are `[x]` or done. If so, flag: "All backlog items done — time to run `/archive` and tag a release"
   - Check if `docs/PROGRESS.md` contains sessions from a prior version (different version number than the active backlog). If so, flag: "PROGRESS.md has prior-version sessions — run `/archive`"

7. **Report to the user:**
   ```
   Sync complete.
   ✓ Marked done: [list of completed task IDs]
   ○ Still in progress: [task ID — what's missing]
   → Next task: [task ID] [task name]
   ⚠ Housekeeping: [any flags from step 6, or "clean" if none]
   ```

## Rules

- **Only mark tasks done after verifying.** Do not assume — check.
- **Do not reorder the Backlog** unless there is a blocking dependency discovered.
- **If `docs/PROGRESS.md` already has today's date**, update that entry rather than creating a new one.
- **Be concise.** The sync report should fit in 10 lines or less.
