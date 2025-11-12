---
output: html_document
css: Bear.css
---

# Temporal Controls UX Research Plan

**Date**: 2025-10-30 **Project**: QuickMap v0.9.x - Year Selection Control Enhancement **Status**: User Selection Phase

------------------------------------------------------------------------

## Overview

Research best practices for temporal controls in Leaflet-based web maps. Goal: Replace radio button year selector with modern, intuitive control compatible with our stack (Leaflet/HTML5/JS/R).

**Context**: Proof of concept validated. Implementation awaiting UX design decisions.

------------------------------------------------------------------------

## 1. Reference Implementations - Modern, Elegant Temporal Controls

Research high quality designs for HTML5/CSS temporal controls for the user to review, especially those for maps on dynamic websites for mobile, tablet and desktop.

### ⭐ Top Pick: Circular Progress Bars

-   **Dossena's Circular Progress Bars for HTML5** 🏆
    -   URL: <https://fdossena.com/?p=html5cool/radprog/i.frag>
    -   Type: Interactive circular progress indicators using HTML5 Canvas
    -   Stack: Pure JavaScript, \<4KB, IE9+ compatible
    -   Features: Interactive via `setValue()`, customizable colors/thickness, spinning animations, scales with font-size
    -   Mobile: ✅ Fully responsive and touch-friendly
    -   Notes: **Top example** - mimics Windows 10 style, highly customizable
    -   **Potential uses**: Visual year indicator, interactive year picker, animation progress display

### Circular Progress & Date Picker Examples

-   **Circular Date Picker (CodePen - yuezk)**
    -   URL: <https://codepen.io/yuezk/pen/pvbGrX>
    -   Type: Ring-based interactive date picker with year/month/day selection
    -   Stack: Pure CSS + JavaScript
    -   Mobile: ✅ Touch-friendly circular interface
    -   Notes: Shows how circular UI can handle discrete value selection

-   **`REJECTED OVER COMPLEX - Circular Progress with Range Slider (CodePen - Tomik23)**
    -   URL: <https://codepen.io/Tomik23/pen/GRpMZBz>
    -   Type: Hybrid - circular progress bar controlled by linear range slider
    -   Stack: HTML5 + CSS + Vanilla JS
    -   Notes: Demonstrates combining circular visual with linear control

-   **Rejected to simplistic Material Design Circular Progress (CodePen - finnhvman)**
    -   URL: <https://codepen.io/finnhvman/pen/bmNdNr>
    -   Type: Pure CSS single-element circular progress
    -   Stack: CSS only (no JavaScript)
    -   Mobile: ✅ Lightweight and responsive
    -   Notes: Elegant Material Design aesthetic

-   GOOD CONCEPT COULD IT BE COMBINED IWTH CIRCULAR DATE PICKER? **CSS Script: Circular Countdown Timer**
    -   URL: <https://www.cssscript.com/circular-countdown-timer-javascript-css3/>
    -   Type: Animated countdown with circular progress
    -   Stack: JavaScript + CSS3
    -   Notes: Good for timed animations/playback

### Modern Range Slider Collections

-   too wide - **uiCookies: 35 Interactive Range Slider Designs**
    -   URL: <https://uicookies.com/range-slider-css/>
    -   Type: Curated collection of modern, elegant range sliders
    -   Features: Animated scales, custom styling, tooltips
    -   Mobile: ✅ Touch-optimized designs
    -   Notes: Flat design aesthetics, ready-to-use code
-   Some really good ones in here** **WP Dean: 40 CSS Range Slider Examples**
    -   URL: <https://wpdean.com/css-range-slider/>
    -   Type: Range slider gallery with various styles
    -   Features: Custom CSS styling, cross-browser compatible
    -   Notes: Includes minimalist and elaborate designs
    -   **Soft dial is really interesting** 
        -   https://codepen.io/chrisgannon/pen/yLQyeEy
-   **FreeFrontend: 35 CSS Range Sliders**
    -   URL: <https://freefrontend.com/css-range-sliders/>
    -   Type: Pure CSS and CSS+JS slider implementations
    -   Features: Dynamic styling, tooltips, animations
    -   Notes: Performance-optimized with CSS transforms
-   **Slider Revolution: CSS Range Slider Templates**
    -   URL: <https://www.sliderrevolution.com/resources/css-range-slider/>
    -   Type: Professional range slider implementations
    -   Features: Custom styling over browser defaults, polished UI
    -   Notes: Demonstrates transforming basic HTML5 into elegant controls

### Timeline Control Collections

-   **FreeFrontend: 90 CSS Timelines**
    -   URL: <https://freefrontend.com/css-timelines/>
    -   Type: Extensive timeline design collection
    -   Stack: Pure CSS and CSS+JS options
    -   Features: Vertical, horizontal, minimalist, animated designs
    -   Mobile: ✅ Many responsive options
    -   Notes: Includes sticky positioning techniques
    -   **Possible solution - Wheel timeline, maybe quartered?**
        -   https://codepen.io/cbolson/pen/vEBWwxL
    
-   **CSS Script: 10 Best Timeline Generators**
    -   URL: <https://www.cssscript.com/best-timeline/>
    -   Type: Vanilla JavaScript timeline libraries
    -   Stack: No jQuery, pure JavaScript
    -   Features: Horizontal/vertical orientations, responsive
    -   Notes: Suitable for our no-dependency requirement

-   **DevSnap: 110+ CSS Sliders**
    -   URL: <https://devsnap.me/css-sliders/>
    -   Type: Comprehensive slider collection
    -   Features: Full-width, thumbnail filmstrips, play/pause buttons
    -   Notes: Includes animation controls inspiration

### Leaflet-Compatible Plugins

-   **Leaflet.TimeDimension**
    -   URL: <https://github.com/socib/Leaflet.TimeDimension>
    -   Demo: <http://apps.socib.es/Leaflet.TimeDimension/examples/>
    -   Type: Timeline slider with play/pause for temporal data
    -   Stack: Leaflet plugin (pure JS)
    -   Features: Animation controls, time range selection
    -   Notes: Full-featured but heavier, good reference for features

-   **Leaflet-timeline**
    -   URL: <https://github.com/skeate/Leaflet-timeline>
    -   Demo: <https://skeate.github.io/Leaflet-timeline/>
    -   Type: Interval-based timeline slider
    -   Stack: Vanilla JS, no dependencies
    -   Notes: Lightweight, good for discrete time periods like years

-   **Leaflet.Sync + Custom Time Controls**
    -   URL: <https://github.com/jieter/Leaflet.Sync>
    -   Example: <https://labs.mapbox.com/bites/00304/>
    -   Type: Synced maps with shared custom control
    -   Stack: Pure Leaflet + custom HTML/JS
    -   Notes: Shows integration pattern for custom controls

### Air Quality / Environmental Reference Maps

-   **OpenAQ Platform**
    -   URL: <https://openaq.org/>
    -   Map: <https://explore.openaq.org/>
    -   Type: Date range selector (dropdown-based)
    -   Stack: Leaflet + React
    -   Notes: Clean, minimal design, mobile-friendly

-   **PurpleAir Map**
    -   URL: <https://map.purpleair.com/>
    -   Type: Time selection dropdown + live toggle
    -   Stack: Leaflet + custom controls
    -   Notes: Simple approach, works well on mobile

### Additional HTML5/CSS3 Resources

-   **CodeHim HTML5/CSS3 Gallery**
    -   URL: <https://codehim.com/category/html5-css3/>
    -   Type: Curated code snippet collection
    -   Categories: Progress bars (5), countdown timers (6), digital clocks (10), analog clocks (5), timelines (5)
    -   Notes: 50+ temporal/animation-related snippets

**📌 USER ACTION REQUIRED:** Review the URLs above. Select **2-3 examples** that best match your vision for QuickMap's temporal control. Note which specific features appeal to you (slider type, play button, positioning, mobile behavior, circular vs linear, etc.).

------------------------------------------------------------------------

## 2. Control Type Comparison - Comprehensive Matrix

### Main Control Types

| Type | Description | Pros | Cons | Mobile | Implementation |
|------|-------------|------|------|--------|----------------|
| **HTML5 Range Slider** | `<input type="range">` | Native, accessible, lightweight, keyboard support | Limited styling, basic UX | ✅ Touch-friendly | 8-12 hrs |
| **Custom Linear Slider** | JS-powered track/handle | Full styling control, smooth animations | More code, testing needed | ⚠️ Touch handling | 15-20 hrs |
| **Timeline Bar** | Video player style scrubber | Familiar UX, good for many years, cinematic | Takes vertical space | ⚠️ Can be cramped | 12-18 hrs |
| **Step Buttons** | Prev/Next + year indicator | Simple, clear, reliable | Less direct than slider | ✅ Large touch targets | 6-8 hrs |
| **Dropdown Select** | Native `<select>` menu | Compact, accessible, native UI | Less visual, no scrubbing | ✅ Native mobile | 4-6 hrs |
| **Play/Pause Animation** | Auto-advance through years | Engaging, storytelling, dynamic | Complexity, battery concern | ✅ Works well | +4-6 hrs (addon) |

### Circular Progress Bar Options 🆕

| Type | Description | Pros | Cons | Mobile | Implementation |
|------|-------------|------|------|--------|----------------|
| **Canvas Circular Progress** | Interactive HTML5 Canvas ring | Elegant, highly customizable, smooth | Canvas drawing overhead | ✅ Touch + responsive | 12-16 hrs |
| **CSS Circular Progress** | Pure CSS conic-gradient | Lightweight, no JS for display | Limited interactivity | ✅ Very lightweight | 8-10 hrs |
| **Circular Date Picker** | Ring-based year selector | Unique UX, space-efficient | Learning curve for users | ⚠️ Gesture handling | 18-24 hrs |
| **Hybrid Circular + Linear** | Circular visual + linear slider | Best of both worlds, intuitive | More complex layout | ✅ Dual interface | 20-25 hrs |

### Circular Progress Use Cases - Detailed Exploration

**Use Case 1: Visual Indicator (Decorative Enhancement)**
- **Concept**: Circular progress shows which year is selected, linear slider for control
- **Example**: Dossena's progress bar paired with HTML5 range input
- **Pros**: Elegant visual feedback, doesn't change interaction model
- **Cons**: Adds complexity for purely aesthetic benefit
- **Best for**: Desktop/tablet where space allows dual controls

**Use Case 2: Interactive Year Selector (Primary Control)**
- **Concept**: User clicks/drags around circle to select year
- **Example**: Circular date picker adapted for discrete years
- **Pros**: Novel UX, space-efficient, works well for 3-8 years
- **Cons**: Less intuitive than linear slider, harder on small screens
- **Best for**: Mobile-first designs, maps with few years

**Use Case 3: Animation Progress Display**
- **Concept**: Circle fills as animation plays through years
- **Example**: Circular countdown timer style
- **Pros**: Clear visual of playback progress, elegant
- **Cons**: Only useful if implementing play/pause feature
- **Best for**: Storytelling maps, presentations

**Use Case 4: Hybrid - Indicator + Playback**
- **Concept**: Circle shows current year + animation progress, separate slider for scrubbing
- **Example**: Like video player (circular = current time, bar = scrub)
- **Pros**: Rich information, supports both modes
- **Cons**: Complex UI, takes more space
- **Best for**: Feature-rich dashboards

**Use Case 5: Concentric Rings (Advanced)**
- **Concept**: Multiple rings for year/month/day or data layers
- **Example**: Nested circular pickers
- **Pros**: Handles hierarchical time selection
- **Cons**: Very complex, high learning curve
- **Best for**: Specialized scientific/research tools

### Comparison Summary

**Most Elegant**: Hybrid circular + linear, Canvas circular progress
**Easiest to Implement**: HTML5 range slider, dropdown select
**Best Mobile UX**: HTML5 range slider, step buttons, dropdown
**Most Unique**: Circular date picker, hybrid indicator + playback
**Best for QuickMap** (recommendation): HTML5 range slider + optional circular visual indicator

**📌 USER ACTION REQUIRED:**
1. Which control type(s) interest you most? Rank top 3 preferences
2. For circular progress: which use case(s) appeal to you?
   - [ ] Use Case 1: Visual indicator
   - [ ] Use Case 2: Interactive selector
   - [ ] Use Case 3: Animation progress
   - [ ] Use Case 4: Hybrid indicator + playback
   - [ ] Use Case 5: Advanced concentric rings
   - [ ] None - prefer linear controls only

------------------------------------------------------------------------

## 3. Create layout options that integrate both animation controls and the legend 

### Option A1: Integrated Legend Panel (Vertical Stack)

```
┌────────────────────────┐
│  Banner: Air Quality   │
├────────────────────────┤
│                        │
│    Map Area            │
│                        │
│    ┌─Legend Panel────┐ │
│    │ NO₂ Scale       │ │
│    │ ▓▓▓▓▓▓▓▓▓▓▓▓▓  │ │
│    │ ────────────────│ │
│    │ Year: 2024      │ │
│    │ ═══○═══════     │ │  ← Slider integrated
│    │    2022   2024  │ │
│    └─────────────────┘ │
└────────────────────────┘
```

**Pros**: Consolidated UI, single panel, clear hierarchy
**Cons**: Legend may get tall on mobile, vertical space usage
**Best for**: Desktop-first, simple designs, minimal configurations
**Mobile**: Stack vertically, legend above control

---

### Option A2: Integrated Panel (Horizontal Split) 🆕

```
┌──────────────────────────────────┐
│  Banner: Air Quality             │
├──────────────────────────────────┤
│                                  │
│    Map Area                      │
│                                  │
│  ┌─Legend─────┐ ┌─Year Control─┐│
│  │ NO₂ Scale  │ │  2024   [▶]  ││
│  │ ▓▓▓▓▓▓▓▓   │ │ ═══○═══      ││
│  │ 0-40 μg/m³ │ │ 2022    2024 ││
│  │            │ │              ││
│  └────────────┘ └──────────────┘│
└──────────────────────────────────┘

Mobile Portrait (<480px):
┌────────────────┐
│ Banner         │
├────────────────┤
│ Map            │
│ ┌─Legend────┐ │
│ │ NO₂ Scale │ │
│ └───────────┘ │
│ ┌─Control───┐ │
│ │ Year: 2024│ │
│ │ ═══○═══   │ │
│ └───────────┘ │
└────────────────┘
```

**Pros**: Efficient space use, clear separation of concerns, wider control panel possible, modern dashboard feel
**Cons**: May be tight on narrow desktop windows, requires responsive breakpoints
**Best for**: Desktop/tablet landscape, dashboard-style layouts
**Mobile**: Automatically stacks vertically via CSS flexbox
**Layout approach**: Use CSS Flexbox with `flex-wrap: wrap` for automatic responsive behavior

---

### Option B: Separate Bottom Bar (Cinematic)

```
┌────────────────────────┐
│  Banner: Air Quality   │
├────────────────────────┤
│                        │
│    Map Area            │
│                        │
│           ┌─Legend───┐ │
│           │ NO₂ Scale│ │
│           │ ▓▓▓▓▓▓▓  │ │
│           └──────────┘ │
├────────────────────────┤
│ Year: ═══○═══  [▶]    │  ← Full-width control
│      2022      2024    │
└────────────────────────┘
```

**Pros**: Clear separation, cinematic feel, prominent temporal control, good for animation/playback
**Cons**: Uses more vertical space, control always visible (no collapse)
**Best for**: Storytelling maps, presentation mode, animation focus
**Mobile**: Control bar remains full-width, may need height adjustment

---

### Option C: Floating Mini Control (Minimalist)

```
┌────────────────────────┐
│  Banner: Air Quality   │
├────────────────────────┤
│                        │
│    Map Area            │
│                        │
│        [2024 ▼]        │  ← Compact floating dropdown
│                        │
│    ┌─Legend───┐        │
│    │ NO₂ Scale│        │
│    └──────────┘        │
└────────────────────────┘
```

**Pros**: Minimal footprint, flexible positioning, doesn't compete with legend, clean aesthetic
**Cons**: Less discoverable, limited to simple controls (dropdown or small slider)
**Best for**: Mobile-first, minimalist designs, maps with infrequent year changes
**Mobile**: Works well on portrait, easy to reposition

---

### Option D: Sidebar Integration (Dashboard Style)

```
┌─Banner────────────────┐
├──┬────────────────────┤
│ L│                    │
│ e│   Map Area         │
│ g│                    │
│ e├────────────────────┤
│ n│ Year: 2024         │
│ d│ ══○══  [▶]         │  ← Temporal control in sidebar
│  │ 2022    2024       │
└──┴────────────────────┘

Mobile: Reverts to Option A or B
```

**Pros**: Excellent desktop space utilization, grouped controls, dashboard aesthetic
**Cons**: Requires responsive fallback, reduces map area on desktop
**Best for**: Dashboard-style layouts, data-heavy applications, desktop-primary use
**Mobile**: Collapses to Option A1 or A2 layout

---

**📌 USER ACTION REQUIRED:**
1. Which layout option(s) appeal to you? Select 1-2 preferred options:
   - [ ] Option A1 (Vertical stack - simple)
   - [ ] Option A2 (Horizontal split - modern)
   - [ ] Option B (Bottom bar - cinematic)
   - [ ] Option C (Floating - minimalist)
   - [ ] Option D (Sidebar - dashboard)

2. Should the control be collapsible like current legend?
   - [ ] Yes, collapsible by default
   - [ ] No, always visible
   - [ ] Depends on layout choice

------------------------------------------------------------------------

## 4. Technical Feasibility Assessment

### Our Stack Compatibility

✅ **What Works Well:** - HTML5 `<input type="range">` + custom CSS - Vanilla JavaScript event handlers - Post-processing HTML injection (like banner/legend) - Leaflet's `map.addLayer()` / `map.removeLayer()` - onRender() JavaScript caching (proven)

⚠️ **Constraints:** - Cannot use Leaflet plugins requiring R package changes - Must work without server-side rendering - Limited to client-side layer management - Must integrate with existing banner/legend system

❌ **Won't Work:** - Solutions requiring real-time data streams - Plugins with complex build processes - Approaches needing Leaflet.js fork/modification

### Implementation Approaches

**Approach 1: Enhanced HTML5 Range** - Customize native `<input type="range">` with CSS - Add year labels via generated `<datalist>` or positioned divs - Optional: Add play/pause button - **Complexity**: Low (8-12 hours) - **Reliability**: High (browser-native)

**Approach 2: Custom Slider Component** - Build slider from scratch (div track + handle) - Full styling control - Touch/mouse event handling - **Complexity**: Medium (15-20 hours) - **Reliability**: Medium (needs testing)

**Approach 3: Adapt Leaflet Plugin** - Take Leaflet-timeline or TimeDimension code - Strip dependencies, simplify - Integrate with our injection pattern - **Complexity**: Medium-High (20-25 hours) - **Reliability**: High (battle-tested code)

### Key Technical Considerations

1.  **Year Range Handling**
    -   Currently hardcoded years array in proof of concept
    -   Should dynamically extract from `window.quickmapLayerCache` keys
    -   Handle edge cases (single year, gaps in data)
2.  **Mobile Touch Optimization**
    -   Slider thumb minimum 44x44px touch target
    -   Prevent map pan during slider drag
    -   Test on iOS Safari and Chrome Mobile
3.  **Accessibility**
    -   ARIA labels for screen readers
    -   Keyboard navigation (arrow keys)
    -   Focus indicators
    -   Announce year changes to assistive tech
4.  **Performance**
    -   Layer switching is fast (\<50ms for 150 markers)
    -   No debouncing needed for discrete steps
    -   Consider transition CSS for smooth appearance
5.  **Integration with Existing System**
    -   Banner injected after `<body>`
    -   Legend injected before `</body>`
    -   Control could inject before or after legend
    -   Z-index coordination (banner: 999, legend: 1000, control: 1001?)

------------------------------------------------------------------------

## 5. Implementation Timeline Estimate

### Research & Design Phase

-   User selects preferred examples: **1 hour**
-   Analyze selected examples: **2-3 hours**
-   Create mockups for chosen layout: **1-2 hours**
-   **Subtotal**: 4-6 hours

### Development Phase (varies by approach)

**If HTML5 Range (Approach 1):** - Core implementation: **4-6 hours** - Responsive CSS: **2-3 hours** - Testing (devices, browsers): **2-3 hours** - **Subtotal**: 8-12 hours

**If Custom Slider (Approach 2):** - Core component: **8-10 hours** - Responsive CSS: **3-4 hours** - Touch/mouse handling: **2-3 hours** - Testing: **3-4 hours** - **Subtotal**: 16-21 hours

**If Adapted Plugin (Approach 3):** - Code extraction/simplification: **10-12 hours** - Integration with our system: **4-6 hours** - Testing & debugging: **4-6 hours** - **Subtotal**: 18-24 hours

### Documentation & Deployment

-   Code documentation: **1 hour**
-   User documentation (if needed): **1-2 hours**
-   Create test cases: **1 hour**
-   **Subtotal**: 3-4 hours

**Total Timeline**: 15-34 hours (depending on approach)

------------------------------------------------------------------------

## 6. Decision Points

### Immediate Decisions Needed

1.  **Control Type**: Slider? Timeline? Play/pause? Dropdown?
2.  **Layout**: Which option (A/B/C/D)?
3.  **Implementation Approach**: HTML5 native? Custom? Adapted plugin?
4.  **Timeline**: When does this need to be ready?

### Nice-to-Have Features (Prioritize Later)

-   [ ] Play/pause animation
-   [ ] Speed control (slow/fast playback)
-   [ ] Year labels showing data availability
-   [ ] Smooth transitions between years
-   [ ] Keyboard shortcuts (space = play, arrows = step)
-   [ ] Deep linking (URL includes selected year)

------------------------------------------------------------------------

## 7. Success Criteria

Implementation will be considered successful when:

✅ User can switch between all available years smoothly ✅ Works on mobile (portrait/landscape) and desktop ✅ No JavaScript errors in console ✅ Accessible via keyboard and screen readers ✅ Doesn't obscure map or conflict with legend ✅ Performance is acceptable (\<100ms year switch) ✅ Code is maintainable and well-documented

------------------------------------------------------------------------

## Next Steps

1.  **USER**: Review reference URLs, select 2-3 favorites
2.  **USER**: Choose control type and layout preference
3.  **DEVELOPER**: Analyze selected examples in detail
4.  **DEVELOPER**: Create detailed mockup of chosen design
5.  **USER**: Approve mockup
6.  **DEVELOPER**: Implement on `experiment/slider-control` branch
7.  **USER**: Test and provide feedback
8.  **DEVELOPER**: Refine based on feedback
9.  **USER**: Approve for merge to main
10. **DEVELOPER**: Document and deploy

------------------------------------------------------------------------

## Reference Materials

-   **Technical proof of concept**: `dev/reference/slider_control_technical_guide.md`
-   **Original task spec**: `dev/v0.9.1_slider_control_status_and_task.md`
-   **Validated working code**: Branch `experiment/slider-control` (if created)
-   **Next steps detail**: `dev/20251030_temporal_controls_next_steps_1600.md`

------------------------------------------------------------------------

**Current Status**: Awaiting user input on preferred examples, control type, and layout.

**Contact**: Provide selections via comments in this document or discussion.
