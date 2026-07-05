# Airstat Styling Reference

Based on inspection of https://airstat-v3.onrender.com/

## Color Scale (NO2, µg/m³)

```yaml
colours:
  - "#75B3F0"  # <10: Light blue
  - "#63D2E9"  # 10-20: Cyan
  - "#67E4A6"  # 20-30: Mint green
  - "#6CF20D"  # 30-40: Bright green
  - "#F9B11F"  # 40-60: Orange
  - "#D92626"  # 60-100: Red
  - "#A32929"  # >100: Dark red
```

## Marker Styling

- **Shape**: Circles
- **Fill Opacity**: 75% (`0.75`)
- **Stroke**: 2px white border (`#ffffff`)
- **Stroke Opacity**: 100% (`1.0`)
- **Size**: 12px diameter

## Basemap

- **Provider**: Light, minimal basemap (equivalent to `CartoDB.Positron`)
- Clean, muted colors with minimal labels
- Focus on data visibility

## Legend Design

- **Background**: Semi-transparent white with blur (`rgba(255, 255, 255, 0.7)`)
- **Effect**: Glassmorphism (backdrop blur: 12px)
- **Border Radius**: 12px
- **Border**: 1px white with 20% opacity (`rgba(255, 255, 255, 0.2)`)
- **Shadow**: Subtle (`0 10px 25px rgba(0, 0, 0, 0.1)`)
- **Position**: Bottom-right corner
- **Scale Items**:
  - Circular swatches (12px diameter)
  - 1px white border
  - Values displayed adjacent

## UI Elements

- **Framework**: TailwindCSS utility classes
- **Transitions**: Smooth 300ms (`transition-all duration-300`)
- **Typography**: Clean, modern sans-serif
- **Controls**: Minimal, icon-based

## Layout

- **Vignette**: Disabled (no darkening outside focus area)
- **Boundary Labels**: Disabled
- **Banner**: Minimal/absent (focus on map)

## Typeface

* 

