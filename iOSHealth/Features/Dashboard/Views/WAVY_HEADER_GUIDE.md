# Wavy Header Implementation Guide

## Overview

The Vitaly app now features dynamic, animated wavy headers that create an organic, flowing design aesthetic. The headers use the app's sunset gradient color scheme with subtle pulsing animations for a modern, engaging user experience.

## Files Created

1. **WavyHeaderView.swift** - Main wavy header components
2. **AnimatedSunburstLogo.swift** - Animated logo for onboarding and branding
3. **WavyHeaderExamples.swift** - Example implementations and demo views
4. **DashboardView.swift** - Updated to use the new wavy header

## Components

### 1. WavyHeaderView

The main animated header with multiple wave layers and pulsing effects.

```swift
WavyHeaderView(
    title: "Välkommen",
    subtitle: "Torsdag, 12 januari"
)
```

**Features:**
- Three layered animated waves with different frequencies and amplitudes
- Sunset gradient colors (vitalyPrimary, vitalySecondary, vitalyTertiary)
- Subtle pulsing glow effect
- 8-second wave animation loop
- 2.5-second pulse animation loop
- Height: 200pt

**Use Cases:**
- Dashboard main header
- Welcome screens
- Hero sections

---

### 2. CompactWavyHeader

A smaller version for internal pages and secondary screens.

```swift
CompactWavyHeader(title: "Profil")
```

**Features:**
- Single animated wave layer
- Smaller footprint (120pt height)
- Same gradient styling
- Less prominent than full header

**Use Cases:**
- Settings pages
- Profile screens
- Detail views

---

### 3. WavyDivider

A decorative wavy divider for separating content sections.

```swift
WavyDivider(height: 40)
```

**Features:**
- Thin animated wave
- Customizable height
- Subtle gradient colors
- 6-second animation loop

**Use Cases:**
- Section separators
- Content breaks
- Timeline dividers

---

### 4. AnimatedSunburstLogo

Animated logo with rotating rays and pulsing effects.

```swift
AnimatedSunburstLogo()
    .frame(width: 200, height: 200)
```

**Features:**
- 16 animated rays with gradient colors
- 20-second rotation animation
- 2-second pulse effect
- 3-second glow pulse
- Radial gradient center
- Outer glow with blur

**Variants:**
- `StaticSunburstLogo(size:)` - Non-animated version
- `MiniSunburstIcon(size:)` - Small icon version

**Use Cases:**
- Onboarding screens
- Splash screens
- App icon placeholder
- Loading indicators

---

## Color Scheme

All wavy headers use the Vitaly brand colors:

| Color | Hex | Usage |
|-------|-----|-------|
| Primary | #F27340 | Main wave, dominant gradient |
| Secondary | #FA9973 | Middle wave, gradient blend |
| Tertiary | #FFC7A6 | Back wave, highlight |
| Background | #0D0D12 | Base background |

## Animation Details

### Wave Animation

```swift
withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
    phase = 2 * .pi
}
```

- Type: Linear continuous
- Duration: 8 seconds
- Pattern: Sine wave
- Direction: Horizontal flow

### Pulse Animation

```swift
withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
    pulseScale = 1.3
}
```

- Type: EaseInOut
- Duration: 2.5 seconds
- Scale: 1.0 → 1.3 → 1.0
- Applies to: Glow effect

## Implementation Examples

### Dashboard Header

```swift
ScrollView(showsIndicators: false) {
    VStack(spacing: 0) {
        WavyHeaderView(
            title: viewModel.dateDisplayText,
            subtitle: viewModel.todayDate
        )
        .overlay(alignment: .topTrailing) {
            // Navigation controls
            HStack(spacing: 12) {
                // Left/Right buttons
            }
            .padding()
        }

        // Content here
    }
}
```

### Profile Screen

```swift
ScrollView {
    VStack(spacing: 0) {
        CompactWavyHeader(title: "Profil")

        // Profile content
    }
}
.background(Color.vitalyBackground)
```

### Section Dividers

```swift
VStack(spacing: 0) {
    // Section 1 content

    WavyDivider(height: 50)
        .padding(.vertical, 20)

    // Section 2 content
}
```

## Best Practices

### Performance

1. **Use Appropriate Variant**
   - Full header (WavyHeaderView): Hero sections only
   - Compact header: Most internal pages
   - Divider: Section breaks

2. **Avoid Overuse**
   - One animated header per screen
   - Limit dividers to 2-3 per scrollable view
   - Static headers for modals and sheets

3. **Animation Performance**
   - Animations use SwiftUI's native animatableData
   - GPU-accelerated blur and gradients
   - Minimal CPU overhead with Shape protocol

### Accessibility

1. **Reduce Motion**
   - Consider adding `@Environment(\.accessibilityReduceMotion)` check
   - Disable animations when reduce motion is enabled

```swift
@Environment(\.accessibilityReduceMotion) var reduceMotion

var body: some View {
    WavyHeaderView(...)
        .onAppear {
            if !reduceMotion {
                startAnimations()
            }
        }
}
```

2. **Contrast**
   - Headers maintain WCAG AA contrast ratios
   - Text always uses vitalyTextPrimary/Secondary
   - Gradients are subtle enough for readability

### Dark Mode

- All components designed for dark theme
- Light mode support can be added by:
  - Adjusting opacity values
  - Using semantic colors
  - Testing contrast ratios

## Customization

### Adjusting Wave Behavior

```swift
AnimatedWaveLayer(
    phase: phase,
    amplitude: 25,      // Height of wave peaks (default: 15-25)
    frequency: 1.2,     // Number of wave cycles (default: 1.2-1.8)
    offset: 0           // Vertical offset (default: 0-20)
)
```

### Changing Colors

```swift
.fill(
    LinearGradient(
        colors: [
            Color.vitalyPrimary,      // Replace with custom colors
            Color.vitalySecondary
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
)
```

### Animation Speed

```swift
// Slower wave (more relaxed)
.linear(duration: 12)

// Faster wave (more energetic)
.linear(duration: 5)
```

## Troubleshooting

### Header Not Animating

1. Check `onAppear` is triggering
2. Verify `@State private var phase: CGFloat = 0` is defined
3. Ensure view is not inside a `LazyVStack` (animations may pause)

### Performance Issues

1. Reduce blur radius (default: 2, try 0-1)
2. Use fewer wave layers (2 instead of 3)
3. Increase animation duration for slower updates
4. Consider static header for low-end devices

### Incorrect Colors

1. Verify Color+Extensions.swift is imported
2. Check color definitions match brand guidelines
3. Ensure dark mode is active (preferredColorScheme)

## Future Enhancements

Potential improvements for future versions:

1. **Dynamic Colors**
   - Time-based gradients (sunrise, midday, sunset)
   - User-selectable themes
   - Metric-based colors (green for good health)

2. **Interactive Waves**
   - Drag gestures affect wave motion
   - Tap creates ripple effects
   - Scroll-linked animations

3. **Seasonal Variations**
   - Winter: Cool blues and whites
   - Summer: Warm yellows and oranges
   - Spring: Fresh greens and pinks
   - Autumn: Deep reds and browns

4. **Accessibility**
   - Automatic reduce motion support
   - High contrast mode
   - Simplified animations setting

## Testing

Run the example view to see all variations:

```swift
#Preview {
    WavyHeaderExamplesView()
        .preferredColorScheme(.dark)
}
```

This provides interactive demos of:
- Dashboard style header
- Profile compact header
- Settings compact header
- Wave divider sections

## Credits

Designed for Vitaly - Swedish health tracking app
Created: January 2026
Design System: Warm dark theme with sunset gradients
Inspired by: Organic, flowing natural forms
