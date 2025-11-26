# Template for Drafting Step-by-Step Coding Plan

## Context - describe the context under this header
- Ideally in one succinct line. Example: A proof of concept HTML control for layer visibility in a leaflet map has been created. This correctly controls layer visibility for a limited set of cases.

## Final Objective - describe under this header
- Clear statment of final objective. Example: "Adapt proof of concept code into a flexible, mobile/touch friendly, expanding/collapsing menu control with styling that uses the years data supplied in a function call

## Set out approach as follows: Take small, testable incremental steps towards goal
- Intermediate tasks will be executed one step at a time
- At the end of each Step, push code, asks user to pull/download locally to test code
- Wait for user feedback on Step
- Only proceed to next step when instructed to do so by user.

## Scope - describe under this header, keep it strict and limited to avoid hallucinations
- **Must Include:** Work only on the code objectives stated in each Step, checking for errors or dependencies, but NO elaboration on instructions.



## DESCRIBE STEPS, in small, testable incremental steps towards goal

EACH STEP MUST SPECIFY

- Restate constraint of scope

- State outcome required

- Include any subsidiary What or Why outcomes, but not How - write NO code

- Keep concepts simple, avoid verbose documentation or over-engineering

- Describe user testing step

  ## Example steps:

### STEP 0: Starting Point (example only)

- Branch: Create branch **example_branch_name** from commit **example commit 53a1db1**
- Base proof of concept code: **Example:** Slider control at `R/quickmap.R` lines 1335-1463 marked with `# PROOF OF CONCEPT: HTML5 slider for year selection`


### STEP 1: Extract and Encapsulate Control Code (example only)

**Scope**: Work only on the code objectives stated in this Step, checking for errors or dependencies, but NO elaboration on instructions.

**Outcome:** Slider control code moved from inline in R file to separate reusable files

**What must exist after this step:**
- Directory: `inst/controls/`
- File: `inst/controls/roller-menu.html` containing the HTML structure
- File: `inst/controls/roller-menu.css` containing all styling
- File: `inst/controls/roller-menu.js` containing all JavaScript behavior
- Modified `R/quickmap.R` with new helper function that reads these files and injects them into the output HTML
- Old inline code (lines 1335-1463) replaced with call to helper function

**User will test:** Slider works exactly as before

---

### STEP 2: Move Control to Bottom-Right (example only)

**Scope**: Work only on the code objectives stated in this Step, checking for errors or dependencies, but NO elaboration on instructions.

**Outcome:** Control repositioned from bottom-center to bottom-right corner

**What must change:**
- CSS positioning updated to place control at bottom-right (15px from bottom and right edges)

**User will test:** Slider appears at bottom-right corner, functions normally

---

### STEP 3: Replace Slider with Collapsible Menu (example only)

**Scope**: Work only on the code objectives stated in this Step, checking for errors or dependencies, but NO elaboration on instructions.

**Outcome:** Slider input replaced with button that shows/hides year list

**What must exist:**
- Collapsed state: Button showing currently selected year with dropdown arrow
- Expanded state: List of all available years (initially hidden)
- Click on button toggles between collapsed/expanded
- Click outside menu closes it
- No layer switching yet - just UI behavior

**User will test:** Menu opens and closes, displays all years

---

### STEP 4: Add Scroll for Long Lists (example only)

**Scope**: Work only on the code objectives stated in this Step, checking for errors or dependencies, but NO elaboration on instructions.

**Outcome:** Menu handles many years without growing too large

**What must exist:**
- Menu shows maximum 6 years at once
- If more than 6 years, scrollbar appears
- If 6 or fewer years, no scrollbar

**User will test:** With 8+ years, menu scrolls; with fewer years, no scroll

---

### STEP 5: Wire Up Layer Switching (example only)

**Scope**: Work only on the code objectives stated in this Step, checking for errors or dependencies, but NO elaboration on instructions.

**Outcome:** Clicking a year in menu changes which map layers are visible

**What must happen:**
- Clicking year in menu switches map layers (use existing layer switching logic from slider)
- Selected year updates in collapsed button
- Menu closes after selection
- Map shows correct layers for selected year

**User will test:** Clicking different years changes map layers correctly

---

### STEP 6: Apply Visual Polish (example only)

**Scope**: Work only on the code objectives stated in this Step, checking for errors or dependencies, but NO elaboration on instructions.

**Outcome:** Menu looks professional and matches map aesthetic

**What must exist:**
- Colors and fonts consistent with existing map controls
- Hover effects on menu items
- Visual indication of currently selected year in list
- Professional appearance

**User will test:** Menu looks polished and fits with map design

---

## After Each Step

1. Agent commits changes
2. Agent pushes to `origin/[branch_name]`
3. Agent tells user: "Step X complete, pushed to origin/[branch name]"
4. User pulls code locally, tests, reports results
5. If pass: user asks for next step
6. If fail: user describes issue, agent fixes in same chat

---

## Add Notes for Agent

- Reuse existing code wherever possible, don't rewrite exisint logic
- Keep changes small and focused on the step objective
- Stop after completing each step and wait for user feedback
- Base the code on working code at [example: commit 53a1db1 ]
