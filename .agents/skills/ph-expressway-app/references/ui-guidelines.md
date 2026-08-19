# Aero UI/UX Guidelines (Authoritative Reference: Aero Nocturnal Command)

Design principles, visual language, component patterns, and motion architecture for **Aero — Philippine Expressway Companion**.

---

## 🦅 Brand Identity & Persona: The Aero Bird Mascot

- **App Name**: **Aero**
- **Mascot Asset**: The authentic Aero bird mascot silhouette asset (`assets/images/aero_mascot.png`).
- **Small Logo / Avatar (`AeroAvatar`)**:
  - Rendered **clean without any outer blue border or rim** across headers, category items, and dialogs.
- **Dedicated Large Animated Mascot Hero Space (`AeroAnimatedHeroMascot` / `AeroHeroHeaderRow`)**:
  - Sizable, prominent character presence (80px–88px) on **Home**, **Tolls**, **Emergency**, and **Quick Guide** screens:
    - **Tolls Screen**: Positioned alongside the `"Trip Details"` heading.
    - **Emergency Screen**: Positioned alongside the `"Emergency"` heading.
    - **Quick Guide Screen**: Positioned alongside the `"Quick Guide"` heading.
    - **Home Dashboard**: Positioned inside the dedicated "Aero Co-Pilot / Radar Active" hero card at the top of the dashboard.

---

## 🎬 Native Motion Architecture: Aero Flutter Animation

The Aero bird mascot features a **native, 100% offline Flutter animation loop** implemented via `AnimationController` and hardware-accelerated transforms (no WebViews, no external CDN dependencies):

- **Floating Translation**: Gentle vertical sine oscillation ($\pm 4.5\text{px}$) mimicking mid-air hovering.
- **Wing-Flap & Breathing**: Coordinated scale expansions ($\text{scaleX}: 1.0 \pm 0.045$, $\text{scaleY}: 1.0 \pm 0.035$) providing a lifelike aerodynamic pulse.
- **Subtle Banking Tilt**: Smooth rotational roll ($\pm 0.035\text{ rad}$) responding to the floating cycle.
- **Ambient Glow**: Electric blue radial elevation (`blurRadius: 20`, `alpha: 0.30`).
- **Test Harness Safety**: Auto-bypasses continuous loops under `TestWidgetsFlutterBinding` for clean synchronous unit testing.

---

## 🛡️ Trust-First Design System & Last-Verified Indicators (Phase 3 Standard)

To prevent driver misinformation, all data-driven content (Emergency hotlines, Toll fares, Route specifics) must visually display their verification status:

### 1. Verification Badges
- **Verified State**:
  - Capsule / Pill shape with `surfaceContainerHighest` (`#343535`) background and `1px solid #2A2A2A` border.
  - Electric Blue (`#0088FF`) verified check icon (`Icons.verified`).
  - Text: `VERIFIED MM/YY` (Emergency Contacts) or `Fare data as of MM/YY` (Toll Calculator) in `textMuted` (`#C0C6D6`) bold 10px font.
- **Unverified / Placeholder State**:
  - Amber badge (`rgba(251, 191, 36, 0.15)` background with `1px solid rgba(251, 191, 36, 0.4)` border).
  - Amber warning icon (`Icons.warning_amber_rounded`).
  - Text: `NOT YET VERIFIED` in bold 10px Amber text.

### 2. Offline Status Banner (`AeroOfflineBanner`)
- Displayed at the top of the content area when showing cached local data due to signal loss or network errors.
- Styled with `surfaceContainerLow` (`#1B1C1C`), amber outline (`rgba(251, 191, 36, 0.4)`), and cloud-off icon.
- Copy: `"Offline — showing saved emergency contacts"`, `"Offline — showing saved routes & fare tables"`.

### 3. In-App Discrepancy Reporting (`ReportDialog`)
- Unobtrusive "Report info" / "Report fare discrepancy" flag button on each contact and fare card.
- Opens an Aero-themed dark modal with auto-attached context chips and a description input field.
- Submits directly to the write-only `dataReports` Firestore collection and confirms with a floating snackbar (`"Thanks, we'll review this."`).

---

## 🎨 Visual Language: Nocturnal Command Tokens

### Color Tokens

| Token | Hex Code | Usage |
|:---|:---|:---|
| `surfaceBase` | `#0A0A0A` | Primary canvas scaffold background, true black |
| `surfaceDim` | `#121414` | Sub-panels, dark avatar containers |
| `surfaceContainerLow` | `#1B1C1C` | Input fields, collapsed accordion tiles |
| `surfaceContainer` | `#1F2020` | Cards, modals, tip containers |
| `surfaceCard` | `#1A1A1A` | Elevated cards, list containers |
| `surfaceContainerHighest` | `#343535` | Verified badge chips |
| `border` | `#2A2A2A` | 1px card outlines, list separators |
| `outlineVariant` | `#404754` | Secondary outlines, segmented radios |
| `neonBlue` | `#0088FF` | Electric Blue primary accent, glow shadows, active states |
| `primaryTint` | `#A8C8FF` | Subtle highlights |
| `successEmerald` | `#34D399` | Active RFID badge, EasyTrip indicator bar |
| `warningAmber` | `#FBBF24` | Low balance warning, unverified chips |
| `errorRed` | `#FF5252` | Fare deductions, destination pin, error notices |
| `textPrimary` | `#FFFFFF` | Primary headings, display numbers |
| `textSecondary` | `#8A919F` | Secondary descriptions, timestamps |
| `textMuted` | `#C0C6D6` | Card labels, subtitles |

### Typography Scale (Inter — Refined Balanced Automotive Values)

- **`displayLg`**: **`36px` / Weight 800 / `#0088FF`** (Autosweep & EasyTrip RFID balance amounts on Home)
- **`displayFare`**: **`34px` / Weight 800 / `#0088FF`** (Estimated Total Fare on Toll Calculator)
- **`displayHero`**: **`36px` / Weight 800 / `#FFFFFF`** (Page hero headings: `"Emergency"`, `"Quick Guide"`)
- **`headlineLg`**: **`32px` / Weight 800 / `#FFFFFF`** (`"Trip Details"` on Toll Calculator)
- **`headlineLgMobile`**: **`24px` / Weight 800 / `#FFFFFF`** (`"Hello, Driver"` on Home top app bar)
- **`titleMd`**: **`20px` / Weight 700 / `#FFFFFF`** (Section Titles, Agency Names, Category Headers)
- **`tier1PillText`**: **`13.5px` / Weight 600 / `#FFFFFF`** (Unified status pills across Tolls, Emergency, and Guide)
- **`bodyLg`**: **`15px` / Weight 400 / `#C0C6D6`** (Descriptions)
- **`bodySm`**: **`13px` / Weight 400 / `#8A919F`** (Timestamps, Hints)
- **`labelCaps`**: **`11.5px` / Weight 700 / Letter Spacing 0.08em / Uppercase** (Card labels, button tags)

---

## 🧭 Navigation Architecture: Persistent Bottom Tab Bar

1. **🏠 Home** (`Icons.home`): Dashboard with animated mascot hero card, 36px balance numbers, and recent routes.
2. **💳 Tolls** (`Icons.payments`): Exit-to-Exit Toll Routing Engine with Searchable Plaza Picker, animated mascot hero, 34px total fare display, strict operator subtotals, trust verification badge, and report action.
3. **🚨 Emergency** (`Icons.emergency`): Hero header with animated mascot alongside "Emergency" heading + Tier 1 Hotlines with verification badges, report action, and 56px glowing "CALL NOW" buttons.
4. **🧭 Guide** (`Icons.explore`): Hero header with animated mascot alongside "Quick Guide" heading + Expandable accordion troubleshooting guide.

---

## 🚗 Exit-to-Exit Search Picker & Routing Pattern (Phase 4 Standard)

The Toll Calculator utilizes an interactive search-based exit picker allowing motorists to select any origin exit and destination exit across all interconnected Philippine expressways:

### 1. Trip Details Selection Cards
- **Origin Box**: Green indicator dot (`#34D399`), uppercase `'ORIGIN EXIT'` label, exit name + expressway code in bold, search icon.
- **Connector Line & Reversible Swap**: Vertical link with a centered pill `'Swap'` button (`Icons.swap_vert`) to instantly invert origin and destination.
- **Destination Box**: Red indicator dot (`#FF5252`), uppercase `'DESTINATION EXIT'` label, exit name + expressway code in bold, search icon.

### 2. Searchable Exit Picker Modal (`PlazaPickerSheet`)
- **Header**: Sheet title + close button.
- **Live Search Bar**: Auto-filtering text field matching exit name, expressway name/code, or operator.
- **Expressway Filter Chips**: Horizontal scrollable chips (`ALL`, `STAR`, `SLEX`, `SKYWAY`, `NLEX`, `CALAX`, `CAVITEX`, `SCTEX`, `TPLEX`).
- **Plaza List Items**:
  - Plaza pin indicator (electric blue when selected).
  - Exit name (14px bold) + expressway subtitle.
  - Interchange badge (`INTERCHANGE`) if connecting to other highways.
  - High-contrast operator pill (`AUTOSWEEP` in emerald / `EASYTRIP` in cyan).

### 3. Multi-Operator Fare Breakdown
- **Estimated Total Fare Card**: Electric blue 34px `displayFare`, corridor breadcrumb chip chain (`STAR → SLEX → Skyway → NLEX`), trust verification indicator.
- **Operator Breakdown Cards**: Independent Autosweep RFID and Easytrip RFID subtotal containers with strict mathematical separation.
- **Traversed Segments Accordion**: Tap-to-expand list showing per-segment entry/exit points, expressway tags, and vehicle class fare rates.

