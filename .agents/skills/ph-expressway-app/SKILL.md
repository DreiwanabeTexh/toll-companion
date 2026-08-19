---
name: ph-expressway-app
description: >-
  Build and maintain a Philippine expressway driving companion Flutter app with
  Firebase/Firestore backend. Use when creating, modifying, or debugging any
  feature of this app — including the Toll Calculator, Quick Guide, or Emergency
  Contacts modules. Also use when designing Firestore collections, structuring
  toll fare data, or working on multi-operator RFID route breakdowns. Activate
  for any task mentioning toll roads, Autosweep, Easytrip, RFID balance,
  expressway routes, or the Phase 1 MVP scope.
---

# Philippine Expressway Driving Companion — Project Skill

This skill defines the full context, conventions, data model, and build
instructions for the app. Read this **before** writing any code for the project.

For detailed reference material, see:
- [Data Model & Firestore Schema](./references/data-model.md)
- [Toll Road Reference Data](./references/toll-roads.md)
- [UI/UX Guidelines](./references/ui-guidelines.md)

---

## 1. Project Overview

A mobile-first driving companion for Philippine expressways (toll roads).
The initial personal route is **Batangas → Novaliches**, crossing multiple toll
operators:

| Operator             | RFID Brand  | Roads                    |
|:---------------------|:------------|:-------------------------|
| SMC Tollways         | Autosweep   | STAR Tollway, SLEX, Skyway, TPLEX, NAIAX |
| Metro Pacific (MPTC) | Easytrip    | NLEX, CAVITEX, CALAX, C5 Link, CCLEX |

A single trip may cross **both** RFID systems, so the app must track fares
per-operator and show which balance(s) to top up.

---

## 2. Tech Stack

| Layer            | Technology                         | Notes                          |
|:-----------------|:-----------------------------------|:-------------------------------|
| Frontend         | **Flutter** (Dart)                 | Single codebase, mobile-first  |
| Backend / Data   | **Firebase** — Cloud Firestore     | Real-time reads, no auth yet   |
| Tap-to-call      | `url_launcher`                     | For `tel:` links               |
| Local caching    | `hive` or `shared_preferences`     | Later phase — offline support  |

> **Dependency rule**: Do NOT add packages beyond the above without asking the
> user first. The project is solo-maintained; keep the dependency surface small.

---

## 3. Phase Scope — What to Build (and What NOT to)

### Phase 1 — MVP (Current)

Build **only** these three features:

1. **Toll Calculator**
   - Route builder: pick origin → destination across expressway segments
   - Fare breakdown by RFID operator (Autosweep vs Easytrip)
   - Show per-operator subtotal so the driver knows which balance to top up
   - Support multi-operator trips (e.g., STAR → SLEX → Skyway → NLEX)

2. **Quick Guide ("What do I do if...")**
   - Static FAQ-style content: flat tire on expressway, ran out of fuel,
     RFID not reading, wrong exit, etc.
   - Simple list → detail UI
   - Content read from Firestore (editable without app redeploy)

3. **Emergency Contacts (Tier 1 ONLY)**
   - Official hotlines ONLY: TRB, SMC/Autosweep, MPTC/Easytrip, MMDA, PNP-HPG
   - Tap-to-call via `url_launcher`
   - Each contact MUST display a `lastVerified` date in the UI for trust
   - **DO NOT** add crowdsourced or unverified local mechanic listings — that is
     Phase 4 (Tier 2), deferred until a verification process exists

### Deferred — Do NOT Build Unless Explicitly Asked

| Phase | Feature                                           |
|:------|:--------------------------------------------------|
| 2     | Pre-Trip Checklist, Route Briefing (lane tips, rest stops, exit gotchas) |
| 4     | Fuel comparison, smart checklist, Tier 2 mechanic listings |

If the user asks about deferred features, acknowledge them and confirm scope
before writing any code.

---

## 4. Data Model Principles

See [Data Model Reference](./references/data-model.md) for full Firestore
schemas.

Key rules:

1. **Content is database-driven.** Fares, contacts, and guide entries live in
   Firestore so they can be updated without app redeploys.
2. **Every emergency contact** needs: `agencyName`, `coverageArea`,
   `phoneNumber` (E.164), `displayNumber`, `lastVerified` (Timestamp).
3. **Toll fare data** must support multi-operator trips and return a
   **per-operator breakdown**, not just a single total.
4. **Firestore reads only** — no user auth, no per-user writes in Phase 1.
   Security rules should allow public reads on content collections.

---

## 5. Coding Conventions

1. **Simple widget structure** — prefer readability over premature abstraction.
   This is a solo-maintained project. Extract widgets only when reuse is clear.
2. **No auth** — all Firestore reads, no per-user writes.
3. **Card/list-based UI** — designed for quick glancing while stopped/parked
   (NOT while driving). See [UI Guidelines](./references/ui-guidelines.md).
4. **Placeholder data markers** — wherever real data (toll fares, phone
   numbers, guide content) is hardcoded or seeded, add a comment:
   ```dart
   // TODO(data): Verify before production — placeholder fare amount
   ```
5. **File organization** — keep it flat and obvious:
   ```
   lib/
   ├── main.dart
   ├── app.dart                  // MaterialApp, theme, routing
   ├── models/                   // Data classes
   │   ├── toll_segment.dart
   │   ├── emergency_contact.dart
   │   └── guide_entry.dart
   ├── services/                 // Firestore reads, business logic
   │   ├── toll_service.dart
   │   ├── contacts_service.dart
   │   └── guide_service.dart
   ├── screens/                  // Top-level pages
   │   ├── home_screen.dart
   │   ├── toll_calculator_screen.dart
   │   ├── quick_guide_screen.dart
   │   ├── guide_detail_screen.dart
   │   └── emergency_contacts_screen.dart
   └── widgets/                  // Reusable components (only when needed)
       ├── fare_breakdown_card.dart
       └── contact_card.dart
   ```
6. **State management** — start with `StatefulWidget` + `FutureBuilder`/
   `StreamBuilder`. Do NOT introduce Provider, Riverpod, Bloc, etc. unless the
   user explicitly asks.

---

## 6. Build Steps

### Step 1: Project Initialization

1. Create a new Flutter project in the workspace root:
   ```bash
   flutter create --org com.example.tollcompanion --project-name toll_companion .
   ```
2. Add dependencies to `pubspec.yaml`:
   ```yaml
   dependencies:
     firebase_core: ^latest
     cloud_firestore: ^latest
     url_launcher: ^latest
   ```
3. Run `flutter pub get`.
4. Set up Firebase:
   - Use `flutterfire configure` if the user has a Firebase project, OR
   - Create placeholder Firebase config files and note them as TODO.

### Step 2: Data Models

Create Dart data classes in `lib/models/` matching the Firestore schemas in
[data-model.md](./references/data-model.md). Each model needs a
`fromFirestore` factory constructor.

### Step 3: Firestore Services

Create service classes in `lib/services/` that:
- Read from the appropriate Firestore collections
- Return typed model objects
- Handle errors gracefully (show user-friendly messages, not crashes)

### Step 4: Screens & Navigation

Build screens in order:
1. **Home Screen** — hub with cards/buttons for each feature
2. **Toll Calculator** — route selection → fare breakdown display
3. **Quick Guide** — list of guide entries → detail view
4. **Emergency Contacts** — list of contacts with tap-to-call

Use `Navigator` with named routes or simple `push`/`pop`.

### Step 5: Verification

- Run `flutter analyze` — zero warnings.
- Run `flutter test` if tests exist.
- Manually verify on an emulator or device:
  - Toll Calculator shows per-operator fare breakdown
  - Quick Guide loads content from Firestore
  - Emergency Contacts show `lastVerified` date and tap-to-call works
  - All placeholder data is flagged with `// TODO(data):` comments

---

## 7. Firestore Security Rules (Phase 1)

Since there's no auth and all data is public content:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Public read-only access for content collections
    match /tollSegments/{doc} {
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
  }
}
```

---

## 8. Common Pitfalls

1. **Don't merge RFID operator totals** — a trip from Batangas to Novaliches
   crosses Autosweep roads (STAR, SLEX) AND Easytrip roads (NLEX). The fare
   breakdown MUST be split by operator. A single "total: ₱XXX" is useless if
   the driver doesn't know which RFID card to load.

2. **Don't add unverified contacts** — Tier 1 means official hotlines only.
   Every contact must have a `lastVerified` date shown to the user.

3. **Don't introduce state management libraries** without asking — keep it
   simple with built-in Flutter state.

4. **Don't skip the placeholder flag** — any hardcoded fare, phone number, or
   guide text must have a `// TODO(data):` comment.

5. **Don't build deferred features** — if the user's request touches Phase 2+
   scope, confirm before proceeding.
