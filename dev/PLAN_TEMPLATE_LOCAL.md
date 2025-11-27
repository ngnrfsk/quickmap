# Template for Drafting Step-by-Step Coding Plan

## Context

One sentence. Current problem, why it needs fixing.

## Final Objective

One sentence. What must be true when complete.

## Approach

Incremental steps, commit-test-approve workflow, code review checkpoints.

## Scope

**Must Exclude:** \[List things NOT to change\]

## Lessons from previous work

-   **Avoid line numbers** - brittle after edits
-   **Design data schemas upfront** - extensibility fields from start, not minimal-then-expand
-   **Avoid prescribing names** - let Claude choose parameters/functions but make them meaningful
-   **State "what" not "how"** - outcomes, not implementation steps
-   **Avoid documentation and code bloat** - no cat statements in user scripts, aim for 1-2 line in-line code comments, reports to user no longer than 250 words, record essential information for future steps, analysis or work, no fluff, no hallucinating, 
- **Always ask user to resolve ambigutity, never guess, infer or hallucinate instructions** Where instructions have any ambigutity, concisely escalate this to the user for claification using multiple choice questions

------------------------------------------------------------------------

## STEP 0: Architecture Discovery

**Outcome:** Document all coupling points

**What to do:** - Grep for all references to entities being refactored - Identify hardcoded assumptions - Document in dev/ANALYSIS\_\[feature\].md

**User will test:** Review architecture analysis, approve approach

------------------------------------------------------------------------

## STEPS 1-N: Implementation Steps

**Format per step:**

**Scope:** Work only on objectives stated, check errors/dependencies, no elaboration

**Outcome:** \[One sentence - testable result\]

**What must exist:** - \[Bulleted requirements - WHAT, not HOW\]

**User will test:** \[Specific test cases\]

------------------------------------------------------------------------

### Example: STEP 1..2..5..8 etc

**Scope:** Work only on objectives stated, check errors/dependencies, no elaboration

**Outcome:** Control code extracted to separate reusable files

**What must exist:** Examples: - Directory `inst/controls/` with HTML/CSS/JS files - Helper function loads and injects control - Old inline code removed - Function that delivers these outcomes that interfaces to those from Step X or Y

**User will test:** Control works identically to before

------------------------------------------------------------------------

## MID-POINT: Code Review Checkpoint

**After core refactoring (typically Step 3-5):** - Run automated code review agent - Address critical/major issues before proceeding - Ensures architecture correct before building on it

------------------------------------------------------------------------

## FINAL STEPS

### Code Cleanup

**Outcome:** Remove dead code, add minimal docs **What must exist:** - No unused code remains - Roxygen2 for new functions - 5-line change note in dev/change_notes/

### Validation

**Outcome:** All tests pass, visual regression check **User will test:** - All existing test scripts pass - Visual comparison with previous version - New feature works via test script

------------------------------------------------------------------------

## After Each Step

1.  Claude confirms: "Step X complete. Changed: \[files\]. Tests: \[passed/failed\]. Proceed to Step Y?"
2.  Claude commits + pushes to branch
3.  User pulls, tests locally, responds: "proceed" or "fix X"

------------------------------------------------------------------------

## Notes for Agent

**What to do:** - Reuse existing patterns, don't rewrite working code - Focus only on step objective - Run smoke test after each step (`Rscript tests/test_quickmap.R`) - Stop and wait for user approval before next step - Explicitly confirm current step number - Keep all documentation concise, describe only essentials in minimum possible words

**What NOT to do:** - Prescribe parameter/function names unless critical - Reference line numbers (brittle) - Design minimal schemas that need expansion later - Combine steps even if related

**Follow Code Minimalism Rules**

_Avoid:_
- cat() in user scripts
- Redundant validation (env vars, parameters already checked downstream)
- Obvious comments
- Try-catch around operations that should fail
- Single-use helpers/wrappers
- Success messages

_Do:_
- Trust R's errors
- Let functions fail naturally
- Write self-evident code
- Ensure map titles and file names contain test information e.g. v093 or title = "this should show 4 networks" etc