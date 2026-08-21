<div align="center">

  <img src="assets/images/aero_icon_full.png" alt="Aero Logo" width="120" />

  # Aero
  ### A Philippine Expressway Driving Companion

  Aero helps drivers estimate Philippine expressway tolls, view Autosweep and Easytrip totals, plan trips, save recent routes, and calculate fuel costs in one unified app.

  <p align="center">
    <code>🛣️ Toll Estimates</code> &nbsp;
    <code>💳 RFID Breakdown</code> &nbsp;
    <code>⛽ Fuel Planning</code>
  </p>

</div>

---

## 📱 See Aero in Action

<div align="center">
  <img src="assets/screenshots/home.png" alt="Home Dashboard" width="45%" />
  &nbsp;
  <img src="assets/screenshots/toll-calculator.png" alt="Toll Calculator" width="45%" />
</div>

<br />

<details>
<summary><b>📷 View More Screens (Recent Routes, Themes, & Settings)</b></summary>
<br />
<div align="center">
  <img src="assets/screenshots/recent-routes.png" alt="Recent Routes" width="45%" />
  &nbsp;
  <img src="assets/screenshots/settings.png" alt="Settings & Theme" width="45%" />
  <br /><br />
  <img src="assets/screenshots/light-mode.png" alt="Light Mode" width="45%" />
  &nbsp;
  <img src="assets/screenshots/dark-mode.png" alt="Dark Mode" width="45%" />
</div>
</details>

---

## ✨ Features

| Feature | Description |
|---|---|
| 🛣️ **Toll Calculator** | TRB-matrix-based toll estimates across 11+ Philippine expressways (STAR, SLEX, Skyway, NLEX, SCTEX, CALAX, CAVITEX, MCX, NAIAX, TPLEX, CCLEX). |
| 💳 **Autosweep & Easytrip** | Clear per-operator RFID balance breakdown — never merged into a single confusing total. |
| ⛽ **Fuel Budget** | Integrated fuel cost estimator with customizable pump prices and one-tap vehicle presets (Sedan, SUV, Van/Pickup). |
| 🧭 **Route Options** | Interactive toggle to switch between elevated Skyway and surface SLEX routes where supported. |
| 🕘 **Recent Trips** | Automatic trip logging with one-tap favorite pinning and instant route re-calculation. |
| 🌗 **Light & Dark Mode** | Seamless theme switching between high-contrast Light Mode and sleek Nocturnal Dark Mode. |
| 📶 **Offline Ready** | Fully functional without internet signal using cached local toll rate matrices. |
| ✏️ **Editable Toll Rates** | Single-file rate structure in [`lib/data/toll_rates_data.dart`](lib/data/toll_rates_data.dart) for fast updates after TRB tariff announcements. |

---

## 🚀 Quick Start

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (v3.19+)
- Android Studio / VS Code with Flutter extension
- Connected Android device or emulator

### Install and Run

```bash
# 1. Clone the repository
git clone https://github.com/DreiwanabeTexh/toll-companion.git
cd toll-companion

# 2. Install dependencies
flutter pub get

# 3. Launch application on connected device
flutter run
```

### Test Suite & Analysis

```bash
# Run unit and widget test suite
flutter test

# Run static analysis check
flutter analyze
```

### Build Android Release APK

```bash
flutter build apk --release
```
*Output location:* `build/app/outputs/flutter-apk/app-release.apk`

---

## 🛠️ Updating Toll Rates

All expressway toll fare rules are stored in a single structured file:
👉 [`lib/data/toll_rates_data.dart`](lib/data/toll_rates_data.dart)

### Real Code Structure Example

```dart
// Example rule from lib/data/toll_rates_data.dart
TollChargeRule(
  id: 'rule_star_tanauan_sto_tomas',
  expressway: 'STAR',
  operator: 'autosweep',
  collectionType: 'closedSystem',
  entryPlazaId: 'star_tanauan',
  exitPlazaId: 'star_sto_tomas',
  fareClass1: 14.0,
  fareClass2: 29.0,
  fareClass3: 43.0,
  effectiveFrom: DateTime(2024, 5, 1),
  sourceName: 'TRB Approved Toll Rate Matrix for STAR Tollway (May 2024)',
  sourceUrl: 'https://trb.gov.ph/index.php/toll-rates/star-tollway-toll-rate',
  ratesLastUpdated: DateTime(2026, 8, 19),
  notes: 'STAR Closed System OD: Tanauan to Sto. Tomas',
),
```

### Steps to Update Rates:
1. Open [`lib/data/toll_rates_data.dart`](lib/data/toll_rates_data.dart).
2. Locate the specific expressway entry/exit rule.
3. Update `fareClass1`, `fareClass2`, and `fareClass3` values.
4. Update `ratesLastUpdated` (and `effectiveFrom`) to the date of the TRB announcement.
5. Run tests and static analysis:
   ```bash
   flutter test
   flutter analyze
   ```
6. Rebuild the release APK if bundling updated rates for distribution.

---

## ⚠️ Disclaimer & Security

> [!IMPORTANT]
> **Toll Estimate Disclaimer**
> Aero provides toll estimates based on manually maintained TRB rate matrices. Actual toll fees may vary due to newly gazetted rate adjustments, barrier configurations, or operator promos. Always check official advisories and toll-plaza signage before travelling.

> [!NOTE]
> **Developer Security & Keystore Privacy**
> Release builds strictly require a private Android release keystore configured via `android/key.properties`. Keystores, signing passwords, and credential files are gitignored and must never be committed to source control or shared publicly. Public testers should download `app-release.apk` only from official repository releases.

---

## 📁 Project Structure

```
Toll/
├── assets/
│   ├── images/              # Logo artwork, mascot graphics, and app icons
│   └── screenshots/         # Real screenshots for documentation
├── lib/
│   ├── data/                # Toll rate matrices, plaza nodes, & segment connectivity
│   ├── models/              # Data models (TollPlaza, Route, RecentTrip, etc.)
│   ├── screens/             # UI Screens (Home, TollCalculator, Guide, Checklist, etc.)
│   ├── services/            # CacheService, TollService, RoutingEngine
│   ├── theme.dart           # Light & Dark theme design system
│   └── main.dart            # Application entrypoint
├── test/                    # Comprehensive unit and widget test suites
├── firestore.rules          # Firestore Security Rules definition
└── pubspec.yaml             # Flutter dependencies & asset declarations
```

---

## 🤝 Contributing

Contributions to update toll rates, add new expressway plazas, or improve route calculations are welcome!
1. Fork the repository.
2. Create a feature branch: `git checkout -b update/nlex-rates`.
3. Make your edits in [`lib/data/toll_rates_data.dart`](lib/data/toll_rates_data.dart) with official TRB source links.
4. Verify with `flutter test` and `flutter analyze`.
5. Submit a Pull Request.

---

<div align="center">

  **License:** To be added &nbsp;•&nbsp; Built with **Flutter** 💙 &nbsp;•&nbsp; *Made for Philippine drivers* 🇵🇭

</div>