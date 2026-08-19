---
name: Dash Visual Identity
colors:
  surface: '#04132c'
  surface-dim: '#04132c'
  surface-bright: '#2c3954'
  surface-container-lowest: '#000d26'
  surface-container-low: '#0c1b34'
  surface-container: '#111f39'
  surface-container-high: '#1c2a44'
  surface-container-highest: '#27354f'
  on-surface: '#d7e2ff'
  on-surface-variant: '#c2c6d1'
  inverse-surface: '#d7e2ff'
  inverse-on-surface: '#23304a'
  outline: '#8c919b'
  outline-variant: '#424750'
  surface-tint: '#a6c8ff'
  primary: '#a6c8ff'
  on-primary: '#00315f'
  primary-container: '#2a5c9a'
  on-primary-container: '#bcd5ff'
  inverse-primary: '#2e5f9d'
  secondary: '#abc7ff'
  on-secondary: '#002f66'
  secondary-container: '#006fe1'
  on-secondary-container: '#f8f8ff'
  tertiary: '#ffb86d'
  on-tertiary: '#492900'
  tertiary-container: '#854e00'
  on-tertiary-container: '#ffc994'
  error: '#ffb4ab'
  on-error: '#690005'
  error-container: '#93000a'
  on-error-container: '#ffdad6'
  primary-fixed: '#d5e3ff'
  primary-fixed-dim: '#a6c8ff'
  on-primary-fixed: '#001c3b'
  on-primary-fixed-variant: '#094784'
  secondary-fixed: '#d7e2ff'
  secondary-fixed-dim: '#abc7ff'
  on-secondary-fixed: '#001b3f'
  on-secondary-fixed-variant: '#004590'
  tertiary-fixed: '#ffdcbd'
  tertiary-fixed-dim: '#ffb86d'
  on-tertiary-fixed: '#2c1600'
  on-tertiary-fixed-variant: '#693c00'
  background: '#04132c'
  on-background: '#d7e2ff'
  surface-variant: '#27354f'
  surface-card: '#121212'
  text-primary: '#FFFFFF'
  text-detail: '#A8D8EA'
typography:
  display-metrics:
    fontFamily: Inter
    fontSize: 48px
    fontWeight: '800'
    lineHeight: 56px
    letterSpacing: -0.04em
  headline-lg:
    fontFamily: Inter
    fontSize: 32px
    fontWeight: '700'
    lineHeight: 40px
  headline-lg-mobile:
    fontFamily: Inter
    fontSize: 24px
    fontWeight: '700'
    lineHeight: 32px
  headline-md:
    fontFamily: Inter
    fontSize: 20px
    fontWeight: '700'
    lineHeight: 28px
  body-lg:
    fontFamily: Inter
    fontSize: 18px
    fontWeight: '300'
    lineHeight: 28px
  body-md:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '300'
    lineHeight: 24px
  label-bold:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '700'
    lineHeight: 20px
    letterSpacing: 0.05em
  label-sm:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '400'
    lineHeight: 16px
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  base: 8px
  touch-target: 56px
  gutter: 16px
  margin-mobile: 20px
  margin-desktop: 40px
---

## Brand & Style

The design system is a high-performance, driver-centric interface engineered for night-time navigation and automotive telemetry. The brand personality is precise, futuristic, and ultra-reliable, evoking the feel of a premium electric vehicle cockpit. It prioritizes safety through cognitive ease, minimizing glare while maximizing information "scannability" during motion.

The visual style is **Glassmorphism** layered over **Minimalism**. It utilizes deep navy depths and frosted black surfaces to create a sense of multi-dimensional space. The atmosphere is defined by high-contrast interactions and subtle radial glows that guide the eye toward critical data points without causing night-blindness.

## Colors

The palette is optimized for low-glare, high-contrast environments. 
- **Primary & Highlighting:** Royal Blue is used for primary actions, while Electric Blue is reserved for active states, live telemetry, and progress indicators to ensure they "pop" against the dark base.
- **Surface Strategy:** The background is a Deep Navy Blue to maintain a "true dark" feel that is softer on the eyes than pure black. Jet Black is used exclusively for card surfaces to provide maximum contrast for data.
- **Functional Accents:** Soft Cyan is used for secondary details and supporting metrics to provide a cooling effect that balances the intensity of the blues.

## Typography

**Inter** is utilized across the entire system for its mathematical precision and exceptional legibility at small sizes. 

The typographic hierarchy is built on a "Weight Contrast" model. Headlines and critical metrics use **Bold** (700) or **Extra Bold** (800) weights to ensure they are readable at a glance from a distance. In contrast, supporting text and secondary descriptions use **Light** (300) weights to reduce visual noise and create a sophisticated, technical aesthetic. Labels for data points should use uppercase and increased letter spacing to further distinguish them from prose.

## Layout & Spacing

The layout follows a **Fluid Grid** model designed for rapid interaction. 

- **Safety Margins:** Generous safe areas are maintained on the edges of the screen to account for bezel overlap in automotive mounts.
- **Rhythm:** An 8px linear scale governs all spatial relationships. 
- **Interaction Model:** Because the user may be in motion, the minimum touch target is strictly 56px. This ensures "blind-reach" capability for primary controls.
- **Adaptive Reflow:** On mobile/vertical displays, metrics stack vertically. On wide-screen automotive displays, the layout splits into a 3nd/2rd ratio, placing navigation on the left and telemetry cards on the right.

## Elevation & Depth

This design system eschews traditional drop shadows in favor of **Glassmorphism** and **Radial Gradients** to define depth.

- **Surface Treatment:** Cards use Jet Black with a 20% opacity and a heavy backdrop blur (20px-30px). This allows the Deep Navy background and its subtle gradients to bleed through, creating a sense of "luminance from within."
- **Edge Definition:** Rather than shadows, surfaces are defined by a 1px inner border (rim light) using a low-opacity White or Soft Cyan to simulate light catching the edge of a glass pane.
- **Gradients:** Subtle, large-scale radial gradients are placed in the background (centered or corner-anchored) to create a sense of focal points and prevent the dark UI from feeling flat or "dead."

## Shapes

The shape language is **Rounded**, reflecting the ergonomic curves of modern automotive interiors. 

Corner radii are standardized to 0.5rem (8px) for standard components, providing a balance between technical precision and organic approachability. Larger containers and cards utilize 1rem (16px) to emphasize the "glass pane" metaphor. Buttons and chips use a higher radius (up to pill-shaped) to clearly distinguish them from informational cards.

## Components

### Buttons
- **Primary:** Royal Blue fill with White Bold text. No shadow; instead, use a 1px Electric Blue outer glow for the active state.
- **Ghost:** Transparent background with a Soft Cyan border. Used for secondary actions to keep the visual field clear.

### Cards & Containers
- Must feature a frosted glass effect. The background should be Jet Black at 40-60% opacity with a blur effect. Content inside cards should be prioritized with high-contrast white bold headers.

### Input Fields
- Outlined style using Soft Cyan at 30% opacity. Upon focus, the border transitions to Electric Blue with a subtle neon glow effect.

### Chips & Metrics
- Data chips use Jet Black backgrounds with Electric Blue text for the metric and Soft Cyan for the label. This color-coding separates the "value" from the "unit."

### Progress & Status
- Use thick, 4px-6px stroke lines for progress bars. Active paths in navigation should use a neon-glow treatment in Electric Blue to remain visible against complex map backgrounds.