# Function Renames - v0.9.2

**Date:** 2025-11-26

Renamed 5 internal functions for clarity:
- `apply_custom_layout_in_html()` → `inject_banner_legend_controls()` (explicitly states what's injected)
- `save_styled_map()` → `save_html_and_style()` (reflects conditional styling)
- `build_static_map_for_year()` → `add_year_and_static_layers()` (clarifies layer addition)
- `load_banner_css()` → `build_banner_css()` (reflects template processing)
- `load_legend_css()` → `build_legend_css()` (consistent with banner)

All internal (`@keywords internal`). No breaking changes. Tests passed.
