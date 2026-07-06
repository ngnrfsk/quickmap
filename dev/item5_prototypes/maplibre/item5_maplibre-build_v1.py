#!/usr/bin/env python3
"""Build the MapLibre prototypes: inline maplibre-gl dist (from mapgl 0.4.4
tarball) + shared datasets into self-contained HTML in aq_maps/."""
import pathlib

REPO = pathlib.Path("/Users/iarla/Coding/quickmap")
SHARED = REPO / "dev/item5_prototypes/shared"
HERE = REPO / "dev/item5_prototypes/maplibre"
OUT = REPO / "aq_maps"

tpl = (HERE / "item5_maplibre-template_v1.html").read_text()
js = (HERE / "assets/maplibre-gl.js").read_text()
css = (HERE / "assets/maplibre-gl.css").read_text()
boundary = (SHARED / "boundary_simplified.json").read_text()
schools = (SHARED / "schools.json").read_text()

for name, data_file, title in [
    ("item5_maplibre-episode_v1.html", "episode.json", "MapLibre — PM2.5 episode Jan 15-20 2024"),
    ("item5_maplibre-synthetic_v1.html", "synthetic.json", "MapLibre — synthetic 500x200"),
]:
    html = (tpl.replace("{{TITLE}}", title)
               .replace("{{MAPLIBRE_CSS}}", css)
               .replace("{{MAPLIBRE_JS}}", js)
               .replace("{{DATA_JSON}}", (SHARED / data_file).read_text())
               .replace("{{BOUNDARY_JSON}}", boundary)
               .replace("{{SCHOOLS_JSON}}", schools))
    out = OUT / name
    out.write_text(html)
    print(name, out.stat().st_size, "bytes")
