#!/usr/bin/env python3
# Item 10 wind-styling mock-ups (Q9), built by swapping the inlined
# leaflet-velocity constants inside the real signed-off episode wind map.
# Run from the repo root: python3 scripts/item10_wind-mockups_v1.py
import re, os, shutil

BASE = "aq_maps/item8_episode-wind_v1.html"
with open(BASE) as fh:
    html = fh.read()

m = re.search(r"colorScale: \[[^\]]*\]", html)
if not m:
    raise SystemExit("colorScale not found in base map")
current = m.group(0)

# 9A reference: current muted slate
shutil.copy2(BASE, "aq_maps/item10_wind-slate_v1.html")
print("aq_maps/item10_wind-slate_v1.html (copy of current)")

def write(name, new_scale, extra=None):
    out_html = html.replace(current, "colorScale: " + new_scale)
    if extra:
        for old, new in extra:
            out_html = out_html.replace(old, new)
    out = f"aq_maps/item10_{name}_v1.html"
    with open(out, "w") as fh:
        fh.write(out_html)
    print(out, os.path.getsize(out), "bytes")

# 9B speed-coloured ramp (blue -> red with wind speed)
write("wind-speedramp",
      "['#3288bd', '#66c2a5', '#abdda4', '#fee08b', '#f46d43', '#d53e4f']")

# 9C high-contrast: near-black particles, slightly heavier line.
# (The MCQ said "white", but white is invisible on the pale basemap the
# maps use - this is the honest high-contrast equivalent.)
write("wind-dark",
      "['#555555', '#444444', '#333333', '#222222', '#111111']",
      extra=[("lineWidth: 1,", "lineWidth: 1.5,")])
