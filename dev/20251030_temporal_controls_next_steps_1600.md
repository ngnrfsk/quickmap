# Temporal Controls - Future Implementation Steps
**Date**: 2025-10-30
**Project**: QuickMap v0.9.x
**Companion to**: `20251030_temporal_controls_ux_research_plan_1600.md`

---

## Overview

This document outlines detailed next steps for implementing temporal controls in QuickMap, to be executed after UX research phase completes and design decisions are made.

---

## Phase 1: Control Component Research

**Trigger**: After user selects preferred reference examples from main plan

### Step 1.1: Deep Dive on Selected Examples

**Tasks:**
1. Review selected 2-3 reference implementations in detail
2. For each example, document:
   - HTML structure (inspect source)
   - CSS approach (responsive breakpoints, styling patterns)
   - JavaScript event handling (touch, mouse, keyboard)
   - Accessibility features (ARIA, keyboard nav)
   - Mobile-specific adaptations
3. Screenshot key states (default, hover, active, mobile view)
4. Record any edge cases handled (single year, missing data, etc.)

**Time estimate**: 2-3 hours

**Deliverable**: Comparison document with code snippets and screenshots

### Step 1.2: Evaluate Control Types for Stack Compatibility

Based on user's control type preferences, assess:

**Sliders (Range Input):**
- Browser styling differences (Chrome, Firefox, Safari)
- Touch target sizing requirements
- Customization limitations and CSS workarounds
- Polyfills needed (if any)

**Play/Pause Animation:**
- Frame rate considerations
- Pause/resume state management
- Auto-advance timing patterns
- Mobile battery impact

**Timeline Scrubbers:**
- Drag handle implementation
- Track positioning calculations
- Year label placement strategies
- Responsive width handling

**Step Buttons:**
- Icon vs text buttons
- Disabled state handling (at endpoints)
- Keyboard shortcut mapping
- Touch target sizing

**Time estimate**: 1-2 hours

**Deliverable**: Technical feasibility matrix with pros/cons

### Step 1.3: Identify Code Patterns

Extract reusable patterns from research:

1. **Event Handling Pattern**
   ```javascript
   // Example structure
   slider.addEventListener('input', function(e) {
     var selectedYear = getYearFromValue(e.target.value);
     updateMapLayers(selectedYear);
   });
   ```

2. **Touch Optimization Pattern**
   ```javascript
   // Prevent map pan during slider drag
   slider.addEventListener('touchstart', function() {
     map.dragging.disable();
   });
   slider.addEventListener('touchend', function() {
     map.dragging.enable();
   });
   ```

3. **Accessibility Pattern**
   ```html
   <input type="range"
     aria-label="Select year"
     aria-valuemin="2022"
     aria-valuemax="2024"
     aria-valuenow="2024"
     aria-valuetext="Year 2024">
   ```

**Time estimate**: 1 hour

**Deliverable**: Code pattern library document

---

## Phase 2: Integration Planning

**Trigger**: After control type and layout decisions finalized

### Step 2.1: Legend + Control Layout Mockups

Create detailed ASCII/HTML mockups for selected layout option(s):

**For Each Layout:**
1. Desktop view (>1024px)
2. Tablet landscape (768-1024px)
3. Tablet portrait (768px)
4. Mobile landscape (480-767px)
5. Mobile portrait (<480px)

**Document for Each:**
- Element positioning (absolute, fixed, relative?)
- Z-index values
- Breakpoint CSS changes
- Collapsible behavior (if any)
- Padding/margins
- Width constraints

**Time estimate**: 2-3 hours

**Deliverable**: Multi-viewport mockup document

### Step 2.2: Injection Strategy

Plan how control HTML/CSS/JS will be injected into saved map files:

**Current Pattern (Banner/Legend):**
```r
# R/quickmap.R circa line 1330
html_text <- sub("(<body[^>]*>)", paste0("\\1\n", banner_html), html_text)
html_text <- sub("</body>", paste0(legend_html, "</body>"), html_text)
```

**Control Injection Options:**

**Option A: Inject with Legend**
- Pro: Single injection point
- Con: Legend and control tightly coupled

**Option B: Separate Injection**
- Pro: Clean separation of concerns
- Con: Multiple sub() calls, order matters

**Option C: Combined Layout Container**
- Pro: Flexbox wrapper controls all positioning
- Con: Bigger refactor of existing system

**Decision needed**: Which injection approach?

**Time estimate**: 1 hour

**Deliverable**: Injection code pattern with rationale

### Step 2.3: CSS Architecture

Design CSS organization for responsive control:

```css
/* Base styles */
.temporal-control { ... }

/* Component parts */
.temporal-control__slider { ... }
.temporal-control__label { ... }
.temporal-control__play-btn { ... }

/* Responsive breakpoints */
@media (max-width: 479px) { /* Mobile portrait */ }
@media (min-width: 480px) and (max-width: 767px) { /* Mobile landscape */ }
@media (min-width: 768px) and (max-width: 1024px) { /* Tablet */ }
@media (min-width: 1025px) { /* Desktop */ }

/* Touch optimization */
@media (pointer: coarse) { /* Touch devices */ }
```

**Decisions needed:**
- BEM naming convention or other?
- Inline styles vs separate `<style>` block?
- CSS custom properties (variables) for theming?

**Time estimate**: 1-2 hours

**Deliverable**: CSS template with responsive structure

---

## Phase 3: Production Implementation

**Trigger**: After mockups approved and technical plan finalized

### Step 3.1: Create Control HTML Generator Function

**Location**: R/quickmap.R (similar to `generate_legend_html()`)

```r
generate_temporal_control_html <- function(years, control_type = "slider") {
  # Generate control HTML based on:
  # - Available years (from data)
  # - Chosen control type
  # - Layout configuration

  # Returns: HTML string ready for injection
}
```

**Features to implement:**
- Dynamic year range from data
- Control type switch (slider/buttons/dropdown)
- Accessibility attributes
- Responsive classes
- Optional play/pause button

**Time estimate**: 3-4 hours

**Deliverable**: R function with documentation

### Step 3.2: Implement JavaScript Control Logic

**Location**: Injected `<script>` block in HTML

**Core Functions:**

```javascript
// 1. Initialize control
function initTemporalControl() {
  // Get cached years from window.quickmapLayerCache
  // Set up event listeners
  // Configure initial state (latest year)
}

// 2. Handle year change
function onYearChange(selectedYear) {
  // Use cached layer references
  // Hide/show layers
  // Update UI state
}

// 3. Optional: Animation playback
function playAnimation() {
  // Auto-advance through years
  // Handle pause/resume
}
```

**Time estimate**: 4-6 hours

**Deliverable**: Working JavaScript module

### Step 3.3: Responsive CSS Implementation

Implement full responsive styling based on CSS architecture plan:

**Tasks:**
1. Base component styles
2. Hover/focus/active states
3. Responsive breakpoints
4. Touch-optimized sizing
5. Dark mode support (if applicable)
6. Print styles (hide control)

**Time estimate**: 3-4 hours

**Deliverable**: Complete CSS stylesheet

### Step 3.4: Integration with Existing System

Modify `apply_custom_layout_in_html()` function:

```r
apply_custom_layout_in_html <- function(...) {
  # Existing banner injection
  # Existing legend injection

  # NEW: Temporal control injection
  if (interactive && length(years) > 1) {
    control_html <- generate_temporal_control_html(years, control_type)
    html_text <- sub("</body>", paste0(control_html, "</body>"), html_text)
  }

  # Write HTML
}
```

**Ensure:**
- Control appears in correct location
- Z-index doesn't conflict
- Mobile collapse behavior works
- Cached layers accessible to control

**Time estimate**: 2-3 hours

**Deliverable**: Integrated working system

---

## Phase 4: Testing & Refinement

**Trigger**: After initial implementation complete

### Step 4.1: Cross-Device Testing

**Test Matrix:**

| Device Type | Browser | Orientation | Tests |
|-------------|---------|-------------|-------|
| Desktop | Chrome, Firefox, Safari | N/A | Full functionality, keyboard nav |
| Tablet | Safari, Chrome | Portrait | Touch, responsive layout |
| Tablet | Safari, Chrome | Landscape | Touch, layout adaptation |
| Phone | Safari, Chrome | Portrait | Touch, collapsed states |
| Phone | Safari, Chrome | Landscape | Touch, compact layout |

**For Each Test:**
- Year switching works smoothly
- No map interaction conflicts
- Touch targets adequate (44x44px minimum)
- Text readable
- No horizontal scroll
- Orientation change handled

**Time estimate**: 3-4 hours

**Deliverable**: Test results matrix, bug list

### Step 4.2: Accessibility Audit

**WCAG 2.1 Checklist:**

- [ ] Keyboard navigation (Tab, Enter, Arrows)
- [ ] Screen reader announces year changes
- [ ] Focus indicators visible
- [ ] Color contrast meets AA standard
- [ ] No reliance on color alone
- [ ] Touch targets minimum 44x44px
- [ ] No keyboard traps
- [ ] Semantic HTML elements

**Tools:**
- Lighthouse accessibility audit
- NVDA/JAWS screen reader testing
- Keyboard-only navigation test

**Time estimate**: 2-3 hours

**Deliverable**: Accessibility compliance report, fixes

### Step 4.3: Performance Testing

**Metrics to measure:**

1. **Layer Switch Time**
   - Target: <100ms
   - Measure: Time from slider input to markers visible

2. **Initial Load Impact**
   - Control code size (aim: <10KB)
   - Additional HTTP requests (aim: 0)
   - Time to interactive delta

3. **Animation Performance** (if implemented)
   - Frame rate (target: 30fps minimum)
   - CPU usage on mobile
   - Battery impact

**Time estimate**: 1-2 hours

**Deliverable**: Performance metrics document

### Step 4.4: Edge Case Handling

**Test scenarios:**

1. **Single year dataset** - Should control hide or show disabled?
2. **Two years** - Min/max slider behavior
3. **Many years** (10+) - Slider usability, label spacing
4. **Missing years** (gaps) - Should control show gaps?
5. **Very large datasets** (200+ markers/year) - Performance acceptable?
6. **No temporal data** - Control shouldn't appear
7. **Different pollutants** - Does control work with both NO₂ and PM₂.₅?

**Time estimate**: 2-3 hours

**Deliverable**: Edge case test results, fixes

---

## Phase 5: Documentation & Deployment

**Trigger**: After testing complete, ready for production

### Step 5.1: Code Documentation

**Update files:**

1. **R/quickmap.R**
   - Function documentation (roxygen2 style)
   - Inline comments for complex logic
   - Parameter descriptions

2. **CLAUDE.md**
   - Add temporal control to "UI Enhancement System" section
   - Document configuration options
   - Note responsive behavior

3. **Create new doc**: `dev/reference/temporal_control_implementation.md`
   - Architecture overview
   - Code walkthrough
   - Customization guide
   - Troubleshooting section

**Time estimate**: 2-3 hours

**Deliverable**: Complete documentation

### Step 5.2: Create Example/Demo

**Create**: `inst/examples/temporal_control_demo.R`

```r
# Demonstrate temporal control features
# Show different configurations
# Include mobile-responsive test
# Document expected output
```

**Time estimate**: 1 hour

**Deliverable**: Working example script

### Step 5.3: Version Update

**Tasks:**
1. Update version number (0.9.x → 0.10.0?)
2. Create changelog entry
3. Archive previous version to `versions/`
4. Tag commit with version

**Time estimate**: 30 minutes

**Deliverable**: Versioned release

---

## Phase 6: Optional Enhancements

**Trigger**: After production deployment, based on user feedback

### Enhancement 1: Animation Playback

Add play/pause button with auto-advance:

**Features:**
- Play button (▶) toggles to pause (⏸)
- Configurable speed (1s, 2s, 5s per year)
- Loop option (continuous or one-pass)
- Keyboard shortcut (spacebar = play/pause)

**Time estimate**: 4-6 hours

### Enhancement 2: Year Data Availability Indicator

Show which years have data visually on timeline:

```
Year: [○ ○ ● ● ●]  ← Filled circles = data available
     2020   2024
```

**Time estimate**: 2-3 hours

### Enhancement 3: Deep Linking

URL includes selected year:

```
?year=2023  ← Load map with 2023 data displayed
```

**Time estimate**: 2-3 hours

### Enhancement 4: Transition Animations

Smooth fade in/out when switching years:

```css
.marker {
  transition: opacity 0.3s ease-in-out;
}
```

**Time estimate**: 1-2 hours

### Enhancement 5: Speed Control

For animation playback, add speed selector:

```
[▶] Speed: [1x ▼]  ← 0.5x, 1x, 2x, 4x options
```

**Time estimate**: 2-3 hours

---

## Timeline Summary

**Minimum Viable Product:**
- Phase 1-4: 25-35 hours
- Phase 5: 3-5 hours
- **Total**: 28-40 hours

**With Optional Enhancements:**
- All phases + enhancements: +40-55 hours
- **Total**: 40-60 hours

---

## Risk Mitigation

### Technical Risks

**Risk**: Browser compatibility issues with custom slider
- **Mitigation**: Use HTML5 range input (Approach 1)
- **Fallback**: Provide dropdown as alternative

**Risk**: Touch events conflict with map interactions
- **Mitigation**: Disable map drag during slider touch
- **Testing**: Early mobile device testing

**Risk**: Performance issues on older devices
- **Mitigation**: Keep animation simple, test on older iPhone
- **Fallback**: Disable animations on low-end devices

### UX Risks

**Risk**: Control placement obscures map or legend
- **Mitigation**: Multiple layout options with user testing
- **Fallback**: Collapsible control

**Risk**: Not intuitive for users unfamiliar with temporal controls
- **Mitigation**: Clear labeling, optional help tooltip
- **Fallback**: Keep radio buttons as config option?

### Project Risks

**Risk**: Timeline extends beyond available resources
- **Mitigation**: Start with MVP, phase enhancements
- **Fallback**: Stay with radio buttons for now

**Risk**: Requirements change mid-implementation
- **Mitigation**: Modular code, easy to swap control types
- **Adaptability**: Use configuration flags

---

## Success Metrics (Revisited)

How will we know if the new temporal control is better than radio buttons?

**Quantitative Metrics:**
- Time to switch between years (current vs new)
- Mobile usability score (via testing)
- Accessibility compliance score
- Load time impact (<5% increase)

**Qualitative Metrics:**
- User feedback (if collecting)
- Visual design improvement (subjective)
- Code maintainability (complexity score)

**Acceptance Criteria:**
- All tests pass
- No accessibility regressions
- Works on target browsers/devices
- Documentation complete
- Stakeholder approval

---

## Contact & Questions

**Document Owner**: Development team
**Last Updated**: 2025-10-30
**Related**: `20251030_temporal_controls_ux_research_plan_1600.md`

**For Questions:**
- Technical implementation: See `dev/reference/slider_control_technical_guide.md`
- UX decisions: Refer back to main research plan
- Testing: See Phase 4 of this document

---

**Status**: Ready for Phase 1 execution once UX research complete.
