import html
import math
import os
import textwrap

OUT = "/Users/iarla/Coding/quickmap/dev/archviz_v1"
INK = "#1f2937"
MUTED = "#4b5563"
KINDS = {
    "r": ("#dbeafe", "#1d4ed8", "R code"),
    "cfg": ("#d1fae5", "#047857", "Configuration in inst/"),
    "js": ("#ffedd5", "#c2410c", "Browser JS"),
    "io": ("#f3f4f6", "#6b7280", "Input, output or note"),
    "warn": ("#fee2e2", "#b91c1c", "Code differs from docs"),
}
FONT = 'font-family="Arial, Helvetica, sans-serif"'
WARNINGS = []


def esc(s):
    return html.escape(s, quote=True)


class Slide:
    def __init__(self, slug, title, subtitle, source):
        self.slug, self.title, self.subtitle = slug, title, subtitle
        self.parts = []
        self.parts.append('<rect x="0" y="0" width="1280" height="720" fill="#ffffff"/>')
        self.text(40, 46, title, 28, INK, "bold")
        self.text(40, 72, subtitle, 16, MUTED)
        self.legend(40, 708)
        self.text(1240, 708, source, 12, MUTED, anchor="end")

    def text(self, x, y, s, size=14, fill=INK, weight="normal", anchor="start"):
        self.parts.append(
            f'<text x="{x}" y="{y}" {FONT} font-size="{size}" font-weight="{weight}" '
            f'fill="{fill}" text-anchor="{anchor}">{esc(s)}</text>'
        )

    def legend(self, x, y):
        for k in ("r", "cfg", "js", "io", "warn"):
            fill, stroke, label = KINDS[k]
            self.parts.append(
                f'<rect x="{x}" y="{y - 11}" width="14" height="14" rx="3" fill="{fill}" stroke="{stroke}" stroke-width="1.5"/>'
            )
            self.text(x + 20, y, label, 12, MUTED)
            x += 24 + len(label) * 6.4 + 14

    def box(self, x, y, w, h, title, body=(), kind="r", ref=None, bsize=14):
        fill, stroke, _ = KINDS[kind]
        self.parts.append(
            f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="6" fill="{fill}" stroke="{stroke}" stroke-width="2"/>'
        )
        cy = y + 12
        cpl_t = max(8, int((w - 20) / (16 * 0.56)))
        for ln in textwrap.wrap(title, cpl_t, break_long_words=False) or [""]:
            cy += 18
            self.text(x + 10, cy, ln, min(16, round((w - 20) / (len(ln) * 0.6), 1)), INK, "bold")
        if ref:
            cy += 17
            self.text(x + 10, cy, ref, 12, MUTED)
        cpl = max(8, int((w - 20) / (bsize * 0.54)))
        for item in body:
            for i, ln in enumerate(textwrap.wrap(item, cpl, break_long_words=False, subsequent_indent="  ")):
                cy += bsize + 4
                self.text(x + 10, cy, ln, bsize, INK)
            cy += 3
        if cy + 8 > y + h:
            WARNINGS.append(f"{self.slug}: '{title}' needs {cy + 8 - y - h:.0f}px more height")

    def arrow(self, pts, color=MUTED, dashed=False, label=None, label_at=None):
        d = "M " + " L ".join(f"{px} {py}" for px, py in pts)
        dash = ' stroke-dasharray="6 4"' if dashed else ""
        self.parts.append(f'<path d="{d}" fill="none" stroke="{color}" stroke-width="2"{dash}/>')
        (x1, y1), (x2, y2) = pts[-2], pts[-1]
        a = math.atan2(y2 - y1, x2 - x1)
        s = 10
        p1 = (x2 - s * math.cos(a - 0.4), y2 - s * math.sin(a - 0.4))
        p2 = (x2 - s * math.cos(a + 0.4), y2 - s * math.sin(a + 0.4))
        self.parts.append(
            f'<polygon points="{x2},{y2} {p1[0]:.1f},{p1[1]:.1f} {p2[0]:.1f},{p2[1]:.1f}" fill="{color}"/>'
        )
        if label:
            lx, ly = label_at or ((x1 + x2) / 2, (y1 + y2) / 2 - 6)
            self.text(lx, ly, label, 12, MUTED, anchor="middle")

    def svg(self):
        body = "\n".join(self.parts)
        return (
            '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1280 720" width="1280" height="720">\n'
            f"<title>{esc(self.title)}</title>\n{body}\n</svg>\n"
        )


slides = []


def s1():
    s = Slide("01", "System overview",
              "Inputs become qm_layer objects; quickmap() renders one self-contained HTML map, optionally a JPG per step.",
              "Source audit 2026-10-05, v0.9.9.13, branch feature/item9-output-paths")
    s.box(40, 110, 250, 80, "Diffusion-tube CSV", ["Easting, Northing (EPSG:27700), year columns"], "io")
    s.box(40, 202, 250, 80, "Schools CSV", ["Easting, Northing, Level, School"], "io")
    s.box(40, 294, 250, 80, "RData / OpenAir", ["siteCode, year, pollutant, lat, lon"], "io")
    s.box(40, 386, 250, 80, "Wind (worldmet)", ["date, ws, wd"], "io")
    s.box(340, 110, 270, 270, "from_csv / from_rdata / from_openair",
          ["Return a qm_layer: sf object, long format, one row per marker per time step, metadata in attr(x, 'qm')",
           "as_qm_layer (A:44) routes: .rdata path to from_rdata, other string to from_csv, data.frame to qm_layer()"],
          "r", "R/qm_layer.R:400, 453, 475")
    s.box(340, 386, 270, 100, "from_worldmet", ["Returns qm_wind (date, ws, wd, u, v), not a qm_layer"], "r", "R/wind.R:25")
    s.box(660, 110, 270, 132, "quickmap()",
          ["Normalises layers, infers pollutant, adds legacy columns. create_pollution_map() (A:262) delegates here."],
          "r", "R/quickmap_api.R:136")
    s.box(660, 266, 270, 224, "render_pollution_map()",
          ["Settings and theme", "Boundary and data", "Time steps and viewport", "Lazy or eager decision",
           "Per-step loop", "Wind layer", "Save and inject banner, slider, indicator, legend"],
          "r", "R/quickmap.R:4075")
    s.box(980, 250, 260, 100, "Interactive HTML",
          ["Self-contained Leaflet map; JS and CSS inlined; chrome injected into the saved file"], "io")
    s.box(980, 370, 260, 100, "JPG per time step", ["webshot2 screenshot of an intermediate HTML, which is then deleted"], "io")
    s.box(40, 520, 1200, 90, "inst/ configuration, loaded at build time",
          ["14 colour scales (YAML), 5 themes (YAML), banner and legend CSS/HTML templates with {{placeholder}}, "
           "controls JS: time-slider, indicator, wind-controller, lazy-time-controller, layer-cache, vendored leaflet-velocity"],
          "cfg")
    s.text(40, 640, "Size: R/ is 5,368 lines (quickmap.R 4,378; qm_layer.R 481; quickmap_api.R 318; wind.R 178). Version 0.9.9.13.", 14, MUTED)
    for y in (150, 242, 334):
        s.arrow([(290, y), (340, y)])
    s.arrow([(290, 426), (340, 426)])
    s.arrow([(610, 165), (660, 165)])
    s.arrow([(610, 436), (635, 436), (635, 330), (660, 330)], label="wind", label_at=(648, 456))
    s.arrow([(795, 242), (795, 266)])
    s.arrow([(930, 300), (980, 300)])
    s.arrow([(930, 420), (980, 420)])
    s.arrow([(795, 520), (795, 490)])
    return s


def s2():
    s = Slide("02", "quickmap() to render_pollution_map(): stages",
              "Front end converts every layer to sf with legacy columns; the renderer then runs six set-up stages.",
              "R/quickmap_api.R and R/quickmap.R; Q: = R/quickmap.R, A: = R/quickmap_api.R")
    s.text(40, 108, "quickmap()   R/quickmap_api.R:136", 16, INK, "bold")
    a = [
        ("absorb_legacy_args", "Q:2390", ["Renames marker_labels to symbol_labels"]),
        ("as_qm_layer", "A:44", [".rdata to from_rdata; other string to from_csv; data.frame to qm_layer()"]),
        ("Infer pollutant", "A:171-179", ["From the first time-varying layer"]),
        ("qm_to_legacy", "A:15", ["Adds year_str, siteCode, Longitude, Latitude for the renderer"]),
        ("Ids and symbols", "A:184-196", ["make.unique ids from layer name; data_symbols from layer shape"]),
    ]
    for i, (t, r, b) in enumerate(a):
        x = 40 + 250 * i
        s.box(x, 120, 200, 150, t, b, "r", r)
        if i < 4:
            s.arrow([(x + 200, 195), (x + 250, 195)])
    s.arrow([(1140, 270), (1140, 290), (137, 290), (137, 336)])
    s.text(1240, 322, "render_pollution_map()   R/quickmap.R:4075", 16, INK, "bold", "end")
    b = [
        ("1 Settings", "Q:4099-4131", ["resolve_output_path (Q:2354)", "parse_export_params (Q:3768)", "load_theme (Q:1351)", "Explicit argument beats theme"]),
        ("2 Boundary", "Q:4137-4143", ["get_boundary_sf (Q:1028)", "None when vignette = FALSE"]),
        ("3 Data", "Q:4146", ["load_spatial_data_sources (Q:3798)", "Layers are already sf, so they pass through (Q:3823)"]),
        ("4 Times, viewport", "Q:4153-4160", ["determine_times_and_viewport (Q:3915)", "apply_time_step_cap (Q:2749): keeps latest 200"]),
        ("5 Styling inputs", "Q:4165-4212", ["default_play_speed", "get_colour_legend", "create_base_map (Q:3636)", "get_measurement_layers (Q:4185)", "build_indicator_data (Q:4201)", "build_banner_key (Q:4212)"]),
        ("6 Lazy decision", "Q:4234", ["use_lazy_rendering (Q:2783)", "More than 50 steps or ~5 MB", "build_lazy_payload (Q:4244)"]),
    ]
    for i, (t, r, bd) in enumerate(b):
        s.box(40 + 201.2 * i, 336, 194, 250, t, bd, "r", r, bsize=13)
    s.box(40, 602, 1200, 80, "Next: per-step loop and save (slide 3)",
          ["Lazy threshold: steps above quickmap.lazy_step_threshold (50), or 1e6 + 65 x rows above quickmap.lazy_size_threshold (5e6). JPG export always uses the pre-built path."],
          "io")
    return s


def s3():
    s = Slide("03", "Per-step loop, lazy path, static export, save and inject",
              "Three lanes draw markers; the interactive lanes converge on one finish that writes the HTML.",
              "R/quickmap.R, R/wind.R; Q: = R/quickmap.R, W: = R/wind.R")
    s.box(40, 110, 170, 120, "1 Interactive, eager", ["50 steps or fewer"], "io")
    xs = [230, 428, 626, 824, 1022]
    l1 = [
        ("generate_map_layers", "Q:3674", ["One layer group per step, loop at Q:4265"]),
        ("prepare_generic_layer_data", "Q:3305", ["via get_layer_year_data"]),
        ("add_layer", "Q:3334", ["Labels, label options, noHide"]),
        ("create_generic_icons", "Q:3162", ["assign_colour per marker (Q:3195)"]),
        ("makeSymbolsSize, addMarkers", "leaflet", ["Shape, size, colour"]),
    ]
    for x, (t, r, b) in zip(xs, l1):
        s.box(x, 110, 170, 120, t, b, "r", r)
    for x in xs[:-1]:
        s.arrow([(x + 170, 170), (x + 198, 170)])
    s.box(40, 244, 170, 130, "2 Interactive, lazy", ["More than 50 steps or ~5 MB"], "io")
    l2 = [
        ("generate_map_layers", "Q:4251", ['Called once with "static_only" for schools etc.']),
        ("build_lazy_payload", "Q:2806", ["times, thresholds, colours, sites with per-step v[]"]),
        ("add_map_controls", "Q:3607-3614", ["onRender(lazy-time-controller.js, payload); digits = 7"]),
    ]
    for x, (t, r, b) in zip(xs[:3], l2):
        s.box(x, 244, 170, 130, t, b, "r", r)
    for x in xs[:2]:
        s.arrow([(x + 170, 309), (x + 198, 309)])
    s.box(40, 388, 170, 115, "3 Static JPG", ["One frame per step"], "io")
    l3 = [
        ("add_year_and_static_layers", "Q:2309", ["Called from the shared loop (Q:4279)"]),
        ("finalize_and_save_map", "Q:4301", ["Writes <stem>_<step>.html"]),
        ("webshot2", "Q:2517-2526", ["Screenshot to .jpg; HTML unlinked"]),
    ]
    for x, (t, r, b) in zip(xs[:3], l3):
        s.box(x, 388, 170, 115, t, b, "r", r)
    for x in xs[:2]:
        s.arrow([(x + 170, 445), (x + 198, 445)])
    s.box(40, 517, 170, 168, "Common finish", ["Lanes 1 and 2 only"], "io")
    l4 = [
        ("add_wind_layer", "W:173, Q:4336", ["Interactive, temporal only"]),
        ("finalize_and_save_map", "Q:2453", ["Interactive = TRUE"]),
        ("add_map_controls", "Q:3558", ["Boundary, fitBounds, setView, layer-cache or lazy JS, vignette"]),
        ("save_html_and_style", "Q:2544", ["saveWidget selfcontained (Q:2566); remove _files (Q:2595)"]),
        ("inject_banner_legend_controls", "Q:2921", ["Banner, CSS, slider, indicator, legend; missing anchor is an error"]),
    ]
    for x, (t, r, b) in zip(xs, l4):
        s.box(x, 517, 170, 168, t, b, "r", r)
    for x in xs[:-1]:
        s.arrow([(x + 170, 600), (x + 198, 600)])
    s.arrow([(1192, 170), (1230, 170), (1230, 560), (1192, 560)])
    s.arrow([(796, 309), (1230, 309)])
    return s


def s4():
    s = Slide("04", "qm_layer: the atomic data unit",
              "One sf object in long format, with metadata in attr(x, 'qm'). Constructors differ by source.",
              "R/qm_layer.R, R/quickmap_api.R, R/wind.R; L: = R/qm_layer.R")
    s.box(40, 110, 380, 148, "from_csv", ["Temporal (no School column, more than one four-digit column): pivot_longer, transform_to_wgs84, shape circle.", "Static: code from School, value_col Level if present, shape cross."], "r", "L:400", bsize=13)
    s.box(40, 270, 380, 94, "from_rdata", ["load_rdata_file (Q:554), duck-typed; shape diamond"], "r", "L:453")
    s.box(40, 376, 380, 94, "from_openair", ["convert_openair_to_spatial (Q:235); shape diamond"], "r", "L:475")
    s.box(40, 482, 380, 90, "from_worldmet", ["Returns qm_wind, not a qm_layer; see slide 7"], "io", "wind.R:25")
    s.box(450, 110, 380, 340, "qm_layer: sf data.frame, long format",
          ["Class c('qm_layer', sf classes)", "code (required)", "lat, lon, geometry (EPSG:4326)", "time_label, time_sort (temporal layers only)",
           "value column, named by value_col", "label column, named by label_col",
           "Aliases dropped: siteCode and site_code to code; year_str to time_label; Latitude and latitude to lat; Longitude and longitude to lon"],
          "r", "L:184, constants L:10-37")
    for y in (175, 317, 423):
        s.arrow([(420, y), (450, y)])
    s.box(860, 110, 380, 120, "attr(x, 'qm')", ["value_col, time_col ('time_label' or NULL), label_col, shape, name, resolution (year, month, day, hour, minute)"], "r", "L:299-310")
    s.box(860, 242, 380, 230, "Validation in qm_layer()",
          ["Shape: aliases (square to rect, cross to simple-cross), then validate_and_fix_icon_shape (Q:3046)",
           "Time: explicit time_col, then Date/POSIXct, then name-gated parse (L:97); grammar YYYY to YYYY-MM-DD HH:MM:SS",
           "Value: explicit, then known pollutant (no2, pm25, pm10, nox, no, o3, so2, co), then the sole candidate, else error"],
          "r", "L:194-297", bsize=13)
    s.box(450, 490, 790, 100, "Renderer still reads legacy columns",
          ["qm_to_legacy (A:15) adds year_str, siteCode, Longitude, Latitude, so qm_layer is not yet the only contract inside render_pollution_map()."],
          "warn", "A:181")
    s.arrow([(640, 450), (640, 490)])
    return s


def s5():
    s = Slide("05", "Configuration: scales, themes, templates and their loaders",
              "Styling lives in inst/ files; three loaders feed the renderer. Explicit arguments beat themes.",
              "R/quickmap.R, inst/; Q: = R/quickmap.R")
    s.box(40, 110, 360, 170, "Colour scales   inst/config/scales (14)",
          ["11 continuous: colours, thresholds (last .Inf), labels, title. 3 categorical (schools, nine_elms, nine_elms_consolidated): colours, domain, labels, title.",
           "footnote_symbols: false only in lbm_aqap_no2, lbm_aqap_pm10"], "cfg", bsize=13)
    s.box(40, 292, 360, 160, "Themes   inst/themes (5)",
          ["airstat, high_contrast, merton, richmond, wandsworth: partial files merged over defaults. Keys: banner, legend, map, controls, indicator, wind. palette appears in 3 files and is undocumented."], "cfg", bsize=13)
    s.box(40, 464, 360, 150, "Templates   inst/banner, legend, controls",
          ["{{placeholder}} in CSS and HTML: banner_style_css, mobile_css, legend_header_bg, legend_header_hover, accent, accent_light, legend_items, legend_title"], "cfg", bsize=13)
    s.box(470, 110, 340, 170, "load_colour_scale",
          ["Reads YAML through load_yaml_config (Q:1225); coerces thresholds to numeric; does not validate."], "r", "Q:1203")
    s.box(470, 292, 340, 160, "load_theme",
          ["Merges file over get_default_theme (Q:1274) with modifyList. Missing or invalid file warns and falls back. Legacy map.marker_labels is renamed with a warning."], "r", "Q:1351")
    s.box(470, 464, 340, 150, "apply_template_replacements",
          ["A {{key}} absent from the template is an error. A template placeholder with no replacement passes silently."], "r", "Q:72-88")
    s.box(880, 110, 360, 170, "Consumers: colour",
          ["assign_colour (Q:1431): findInterval on thresholds; NA gives white; called from create_generic_icons (Q:3195).",
           "generate_legend_html (Q:1622) checks colours and labels lengths."], "r", bsize=13)
    s.box(880, 292, 360, 160, "Consumers: theme",
          ["Precedence: argument, then theme, then default (Q:4111-4130).",
           "Never read (grep of quickmap.R): legend.show, legend.background, banner.text_color, controls.background, controls.text_color."], "warn", bsize=13)
    s.box(880, 464, 360, 150, "Consumers: templates",
          ["build_banner_css (Q:2211), build_legend_css (Q:2283), load_time_slider_control (Q:2644-2719); injected by inject_banner_legend_controls."], "r", bsize=13)
    for y in (195, 372, 539):
        s.arrow([(400, y), (470, y)])
        s.arrow([(810, y), (880, y)])
    return s


def s6():
    s = Slide("06", "R to browser boundary and the JS call order",
              "R writes one HTML file; in the browser, switchToTime calls wind, then indicator, then the lazy or eager path.",
              "R/quickmap.R, inst/controls/*; Q: = R/quickmap.R")
    s.text(40, 108, "R, at build time", 16, INK, "bold")
    s.box(40, 120, 330, 110, "Leaflet widget", ["htmlwidgets saveWidget(selfcontained = TRUE) with JS dependencies inlined"], "r", "Q:2566")
    s.box(40, 242, 330, 170, "onRender attachments",
          ["Wind first: wind-controller.js plus wind payload (Q:4336).", "Then layer-cache.js (eager) or lazy-time-controller.js plus lazy payload (Q:3607-3618)."], "r", "Q:3607-3618", bsize=13)
    s.box(40, 424, 330, 230, "String injection into the saved file",
          ["Anchors </head>, <body, </body> (missing is an error).", "Banner, CSS, window.quickmapConfig {autoplay, playSpeed, speeds}, time-slider.js, window.quickmapIndicatorData plus indicator.js, legend."], "r", "Q:2921-3039", bsize=13)
    s.text(450, 108, "Saved HTML: window objects", 16, INK, "bold")
    s.box(450, 120, 340, 534, "Registered at load",
          ["window.quickmapConfig", "  from R; defaults {autoplay: false, playSpeed: 500}",
           "window.quickmapLayerCache", "  layer-cache.js:23, or a stub at lazy-time-controller.js:241",
           "window.quickmapTimeController", "  lazy only; lazy-time-controller.js:240",
           "window.quickmapWindController", "  wind-controller.js:37; shows the last step at load (38)",
           "window.quickmapIndicatorController", "  indicator.js:107; returns early if no indicator data (11)",
           "window.quickmapPlayInterval", "  time-slider.js:158; the lazy fade reads it (160-164)"], "js", bsize=13)
    s.text(860, 108, "Browser: switchToTime  time-slider.js:20-56", 16, INK, "bold")
    s.box(860, 120, 380, 80, "1 Wind setTime(label)", ["Lines 26-28; updates or removes the velocity layer"], "js", bsize=13)
    s.box(860, 222, 380, 80, "2 Indicator setTime", ["Lines 29-31; above the lazy early return"], "js", bsize=13)
    s.box(860, 324, 380, 90, "3 Lazy: quickmapTimeController.setTime", ["Lines 32-36; returns, so step 4 is skipped"], "js", bsize=13)
    s.box(860, 436, 380, 90, "4 Eager: layer-cache", ["Lines 37-52; add and remove layer groups"], "js", bsize=13)
    s.box(860, 548, 380, 106, "Timer", ["One startTimer() (143-148) reads currentInterval(); play, resume-after-hidden and speed change all go through it."], "js", bsize=13)
    s.arrow([(370, 175), (450, 175)])
    s.arrow([(370, 327), (450, 327)])
    s.arrow([(370, 539), (450, 539)])
    s.arrow([(790, 160), (860, 160)])
    s.arrow([(1050, 200), (1050, 222)])
    s.arrow([(1050, 302), (1050, 324)])
    s.arrow([(1050, 414), (1050, 436)], dashed=True, label="not lazy", label_at=(1100, 430))
    return s


def s7():
    s = Slide("07", "Wind animation data flow",
              "One uniform wind value per time step across the map, rendered by vendored leaflet-velocity. Interactive HTML only.",
              "R/wind.R, inst/controls/wind-controller.js; W: = R/wind.R")
    cols = [
        ("from_worldmet", "W:25-58", ["Data frame, or worldmet::importNOAA(station, year). Needs date, ws, wd; drops NA. u = -ws sin(wd), v = -ws cos(wd)."], "r"),
        ("build_wind_payload", "W:86-134", ["Date format chosen from step-label width (4, 7, 10, 13, 16 chars). Mean u and v per step. 2x2 grid over bbox + 3 degrees. maxVelocity = ceiling(max ws) + 2. Empty step is null."], "r"),
        ("wind_style_options", "W:140", ["Theme wind block over defaults: colour_ramp to colorScale, particle_density to particleMultiplier, line_width to lineWidth, velocity_scale to velocityScale."], "r"),
        ("Attach to the widget", "W:173, Q:4335-4343", ["add_wind_layer: onRender(wind-controller.js, payload). velocity_dependency (W:159) inlines the plugin."], "r"),
    ]
    for i, (t, r, b, k) in enumerate(cols):
        x = 40 + 308 * i
        s.box(x, 120, 275, 230, t, b, k, r, bsize=13)
        if i < 3:
            s.arrow([(x + 275, 235), (x + 308, 235)])
    s.text(40, 394, "In the browser", 16, INK, "bold")
    s.box(40, 406, 360, 150, "quickmapWindController.setTime(label)", ["wind-controller.js:37. Looks up the frame by label; a null frame removes the layer (13)."], "js", bsize=13)
    s.box(460, 406, 360, 150, "L.velocityLayer", ["Created on first call (25) and added to the map; updateData(frame) afterwards (19)."], "js", bsize=13)
    s.box(880, 406, 360, 150, "leaflet-velocity 2.1.4, patched", ["Vendored, unminified. QUICKMAP patch markers at lines 103, 341, 823-877, 933, 1019-1036."], "js", bsize=13)
    s.arrow([(1102, 350), (1102, 380), (220, 380), (220, 406)])
    s.arrow([(400, 481), (460, 481)])
    s.arrow([(820, 481), (880, 481)])
    s.box(40, 580, 1200, 90, "Scope",
          ["Interactive maps with temporal data only; never in JPG frames. The field is uniform: one averaged vector for the whole map at each step. Non-uniform fields are a post-1.0 plan."],
          "io", bsize=13)
    return s


def s8():
    s = Slide("08", "Documented claims the code contradicts",
              "Found by reading the source; CLAUDE.md says the code is the source of truth.",
              "Cites: Q: = R/quickmap.R, W: = R/wind.R. 'grep only' = not traced by hand")
    rows = [
        ("Pipeline runs load_data_file to generate_map_layers in order", "quickmap() passes sf layers, so load_data_file is not reached on that path. generate_map_layers is the outer driver calling prepare_generic_layer_data and add_layer; add_layer calls create_generic_icons.", "Q:3823, Q:3674"),
        ("generate_map_layers emits HTML and static exports from one loop", "It only draws markers. Static frames use add_year_and_static_layers in the shared loop.", "Q:2309, Q:4279"),
        ('Example quickmap("wandsworth_2017_2024.csv", boroughs = ...)', "output_file is required, so the call errors.", "Q:2354"),
        ("who_no2.yaml has 5 bands, name, pollutant", "Real file: 11 bands, no name, no pollutant.", "who_no2.yaml"),
        ("Theme keys legend.show, legend.background, banner.text_color, controls.background, controls.text_color", "Not read anywhere in R/quickmap.R (grep only).", "Q:1274-1344"),
        ("A missing placeholder is a hard error", "Only a {{key}} absent from the template errors; an unfilled template placeholder passes silently.", "Q:72-88"),
        ("Two timer-start sites must read currentInterval", "One startTimer() reads it; the lazy fade reads window.quickmapPlayInterval.", "time-slider.js:143-148"),
        ("Wind comes from one worldmet station", "Any data frame with date, ws, wd is accepted.", "W:25-58"),
        ("indicator.placement defaults to title_row", "True in get_default_theme; function fallbacks use right.", "Q:4216, Q:2937"),
        ("Controls comments describe the roller menu and switchToYear", "Stale: replaced by the time slider.", "wind-controller.js:4"),
    ]
    xs = (40, 70, 560, 1090)
    ws = (30, 490, 530, 150)
    y = 98
    for i, h in enumerate(("#", "Documented", "Code says", "Evidence")):
        pass
    s.parts.append(f'<rect x="40" y="{y}" width="1200" height="26" fill="#1f2937"/>')
    for x, h in zip(xs, ("#", "Documented", "Code says", "Evidence")):
        s.text(x + 6, y + 18, h, 14, "#ffffff", "bold")
    y += 26
    for n, (c, k, e) in enumerate(rows, 1):
        cols = [textwrap.wrap(c, 62, break_long_words=False), textwrap.wrap(k, 66, break_long_words=False), textwrap.wrap(e, 17, break_long_words=False)]
        lines = max(len(x) for x in cols)
        h = max(34, 12 + lines * 17)
        fill = "#fee2e2" if n in (1, 2, 3) else "#f3f4f6"
        s.parts.append(f'<rect x="40" y="{y}" width="1200" height="{h}" fill="{fill}" stroke="#d1d5db" stroke-width="1"/>')
        s.text(46, y + 21, str(n), 13, INK, "bold")
        for x, col in zip(xs[1:], cols):
            for j, ln in enumerate(col):
                s.text(x + 6, y + 21 + j * 17, ln, 13, INK)
        y += h
    if y > 684:
        WARNINGS.append(f"08: table ends at y={y}, over 684")
    s.text(40, y + 16, "Red rows 1-3 change how a reader should understand the pipeline or break a copied example.", 12, MUTED)
    return s


def s9():
    s = Slide("09", "Technology stack by layer",
              "Data flows top to bottom: R packages build the map, a saved HTML file carries it, the browser runs it.",
              "DESCRIPTION (Imports, Suggests), R/, inst/controls/, .claude/; CLAUDE.md claims marked")
    rows = [
        ("Data in", "io", "CSV (diffusion tubes, schools), RData objects, OpenAir tibbles, NOAA wind through worldmet.",
         "Suggests: openair, worldmet, httr, jsonlite. Planned: Breathe London API (roadmap item 12, blocked on an API key)."),
        ("Spatial data and wrangling (R)", "r", "sf: British National Grid EPSG:27700 to WGS84 EPSG:4326. dplyr, tidyr, lubridate, zeallot, yaml.",
         "Boundaries come from get_boundary_sf (Q:1028); scales and themes are read as YAML."),
        ("Map construction (R)", "r", "leaflet (R package, 2.2.2 or later), leaflegend, htmlwidgets (1.6.2 or later), htmltools.",
         "htmlwidgets saveWidget(selfcontained = TRUE) writes the file; onRender attaches the JS controllers."),
        ("Browser runtime (JS)", "js", "Leaflet map inside the widget. Hand-written JS files in inst/controls: time-slider, indicator, lazy-time-controller, layer-cache, wind-controller.",
         "Vendored leaflet-velocity 2.1.4, patched, for wind. All JS and CSS inlined into the one HTML file."),
        ("Static export", "io", "webshot2 screenshots an intermediate HTML to JPG (headless Chrome; the roadmap defect list names chromote).",
         "The intermediate HTML is deleted. Wind is not drawn in JPG frames."),
        ("Docs, tests, tooling", "io", "testthat suite in tests/testthat; vignettes (knitr, rmarkdown); pkgdown site in docs/.",
         "Claude Code hooks: gatekeeper.py (Python) and protect-main.sh (jq) guard unattended runs and commits on main."),
    ]
    y = 98
    for t, k, a, b in rows:
        s.box(40, y, 1200, 78, t, [a, b], k, bsize=13)
        y += 84
    s.box(40, 608, 1200, 78, "Rendering backend decision (per CLAUDE.md; not traced in this audit)",
          ["Leaflet with Canvas markers restyled from one embedded JSON payload (\"Option D\"), approved 2026-07-06. MapLibre/mapgl is the post-1.0 path.",
           "Default base tiles are OpenStreetMap when base_tiles is NULL (CLAUDE.md). Sharing constraint: output must work as a self-contained file."],
          "io", bsize=13)
    return s


def page(slides_):
    nav = "".join(f'<a href="#v{s.slug}">{s.slug} {esc(s.title)}</a>' for s in slides_)
    figs = ""
    for s in slides_:
        figs += (
            f'<section id="v{s.slug}"><figure>{s.svg()}'
            f'<figcaption>{esc(s.title)} · <a href="svg/{s.slug}.svg">SVG</a> · <a href="png/{s.slug}.png">PNG</a></figcaption></figure></section>\n'
        )
    return f"""<!doctype html>
<html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>QuickMap Architecture</title>
<style>
:root{{--bg:#f9fafb;--fg:#1f2937;--muted:#4b5563;--card:#ffffff;--line:#d1d5db;--link:#1d4ed8}}
@media (prefers-color-scheme: dark){{:root:not([data-theme="light"]){{--bg:#111827;--fg:#e5e7eb;--muted:#9ca3af;--card:#1f2937;--line:#374151;--link:#93c5fd}}}}
:root[data-theme="dark"]{{--bg:#111827;--fg:#e5e7eb;--muted:#9ca3af;--card:#1f2937;--line:#374151;--link:#93c5fd}}
body{{margin:0;background:var(--bg);color:var(--fg);font:16px/1.5 Arial,Helvetica,sans-serif}}
header,main{{max-width:1320px;margin:0 auto;padding:16px}}
h1{{font-size:24px;margin:8px 0}}p{{color:var(--muted);margin:4px 0 12px}}
nav{{display:flex;flex-wrap:wrap;gap:8px 16px;margin-bottom:8px}}a{{color:var(--link)}}
section{{margin:0 0 24px}}figure{{margin:0;background:var(--card);border:1px solid var(--line);border-radius:8px;padding:8px}}
svg{{width:100%;height:auto;display:block}}figcaption{{padding:8px 4px 0;color:var(--muted);font-size:14px}}
</style></head><body>
<header><h1>QuickMap architecture</h1>
<p>Nine views built from reading the source at v0.9.9.13 (branch feature/item9-output-paths, audited 2026-10-05). Each box cites file:line. View 8 lists claims in CLAUDE.md that the code contradicts. Each view is also a standalone SVG and PNG for slides.</p>
<nav>{nav}</nav></header>
<main>
{figs}</main></body></html>
"""


if __name__ == "__main__":
    built = [f() for f in (s1, s2, s3, s4, s5, s6, s7, s8, s9)]
    os.makedirs(os.path.join(OUT, "svg"), exist_ok=True)
    os.makedirs(os.path.join(OUT, "png"), exist_ok=True)
    names = {
        "01": "01_system_overview", "02": "02_quickmap_to_render_stages", "03": "03_loop_lazy_static_save",
        "04": "04_qm_layer_data_model", "05": "05_configuration", "06": "06_r_to_browser_boundary",
        "07": "07_wind_data_flow", "08": "08_docs_vs_code", "09": "09_technology_stack",
    }
    for s in built:
        s.slug = names[s.slug]
    for s in built:
        with open(os.path.join(OUT, "svg", s.slug + ".svg"), "w", encoding="utf-8") as f:
            f.write(s.svg())
    with open(os.path.join(OUT, "index.html"), "w", encoding="utf-8") as f:
        f.write(page(built))
    for w in WARNINGS:
        print("OVERFLOW", w)
    print("built", len(built))
