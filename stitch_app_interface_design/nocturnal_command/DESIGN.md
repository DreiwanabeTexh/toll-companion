---
name: Aero Dash
colors:
  surface: '#131313'
  surface-dim: '#131313'
  surface-bright: '#3a3939'
  surface-container-lowest: '#0e0e0e'
  surface-container-low: '#1c1b1b'
  surface-container: '#201f1f'
  surface-container-high: '#2a2a2a'
  surface-container-highest: '#353534'
  on-surface: '#e5e2e1'
  on-surface-variant: '#c0c6d6'
  inverse-surface: '#e5e2e1'
  inverse-on-surface: '#313030'
  outline: '#8a919f'
  outline-variant: '#404754'
  surface-tint: '#a8c8ff'
  primary: '#a8c8ff'
  on-primary: '#003061'
  primary-container: '#3491ff'
  on-primary-container: '#002955'
  inverse-primary: '#005eb3'
  secondary: '#c8c6c5'
  on-secondary: '#313030'
  secondary-container: '#474746'
  on-secondary-container: '#b7b5b4'
  tertiary: '#c8c6c5'
  on-tertiary: '#303030'
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
  secondary-fixed-dim: '#c8c6c5'
  on-secondary-fixed: '#1c1b1b'
  on-secondary-fixed-variant: '#474746'
  tertiary-fixed: '#e4e2e1'
  tertiary-fixed-dim: '#c8c6c5'
  on-tertiary-fixed: '#1b1c1c'
  on-tertiary-fixed-variant: '#474746'
  background: '#131313'
  on-background: '#e5e2e1'
  surface-variant: '#353534'
  neon-blue: '#0088FF'
  success-emerald: '#34D399'
  warning-amber: '#FBBF24'
  error-red: '#FFB4AB'
  surface-base: '#0A0A0A'
  surface-card: '#1A1A1A'
  surface-border: '#2A2A2A'
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
  xs: 4px
  base: 8px
  sm: 12px
  md: 16px
  gutter: 16px
  lg: 24px
  container-margin: 24px
  xl: 40px
---

## Brand & Style
Aero Dash is a high-performance, driver-centric dashboard designed for the modern commute. The aesthetic is **Cyber-Corporate**, blending the reliability of a financial tool with the high-tech energy of automotive telemetry. 

The visual style utilizes a **Dark Glassmorphism** approach, featuring deep obsidian surfaces, sharp electric blue accents, and subtle "neon-glow" elevations. It evokes a sense of precision, speed, and night-time urban navigation. The interface should feel like a premium heads-up display (HUD): informative, unobtrusive, and technologically advanced.

## Colors
The palette is anchored in a "True Black" (`#0A0A0A`) environment to maximize contrast and reduce driver eye strain. 

- **Primary (Electric Blue):** Used for critical data points, active states, and primary actions. It is often paired with a 50% opacity outer glow to simulate a neon effect.
- **Surface Tiers:** Backgrounds use `#0A0A0A`, while interactive containers and cards use `#1A1A1A`. 
- **Borders:** A strict `#2A2A2A` is used for structural separation, ensuring a low-profile but defined grid.
- **Status Colors:** Semantic colors (Emerald, Amber, Red) are used with low-opacity backgrounds (20%) and high-vibrancy foregrounds for status chips.

## Typography
The system relies exclusively on **Inter** to maintain a clean, functional, and highly legible interface. 

The hierarchy is driven by extreme scale variance: **Display LG** is reserved for high-impact data like monetary balances, while **Label Caps** provides a technical, data-tag feel for metadata. Headlines use tighter letter spacing and heavy weights to appear "bolted on" and sturdy. On mobile, headlines scale down significantly to ensure content remains the priority.

## Layout & Spacing
The layout uses a **Fluid Grid** with fixed horizontal safe areas. 

- **Desktop/Tablet:** A max-width container of 1280px (`7xl`) centered with 24px side margins. Sections are vertically stacked with a 32px to 40px (`xl`) gap.
- **Mobile:** 16px horizontal margins. The layout transitions to a single-column stack.
- **Search & Navigation:** The top app bar is a fixed 64px (`h-16`) height. Navigation shifts from a top bar (desktop) to a fixed bottom bar (mobile) for thumb-friendly reachability.

## Elevation & Depth
Elevation is achieved through **Material Stacking** and **Light Emission** rather than traditional soft shadows.

1.  **Base (Level 0):** `#0A0A0A` background.
2.  **Raised (Level 1):** `#1A1A1A` surfaces (Glass Cards). These use a 1px solid border of `#2A2A2A` to define edges.
3.  **Active/Focus (Level 2):** Elements emit a "Neon Glow" using `box-shadow: 0 0 15px rgba(0, 136, 255, 0.5)`.
4.  **Overlays:** Navigation bars use high-opacity backgrounds with a blur effect to maintain context of the content scrolling beneath.

## Shapes
Aero Dash uses a "Soft" base roundedness but scales it aggressively for specific components to denote interactivity:

- **Cards/Containers:** 12px (`rounded-xl`) to provide a modern, friendly feel to data clusters.
- **Inputs & Search:** Full pill-shaped (`rounded-full`) to differentiate interactive text areas from static content.
- **Buttons/Chips:** Full pill-shaped for high-affinity actions.
- **Icons/Avatars:** Circular (`rounded-full`) with consistent border-weights (2px).

## Components

### Buttons
- **Primary:** Text-only or Icon + Text in Electric Blue. Hover states feature an underline or a subtle color shift to `#A8C8FF`.
- **Navigation:** Mobile nav buttons use a 10% opacity primary color background for the active state, creating a "tab" highlight.

### Glass Cards
- Feature a `#1A1A1A` background and `#2A2A2A` border. 
- Interactive cards transition the border to `Primary/50%` on hover. 
- Background imagery (mascots or icons) should be placed with low opacity (10-20%) to add depth without distracting from data.

### Lists
- Route items and transactions use a `divide-y` approach with `#2A2A2A` separators.
- Each item features a circular icon lead-in and right-aligned numeric data.

### Input Fields
- Fully rounded (`rounded-full`) with `#1A1A1A` fill and `#2A2A2A` border.
- Active state transitions the border to Electric Blue with a 1px ring.

### Chips/Badges
- Status badges (Active, Low Balance) use a low-opacity color fill with a high-saturation text and a small leading "dot" indicator for quick status recognition.