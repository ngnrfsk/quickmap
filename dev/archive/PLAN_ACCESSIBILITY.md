# Accessibility Enhancement Plan for animation and menu controls
## Keyboard Navigation + Screen Reader Support

**Date**: 2025-11-16
**Branch**: `claude/new-menu-control-01UrKpgwLiQRvzcUWtWyAD7T`
**Base Version**: v0.9.0.2 + quick wins
**Estimated Effort**: 3 hours

---

## Context
- Animation controls have been added to the year selector menu control in the quickmap mapping suite. The animation and menu controls work well but lack accessibility features. The controls are contained in
### Files
- `inst/controls/roller-menu.html` - Add aria attributes
- `inst/controls/roller-menu.css` - Add focus styles
- `inst/controls/roller-menu.js` - Add keyboard handlers

## Final Objective
Add full keyboard navigation and basic screen reader support to year control menu.

**Intermediate Objectives**
- Create Full keyboard support (Space, Enter, Escape, Arrow keys)
- Add basic ARIA accessibility features with dynamic labels

**Why:**
- Keyboard controls helpful to all users (analysts, power users)
- Tables provide accessible alternative (map doesn't need full ARIA compliance)
- Basic screen reader labels provide context without over-engineering

## Approach - Take small, testable incremental steps towards goal
- Intermediate tasks will be executed one step at a time
- At the end of each Step, push code, asks user to pull/download locally to test code
- Wait for user feedback on Step
- Only proceed to next step when instructed to do so by user.

**Scope:**
- Work only on the code objectives stated in each Step, checking for errors or dependencies, but NO elaboration on instructions.



---

## Step 0: Branch and commit to start from
- branch https://github.com/ngnrfsk/quickmap/tree/claude/new-menu-control-01UrKpgwLiQRvzcUWtWyAD7T
- commit 686e174
- Create branch accessible_animation from commit **686e174**

---

## Step 1: Space/Enter on Buttons

**Scope**: Work only on the code objectives stated in this Step, checking for errors or dependencies, but NO elaboration on instructions.

### What
Space and Enter keys trigger play/pause and dropdown toggle.

### Files
- `inst/controls/roller-menu.js`

### Approach
Add keydown handlers:
- Play button: Space/Enter → toggle
- Year button: Space/Enter → open/close dropdown

### Test
- ✅ Tab to play button, press Space → toggles
- ✅ Tab to year button, press Enter → opens dropdown
- ✅ No page scroll when Space pressed on buttons

---

## Step 2: Escape to Close

**Scope**: Work only on the code objectives stated in this Step, checking for errors or dependencies, but NO elaboration on instructions.

### What
Escape key closes dropdown from anywhere.

### Files
- `inst/controls/roller-menu.js`

### Approach
Add document-level keydown listener for Escape.

### Edge Cases
- Only close if dropdown is open
- Don't interfere with browser defaults

### Test
- ✅ Open dropdown, press Escape → closes
- ✅ Escape when closed → no effect
- ✅ Works from any focused element

---

## Step 3: Arrow Key Navigation

**Scope**: Work only on the code objectives stated in this Step, checking for errors or dependencies, but NO elaboration on instructions.

### What
Arrow Up/Down navigate years in dropdown, apply selection.

### Files
- `inst/controls/roller-menu.js`

### Approach
When dropdown open:
- Arrow Down → next year
- Arrow Up → previous year
- Enter → apply and close
- Track keyboard focus separately from mouse hover

When dropdown closed:
- Arrow Up/Down → cycle years directly (no open)

### Edge Cases
- First item + Up → wrap to last
- Last item + Down → wrap to first
- Prevent page scroll when arrows pressed

### Test
- ✅ Open dropdown, press Down 3 times → highlights move
- ✅ Press Enter → applies year and closes
- ✅ Dropdown closed, press Up → changes year directly
- ✅ No page scroll during navigation

---

## Step 4: Focus Management

**Scope**: Work only on the code objectives stated in this Step, checking for errors or dependencies, but NO elaboration on instructions.

### What
Visible focus indicators and proper focus flow.

### Files
- `inst/controls/roller-menu.css`
- `inst/controls/roller-menu.js`

### Approach
CSS: Add :focus-visible styles
JS: Return focus to button after dropdown closes

### Test
- ✅ Tab shows focus indicator on buttons
- ✅ Close dropdown → focus returns to year button
- ✅ Focus indicators visible but not distracting

---

## Step 5: Basic ARIA Labels

**Scope**: Work only on the code objectives stated in this Step, checking for errors or dependencies, but NO elaboration on instructions.

### What
Add aria-label and aria-pressed to buttons.

### Files
- `inst/controls/roller-menu.html`
- `inst/controls/roller-menu.js`

### Approach
HTML: Static aria-label on year button
JS: Dynamic aria-label and aria-pressed on play button

### Test
- ✅ Screen reader announces "Play animation" / "Pause animation"
- ✅ aria-pressed updates when playing/paused

---

## Step 6: ARIA Expansion State

**Scope**: Work only on the code objectives stated in this Step, checking for errors or dependencies, but NO elaboration on instructions.

### What
Update aria-expanded when dropdown opens/closes.

### Files
- `inst/controls/roller-menu.html`
- `inst/controls/roller-menu.js`

### Approach
HTML: Add aria-expanded="false" to year button
JS: Toggle aria-expanded on open/close

### Test
- ✅ Screen reader announces expanded/collapsed state

---

## Implementation Notes

**Key Variables:**
- `keyboardFocusIndex` - track which year item has keyboard focus
- Separate from mouse `.selected` class

**Focus Logic:**
- Mouse: Highlights on hover, selects on click
- Keyboard: Highlights on arrow, selects on Enter
- Both: Update same visual state

**Prevent Conflicts:**
- `e.preventDefault()` on Space to prevent page scroll
- Check if dropdown open before handling arrow keys

---

## Test Checklist (All Steps)

### Keyboard
- [ ] Tab through controls (play → year → year items)
- [ ] Space on play button toggles
- [ ] Space on year button opens/closes
- [ ] Escape closes dropdown
- [ ] Arrow Up/Down in dropdown navigates
- [ ] Enter on dropdown item applies year
- [ ] Arrow Up/Down when closed changes year
- [ ] No page scrolling during keyboard use
- [ ] Focus visible on all interactive elements

### Screen Reader
- [ ] Play button announces purpose and state
- [ ] Year button announces current year
- [ ] Dropdown expansion announced
- [ ] Year changes announced (via aria-label update)

### Edge Cases
- [ ] Keyboard + mouse work together
- [ ] Single year mode (keyboard shortcuts disabled)
- [ ] Large year range (25+ years, arrow navigation useful)

---

## Success Criteria

- Full keyboard control without mouse
- Screen readers announce button purposes and states
- No interference with existing mouse/touch interactions
- Follows standard UI patterns (Space, Escape, Arrows)
