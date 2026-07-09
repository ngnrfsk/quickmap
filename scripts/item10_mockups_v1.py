#!/usr/bin/env python3
# Item 10 UI mock-up builder. Takes the real rendered base map
# (aq_maps/item10_tiles-positron_v1.html) and writes CSS/HTML-override
# variants for the undecided MCQs: banner (Q3), legend (Q4), time control
# (Q6). All variants share the settled decisions: system fonts (Q2A),
# neutral chrome with brand accents (Q7A), footnote symbols kept (Q5B).
# The stepper and slider time controls are VISUAL mocks (not functional).
# Run from the repo root: python3 scripts/item10_mockups_v1.py
import re, os

BASE = "aq_maps/item10_tiles-positron_v1.html"
ACCENT = "#5F3E94"

with open(BASE) as fh:
    base_html = fh.read()

# settled base style applied to every mock
COMMON = f"""
<style>
html, body, .banner, .year-button, .year-item, .legend {{
  font-family: system-ui, -apple-system, "Segoe UI", Roboto, "Helvetica Neue", sans-serif !important;
}}
.legend {{ background:#fff; border-top:1px solid #e5e5e5; }}
.legend-header {{ background:#fff; border:1px solid #ddd; font-weight:600; }}
.legend-header:hover {{ background:#f4f2f8; }}
.play-pause-button {{ background:{ACCENT}; border-color:{ACCENT}; }}
.year-button {{ background:#fff; border:1px solid #ccc; color:#222; font-weight:600; }}
.year-button:hover {{ background:#f4f2f8; border-color:{ACCENT}; }}
.year-item.selected {{ background:{ACCENT}; }}
</style>
"""

# injected overlays are direct children of .map-container, which a base rule
# stretches to height:100% - neutralise it for mock overlays
OVERLAY_FIX = "height:auto !important; "

def variant(name, extra_head, html_transform=None):
    html = base_html
    if html_transform:
        html = html_transform(html)
    html = html.replace("</head>", COMMON + extra_head + "\n</head>", 1)
    out = f"aq_maps/item10_{name}_v1.html"
    with open(out, "w") as fh:
        fh.write(html)
    print(out, os.path.getsize(out), "bytes")

title_m = re.search(r'<div class="banner">(.*?)</div>', base_html, re.S)
TITLE = title_m.group(1).strip() if title_m else "Merton NO2 Annual Mean"

# ---- Q3 banner variants ----
variant("banner-strip", f"""
<style>
.banner {{ background:#fff; color:#111; text-align:left; padding:0.6rem 1.25rem 0.55rem;
  font-size:1.05rem; font-weight:650; border-bottom:3px solid {ACCENT}; }}
</style>""")

variant("banner-bar", f"""
<style>
.banner {{ padding:0.7rem 1.25rem; font-size:1.1rem; font-weight:600; text-align:left; }}
</style>""")

def card_transform(html):
    card = (f'<div style="{OVERLAY_FIX}position:absolute; top:0.75rem; left:3.4rem; z-index:1000;'
            f' background:rgba(255,255,255,0.95); color:#111; padding:0.6rem 0.9rem;'
            f' border-radius:0.5rem; box-shadow:0 1px 6px rgba(0,0,0,0.25);'
            f' font-weight:650; font-size:1rem; max-width:24rem;'
            f' border-left:4px solid {ACCENT};">{TITLE}</div>')
    return html.replace('<div class="map-container">',
                        '<div class="map-container">' + card, 1)

variant("banner-card", """
<style>.banner { display:none; }</style>""", card_transform)

# ---- Q4 legend variants ----
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
    # replace only the legend-items block: head ends where legend-key begins,
    # so everything from the legend-items opening to the end of head is the
    # block to swap
    head, sep, tail = html.partition('<div class="legend-key')
    head = re.sub(r'<div class="legend-items">.*', ramp + "\n", head,
                  count=1, flags=re.S)
    return head + sep + tail

variant("legend-ramp", """
<style>
.legend-key span { font-family:inherit !important; border-radius:999px;
  padding:0.25rem 0.6rem; font-size:0.78rem; font-weight:600; }
.legend-content { gap:0.4rem; }
</style>""", ramp_transform)

variant("legend-chips", """
<style>
.legend-item span, .legend-key span { font-family:inherit !important;
  border-radius:999px; padding:0.3rem 0.7rem; font-size:0.85rem; font-weight:600; }
</style>""")

variant("legend-card", """
<style>
body { position:relative; }
.legend { position:absolute; right:0.75rem; bottom:1.5rem; z-index:1000; width:auto;
  max-width:19rem; border:1px solid #ddd; border-radius:0.5rem;
  box-shadow:0 1px 6px rgba(0,0,0,0.25); }
.legend-container { flex-direction:column; align-items:flex-start; gap:0.5rem; padding:0.6rem 0.75rem; }
.legend-items { font-size:0.85rem; }
.legend-key { font-size:0.75rem; }
</style>""")

# ---- Q6 time-control variants (stepper + slider are visual mocks) ----
variant("time-dropdown", "")   # the COMMON restyle alone = neutral pill dropdown

def stepper_transform(html):
    stepper = (f'<div style="{OVERLAY_FIX}position:absolute; top:2rem; right:1rem; z-index:1001;'
               f' display:flex; align-items:center; gap:0.4rem;'
               f' background:#fff; border:1px solid #ccc; border-radius:999px;'
               f' padding:0.3rem 0.6rem; box-shadow:0 1px 4px rgba(0,0,0,0.15);">'
               f'<span style="background:{ACCENT}; color:#fff; border-radius:50%;'
               f' width:1.7rem; height:1.7rem; display:flex; align-items:center;'
               f' justify-content:center; font-size:0.8rem;">&#9654;</span>'
               f'<span style="font-size:1.1rem; color:#888; padding:0 0.2rem;">&#8249;</span>'
               f'<span style="font-weight:650;">2021'
               f'<div style="height:3px; background:#eee; border-radius:2px; margin-top:2px;">'
               f'<div style="height:3px; width:66%; background:{ACCENT}; border-radius:2px;"></div></div></span>'
               f'<span style="font-size:1.1rem; color:#333; padding:0 0.2rem;">&#8250;</span></div>')
    return html.replace('<div class="map-container">',
                        '<div class="map-container">' + stepper, 1)

variant("time-stepper", """
<style>#yearControl { display:none !important; }</style>""", stepper_transform)

def slider_transform(html):
    ticks = "".join(
        f'<span style="font-size:0.8rem; color:{"#111" if y == "2021" else "#888"};'
        f' font-weight:{650 if y == "2021" else 400};">{y}</span>'
        for y in ["2020", "2021", "2022"])
    slider = (f'<div style="{OVERLAY_FIX}position:absolute; bottom:1.4rem; left:50%; transform:translateX(-50%);'
              f' z-index:1001; background:rgba(255,255,255,0.95); border:1px solid #ddd;'
              f' border-radius:0.6rem; box-shadow:0 1px 6px rgba(0,0,0,0.2);'
              f' padding:0.5rem 1rem; width:24rem;">'
              f'<div style="display:flex; align-items:center; gap:0.7rem;">'
              f'<span style="background:{ACCENT}; color:#fff; border-radius:50%; width:1.9rem;'
              f' height:1.9rem; display:flex; align-items:center; justify-content:center;">&#9654;</span>'
              f'<div style="flex:1;">'
              f'<div style="height:4px; background:#e8e8e8; border-radius:2px; position:relative;">'
              f'<div style="height:4px; width:50%; background:{ACCENT}; border-radius:2px;"></div>'
              f'<div style="position:absolute; left:50%; top:50%; transform:translate(-50%,-50%);'
              f' width:0.95rem; height:0.95rem; background:#fff; border:3px solid {ACCENT};'
              f' border-radius:50%;"></div></div>'
              f'<div style="display:flex; justify-content:space-between; margin-top:0.25rem;">{ticks}</div>'
              f'</div></div></div>')
    return html.replace('<div class="map-container">',
                        '<div class="map-container">' + slider, 1)

variant("time-slider", """
<style>#yearControl { display:none !important; }</style>""", slider_transform)
