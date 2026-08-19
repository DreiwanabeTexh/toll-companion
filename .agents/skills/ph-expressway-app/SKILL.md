---
name: ph-expressway-app
description: >-
  Build and maintain Aero, a Philippine expressway driving companion Flutter app with
  Firebase/Firestore backend. Use when creating, modifying, or debugging any
  feature of this app — including the Toll Calculator, Quick Guide, Emergency
  Contacts, Pre-Trip Checklist, Route Briefings, or Routing Engine. Also use
  when designing Firestore collections, structuring toll fare data, implementing
  offline caching, or working on multi-operator RFID route breakdowns.
---

# Aero: Philippine Expressway Driving Companion — Project Skill

This skill defines the full context, architecture, conventions, data model, and
build instructions for **Aero** — the Philippine Expressway Driving Companion.
Read this **before** writing or modifying code in this repository.

For detailed reference material, see:
- [Data Model & Firestore Schema](./references/data-model.md)
- [Toll Road Reference Data](./references/toll-roads.md)
- [UI/UX Guidelines (Aero Nocturnal Command)](./references/ui-guidelines.md)

---

## 1. Project Overview

**Aero** is a mobile-first driving companion designed for motorists navigating the
expressway networks across the Philippines. The app addresses the fundamental
friction points of Philippine toll driving: multi-operator RFID systems, unpredictable
toll costs, gantry non-detection, roadside emergencies, and route preparation.

Philippine expressways are split across two non-interoperable RFID systems operated
by different concessionaires:

| Operator             | RFID Brand  | Concessionaire Expressways |
|:---------------------|:------------|:---------------------------|
| SMC Tollways         | Autosweep   | STAR Tollway, SLEX, Skyway (Stages 1–3), TPLEX, NAIAX, MCX |
| Metro Pacific (MPTC) | Easytrip    | NLEX, SCTEX, CAVITEX, CALAX, C5 Southlink, NLEX Connector, CCLEX |

A single journey across urban corridors or inter-provincial routes often traverses
**both** RFID systems (e.g. SLEX → Skyway → NLEX). Aero isolates and calculates
fares per operator, providing drivers with clear, per-wallet top-up targets before
they depart.

---

## 2. Tech Stack

| Layer            | Technology                         | Notes                          |
|:-----------------|:-----------------------------------|:-------------------------------|
| Frontend         | **Flutter** (Dart)                 | Single codebase, mobile-first, dark Nocturnal Command design system |
| Backend / Data   | **Firebase** — Cloud Firestore     | Real-time reads & remote content updates without app redeploys |
| Tap-to-call      | `url_launcher`                     | Direct Android/iOS `tel:` scheme intent handling |
| Local caching    | `shared_preferences`               | Offline JSON persistence for routes, segments, contacts, guides, and last trip |
| Feedback system  | Cloud Firestore (`dataReports`)   | Write-only collection for driver discrepancy reports |

> **Dependency Rule**: Do NOT add third-party packages beyond the above without
> explicit approval from the user. The project is solo-maintained; keep the dependency
> footprint lean.

---

## 3. Phase Scope & Roadmap

```
Phase 0 — Foundation [COMPLETE]
  └─ Flutter project setup, Firestore connection, core schema definitions

Phase 1 — Core MVP [COMPLETE]
  ├─ Toll Calculator (multi-operator fare breakdown)
  ├─ Quick Guide (expandable troubleshooting accordions)
  └─ Emergency Contacts Tier 1 (official hotlines, tap-to-call)

Phase 2 — Companion Depth [COMPLETE]
  ├─ Pre-Trip Checklist (categorized vehicle & RFID readiness)
  └─ Route Briefing (Lane tips, rest stops, exit warnings)

Phase 2.5 — Aero Rebrand & Visual Identity [COMPLETE]
  ├─ Rebrand to "Aero", persistent 4-tab bottom navigation
  ├─ Native Flutter animated bird mascot hero (floating, breathing, banking)
  └─ Standardized Nocturnal Command design tokens & typography

Phase 3 — Polish & Trust [COMPLETE]
  ├─ Visible "last verified" indicators across all contact and fare data
  ├─ Offline caching resilience via SharedPreferences
  └─ Write-only driver discrepancy feedback reporting (`ReportDialog`)

Phase 3.5 — Real Data Verification [COMPLETE for Tier 1 Contacts]
  ├─ Tier 1 Emergency Contacts verified against official records (2026-08-19)
  └─ Toll fare segment verification (pending official TRB rate audits)

Phase 4 — Routing Engine & Personalization Core [IN PROGRESS]
  ├─ Free exit-to-exit routing & path calculation across interconnecting expressways
  ├─ Manual offline balance tracking & low-balance alerts
  ├─ Recent Routes history, custom route favoriting, and trip logging
  └─ Dynamic randomized status copy for Aero header pills

Phase 5 — Accounts & Cloud Sync [TENTATIVE / NOT COMMITTED]
  └─ User authentication, multi-device sync, vehicle profile management

Phase 6 — v2 Features [FUTURE]
  ├─ Real-time fuel price comparison across service plazas
  ├─ Smart checklist auto-suggesting exact RFID top-up amounts per route
  ├─ Tier 2 emergency contacts (local accredited towing/mechanic shops per exit)
  └─ Full nationwide toll plaza & ramp coverage
```

---

## 4. Data Model Principles

See [Data Model Reference](./references/data-model.md) for full collection schemas.

Key rules:
1. **Content is database-driven**: Fares, emergency contacts, guide entries, checklist
   items, and route briefings live in Firestore with fallback local constants in services.
2. **Every emergency contact** requires: `agencyName`, `coverageArea`, `phoneNumber` (E.164),
   `displayNumber`, `lastVerified` (Timestamp), `sortOrder`, and `isActive`.
3. **Toll fare calculation** must always preserve **per-operator subtotals** (Autosweep vs.
   Easytrip) and never blend them into a single opaque number.
4. **Trust-first indicators**: All contact cards and fare cards must visually surface
   their `lastVerified` timestamp (`VERIFIED MM/YY`) or display the unverified warning
   (`NOT YET VERIFIED`) when null.
5. **Write-only feedback**: User reports submitted through `ReportDialog` are saved
   strictly into the `dataReports` collection with client permissions restricted to `create`.

---

## 5. File Structure & Conventions

```
lib/
├── main.dart                       // App entrypoint & Firebase initialization
├── app.dart                        // AeroApp MaterialApp, theme configuration, routes
├── theme.dart                      // AeroColors, AeroTypography, AeroGlow design tokens
├── firebase_options.dart           // FlutterFire generated platform credentials
├── models/                         // Strongly-typed data models
│   ├── checklist_item.dart         // Pre-trip checklist item model
│   ├── data_report.dart            // Discrepancy report feedback model
│   ├── emergency_contact.dart      // Tier 1 emergency hotline model
│   ├── guide_entry.dart            // Troubleshooting accordion model
│   ├── route_briefing.dart         // Lane tips, rest stops, exit warnings model
│   ├── route_model.dart            // Pre-defined corridor route model
│   ├── route_result.dart           // Calculated multi-operator fare result model
│   └── toll_segment.dart           // Individual entry-to-exit toll fare segment
├── services/                       // Data access & business logic
│   ├── briefing_service.dart       // Route briefing stream & static defaults
│   ├── cache_service.dart          // SharedPreferences offline persistence
│   ├── checklist_service.dart      // Pre-trip checklist stream & static defaults
│   ├── contacts_service.dart       // Tier 1 hotlines stream, cache, and Firestore sync
│   ├── firestore_service.dart      // Cloud Firestore collections & converters
│   ├── guide_service.dart          // Quick guide stream & static defaults
│   ├── report_service.dart         // Write-only dataReports submission & queuing
│   └── toll_service.dart           // Toll computation, segments & routes catalog
├── screens/                        // Top-level UI pages
│   ├── checklist_screen.dart       // Pre-Trip Checklist screen with progress bar
│   ├── emergency_contacts_screen.dart // Verified 24/7 hotline cards & dialer triggers
│   ├── guide_detail_screen.dart    // Step-by-step troubleshooting instructions
│   ├── home_screen.dart            // Aero dashboard, balance cards, recent routes
│   ├── main_navigation_scaffold.dart // Persistent 4-tab bottom navigation shell
│   ├── quick_guide_screen.dart     // Troubleshooting categories & accordion lists
│   ├── route_briefing_screen.dart  // 3-tab route briefing (Tips, Stops, Warnings)
│   └── toll_calculator_screen.dart // Trip details, class selector, fare card
└── widgets/                        // Shared visual components
    ├── aero_mascot.dart            // AeroAvatar, AeroAnimatedHeroMascot, AeroHeroHeaderRow
    ├── aero_offline_banner.dart    // Amber offline warning notification strip
    └── report_dialog.dart          // Discrepancy reporting bottom sheet dialog
```

### Architectural & State Conventions
1. **Stream Initialization**: Never instantiate new streams inside widget `build()` methods.
   Always assign `late final Stream` in `initState()` and supply `initialData` (from local cache
   or static service defaults) to prevent blank loading spinners when offline.
2. **State Management**: Built with Flutter's standard `StatefulWidget`, `StreamBuilder`, and
   service singletons. No external state management packages are used.
3. **Safe Dropdown Handling**: When binding values to `DropdownButton<T>`, always assert
   that `value` exists in the item collection before assigning, falling back to `items.first.value`.

---

## 6. Firestore Security Rules

Deployed Firestore security rules enforce public read access on catalog collections and
strict write-only access for driver feedback:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Public read-only catalog collections
    match /tollSegments/{doc} {
      allow read: if true;
      allow write: if false;
    }
    match /routes/{doc} {
      allow read: if true;
      allow write: if false;
    }
    match /emergencyContacts/{doc} {
      allow read: if true;
      allow write: if false;
    }
    match /guideEntries/{doc} {
      allow read: if true;
      allow write: if false;
    }
    match /checklistItems/{doc} {
      allow read: if true;
      allow write: if false;
    }
    match /routeBriefings/{doc} {
      allow read: if true;
      allow write: if false;
    }

    // Driver discrepancy feedback — client write-only (create)
    match /dataReports/{doc} {
      allow create: if true;
      allow read, update, delete: if false;
    }
  }
}
```

---

## 7. Common Pitfalls & Guardrails

1. **Never merge RFID operator totals** — Autosweep and Easytrip are distinct wallets.
   Always render subtotals per operator (`Autosweep: ₱XXX.XX`, `Easytrip: ₱YYY.YY`).
2. **Preserve Trust Indicators** — Always display `lastVerified` on data-driven cards.
   Do not render dummy or unverified numbers as verified.
3. **Offline-First Resilience** — The app must function seamlessly without internet connectivity.
   All services must maintain static default fallbacks and local SharedPreferences caches.
4. **Respect Deferred Scope**:
   - Do NOT implement user accounts or Firebase Auth without approval (Phase 5).
   - Do NOT implement fuel price scrapers or crowdsourced unverified mechanics (Phase 6).
