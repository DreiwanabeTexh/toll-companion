# Philippine Toll Road Reference Data

This document catalogs the expressways, concessionaire operators, RFID systems, and
key toll plazas across the Philippine expressway network. This serves as domain reference
material for the Aero Toll Calculator and routing catalog.

> **⚠️ NOTE:** Toll fare amounts change periodically via TRB-approved petitions.
> Fares in the app must carry verification timestamps (`lastVerified`) and support
> discrepancy reporting.

---

## 1. Concessionaire Toll Operators & RFID Systems

### SMC Tollways (Autosweep RFID)
Operated by San Miguel Corporation infrastructure subsidiaries. Uses **Autosweep** RFID.

| Expressway | Code | Network Corridor | RFID Tag |
|:---|:---|:---|:---|
| STAR Tollway | `STAR` | Batangas City ↔ Sto. Tomas, Batangas | Autosweep |
| South Luzon Expressway (SLEX) | `SLEX` | Sto. Tomas ↔ Alabang (Muntinlupa) | Autosweep |
| Skyway Stages 1, 2, & 3 | `SKYWAY` | Alabang ↔ Buendia ↔ Balintawak (QC) | Autosweep |
| Tarlac–Pangasinan–La Union (TPLEX) | `TPLEX` | Tarlac City ↔ Rosario, La Union | Autosweep |
| NAIA Expressway (NAIAX) | `NAIAX` | Skyway / Sales ↔ NAIA Terminals 1–3, Macapagal | Autosweep |
| Muntinlupa–Cavite Expressway (MCX) | `MCX` | SLEX Susana Heights ↔ Daang Hari, Cavite | Autosweep |

### Metro Pacific Tollways Corporation (Easytrip RFID)
Operated by MPTC subsidiaries. Uses **Easytrip** RFID.

| Expressway | Code | Network Corridor | RFID Tag |
|:---|:---|:---|:---|
| North Luzon Expressway (NLEX) | `NLEX` | Balintawak (QC) / Mindanao Ave ↔ Sta. Ines (Mabalacat) | Easytrip |
| Subic–Clark–Tarlac (SCTEX) | `SCTEX` | Subic Tipo ↔ Clark ↔ Tarlac (TPLEX Connection) | Easytrip |
| Manila–Cavite Expressway (CAVITEX) | `CAVITEX` | Roxas Blvd (Parañaque) ↔ Kawit, Cavite | Easytrip |
| Cavite–Laguna Expressway (CALAX) | `CALAX` | Mamplasan (SLEX) ↔ Silang / Kawit (CAVITEX) | Easytrip |
| C5 Southlink Expressway | `C5LINK` | C5 Road (Taguig) ↔ Merville / SLEX / CAVITEX | Easytrip |
| NLEX Connector Road | `NLEXCONN` | Caloocan Interchange ↔ España ↔ Sta. Mesa | Easytrip |
| Cebu–Cordova Link Expressway (CCLEX) | `CCLEX` | Cebu City ↔ Cordova (Mactan Island) | Easytrip / CCLEX |

---

## 2. Multi-Operator Corridor Example: Batangas → North Metro Manila / NLEX

A representative cross-operator journey illustrating how Aero segments toll calculations:

### Segment Breakdown

| # | Expressway | Segment | Concessionaire | RFID Operator | Class 1 Est. |
|:--|:---|:---|:---|:---|:---|
| 1 | STAR Tollway | Batangas City → Lipa | SMC Tollways | Autosweep | ₱89 |
| 2 | STAR Tollway | Lipa → Sto. Tomas | SMC Tollways | Autosweep | ₱57 |
| 3 | SLEX | Sto. Tomas → Alabang | SMC Tollways | Autosweep | ₱195 |
| 4 | Skyway Stage 3 | Alabang → Balintawak | SMC Tollways | Autosweep | ₱274 |
| 5 | NLEX | Balintawak → Mindanao Ave / Bocaue | MPTC | Easytrip | ₱87 |

### Operator Subtotal Breakdown

| Operator | Applicable Segments | Operator Subtotal |
|:---|:---|:---|
| **Autosweep RFID** | STAR (1–2), SLEX (3), Skyway 3 (4) | **₱615.00** |
| **Easytrip RFID** | NLEX (5) | **₱87.00** |
| **Combined Estimated Total** | All 5 Segments | **₱702.00** |

### Driver Action Target
> **Top-Up Notice:** Load at least **₱615.00 on Autosweep** and **₱87.00 on Easytrip** before departure.

---

## 3. Philippine Vehicle Classifications

All Philippine tollways classify vehicles into three regulatory classes:

| Class | Eligible Vehicle Types | Toll Ratio Multiplier |
|:---|:---|:---|
| **Class 1** | Cars, sedans, SUVs, crossovers, pickups, passenger vans (height ≤ 7.5ft / 2 axles) | Base Fare ($1.0\times$) |
| **Class 2** | Light trucks, medium buses, commercial delivery vans (height > 7.5ft / 2 axles) | Approx. $2.0\times$ Base Fare |
| **Class 3** | Heavy multi-axle trucks, trailers, articulated freight haulers (3+ axles) | Approx. $3.0\times$ Base Fare |

---

## 4. Key Expressways & Toll Plaza Index

### STAR Tollway Plazas
- Batangas City
- Ibaan
- Lipa
- Malvar
- Tanauan
- Sto. Tomas

### SLEX Plazas
- Sto. Tomas
- Calamba
- Canlubang / Mayapa
- Silangan / Cabuyao
- Santa Rosa
- Greenfield / Eton City
- Southwoods / Biñan
- Carmona
- San Pedro
- Susana Heights / MCX
- Filinvest / Alabang

### Skyway (Stages 1, 2, 3) Plazas
- Alabang Main Plazas (Northbound / Southbound)
- Sucat Exit / Entry
- Bicutan Exit / Entry
- Nichols / Sales Interchange
- Buendia / Makati Ramp
- Quirino Ave Ramp
- Plaza Dilao Ramp
- E. Rodriguez / Quezon Ave Ramp
- Balintawak Main Gantry

### NLEX Plazas
- Balintawak Barrier
- Mindanao Avenue Barrier (Smart Connect)
- Karuhatan / Harbor Link
- Meycauayan
- Marilao
- Bocaue Barrier
- Tabang (Guiguinto)
- Balagtas
- San Simon
- San Fernando
- Mexico
- Angeles
- Clark South / Dau
- Sta. Ines

### CAVITEX & C5 Southlink Plazas
- Parañaque Toll Plaza (Coastal Road)
- Zapote Interchange
- Kawit / Longos Extension
- Merville Plaza
- Taguig / C5 Plaza

### CALAX Plazas
- Mamplasan Barrier (SLEX interchange)
- Laguna Technopark
- Santa Rosa–Tagaytay
- Silang East
- Silang Aguinaldo
- Governor's Drive (under construction / future expansion)
