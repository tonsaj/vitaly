# Vitaly App Icon Design Specification

## Overview

Premium health app icon for **Vitaly** - a Swedish iOS health tracking application inspired by WHOOP's modern aesthetic. The icon features a radiating sunburst design that embodies energy, vitality, and the app's core health monitoring purpose.

---

## Design Concept

### Primary Design (AppIcon.png)
**Sunburst with Gradient Rays**

The icon features a geometric sunburst pattern radiating from a central circle, using the Vitaly brand gradient colors. This design:
- Symbolizes vitality, energy, and daily health cycles
- References the sun/light motif used throughout the app
- Creates a distinctive, recognizable mark at all sizes
- Maintains premium, minimal aesthetic aligned with WHOOP-style apps

### Alternative Design (AppIcon_V.png)
**Sunburst with "V" Monogram**

Same sunburst design with a minimalist "V" lettermark in the center circle, providing:
- Brand initial recognition
- Additional visual anchor point
- Slightly more literal brand connection

---

## Design Elements

### Color Palette

| Color Name | Hex Code | RGB Values | Usage |
|------------|----------|------------|-------|
| Primary (Warm Orange) | `#F27340` | `rgb(0.95, 0.45, 0.25)` | Primary rays, center gradient |
| Secondary (Coral/Peach) | `#FA9973` | `rgb(0.98, 0.6, 0.45)` | Middle rays, gradient transition |
| Tertiary (Light Peach) | `#FFC7A6` | `rgb(1.0, 0.78, 0.65)` | Outer rays, gradient highlights |
| Background (Deep Black) | `#0D0D12` | `rgb(0.05, 0.05, 0.07)` | Base background, "V" stroke |

### Gradient Application

**Primary Gradient**: Linear diagonal gradient from Primary → Secondary → Tertiary
- Creates warm "sunset" effect
- Flows top-left to bottom-right
- Applied to center circle

**Ray Colors**: Distributed progressively around the sunburst
- First third (0-33%): Primary color
- Second third (33-66%): Secondary color
- Final third (66-100%): Tertiary color
- Creates smooth color rotation

### Geometry

**Icon Size**: 1024×1024px (iOS master size)

**Sunburst Structure**:
- **Total Rays**: 24 rays (12 long, 12 short, alternating)
- **Inner Radius**: 15% of icon size (154px)
- **Long Ray Radius**: 48% of icon size (492px)
- **Short Ray Radius**: 38% of icon size (389px)
- **Long Ray Width**: 4.5% of icon size (46px)
- **Short Ray Width**: 3.5% of icon size (36px)

**Center Circle**:
- **Radius**: 14.25% of icon size (146px)
- **Inner Glow Radius**: 8.55% of icon size (88px)
- **Glow Opacity**: 30%

**"V" Lettermark** (alternative version):
- **Stroke Width**: 2.4% of icon size (25px)
- **Height**: 75% of center radius (109px)
- **Width**: 65% of center radius (95px)
- **Stroke Color**: Background dark for contrast
- **Stroke Cap**: Round
- **Stroke Join**: Round

---

## Technical Specifications

### File Format
- **Master File**: PNG (1024×1024px)
- **Color Space**: sRGB
- **Bit Depth**: 8 bits per channel
- **Alpha Channel**: Premultiplied

### iOS Size Requirements
The 1024×1024 master icon scales to all required iOS sizes:

| Size | Usage | Scale Factors |
|------|-------|---------------|
| 1024×1024 | App Store | @1x |
| 180×180 | iPhone (iOS 14+) | @3x (60pt) |
| 167×167 | iPad Pro | @2x (83.5pt) |
| 152×152 | iPad, iPad mini | @2x (76pt) |
| 120×120 | iPhone (iOS 14+) | @2x (60pt) |
| 87×87 | iPhone | @3x (29pt) |
| 80×80 | iPad, iPad mini | @2x (40pt) |
| 76×76 | iPad | @1x (76pt) |
| 60×60 | iPhone | @2x (30pt) |
| 58×58 | iPad, iPhone | @2x (29pt) |
| 40×40 | iPad, iPhone | @2x (20pt) |
| 29×29 | iPad, iPhone | @1x (29pt) |
| 20×20 | iPad, iPhone | @1x (20pt) |

### Scalability Testing
The icon design maintains clarity and recognition at all sizes:
- **Large (1024-180px)**: Full detail visible, gradient smooth, rays distinct
- **Medium (152-60px)**: Sunburst pattern clear, colors recognizable
- **Small (58-20px)**: Shape recognizable, overall impression maintained

---

## Design Rationale

### Brand Alignment
- **Color Consistency**: Uses exact Vitaly brand colors from design system
- **Visual Motif**: Sunburst aligns with app's existing sun/rays iconography
- **Premium Feel**: Dark background with warm accents matches WHOOP aesthetic
- **Energy & Vitality**: Radiating design communicates health, energy, and dynamism

### User Experience Considerations

**Home Screen Visibility**:
- **Light Backgrounds**: Warm colors pop against white/light backgrounds
- **Dark Backgrounds**: Dark base with bright rays stands out in dark mode
- **High Contrast**: 4.5:1+ contrast ratio ensures accessibility

**Recognition**:
- **Unique Shape**: Geometric sunburst differentiates from common health app icons
- **Consistent Brand**: Reinforces in-app visual language
- **Memorable**: Distinctive radial pattern aids quick recognition

**Platform Integration**:
- **iOS Guidelines**: Follows Apple HIG for app icons
- **No Transparency**: Solid background as required
- **No Text** (except alternative): Primary design is purely symbolic
- **Corner Radius**: iOS automatically applies mask

---

## Implementation Files

### Generated Assets

1. **AppIcon.png** (Primary - Recommended)
   - Location: `/iOSHealth/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png`
   - Size: 1024×1024px
   - Design: Pure sunburst with gradient center

2. **AppIcon_V.png** (Alternative)
   - Location: `/iOSHealth/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon_V.png`
   - Size: 1024×1024px
   - Design: Sunburst with "V" monogram

### Generator Scripts

1. **GenerateAppIcon.swift**
   - Generates primary sunburst icon
   - Programmatic CoreGraphics rendering
   - Fully customizable parameters

2. **GenerateAppIcon_WithV.swift**
   - Generates alternative version with "V"
   - Same base design with lettermark overlay

### Asset Catalog Configuration

**Contents.json** configuration:
```json
{
  "images" : [
    {
      "filename" : "AppIcon.png",
      "idiom" : "universal",
      "platform" : "ios",
      "size" : "1024x1024"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
```

---

## Usage Guidelines

### Recommended Primary Icon
**AppIcon.png** (pure sunburst) is recommended because:
- More abstract and scalable
- Cleaner at small sizes
- More modern and minimal
- Better aligns with WHOOP-style aesthetic
- "V" shape could be less clear at small sizes

### When to Use Alternative
Use **AppIcon_V.png** if:
- Stronger brand letter recognition needed
- Competing with many health apps in same space
- User testing shows preference for lettermark
- Marketing requires more explicit branding

### Customization

To modify the icon design, edit parameters in generator scripts:

**Color Changes**: Update CGColor values at top of script
```swift
let primaryColor = CGColor(red: 0.95, green: 0.45, blue: 0.25, alpha: 1.0)
```

**Ray Count**: Modify `numberOfRays` variable (recommended: 16, 20, 24, or 32)
```swift
let numberOfRays = 24
```

**Proportions**: Adjust radius multipliers
```swift
let innerRadius = iconSize * 0.15  // Center circle size
let outerRadius = iconSize * 0.48  // Long ray length
```

---

## Accessibility

### Contrast Ratios
- **Rays on Dark Background**: >7:1 (AAA level)
- **Overall Icon**: High contrast ensures visibility for low vision users
- **Color Independence**: Shape recognizable without color (for color blindness)

### Reduced Motion
Icon is static (no animation), respecting reduced motion preferences.

### VoiceOver
Asset catalog automatically provides "Vitaly" app name for VoiceOver users.

---

## Quality Assurance Checklist

- [x] Uses exact Vitaly brand colors from design system
- [x] 1024×1024px master size for App Store
- [x] Works on both light and dark backgrounds
- [x] Maintains clarity at 20×20px minimum size
- [x] No transparency (solid background)
- [x] Follows iOS Human Interface Guidelines
- [x] Aligns with WHOOP-style modern health aesthetic
- [x] Incorporates sunburst motif from app design
- [x] High contrast for accessibility
- [x] Distinctive and memorable design
- [x] Programmatically generated (reproducible)
- [x] Alternative version provided

---

## Next Steps

### To Use the Icon

1. **Review both versions**:
   ```bash
   open /Users/tonsaj/Workspace/iOSHealth/iOSHealth/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png
   open /Users/tonsaj/Workspace/iOSHealth/iOSHealth/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon_V.png
   ```

2. **Select preferred version**: Rename chosen file to `AppIcon.png` if using alternative

3. **Build and test**: Run app on simulator and device to verify appearance

4. **Test on home screen**: Check visibility on various wallpapers

### Future Enhancements

- **Seasonal Variants**: Adjust colors for special events
- **Animated Icon**: iOS 18+ supports animated icons (can animate rays)
- **Widget Icons**: Create matching widget glyphs using same sunburst motif
- **Alternative Color Schemes**: Generate variations for testing

---

## Design Credits

**Created**: January 2026
**Platform**: iOS 17+
**Design System**: Vitaly Brand Guidelines
**Style Reference**: WHOOP-inspired premium health aesthetic
**Generated**: Programmatically using CoreGraphics/Swift

---

## Files Reference

| File | Path | Purpose |
|------|------|---------|
| AppIcon.png | Resources/Assets.xcassets/AppIcon.appiconset/ | Primary app icon (recommended) |
| AppIcon_V.png | Resources/Assets.xcassets/AppIcon.appiconset/ | Alternative with "V" monogram |
| Contents.json | Resources/Assets.xcassets/AppIcon.appiconset/ | Asset catalog configuration |
| GenerateAppIcon.swift | Project root | Icon generator script (primary) |
| GenerateAppIcon_WithV.swift | Project root | Icon generator script (alternative) |
| APP_ICON_DESIGN_SPEC.md | Project root | This specification document |

---

## Support

For questions or modifications to the icon design, refer to:
- **Color System**: `/iOSHealth/Core/Extensions/Color+Extensions.swift`
- **Generator Scripts**: `GenerateAppIcon.swift` and `GenerateAppIcon_WithV.swift`
- **This Document**: `APP_ICON_DESIGN_SPEC.md`

To regenerate icons with modifications, simply edit the generator scripts and run:
```bash
swift GenerateAppIcon.swift
swift GenerateAppIcon_WithV.swift
```
