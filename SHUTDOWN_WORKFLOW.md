# Shut-Down Workflow for quickmap Project

## Purpose
This document defines the standard workflow to follow before shutting down Cursor/closing the project. Following this checklist ensures all work is properly saved, committed, and pushed to version control.

## When to Use
- Before closing Cursor
- Before switching projects
- At the end of a coding session
- When asked "anything else to do before shut down?"

---

## Step 1: Document Current Changes

### Check for New or Modified Documentation
```bash
git status
```
**Action required if:**
- New documentation files exist (`.md` files, not yet committed)
- Existing documentation has been modified

**What to do:**
- Review changes for accuracy
- Stage relevant documentation files
- Commit with descriptive message

---

## Step 2: Review Modified Code Files

### Check Git Status for Modified Files
```bash
git status
git diff [filename]
```

**For each modified file:**
- [ ] Read the diff to understand changes
- [ ] Categorize changes:
  - Bug fix
  - New feature
  - Refactoring/formatting
  - Documentation update
  - [ ] Decide: commit, discard, or leave for later
- [ ] If the main code body has been updated: duplicate it to the versions folder with filename tracking the version
  ```bash
  # Example: if version is 0.8.11, copy to quickmap_0_8_11.R
  VERSION=$(grep "^# Version" quickmap.R | head -1 | awk '{print $3}')
  VERSION_FILE=$(echo "quickmap_${VERSION}.R" | sed 's/\./_/g')
  cp quickmap.R "versions/${VERSION_FILE}"
  ```

### Common Scenarios

**Scenario A: Work is complete and tested**
```bash
git add [files]
git commit -m "Descriptive commit message"
git push
```

**Scenario B: Work in progress, want to save**
```bash
git add [files]
git commit -m "WIP: brief description"
git push
```

**Scenario C: Changes are incomplete/experimental**
- Leave unstaged for next session
- OR commit with `WIP:` prefix
- OR stash changes: `git stash save "description"`

**Scenario D: Unwanted changes (formatting only, accidental edits)**
```bash
git restore [filename]  # Discard changes
```

---

## Step 3: Check for Untracked Files

### Temporary Files
```bash
git status
```
**Look for:**
- Backup files (`.parachute`, `.bak`, `.old`)
- IDE cache files
- Temporary scripts

**Action:**
- If temporary: delete them
- If important: commit or add to `.gitignore`

### New Important Files
Ending in: `.md`, `.R`, `.csv`, `.txt`
- Review and decide if they should be committed
- If yes: add to repository with documentation
- If no: add to `.gitignore`

---

## Step 4: Verify Push Status

### Check if Local is Ahead of Remote
```bash
git status
```

**Look for:**
```
Your branch is ahead of 'origin/main' by X commit(s).
```

**If present:**
```bash
git push
```

**Verify success:**
```bash
git status  # Should show "up to date with 'origin/main'"
```

---

## Step 5: Final Verification

### Clean Working Tree Check
```bash
git status
```

**Expected output:**
```
On branch main
Your branch is up to date with 'origin/main'.

nothing to commit, working tree clean
```

**If not clean:**
- Review remaining unstaged changes
- Decide: commit, stash, or discard
- See scenarios in Step 2

---

## Step 6: Summary Report

Before shutdown, provide a brief summary:

**Example:**
```
Session Summary:
- ✓ Committed parameter documentation (PARAMETER_REFERENCE.md)
- ✓ Committed refactoring proposals (PARAMETER_REFACTORING_PROPOSALS.md)
- ✓ Updated version to 0.8.11
- ✓ Fixed Richmond palette colors
- ✓ All changes pushed to origin/main
- ✓ Working tree clean - ready for shutdown
```

---

## Common Git Patterns Used

### Push New Branch (First Time)
```bash
git push --set-upstream origin main
# or
git push -u origin main
```

### Update Existing Branch
```bash
git push
```

### Stash Work in Progress
```bash
git stash save "descriptive message"
```

### Discard Local Changes
```bash
git restore [filename]
```

### View What Will Be Committed
```bash
git diff --staged
```

---

## Red Flags - Do NOT Shut Down If:

❌ Uncommitted changes with message "TODO: review this"
❌ Local commits not pushed to remote
❌ Git status shows merge conflicts
❌ Untracked important files (documentation, scripts)
❌ Recent changes not tested or reviewed
❌ Broken code committed (failing tests)

**Action if red flags present:**
1. Document what needs attention
2. Add to task list or create GitHub issue
3. Either fix now OR commit with clear "WIP:" message
4. Push to remote for backup

---

## Backup Strategy

**Before shutdown, ensure:**
- [ ] All work is pushed to GitHub (remote backup)
- [ ] Important documents copied to iCloud Drive (if needed)
- [ ] Any work files saved (not tempan>
ary)

**How to copy to iCloud Drive:**
```bash
cp [filename] ~/Library/Mobile\ Documents/com~apple~CloudDocs/
```

---

## Integration with Claude/Cursor

### How to Use This Workflow

**Option 1: Manual Reference**
- Say: "Follow the shutdown workflow in SHUTDOWN_WORKFLOW.md"
- Claude will read this file and execute the steps

**Option 2: Automatic Trigger**
- Say: "anything else to do before shut down?"
- This is the trigger phrase for this workflow
- Claude should:
  1. Read `SHUTDOWN_WORKFLOW.md`
  2. Execute `git status`
  3. Follow each step
  4. Report summary

### Making This Document "Executable"

**For Claude:**
When you say "follow the shutdown workflow" or "prepare for shutdown", Claude will:
1. Read `SHUTDOWN_WORKFLOW.md`
2. Execute each git command
3. Review results
4. Ask for decisions on any ambiguities
5. Provide final summary

**Modify this file to:**
- Add project-specific steps
- Include custom validation rules
- Reference other important files
- Define what "clean shutdown" means for this project

---

## Example Session Closure

**User:** "anything else to do before shut down?"

**Claude should respond:**
1. Run `git status`
2. Check for modified/new files
3. Review diffs if needed
4. Ask about each change
5. Commit/push as appropriate
6. Verify clean working tree
7. Provide summary
8. Confirm ready for shutdown

**Expected outcome:**
```
✓ Working tree clean
✓ All commits pushed to origin/main
✓ No untracked important files
✓ Ready for shutdown
```

---

## Version History

- v1.0 (2024-10-25): Initial workflow based on session closure experience

---

## Notes

- This workflow is specific to quickmap project
- Adapt for other projects as needed
- Update as new patterns emerge
- Review periodically to ensure it remains current

