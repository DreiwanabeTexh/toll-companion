# Philippine Toll Road Reference Data

This document catalogs the expressways, their operators, and key toll plazas
relevant to the app. This is reference material for building the Toll Calculator
feature and seeding Firestore.

> **⚠️ ALL fare amounts below are approximate/placeholder values.**
> They must be verified against official toll operator websites or signage
> before production use. Fares change periodically via TRB-approved petitions.

---

## Toll Operators

### SMC Tollways (Autosweep RFID)

San Miguel Corporation's toll road subsidiary. Uses the **Autosweep** RFID
system (black RFID sticker).

| Expressway       | Code     | Stretch                                |
|:-----------------|:---------|:---------------------------------------|
| STAR Tollway     | `STAR`   | Batangas City ↔ Sto. Tomas, Batangas   |
| SLEX             | `SLEX`   | Sto. Tomas ↔ Alabang (Muntinlupa)      |
| Skyway Stage 3   | `SKYWAY` | Alabang ↔ Balintawak (Quezon City)     |
| TPLEX            | `TPLEX`  | Tarlac ↔ Rosario, La Union             |
| NAIAX            | `NAIAX`  | Skyway ↔ NAIA Terminals                |

### Metro Pacific Tollways Corp (Easytrip RFID)

MPTC, a subsidiary of Metro Pacific Investments. Uses the **Easytrip** RFID
system (blue RFID sticker).

| Expressway       | Code      | Stretch                               |
|:-----------------|:----------|:--------------------------------------|
| NLEX             | `NLEX`    | Balintawak (QC) ↔ Tarlac              |
| SCTEX            | `SCTEX`   | Clark ↔ Subic                         |
| CAVITEX          | `CAVITEX` | Manila ↔ Cavite                       |
| CALAX            | `CALAX`   | Mamplasan (Laguna) ↔ Silang (Cavite)  |
| C5 Link          | `C5LINK`  | C5 Road ↔ SLEX                       |
| CCLEX            | `CCLEX`   | Cebu ↔ Cordova (Cebu-Cordova Bridge)  |

---

## Key Route: Batangas → Novaliches

This is the initial personal route that the app must support.

### Segment Breakdown

| # | Expressway | Segment               | Operator   | Class 1 Fare (est.) |
|:--|:-----------|:----------------------|:-----------|:--------------------|
| 1 | STAR       | Batangas → Lipa       | Autosweep  | ₱89                 |
| 2 | STAR       | Lipa → Sto. Tomas     | Autosweep  | ₱57                 |
| 3 | SLEX       | Sto. Tomas → Alabang  | Autosweep  | ₱195                |
| 4 | Skyway 3   | Alabang → Balintawak  | Autosweep  | ₱274                |
| 5 | NLEX       | Balintawak → Mindanao Ave | Easytrip | ₱87               |

### Operator Summary

| Operator   | Segments | Subtotal (est.) |
|:-----------|:---------|:----------------|
| Autosweep  | 1–4      | ₱615            |
| Easytrip   | 5        | ₱87             |
| **Total**  |          | **₱702**        |

### Top-Up Advisory

> "Load at least **₱615 on Autosweep** and **₱87 on Easytrip** before this
> trip."

This is the core UX value proposition of the Toll Calculator.

---

## Toll Plaza Names (Reference List)

These are the entry/exit point names used in `tollSegments` documents.

### STAR Tollway
- Batangas
- Lipa
- Sto. Tomas

### SLEX
- Sto. Tomas
- Calamba
- Santa Rosa
- Cabuyao
- San Pedro
- Biñan
- Alabang (Filinvest)

### Skyway Stage 3
- Alabang
- Sucat
- Bicutan
- Nichols
- Makati
- Guadalupe
- Quezon Ave
- Balintawak

### NLEX
- Balintawak
- Mindanao Ave (Quirino)
- Karuhatan (Valenzuela)
- Meycauayan
- Marilao
- Bocaue
- Sta. Rita
- San Fernando
- Angeles
- Dau
- Tarlac

### CAVITEX
- Coastal Road (Manila)
- Zapote
- Kawit
- Noveleta

### CALAX
- Mamplasan
- Santa Rosa–Tagaytay
- Silang

---

## Notes for Implementation

1. **Fare direction** — Some toll plazas have different fares for northbound vs.
   southbound. The `direction` field in `tollSegments` handles this. For
   simplicity in Phase 1, assume `"both"` (same fare either direction) unless
   data shows otherwise.

2. **Class types** — Philippine expressways use 3 vehicle classes:
   - **Class 1**: Cars, SUVs, pickups, vans (most users)
   - **Class 2**: Buses, small trucks
   - **Class 3**: Large trucks, trailers
   
   The app defaults to Class 1 but should allow selection.

3. **RFID interoperability** — As of 2024, Autosweep and Easytrip are NOT
   interoperable. A driver needs BOTH stickers if crossing between SMC and
   MPTC roads. This is a key pain point the app addresses.

4. **Fare updates** — Toll fares are regulated by the TRB and change via
   approved petitions. The `lastUpdated` field on each segment lets the app
   show data freshness to users.
