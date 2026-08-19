# PH Expressway Companion

A driver's companion app for navigating Philippine expressways — built around the real pain point of multi-operator toll systems (Autosweep vs. Easytrip), for any driver planning a trip across PH expressways.

> **Status:** Pre-development / Planning complete for Phase 1
> **Note:** All fare amounts, toll plaza data, and phone numbers referenced in this project are **placeholders** pending verification against official sources. Do not ship with unverified data.

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
| Local caching (later phase) | `hive` or `shared_preferences` | Offline support for spotty expressway signal |
| Auth | None (Phase 1) | No user accounts needed yet; all Firestore reads, no per-user writes |

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

### Phase 1 — MVP (build first, ship first)

| Feature | Description |
|---|---|
| **Toll Calculator** | Route builder + fare breakdown by RFID operator. Shows which wallet (Autosweep / Easytrip) needs topping up and by how much — never a single merged total. |
| **Quick Guide** ("What do I do if...") | Static FAQ-style content for common on-road situations. Simple list/detail UI, content pulled from Firestore. |
| **Emergency Contacts (Tier 1 only)** | Official hotlines only — TRB, SMC/Autosweep, MPTC/Easytrip, MMDA, PNP-HPG. Tap-to-call UX. Every entry carries a mandatory **last-verified date** shown in the UI. Crowdsourced/local listings explicitly excluded from this phase. |

### Phase 2 — Companion Depth (after real trip usage)

| Feature | Description |
|---|---|
| **Pre-Trip Checklist** | Loosely tied to the route built in the Toll Calculator; eventually smart enough to suggest specific top-up amounts. |
| **Route Briefing** | Lane tips, rest stops, and common exit confusions, tied to whatever route the user builds. Content-heavy — driven by real research across major PH expressway routes, expanded incrementally based on usage. |

### Phase 3 — Polish & Trust

- Visible "last verified" indicators across all contact and fare data
- Offline caching for last-used route, checklist, and contacts
- User feedback mechanism to flag outdated numbers or fares

### Phase 4 — v2 Exploration

- **Fuel comparison** across the route (explicitly deferred from v1 — strong v2 story, not a launch blocker)
- Smart checklist auto-suggesting RFID top-up amounts based on the built route
- **Tier 2 emergency contacts** — local mechanic shops per exit — only once a verification/moderation process exists

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
Phase 0 — Foundation
  └─ Flutter project setup, Firebase/Firestore connection, schema design

Phase 1 — Core MVP  ⬅ SHIP HERE
  ├─ Toll Calculator (multi-operator breakdown)
  ├─ Quick Guide
  └─ Emergency Contacts (Tier 1, verified only)

        ↓ Soft-launch to self / friends & family, use on real trips ↓

Phase 2 — Companion Depth
  ├─ Pre-Trip Checklist
  └─ Route Briefing (expanded incrementally across major PH expressway routes)

Phase 3 — Polish & Trust
  ├─ Last-verified indicators
  ├─ Offline caching
  └─ Feedback / correction mechanism

Phase 4 — v2
  ├─ Fuel comparison
  ├─ Smart checklist
  └─ Tier 2 local mechanic listings (verification process required first)
```

**Deployment path:**
1. Local device testing during development (Flutter hot reload, USB debugging/emulator)
2. Shareable APK for informal testing (Android)
3. Public release — Google Play first (cheaper, faster review), Apple App Store once stable (requires active Apple Developer account)

---

## Explicit Non-Goals (Phase 1)

- No user accounts or authentication
- No state management libraries or extra dependencies beyond what's listed, without discussion
- No crowdsourced or unverified emergency contact data
- No fuel comparison, smart suggestions, or Tier 2 features until their respective phases