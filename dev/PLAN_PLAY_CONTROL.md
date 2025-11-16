# Play/Pause Control Plan
## Auto-Play Animation for Year Layers

**Date**: 2025-11-16
**Branch**: `claude/new-menu-control-01UrKpgwLiQRvzcUWtWyAD7T`
**Base Version**: v0.9.0.2
**Target Version**: v0.9.0.3 (or defer to v0.9.1)
**Estimated Effort**: 2.5-3 hours

---

## Overview

Add play/pause button to year control menu that automatically cycles through available years at 500ms intervals. Button integrates with existing roller menu theming and year selection logic.

**Scope:** Steps 1-5 (functional play/pause, no R configuration parameters)
**Deferred:** Step 6 (R config for autoplay/speed) - can add later if needed

---

## Step 1: Add Play/Pause Button UI

### What
Add visual play/pause button element to roller menu.

### Why
Need UI control for user to trigger animation. Button must exist before adding behavior.

### Files to Modify
- `inst/controls/roller-menu.html`
- `inst/controls/roller-menu.css`

### Approach
- Add button element positioned left of year selector button
- Style to match existing banner color theme
- Use Unicode icons: ▶ (play) and ⏸ (pause)
- Circular button with banner background color

### Edge Cases
- **Small screens:** Button must not cause layout overflow
- **Long year ranges:** Button position shouldn't shift when menu content changes

### Test Checklist
- ✅ Button appears left of year selector
- ✅ Button matches banner theme colors (uses existing banner_colour tints)
- ✅ Layout doesn't break on mobile screens (<480px)
- ✅ Button displays ▶ icon initially
- ✅ Clicking does nothing yet (expected at this step)

---

## Step 2: Add Play/Pause Toggle Behavior

### What
Make button toggle between play (▶) and pause (⏸) icons when clicked.

### Why
Establish state management and visual feedback before adding actual animation. Verifies click handlers work and icon swapping functions correctly.

### Files to Modify
- `inst/controls/roller-menu.js`

### Approach
- Track playing state (boolean)
- Add click event handler to button
- Swap icon based on state
- No layer switching yet - just icon toggle

### Edge Cases
- **Rapid clicking:** Should toggle cleanly without state confusion
- **Multiple instances:** If multiple maps on page, each button should control its own map

### Test Checklist
- ✅ Click button → icon changes to ⏸
- ✅ Click again → icon changes back to ▶
- ✅ State persists correctly across rapid clicks
- ✅ No layers switch yet (expected)
- ✅ No console errors

---

## Step 3: Implement Auto-Advance Animation

### What
When play button clicked, automatically cycle through years at 500ms intervals.

### Why
Core functionality - makes the play button actually control layer visibility over time.

### Files to Modify
- `inst/controls/roller-menu.js`

### Approach
- Use timer interval (500ms per year)
- Track current position in year array
- Loop back to first year after last year
- Reuse existing `switchToYear()` function for layer control
- Clear interval when pause clicked

### Edge Cases
- **Single year dataset:** Should handle gracefully (likely disable/hide button)
- **Memory leak:** Interval must be cleared properly when paused or page unloads
- **Year display sync:** Button must show currently visible year during animation
- **Dropdown highlight:** Selected item in dropdown must update during auto-advance

### Test Checklist
- ✅ Click ▶ → layers switch every 500ms
- ✅ **Year display in button updates during play**
- ✅ **Selected item in dropdown highlights correctly during play**
- ✅ Animation loops back to first year after last year
- ✅ Click ⏸ → animation stops immediately
- ✅ Map layers actually switch (visual verification)
- ✅ Animation speed is 500ms (verify with stopwatch)

---

## Step 4: Synchronize Manual Clicks with Animation

### What
When user manually clicks a year during playback, animation should pause and resume from clicked year if restarted.

### Why
Manual interaction should take priority over auto-play. User expects to control which year is displayed.

### Files to Modify
- `inst/controls/roller-menu.js`

### Approach
- Modify year item click handlers
- Auto-pause animation when user clicks year
- Track which year was manually selected
- If play resumed, continue from that year (not where animation was)

### Edge Cases
- **Click during animation:** Animation must pause immediately, not complete current cycle
- **Click same year:** Should still pause animation
- **Dropdown open during play:** Should menu close when year selected? (Current behavior: yes, maintain this)

### Test Checklist
- ✅ Start play, let run for 2-3 years
- ✅ Manually click different year in dropdown
- ✅ Animation pauses (button icon changes to ▶)
- ✅ Clicked year becomes visible
- ✅ Click ▶ again → animation resumes from manually selected year
- ✅ Animation doesn't resume from where it was before manual click

---

## Step 5: Handle Edge Cases

### What
Robust behavior for unusual scenarios: single year, page navigation, initial state.

### Why
Prevent errors and poor UX in edge cases. Ensure cleanup happens properly.

### Files to Modify
- `inst/controls/roller-menu.js`

### Approach
- Hide play button if only 1 year available
- Clean up timer interval on page unload
- Initialize current position to match initially displayed year
- Handle case where years array is empty

### Edge Cases to Handle
- **Single year:** Play button hidden or disabled (nothing to animate)
- **Empty years:** Should not crash if no years found
- **Page navigation during play:** Timer must be cleared (prevent memory leak)
- **Initial year selection:** First click of play should start from currently visible year
- **Dynamic year loading:** If years populate late, button should appear/hide appropriately

### Test Checklist
- ✅ Load map with single year → play button hidden/disabled
- ✅ Load map with multiple years → play button visible
- ✅ Start play, navigate away from page → no console errors
- ✅ First click of play starts from currently displayed year (not always first year)
- ✅ No JavaScript errors if years array is empty

---

## Known Limitations (Acceptable for v1)

These are intentionally deferred to future enhancements:

1. **Fixed speed:** Hardcoded to 500ms (no user control)
2. **No autoplay on load:** Map always loads paused (user must click play)
3. **No reverse playback:** Only forward animation
4. **No speed controls:** Cannot adjust playback speed
5. **No progress indicator:** No visual showing position in sequence
6. **No loop mode toggle:** Always loops infinitely (no "play once" mode)

---

## Files Summary

### New Files
None - all changes to existing roller menu files

### Modified Files
- `inst/controls/roller-menu.html` - Add play button element (~5 lines)
- `inst/controls/roller-menu.css` - Style play button (~30 lines)
- `inst/controls/roller-menu.js` - Add animation logic (~70-80 lines)
- `R/quickmap.R` - No changes (just reloads updated control files)

---

## Testing Strategy

### Per-Step Testing
After each step, generate test map and verify checklist items.

### Test Script Template
```r
source("R/quickmap.R")

# Test with multiple years
map <- create_pollution_map(
  diffusion_tube_file = "wandsworth_2017_2024_no_labels.csv",
  boroughs = "Wandsworth",
  years = c(2021, 2022, 2023, 2024),
  output_file = "test_play_control.html"
)

# Test with single year (edge case)
map_single <- create_pollution_map(
  diffusion_tube_file = "wandsworth_2017_2024_no_labels.csv",
  boroughs = "Wandsworth",
  years = 2024,
  output_file = "test_play_single_year.html"
)
```

### Manual Test Checklist (After Step 5)
- [ ] Multiple years: Play button visible and functional
- [ ] Single year: Play button hidden
- [ ] Animation cycles through all years at 500ms
- [ ] Manual click pauses and repositions correctly
- [ ] Refresh page during play: no errors
- [ ] Mobile screen: button fits in layout
- [ ] Desktop screen: button styled correctly

---

## Version Control

### Commit Strategy
- Each step gets separate commit for easy rollback
- Commit messages: "Step N: [What] - [Why]"

### Example Commit Messages
```
Step 1: Add play/pause button UI - Establishes visual control for animation

Step 2: Add play/pause toggle - Icon swapping and state management

Step 3: Implement auto-advance - Core animation cycling through years

Step 4: Synchronize manual clicks - Pause on user interaction

Step 5: Handle edge cases - Single year, cleanup, initial state
```

### Version Bump Decision
After completion, decide:
- **v0.9.0.3** if minor enhancement to v0.9.0.2
- **v0.9.1** if bundling with other features

---

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Timer not cleared (memory leak) | Medium | Low | Add beforeunload cleanup, test navigation |
| Animation conflicts with manual selection | Medium | Medium | Clear testing of Step 4 behavior |
| Button breaks mobile layout | Low | Medium | Test on small screens after Step 1 |
| Single year crashes | Low | High | Explicit handling in Step 5 |
| Colors don't match theme | Low | Low | Reuse existing banner_colour system |

---

## Success Criteria

**Step 1-5 Complete When:**
- ✅ Play button visible and styled correctly
- ✅ Animation cycles through years at 500ms
- ✅ Manual clicks pause and reposition animation
- ✅ Single year datasets handled gracefully
- ✅ No memory leaks on page navigation
- ✅ All test checklists passed
- ✅ No JavaScript console errors
- ✅ Mobile and desktop layouts work

---

## Future Enhancements (Not in This Plan)

### Step 6: R Configuration Parameters (Deferred)
Add optional parameters to `create_pollution_map()`:
- `autoplay = FALSE` - Start animation on load?
- `play_speed = 500` - Milliseconds per year

**Why deferred:** Adds complexity (R→JS config injection), not essential for v1

### Other Future Ideas
- Speed control slider (0.5x, 1x, 2x)
- Reverse playback button
- Progress bar showing position
- Keyboard shortcuts (spacebar = play/pause)
- Loop once vs. infinite toggle

---

**Ready to begin Step 1?**
