# Aero — Philippine Expressway Companion

A driver's companion app for navigating Philippine expressways — built around the real pain point of multi-operator toll systems (Autosweep vs. Easytrip), for any driver planning a trip across PH expressways. Branded as **Aero**, with a bird mascot and dark "Nocturnal Command" visual identity.

> **Status:** Phases 0–3 complete and functionally shipped (self/informal testing). Phase 3.5 (real data verification) in progress — Tier 1 emergency contacts verified; toll fare matrix verification still pending. Phase 4 (routing engine + personalization core) in active development.
> **Note:** Toll plaza/fare data is still largely **placeholder** pending full verification against official sources (TRB, Autosweep, Easytrip). Emergency contact hotlines for the 5 Tier 1 agencies have been verified against official sources. Do not treat any unverified data as production-accurate — check each entry's "last verified" status in-app.

---

## The Problem

First-time and infrequent expressway drivers in the Philippines often don't know:
- How much a trip will actually cost in tolls
- That different expressways are operated by different RFID systems (Autosweep vs. Easytrip), each requiring separate balance
- Whether their RFID balance is enough to get there and back
- Who to call if something goes wrong mid-trip, and where the nearest help actually is

Existing tools (Autosweep app, Easytrip app, Waze/Google Maps toll estimates) solve pieces of this, but nothing unifies a multi-operator trip into one clear picture — and none of them function as a broader trip companion.

## The Solution

A companion app that consolidates:
- **Toll cost calculation**, broken down by RFID operator (never merged into a single misleading total)
- **Emergency contacts**, sourced only from official/verified channels
- **Quick guidance** for common on-the-road situations
- Later: **route-specific briefings** and **pre-trip checklists**, built from real trip usage rather than guesswork

---

## Tech Stack

| Layer | Choice | Why |
|---|---|---|
| Frontend | **Flutter (Dart)** | Single codebase for Android + iOS, native performance, strong widget support for card/list-based UI |
| Backend / Data | **Firebase (Firestore)** | Content-editable without app redeploys; pairs natively with Flutter via FlutterFire |
| Tap-to-call | `url_launcher` package | Native `tel:` link handling |
| Local caching | **`shared_preferences`** (implemented, Phase 3) | Offline support for spotty expressway signal — caches contacts, last route, guide entries; falls back automatically when Firestore reads fail |
| Feedback/reporting | Write-only `dataReports` Firestore collection | Users can flag outdated data; no client read/update/delete access — reviewed manually via Firebase Console |
| Auth | None yet — **tentative Phase 5** | No user accounts currently; all Firestore reads, no per-user writes. Login/sign-in is being considered as an optional future phase, not yet committed |

---

## Target Audience

- **Primary:** First-time or infrequent provincial/expressway drivers (holiday travelers, students, relocating families)
- **Secondary:** Logistics/delivery drivers and small fleet operators needing quick trip cost estimates

---

## Competitive Landscape (Summary)

| Competitor | Strength | Gap This App Fills |
|---|---|---|
| Autosweep app | Official, accurate for SMC roads | Doesn't cover NLEX/Cavitex/CALAX |
| Easytrip app | Official, accurate for MPTC roads | Doesn't cover SLEX/STAR |
| Waze / Google Maps | Already installed, shows routes | Toll estimates often rough for PH; no multi-operator breakdown |
| Generic toll calculators | Cross-operator, multi-country | Not PH-specialized; lacks local nuance and route-specific guidance |

**Positioning:** Not "another calculator" — the one app that correctly stitches together multi-operator PH expressway trips and tells drivers exactly what to top up, before they're stuck at a gantry.

---

## Features

### Phase 1 — MVP ✅ Complete

| Feature | Description |
|---|---|
| **Toll Calculator** | Route builder + fare breakdown by RFID operator. Shows which wallet (Autosweep / Easytrip) needs topping up and by how much — never a single merged total. |
| **Quick Guide** ("What do I do if...") | Expandable category accordion, content pulled from Firestore, "Troubleshoot" / "View FAQ" actions per topic. |
| **Emergency Contacts (Tier 1 only)** | Official hotlines only — TRB, SMC/Autosweep, MPTC/Easytrip, MMDA, PNP-HPG. Tap-to-call UX. Every entry carries a mandatory **last-verified date** shown in the UI. Crowdsourced/local listings explicitly excluded from this phase. |

### Phase 2 — Companion Depth ✅ Complete

| Feature | Description |
|---|---|
| **Pre-Trip Checklist** | Categorized readiness checklist (RFID & Toll Wallets, Vehicle Roadworthiness, Documents, Emergency Equipment) with progress tracking, tied to the active route. |
| **Route Briefing** | Tabbed Lane Tips / Rest Stops / Exit Warnings, tied to whatever route the user builds. Expanded incrementally based on real usage. |

### Phase 2.5 — Aero Rebrand & Visual Identity ✅ Complete

- Full UI/UX rebuild and rebrand to **Aero**, adopting the bird mascot and "Nocturnal Command" dark visual design system from the reference design folder
- Persistent bottom tab navigation (Home / Tolls / Emergency / Guide)
- Native Flutter-based mascot animation (wing-flap, breathing, banking tilt) — built with `AnimationController`, not a WebView, to keep the app fully functional offline
- Dedicated large mascot "hero" placement on Home, Emergency, Quick Guide, and Toll Calculator

### Phase 3 — Polish & Trust ✅ Complete

- Visible "last verified" indicators across all contact and fare data
- Offline caching (`shared_preferences`) for last-used route, emergency contacts, and guide entries — with a visible "Offline — showing saved data" banner when serving cached content
- Write-only feedback/reporting mechanism to flag outdated numbers or fares

### Phase 3.5 — Real Data Verification 🔄 In Progress

- ✅ Tier 1 emergency contact hotlines verified against official sources (TRB, SMC/Autosweep, MPTC/Easytrip, MMDA, PNP-HPG)
- ⬜ Toll fare matrix verification against official TRB/Autosweep/Easytrip sources — pending, larger scope (per-segment, per-operator, per-vehicle-class)

### Phase 4 — Routing Engine & Personalization Core 🔄 In Progress

| Feature | Description |
|---|---|
| **Free exit-to-exit routing engine** | Replaces the predefined-routes-only calculator with a searchable plaza/exit picker (origin + destination) and automatic multi-segment, multi-operator path calculation — matching how established PH toll calculator apps work, while keeping Aero's strict per-operator fare breakdown. |
| **Manual RFID balance tracking** | User manually enters their known Autosweep/EasyTrip balance (no official balance-check API exists for third-party apps); app warns if a planned trip's fare would exceed the recorded balance. Includes a visible "balance last updated" trust indicator, same pattern as verified contacts/fares. |
| **Recent Routes — real history** | Auto-logs every calculated trip locally (no manual save required) plus a separate manual "save as favorite" option for routes used often. |
| **Randomized status copy** | Small pool of variant phrases for each screen's status pill (e.g. "Plan your trip.") that rotate rather than showing the same static line every time. |

### Phase 5 — Accounts & Sync (Tentative / Not Yet Committed)

- Login / sign-up
- Personalized greeting (first name replacing "Hello, Driver")
- Cross-device sync of saved routes, balance, and checklist state
- *This phase is exploratory — "if ever" per current direction, not a committed roadmap item.*

### Phase 6 — v2 Exploration

- **Fuel comparison** across the route (explicitly deferred from v1 — strong v2 story, not a launch blocker)
- Smart checklist auto-suggesting RFID top-up amounts based on the built route
- **Tier 2 emergency contacts** — local mechanic shops per exit — only once a verification/moderation process exists
- **Full nationwide toll plaza network data population** — real, verified plaza-to-plaza connectivity and fares across all PH expressways (the routing engine in Phase 4 ships with sample/placeholder network data; full real-data population is its own dedicated task)

---

## Monetization Opportunities (Future Consideration)

- Freemium: free core features, paid tier for saved routes / trip history / multi-vehicle tracking
- Affiliate/referral: RFID top-up deep links via GCash/Maya/convenience store partners
- Contextual ads or sponsored placements in Route Briefing (gas stations, food stops, tire shops at specific exits)
- B2B: bulk route-cost estimation and reporting for logistics/fleet operators

*Not a priority for Phase 1 — trust and word-of-mouth come first.*

---

## Data Principles

- Firestore collections are structured so content (fares, contacts, guide entries) can be updated by editing the database directly — no app redeploy required
- Every emergency contact record requires: agency name, coverage area/roads, phone number, tap-to-call format, and last-verified date
- Toll fare data supports multi-operator trips and returns a **per-operator breakdown**, never a single blended total
- All placeholder data (fares, phone numbers) flagged clearly in code (`// TODO(data):`) until verified against official sources

---

## Known Risks

- **Data accuracy is existential.** A wrong toll estimate or dead emergency number actively harms trust — this is the core risk to manage above all else.
- **Toll rates and operator coverage change over time** — needs a sustainable process for periodic verification, not a one-time data entry.
- **Low usage frequency** for casual drivers (few trips per year) — Phase 2's Route Briefing and Checklist are meant to counter this by giving reasons to open the app before *and* during a trip.
- **Official operator apps could add similar features** — the app's moat is the unified multi-operator experience and route-specific local knowledge, not the calculator alone.

---

## Roadmap Overview

```
Phase 0 — Foundation ✅
  └─ Flutter project setup, Firebase/Firestore connection, schema design

Phase 1 — Core MVP ✅
  ├─ Toll Calculator (multi-operator breakdown)
  ├─ Quick Guide
  └─ Emergency Contacts (Tier 1, verified only)

Phase 2 — Companion Depth ✅
  ├─ Pre-Trip Checklist
  └─ Route Briefing

Phase 2.5 — Aero Rebrand & Visual Identity ✅
  ├─ Full UI/UX rebuild matching reference design
  ├─ Bottom tab navigation
  └─ Native animated mascot (offline-safe, no WebView)

Phase 3 — Polish & Trust ✅
  ├─ Last-verified indicators
  ├─ Offline caching (shared_preferences)
  └─ Feedback / correction mechanism (write-only reports)

Phase 3.5 — Real Data Verification 🔄
  ├─ Tier 1 emergency contacts ✅ verified
  └─ Toll fare matrix ⬜ pending

Phase 4 — Routing Engine & Personalization Core ✅
  ├─ Free exit-to-exit routing engine (graph BFS + operator boundary detection)
  ├─ Manual RFID balance tracking + dynamic low-balance warnings
  ├─ Recent Routes: auto-history + save favorites + tap-to-recalculate
  └─ Offline persistence via SharedPreferences (zero-login)

Phase 5 — Accounts & Sync (tentative, not committed)
  ├─ Login / sign-up
  ├─ Personalized greeting
  └─ Cross-device sync

Phase 6 — v2
  ├─ Fuel comparison
  ├─ Smart checklist
  ├─ Tier 2 local mechanic listings (verification process required first)
  └─ Full nationwide toll plaza network data population
```

**Deployment path:**
1. Local device testing during development (Flutter hot reload, USB debugging/emulator)
2. Shareable APK for informal testing (Android)
3. Public release — Google Play first (cheaper, faster review), Apple App Store once stable (requires active Apple Developer account)

---

## How to Update Toll Rates After a TRB Announcement

All manually editable toll fare data in Aero is stored in a single, clearly organized file:
👉 [`lib/data/toll_rates_data.dart`](file:///c:/Users/USER/project/Toll/lib/data/toll_rates_data.dart)

### Quick Update Steps:
1. Open [`lib/data/toll_rates_data.dart`](file:///c:/Users/USER/project/Toll/lib/data/toll_rates_data.dart).
2. Locate the expressway section (e.g. `STAR`, `SLEX`, `SKYWAY`, `NLEX`, `CALAX`, `SCTEX`, `TPLEX`, `CAVITEX`, `MCX`, `NAIAX`, etc.).
3. Update the fare values for the entry/exit combination:
   - `fareClass1`: Class 1 rate (cars, SUVs, motorcycles ≥400cc)
   - `fareClass2`: Class 2 rate (buses, 2-axle trucks)
   - `fareClass3`: Class 3 rate (heavy trucks, trailers)
4. Update `ratesLastUpdated` (or `effectiveFrom`) to the date of the change or announcement (e.g. `DateTime(2026, 8, 20)`).
   > **Note:** Whenever you change any fare value, always update the `ratesLastUpdated` date for that rule so the app accurately reflects the latest update date in the calculator UI.
5. Save the file. Flutter hot reloads automatically, and all route calculations will immediately use the new rates!