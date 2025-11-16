# Legend Sizing Options for Horizontal Layout

**Current Issue:** Legend elements (header, symbols, text) may be too large/small for horizontal layout

## Option A: Compact (Smaller elements)
**Best for:** Maps with many legend items, maximizing map space

- **Header button:** padding: 0.35rem 0.75rem, font-size: 0.9rem
- **Symbol size:** 0.9rem (down from 1.25rem)
- **Item gap:** 0.4rem (down from 0.625rem)
- **Container padding:** 0.5rem 0.75rem
- **Item font-size:** 0.8rem
- **Header gap (toggle ↔ text):** 0.4rem

**Visual:** `[▼ Legend] [●0-10] [●10-20] [●20-30] ...` - tight spacing, smaller symbols

---

## Option B: Balanced (Medium elements) - RECOMMENDED
**Best for:** General use, good readability without excessive space

- **Header button:** padding: 0.45rem 0.875rem, font-size: 1rem
- **Symbol size:** 1rem (down from 1.25rem)
- **Item gap:** 0.5rem (down from 0.625rem)
- **Container padding:** 0.625rem 0.875rem
- **Item font-size:** 0.875rem
- **Header gap (toggle ↔ text):** 0.5rem

**Visual:** `[▼ Legend] [● 0-10] [● 10-20] [● 20-30] ...` - comfortable spacing

---

## Option C: Roomy (Larger elements)
**Best for:** Maps with few legend items, emphasizing readability

- **Header button:** padding: 0.5rem 1rem, font-size: 1.05rem
- **Symbol size:** 1.1rem (down slightly from 1.25rem)
- **Item gap:** 0.625rem (current)
- **Container padding:** 0.75rem 1rem (current)
- **Item font-size:** 0.95rem
- **Header gap (toggle ↔ text):** 0.625rem (current)

**Visual:** `[▼ Legend]  [● 0-10]  [● 10-20]  [● 20-30] ...` - generous spacing

---

## Option D: Extra Compact (Minimal)
**Best for:** Dense data, very small screens, maximum map area

- **Header button:** padding: 0.3rem 0.65rem, font-size: 0.85rem
- **Symbol size:** 0.8rem
- **Item gap:** 0.35rem
- **Container padding:** 0.4rem 0.65rem
- **Item font-size:** 0.75rem
- **Header gap (toggle ↔ text):** 0.35rem

**Visual:** `[▼Legend][●0-10][●10-20][●20-30]...` - very tight, minimal chrome

---

## Implementation Notes

**To change option:** Modify values in `load_legend_css()` function at R/quickmap.R ~lines 1169-1179

**Current values (for reference):**
```r
container_padding <- "0.75rem 1rem"
header_gap <- "0.625rem"
items_gap <- "0.625rem"
item_gap <- "0.625rem"
symbol_width <- "1.25rem"
symbol_height <- "1.25rem"
```

**Mobile behavior:** All options stack vertically on screens ≤480px with adjusted sizing

---

## Additional Considerations

1. **Symbol vs Text ratio:** Current symbols may be competing with text. Reducing symbols emphasizes labels.

2. **Header visibility:** Making header button smaller/tighter could make it less obvious it's clickable.

3. **Touch targets:** Very compact options (A, D) may have poor touch targets on mobile.

4. **Wrap behavior:** Fewer items per row with larger elements; more items wrap with compact options.

5. **Dynamic scaling:** Could implement auto-scaling based on number of legend items (more items = more compact).

---

## Recommendation

**Start with Option B (Balanced)** - good compromise between readability and space efficiency. If still too large, move to Option A. If legend has ≤4 items, Option C works well.

Consider adding CSS class variants so users can choose sizing per map via parameter.
