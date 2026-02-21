---
description: Archive a shipped version — compress completed tasks and session logs into docs/archive/, reset PROGRESS.md and TODO.md Done section for the next version. Run once per version at ship time.
---

# /archive — Version Archive & Doc Reset

Run this command **when a version ships** (all backlog tasks done, release tagged on GitHub).
It compresses historical content out of the active files and into `docs/archive/`.

---

## Before Running

Confirm all of the following are true:
- [ ] All items in the current version's Backlog are `[x]` or moved to Done
- [ ] The GitHub Release for this version is tagged
- [ ] `/sync` has been run and the report shows no in-progress tasks

If any are false, do not proceed — finish the work first.

---

## Steps (in order)

### 1. Determine the version being archived
Read the most recent GitHub release tag:
```bash
git tag --sort=-version:refname | head -3
```
Use that version string (e.g., `v0.1.0`) as `{VERSION}` in the steps below.

### 2. Create the archive directory (if it doesn't exist)
```bash
mkdir -p docs/archive
```

### 3. Archive PROGRESS.md
- Copy the full current content of `PROGRESS.md` to `docs/archive/PROGRESS-{VERSION}.md`
- Reset `PROGRESS.md` to contain only the template block (the section between the `---` lines at the top), with no session entries

### 4. Archive the Done section of TODO.md
- Copy the full `## Done` section content (all `[x]` items and their notes) to `docs/archive/TODO-done-{VERSION}.md`
- Replace the `## Done` section body in `TODO.md` with a single line:
  `_v{VERSION} tasks archived to docs/archive/TODO-done-{VERSION}.md_`

### 5. Archive MVP.md (or current version spec file)
- If `MVP.md` exists in the root, move it to `docs/archive/MVP-{VERSION}.md`
- Remove `MVP.md` from the root
- If a future version has its own spec file (e.g., `SPEC-v0.2.0.md`), archive it the same way at that version's ship time

### 6. Update CLAUDE.md
- In the File Map section, change the `MVP.md` line to:
  `├── docs/archive/           ← Archived specs, progress logs, and done tasks by version`
- Remove or update the `MVP.md ← Frozen MVP spec` line since it no longer lives in root

### 7. Update TODO.md "In Progress" section
- Set the next task to be worked on (first item in the new version's backlog)

### 8. Verify
```bash
wc -l TODO.md          # Should be noticeably shorter
wc -l PROGRESS.md      # Should be < 40 lines (template only)
ls docs/archive/       # Should show the new archived files
```

### 9. Commit the archive
```bash
git add docs/archive/ TODO.md PROGRESS.md CLAUDE.md
git commit -m "chore: archive v{VERSION} docs, reset for v{NEXT_VERSION}"
```

---

## What NOT to Archive

| File | Action |
|---|---|
| CLAUDE.md | Update in place, never archive |
| DECISIONS.md | Never archive — ADRs are permanent; mark reversed ones `[SUPERSEDED]` |
| MAP.md | Remove completed version's feature section; keep future sections |
| FUTURE.md | Never archive — append-only parking lot |
| TODO.md Backlog | Keep active backlog, only clear Done section |

---

## Ongoing Cadence

This command runs **once per version**, at ship time. Between versions, `/sync` passively
monitors and will flag when archiving is due.
