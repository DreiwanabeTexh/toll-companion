# Data Model & Firestore Schema Reference

This document defines the Firestore collection schemas for all Phase 1, Phase 2, and Phase 3 features.
All public collections are **read-only** for clients, with `dataReports` being **write-only** for client devices.

---

## 1. Collection: `tollPlazas` (Phase 4 Exit Graph)
Each document represents a discrete exit, entry barrier, or interchange node on an expressway.

| Field | Type | Description |
|:---|:---|:---|
| `id` | string | Unique plaza ID (e.g. `star_batangas`, `slex_calamba`, `nlex_bocaue`) |
| `name` | string | Human-readable exit name (e.g. `"Batangas City Terminal"`, `"Bocaue Barrier"`) |
| `expressway` | string | Expressway code (e.g. `STAR`, `SLEX`, `SKYWAY`, `NLEX`, `CALAX`, `CAVITEX`, `TPLEX`, `SCTEX`) |
| `expresswayName` | string | Full name (e.g. `"STAR Tollway"`, `"South Luzon Expressway"`) |
| `operator` | string | Operator tag (`"autosweep"` or `"easytrip"`) |
| `orderIndex` | number | Position/sequence index along the expressway line |
| `isInterchange` | boolean | True if this plaza connects to another expressway |
| `connectsTo` | array\<string\> | List of connecting interchange plaza IDs |
| `isActive` | boolean | Active status |
| `code` | string? | Optional plaza code / abbreviation |

---

## 2. Collection: `tollSegments`
Each document represents a single entry-to-exit toll segment on one expressway.

| Field | Type | Description |
|:---|:---|:---|
| `id` | string | e.g. `seg_star_batangas_lipa` |
| `expressway` | string | `STAR`, `SLEX`, `SKYWAY`, `NLEX`, `TPLEX`, `CAVITEX`, `CALAX`, etc. |
| `expresswayName` | string | `"STAR Tollway"`, `"South Luzon Expressway"` |
| `operator` | string | `"autosweep"` or `"easytrip"` |
| `entryPoint` | string | Entry toll plaza ID / name |
| `exitPoint` | string | Exit toll plaza ID / name |
| `fareClass1` | number | Class 1 fare (PHP) |
| `fareClass2` | number | Class 2 fare (PHP) |
| `fareClass3` | number | Class 3 fare (PHP) |
| `direction` | string | `"northbound"`, `"southbound"`, or `"both"` |
| `isActive` | boolean | Active status |
| `lastUpdated` | timestamp | Last modified date |
| `lastVerified` | timestamp? | **Nullable** trust verification date |

---

## 2. Collection: `routes`
Pre-defined routes referencing ordered `tollSegments` document IDs.

| Field | Type | Description |
|:---|:---|:---|
| `id` | string | e.g. `sample_route_multi_operator` |
| `name` | string | Display route name |
| `origin` | string | Starting point |
| `destination` | string | Terminus |
| `segmentIds` | array\<string\> | Ordered list of `tollSegments` IDs |
| `lastVerified` | timestamp? | **Nullable** trust verification date |
| `isActive` | boolean | Active status |

---

## 3. Collection: `emergencyContacts`
Official hotlines only (Tier 1).

| Field | Type | Description |
|:---|:---|:---|
| `id` | string | e.g. `contact_trb` |
| `agencyName` | string | Full agency name |
| `agencyShort` | string | Short label (e.g. `TRB`, `AUTOSWEEP`) |
| `coverageArea` | string | Road network coverage |
| `phoneNumber` | string | E.164 phone number for `tel:` URI |
| `displayNumber` | string | Formatted display number |
| `description` | string | Role / services |
| `lastVerified` | timestamp? | **Nullable** verification date (null = unverified placeholder) |
| `sortOrder` | number | Display sort order |
| `isActive` | boolean | Active status |

---

## 4. Collection: `guideEntries`
FAQ-style guidance for on-road situations.

| Field | Type | Description |
|:---|:---|:---|
| `id` | string | e.g. `guide_rfid_unreadable` |
| `title` | string | Question / situation title |
| `shortTitle` | string | Compact card title |
| `category` | string | `"rfid"`, `"breakdown"`, `"navigation"`, `"safety"` |
| `content` | string | Step-by-step guidance text |
| `sortOrder` | number | Display sort order |
| `tags` | array\<string\> | Search / categorization tags |
| `isActive` | boolean | Active status |
| `lastUpdated` | timestamp | Freshness date |

---

## 5. Collection: `checklistItems` (Phase 2)
Pre-trip readiness items editable in Firestore.

| Field | Type | Description |
|:---|:---|:---|
| `id` | string | e.g. `check_autosweep_balance` |
| `title` | string | Item title (e.g. `"Autosweep RFID Balance"`) |
| `description` | string | Actionable advice (e.g. `"Ensure balance is at least ₱615.00"`) |
| `category` | string | `"rfid"`, `"vehicle"`, `"documents"`, `"emergency"` |
| `operator` | string? | `"autosweep"`, `"easytrip"`, or `null` (for route filtering) |
| `sortOrder` | number | Display order |
| `isActive` | boolean | Active status |

---

## 6. Collection: `routeBriefings` (Phase 2)
Route-specific briefings with lane tips, rest stops, and exit guidance.

| Field | Type | Description |
|:---|:---|:---|
| `id` | string | e.g. `briefing_sample_route_multi_operator` |
| `routeId` | string | Matches `routes` doc id |
| `routeName` | string | Route title for display |
| `laneTips` | array\<map\> | `[{"title": "...", "description": "...", "icon": "..."}]` |
| `restStops` | array\<map\> | `[{"name": "...", "location": "...", "amenities": ["Fuel", "Food"]}]` |
| `exitConfusions` | array\<map\> | `[{"location": "...", "warning": "...", "tip": "..."}]` |
| `generalAdvice` | string | Summary route briefing advice |
| `lastUpdated` | timestamp | Verification date |
| `isActive` | boolean | Active status |

---

## 7. Collection: `dataReports` (Phase 3 — Write-Only Client Feedback)
Stores driver feedback and discrepancy reports for manual administrative review. Client permissions are strictly **create-only** (read/update/delete denied).

| Field | Type | Description |
|:---|:---|:---|
| `id` | string | Auto-generated document ID |
| `reportType` | string | `"emergency_contact"`, `"toll_fare"`, or `"route"` |
| `targetId` | string | ID of the contact, route, or toll plaza |
| `targetName` | string | Display label of the reported entity |
| `issueDescription` | string | Free-form driver description of the discrepancy |
| `appVersion` | string | e.g. `"1.0.0+1"` |
| `contextData` | map | Auto-attached context (fares, phone numbers, route endpoints) |
| `timestamp` | timestamp | Submission timestamp |
| `status` | string | `"pending"`, `"reviewed"`, or `"resolved"` (for console admin) |

---

## 8. Local Device Cache Keys (`SharedPreferences`)

| Key | Description |
|:---|:---|
| `aero_cached_emergency_contacts` | JSON stringified list of `EmergencyContact` objects |
| `aero_cached_routes` | JSON stringified list of `RouteModel` objects |
| `aero_cached_segments_{routeId}` | JSON stringified list of `TollSegment` objects per route |
| `aero_cached_guide_entries` | JSON stringified list of `GuideEntry` objects |
| `aero_cached_last_trip` | JSON map storing the last selected route, class, total fare, and breakdown |
