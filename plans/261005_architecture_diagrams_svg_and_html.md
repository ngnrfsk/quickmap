# Architecture diagrams: SVG for slides, HTML page for review

## Output
- `dev/archviz_v1/svg/*.svg`: 8 slides, 1280×720, inline attributes only, Arial. Imports into PowerPoint; Convert to Shape makes them editable.
- `dev/archviz_v1/png/*.png`: 2560×1440 raster fallbacks.
- `dev/archviz_v1/index.html`: the same 8 views in one page, for the engineer.
- `dev/archviz_v1/README.md`: plain-English guide.

## Views
1. System overview
2. quickmap() to render_pollution_map(): stages
3. Per-step loop, lazy path, static export, save and inject
4. qm_layer data model and constructors
5. Configuration: scales, themes, templates and their loaders
6. R to browser boundary and the JS call order
7. Wind animation data flow
8. Documented claims that the code contradicts

## Method
Facts come from three source reads (R pipeline, JS and injection, repo layout), not from CLAUDE.md. Every box carries a `file:line` reference. View 8 lists divergences found.

## Build
- `dev/archviz_build_v1.py` writes svg/ and index.html.
- `dev/archviz_png_v1.R` writes png/ with the rsvg package.
- Copy to iCloud `dev/archviz_v1/` with a Python copy script after sign-off.
