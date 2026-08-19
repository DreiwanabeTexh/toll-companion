---
name: Nocturnal Command
colors:
  surface: '#121414'
  surface-dim: '#121414'
  surface-bright: '#383939'
  surface-container-lowest: '#0d0e0f'
  surface-container-low: '#1b1c1c'
  surface-container: '#1f2020'
  surface-container-high: '#292a2a'
  surface-container-highest: '#343535'
  on-surface: '#e3e2e2'
  on-surface-variant: '#c0c6d6'
  inverse-surface: '#e3e2e2'
  inverse-on-surface: '#303031'
  outline: '#8a919f'
  outline-variant: '#404754'
  surface-tint: '#a8c8ff'
  primary: '#a8c8ff'
  on-primary: '#003061'
  primary-container: '#3491ff'
  on-primary-container: '#002955'
  inverse-primary: '#005eb3'
  secondary: '#c9c6c5'
  on-secondary: '#313030'
  secondary-container: '#4a4949'
  on-secondary-container: '#bab8b7'
  tertiary: '#c8c6c5'
  on-tertiary: '#313030'
  tertiary-container: '#929090'
  on-tertiary-container: '#2a2a2a'
  error: '#ffb4ab'
  on-error: '#690005'
  error-container: '#93000a'
  on-error-container: '#ffdad6'
  primary-fixed: '#d5e3ff'
  primary-fixed-dim: '#a8c8ff'
  on-primary-fixed: '#001b3c'
  on-primary-fixed-variant: '#004689'
  secondary-fixed: '#e5e2e1'
  secondary-fixed-dim: '#c9c6c5'
  on-secondary-fixed: '#1c1b1b'
  on-secondary-fixed-variant: '#474646'
  tertiary-fixed: '#e5e2e1'
  tertiary-fixed-dim: '#c8c6c5'
  on-tertiary-fixed: '#1c1b1b'
  on-tertiary-fixed-variant: '#474746'
  background: '#121414'
  on-background: '#e3e2e2'
  surface-variant: '#343535'
typography:
  display-lg:
    fontFamily: Inter
    fontSize: 48px
    fontWeight: '700'
    lineHeight: 56px
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Inter
    fontSize: 32px
    fontWeight: '700'
    lineHeight: 40px
    letterSpacing: -0.01em
  headline-lg-mobile:
    fontFamily: Inter
    fontSize: 24px
    fontWeight: '700'
    lineHeight: 32px
  title-md:
    fontFamily: Inter
    fontSize: 20px
    fontWeight: '600'
    lineHeight: 28px
  body-lg:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  body-sm:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  label-caps:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '600'
    lineHeight: 16px
    letterSpacing: 0.05em
rounded:
  sm: 0.125rem
  DEFAULT: 0.25rem
  md: 0.375rem
  lg: 0.5rem
  xl: 0.75rem
  full: 9999px
spacing:
  base: 8px
  xs: 4px
  sm: 12px
  md: 16px
  lg: 24px
  xl: 40px
  container-margin: 24px
  gutter: 16px
---

## Brand & Style

The design system is engineered for high-stakes, low-light environments, specifically optimized for night-time operation and high-performance automotive or technical interfaces. The personality is focused, authoritative, and precise, prioritizing legibility and visual ergonomics over decorative flair.

The style is a fusion of **Modern Minimalism** and **Technical Precision**. It utilizes a "True Dark" foundation to eliminate screen glare, using high-contrast typography and singular electric accents to guide the user's focus. Visual noise is aggressively reduced to ensure that every illuminated pixel serves a functional purpose.

## Colors

The palette is strictly functional, designed to maintain the user's natural night vision.

- **Foundations:** The primary canvas is #0A0A0A. Layered elements use #141414 and #1A1A1A to create depth without introducing significant luminance.
- **Accents:** #0088FF is the "Action Color." It is used sparingly for interactive elements, progress indicators, and critical branding. Avoid using this color for large background fills to prevent eye fatigue.
- **Feedback:** Success and Error states use highly saturated greens and reds but are limited to small icons, thin strokes, or text labels to maintain the low-glare profile.
- **Borders:** Subtle #2A2A2A borders define structure where tonal differences are insufficient.

## Typography

This design system relies on **Inter** for its neutral, highly legible glyphs. 

- **Hierarchy:** Use Bold (700) and SemiBold (600) for headlines and critical metrics to ensure they "pop" against the dark background. 
- **Readability:** Body text uses Regular (400) weight in Off-White (#F0F0F0) to provide maximum contrast without the vibration of pure white.
- **Labels:** Small labels and metadata should use `label-caps` in Muted Gray (#888888) to establish a clear secondary hierarchy.

## Layout & Spacing

The layout follows a **Fluid Grid** model with an 8px base unit, ensuring alignment and rhythmic consistency across varying screen aspect ratios.

- **Desktop:** 12-column grid with 24px margins.
- **Tablet:** 8-column grid with 24px margins.
- **Mobile:** 4-column grid with 16px margins.
- **Philosophy:** Elements are spaced generously to prevent accidental "fat-finger" interactions in high-motion environments. Use "Space-Between" logic for header elements and "Stacked" logic for mobile data readouts.

## Elevation & Depth

Depth is communicated through **Tonal Layers** rather than shadows. In a near-black environment, traditional shadows are invisible; therefore, we use increasing lightness of the surface color to indicate "height."

1.  **Level 0 (Base):** #0A0A0A (The void)
2.  **Level 1 (Navigation/Sidebars):** #141414
3.  **Level 2 (Cards/Modals):** #1A1A1A + #2A2A2A border.

For active or focused states, use a 1px solid stroke of the Accent Color (#0088FF) or a very subtle outer glow (0px 0px 8px) with 20% opacity of the accent color.

## Shapes

The shape language is **Soft** but disciplined. 

- **Standard Elements:** Buttons, inputs, and cards use a 0.25rem (4px) corner radius. This provides a modern feel while maintaining a professional, "tool-like" appearance.
- **Large Containers:** Use 0.75rem (12px) for large content blocks or modals.
- **Interactive Indicators:** Small circular pips (full radius) are used for status indicators or notification dots.

## Components

- **Buttons:** 
    - *Primary:* Solid #0088FF background with Black (#0A0A0A) text for maximum visibility.
    - *Secondary:* Ghost style with #2A2A2A border and #F0F0F0 text. 
- **Input Fields:** Background #141414, border #2A2A2A. On focus, the border changes to #0088FF.
- **Cards:** Background #1A1A1A with a 1px #2A2A2A border. No drop shadows. Content within cards should follow the standard spacing rhythm.
- **Chips/Status:** Minimalist background (#2A2A2A) with colored text labels (e.g., #00CC88 for "Go").
- **Lists:** Separated by 1px solid lines (#2A2A2A). Use high-contrast #F0F0F0 for the primary list item title and #888888 for the description.
- **Mascot/Iconography:** When using brand illustrations or mascots, use #0088FF for key features (eyes, logos, active lines) while the body of the illustration remains in shades of gray to prevent visual overwhelm.