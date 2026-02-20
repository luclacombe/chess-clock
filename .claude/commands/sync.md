# /sync — Session Progress Review

Run this command at the **start and end of every development session**.

## Steps to Follow (in order)

1. **Read `TODO.md`** — identify every item currently marked as `in_progress` or recently worked on

2. **For each in-progress item**, check its acceptance criteria:
   - Run the listed `Verify:` command if one is specified
   - Check if the files mentioned in the criteria actually exist and are non-empty
   - Check git status to see what was actually changed

3. **Determination:**
   - If ALL criteria pass → move the item from `## In Progress` to `## Done` in `TODO.md`, adding the completion date in the format `(completed YYYY-MM-DD)`
   - If ANY criteria fail → leave it in `## In Progress`, note what specifically is missing

4. **Next task:** Identify the first item in `## Backlog` and confirm it is ready to start (no blocking dependencies)

5. **Update `PROGRESS.md`:** Append a new session entry using this format:
   ```
   ## YYYY-MM-DD — Session N
   **Goal:** [what was attempted]
   **Completed:** [task IDs and brief description]
   **Blocked / Skipped:** [if any]
   **Next session:** Start at [task ID] [task name]
   **Notes:** [context to carry forward]
   ```

6. **Report to the user:**
   ```
   Sync complete.
   ✓ Marked done: [list of completed task IDs]
   ○ Still in progress: [task ID — what's missing]
   → Next task: [task ID] [task name]
   ```

## Rules

- **Only mark tasks done after verifying.** Do not assume — check.
- **Do not reorder the Backlog** unless there is a blocking dependency discovered.
- **If PROGRESS.md already has today's date**, update that entry rather than creating a new one.
- **Be concise.** The sync report should fit in 10 lines or less.
