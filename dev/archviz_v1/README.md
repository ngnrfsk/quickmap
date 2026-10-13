# QuickMap architecture diagrams (v1)

Built 2026-10-05 from reading the source at v0.9.9.13, branch `feature/item9-output-paths`. Each box cites `file:line` (Q: = R/quickmap.R, A: = R/quickmap_api.R, L: = R/qm_layer.R, W: = R/wind.R).

## What is here

| Folder or file | Use |
|---|---|
| `index.html` | All 9 views on one page, for the engineer reviewing the code. Open in a browser. |
| `svg/` | One SVG per view, 1280x720 (16:9). For slide decks. |
| `png/` | The same views at 2560x1440. Use if an SVG does not import cleanly. |

## Views

1. System overview
2. quickmap() to render_pollution_map(): stages
3. Per-step loop, lazy path, static export, save and inject
4. qm_layer data model and constructors
5. Configuration: scales, themes, templates and loaders
6. R to browser boundary and JS call order
7. Wind data flow
8. Documented claims the code contradicts (read this one first)
9. Technology stack by layer (packages, JS, export, tooling)

## Using the SVGs in PowerPoint

- Insert > Pictures > This Device, pick the `.svg`.
- Right-click > Convert to Shape to edit boxes and text. Each slide has a white background rectangle; delete it for a transparent slide.
- Text is Arial. Colours are fixed hex values, no CSS.
- Keynote and Google Slides import SVG as pictures; use the PNG there if text shifts.

## Limits

- Built from a source read, not by running the package. Claims marked "grep only" were not traced by hand.
- Claims not verified by the audit: `CLAUDE.md` text outside lines 15-64 of the R-side check; whether `build_banner_css` and `build_legend_css` call `apply_template_replacements`.
- Static diagrams: line numbers will drift as the code changes.

## Rebuild

- `dev/archviz_build_v1.py` writes `svg/` and `index.html`.
- `dev/archviz_png_v1.R` writes `png/` (needs the `rsvg` package).
