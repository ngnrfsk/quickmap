#!/usr/bin/env python3
"""Build the Option D (Leaflet Canvas + embedded JSON) prototypes.

Inlines leaflet.js/.css from the installed R leaflet package and the shared
datasets into the template, producing self-contained HTML in aq_maps/.
"""
import subprocess, pathlib

REPO = pathlib.Path("/Users/iarla/Coding/quickmap")
SHARED = REPO / "dev/item5_prototypes/shared"
TPL = REPO / "dev/item5_prototypes/optiond/item5_optiond-template_v1.html"
OUT = REPO / "aq_maps"

lib = pathlib.Path(subprocess.run(
    ["Rscript", "-e", 'cat(find.package("leaflet"))'],
    capture_output=True, text=True).stdout.strip()) / "htmlwidgets/lib/leaflet"
leaflet_js = (lib / "leaflet.js").read_text()
leaflet_css = (lib / "leaflet.css").read_text()

tpl = TPL.read_text()
boundary = (SHARED / "boundary_simplified.json").read_text()
schools = (SHARED / "schools.json").read_text()

for name, data_file, title in [
    ("item5_optiond-episode_v1.html", "episode.json", "Option D — PM2.5 episode Jan 15-20 2024"),
    ("item5_optiond-synthetic_v1.html", "synthetic.json", "Option D — synthetic 500x200"),
]:
    html = (tpl.replace("{{TITLE}}", title)
               .replace("{{LEAFLET_CSS}}", leaflet_css)
               .replace("{{LEAFLET_JS}}", leaflet_js)
               .replace("{{DATA_JSON}}", (SHARED / data_file).read_text())
               .replace("{{BOUNDARY_JSON}}", boundary)
               .replace("{{SCHOOLS_JSON}}", schools))
    out = OUT / name
    out.write_text(html)
    print(name, out.stat().st_size, "bytes")
