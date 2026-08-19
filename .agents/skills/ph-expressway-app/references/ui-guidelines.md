# UI/UX Guidelines (Authoritative Reference: Nocturnal Command)

Design principles, visual language, and component patterns for the Philippine expressway companion app.

---

## Core Design Principle

> **Designed for glanceability in low-light & automotive environments** — the user is a driver stopped or parked before or during a trip. Content must be scannable in 2–3 seconds. No dense text walls, no tiny fonts, no complex multi-layer navigation.

---

## Visual Language: Nocturnal Command

The design system is engineered for high-stakes, low-light automotive ergonomics: glare-free, high-contrast, and focused on essential metrics.

### Color Palette

| Role | Color | Hex Code | Usage |
|:---|:---|:---|:---|
| **Canvas / Background** | Deepest Charcoal | `#0A0A0A` / `#121414` | Primary scaffold background, zero glare |
| **Surface Level 1** | Dark Surface | `#141414` / `#1B1C1C` | App bars, search bars, inputs |
| **Surface Level 2** | Glass Card Surface | `#1A1A1A` / `#1F2020` | Cards, modals, accordion panels |
| **Border / Stroke** | Subtle Dark Border | `#2A2A2A` / `#343535` | 1px card outlines, list separators |
| **Primary Action** | Electric Sky Blue | `#0088FF` | Primary buttons, active tabs, progress, links |
| **Primary Container** | Electric Blue Tint | `#0088FF` (12% alpha) | Icon backgrounds, selected chips |
| **Success / Verified** | Emerald Green | `#00CC88` / `#10B981` | Ready checklist items, verified badges |
| **Warning / Caution** | Amber | `#FFA000` / `#F59E0B` | Low balance warnings, unverified badges |
| **Emergency / Error** | Crimson Red | `#FF5252` / `#D32F2F` | Emergency call buttons, fare deductions |
| **Text Primary** | High-Contrast Off-White | `#E3E2E2` / `#F0F0F0` | Headings, amounts, primary labels |
| **Text Secondary** | Muted Silver / Steel | `#8A919F` / `#C0C6D6` | Descriptions, metadata, category labels |

---

### Typography

- **Headings**: Bold (700) or SemiBold (600), 18–24sp, Off-White `#E3E2E2`
- **Body Text**: Regular (400), 14–16sp, high-contrast `#F0F0F0`
- **Captions & Metadata**: Regular (400), 12–13sp, `#8A919F`
- **Label Caps**: SemiBold (600), 11–12sp, uppercase with `0.05em` letter-spacing
- **Numeric Amounts & Fares**: Bold (700), 20–28sp, Electric Blue `#0088FF` or Off-White

---

### Component Shapes & Elevation

- **Cards**: Background `#1A1A1A` with `1px` border `#2A2A2A` and `BorderRadius.circular(12)`
- **Buttons & Inputs**: `BorderRadius.circular(8)` to `BorderRadius.circular(10)`
- **Badges & Chips**: `BorderRadius.circular(999)` (pill shape)
- **Tonal Elevation**: In dark mode, depth is indicated by lighter surfaces (`#1A1A1A` over `#0A0A0A`) and subtle 1px borders rather than heavy drop shadows.

---

## Screen Patterns

### 1. Home Hub Screen
Presents a scannable grid/list of 5 feature cards:
1. **Toll Calculator** — Route builder & multi-operator RFID fare breakdown
2. **Pre-Trip Checklist** — Vehicle, RFID, document, and safety readiness check
3. **Route Briefing** — Lane tips, rest stops, and exit guidance
4. **Quick Guide** — What to do during breakdowns and RFID issues
5. **Emergency Contacts** — Official hotlines (Tier 1) with tap-to-call

### 2. Toll Calculator Screen
- Route selection dropdown
- Vehicle class segmented toggle (Class 1, 2, 3)
- Operator breakdown cards (Autosweep vs Easytrip separated)
- Combined Total card with actionable top-up summaries
- Quick-launch buttons to **Pre-Trip Checklist** and **Route Briefing**

### 3. Pre-Trip Checklist Screen
- Progress header: "X of Y items ready" with visual progress bar and completion status badge
- Route operator awareness: Highlights relevant RFID balance items when a route is active
- Interactive toggleable checkboxes with in-session local state
- Reset checklist action
- Categorized sections: RFID Wallets, Vehicle Health, Documents, Safety & Emergency

### 4. Route Briefing Screen
- Route picker header
- 3 structured tab/accordion views:
  1. 🛣️ **Lane & Gantry Tips**: RFID lane approach speeds, ETC vs cash lanes, gantry etiquette
  2. ⛽ **Rest Stops & Fuel**: Service plazas with distance/KM and amenities (Fuel, Food, Restrooms, Tire check)
  3. ⚠️ **Exit & Fork Warnings**: Tricky interchanges, split lane guidance to avoid wrong turns

### 5. Quick Guide Screen
- Category filter chips (`All Topics`, `RFID`, `Breakdown`, `Navigation`, `Safety`)
- Scannable card list with category pills and chevron navigation
- Guidance detail view with numbered step-by-step action items

### 6. Emergency Contacts Screen
- Top trust disclaimer (Official Tier 1 hotlines only)
- Contact cards with agency badge, coverage roads, and prominent verification status (`Verified: MMM YYYY` or `⚠️ Not yet verified`)
- Full-width tap-to-call action button triggering native dialer via `url_launcher` without auto-dialing
