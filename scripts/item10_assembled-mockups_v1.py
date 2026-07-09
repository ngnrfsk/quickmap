#!/usr/bin/env python3
# Item 10: assembled final-design mock-ups combining the user's picks
# (2026-07-09): system fonts, neutral chrome + brand accent, slim banner
# strip (bar remains a theme option), thin ramp legend, bottom slider with
# fine-step arrows (visual mock), Positron tiles, speed-ramp wind.
# Run from the repo root: python3 scripts/item10_assembled-mockups_v1.py
import re, os

ACCENT = "#5F3E94"

COMMON = f"""
<style>
html, body, .banner, .year-button, .year-item, .legend {{
  font-family: system-ui, -apple-system, "Segoe UI", Roboto, "Helvetica Neue", sans-serif !important;
}}
.banner {{ background:#fff; color:#111; text-align:left; padding:0.6rem 1.25rem 0.55rem;
  font-size:1.05rem; font-weight:650; border-bottom:3px solid {ACCENT}; }}
.legend {{ background:#fff; border-top:1px solid #e5e5e5; }}
.legend-header {{ background:#fff; border:1px solid #ddd; font-weight:600; }}
.legend-key span {{ font-family:inherit !important; border-radius:999px;
  padding:0.25rem 0.6rem; font-size:0.78rem; font-weight:600; }}
.legend-content {{ gap:0.4rem; }}
#yearControl {{ display:none !important; }}
</style>
"""

def ramp_transform(html):
    items = re.findall(
        r'<div class="legend-item"><span style="background: (#[0-9A-Fa-f]+); color: [^;]+;">(.*?)</span></div>',
        html)
    blocks, labels = [], []
    for colour, label in items:
        blocks.append(f'<div style="flex:1; height:0.7rem; background:{colour};"></div>')
        labels.append(f'<div style="flex:1; text-align:center; font-size:0.8rem; color:#333;">{label}</div>')
    ramp = ('<div class="legend-items" style="display:block; width:100%; max-width:44rem;">'
            '<div style="display:flex; border-radius:3px; overflow:hidden;">'
            + "".join(blocks) + '</div>'
            '<div style="display:flex; margin-top:0.2rem;">' + "".join(labels) + '</div></div>')
    head, sep, tail = html.partition('<div class="legend-key')
    head = re.sub(r'<div class="legend-items">.*', ramp + "\n", head,
                  count=1, flags=re.S)
    return head + sep + tail

def slider(current_label, left_label, right_label, frac):
    return (f'<div style="height:auto !important; position:absolute; bottom:1.4rem; left:50%;'
            f' transform:translateX(-50%); z-index:1001; background:rgba(255,255,255,0.95);'
            f' border:1px solid #ddd; border-radius:0.6rem; box-shadow:0 1px 6px rgba(0,0,0,0.2);'
            f' padding:0.5rem 0.9rem; width:min(26rem, 90vw);">'
            f'<div style="display:flex; align-items:center; gap:0.55rem;">'
            f'<span style="background:{ACCENT}; color:#fff; border-radius:50%; width:1.9rem;'
            f' height:1.9rem; display:flex; align-items:center; justify-content:center;'
            f' flex-shrink:0;">&#9654;</span>'
            f'<span style="color:#666; font-size:1.05rem;">&#8249;</span>'
            f'<div style="flex:1;">'
            f'<div style="text-align:center; font-weight:650; font-size:0.85rem;'
            f' margin-bottom:0.2rem;">{current_label}</div>'
            f'<div style="height:4px; background:#e8e8e8; border-radius:2px; position:relative;">'
            f'<div style="height:4px; width:{int(frac*100)}%; background:{ACCENT}; border-radius:2px;"></div>'
            f'<div style="position:absolute; left:{int(frac*100)}%; top:50%;'
            f' transform:translate(-50%,-50%); width:0.95rem; height:0.95rem; background:#fff;'
            f' border:3px solid {ACCENT}; border-radius:50%;"></div></div>'
            f'<div style="display:flex; justify-content:space-between; margin-top:0.2rem;'
            f' font-size:0.75rem; color:#888;"><span>{left_label}</span><span>{right_label}</span></div>'
            f'</div>'
            f'<span style="color:#333; font-size:1.05rem;">&#8250;</span>'
            f'</div></div>')

def assemble(src, out, current_label, left_label, right_label, frac):
    with open(src) as fh:
        html = fh.read()
    html = ramp_transform(html)
    html = html.replace('<div class="map-container">',
                        '<div class="map-container">'
                        + slider(current_label, left_label, right_label, frac), 1)
    html = html.replace("</head>", COMMON + "\n</head>", 1)
    with open(out, "w") as fh:
        fh.write(html)
    print(out, os.path.getsize(out), "bytes")

assemble("aq_maps/item10_tiles-positron_v1.html",
         "aq_maps/item10_assembled-annual_v1.html",
         "2021", "2020", "2022", 0.5)

assemble("aq_maps/item10_wind-speedramp_v1.html",
         "aq_maps/item10_assembled-episode-wind_v1.html",
         "17 Jan 2024, 09:00", "15 Jan", "19 Jan", 0.4)
