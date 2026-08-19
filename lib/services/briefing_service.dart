import '../models/route_briefing.dart';
import 'firestore_service.dart';

/// Data service for Route Briefings (Phase 2).
///
/// Fetches route-specific lane tips, rest stops, and exit warnings from Firestore.
class BriefingService {
  final FirestoreService? _customFirestoreService;

  BriefingService({FirestoreService? firestoreService})
      : _customFirestoreService = firestoreService;

  FirestoreService get _firestoreService =>
      _customFirestoreService ?? FirestoreService();

  /// Fetches the route briefing for a specific route ID.
  Stream<RouteBriefing?> getBriefingForRoute(String routeId) {
    return _firestoreService.routeBriefingsRef
        .where('routeId', isEqualTo: routeId)
        .where('isActive', isEqualTo: true)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      return snapshot.docs.first.data();
    });
  }

  /// Fetches all active route briefings.
  Stream<List<RouteBriefing>> getAllBriefings() {
    return _firestoreService.routeBriefingsRef
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  /// Seeds general-purpose route briefings if collection is empty.
  ///
  /// TODO(data): All briefing entries below are placeholders for route structure verification.
  Future<void> seedPlaceholderDataIfEmpty() async {
    final existing =
        await _firestoreService.routeBriefingsRef.limit(1).get();
    if (existing.docs.isNotEmpty) {
      return; // Already seeded
    }

    // TODO(data): Sample briefings for the 3 sample routes
    final sampleBriefings = [
      RouteBriefing(
        id: 'briefing_sample_route_multi_operator',
        routeId: 'sample_route_multi_operator',
        routeName: 'Sample Multi-Operator Corridor (Plaza A1 → Plaza B3)',
        generalAdvice:
            'This corridor crosses two separate toll operators (Autosweep on Alpha & Connector, Easytrip on Beta). Maintain safe following distance at transition plazas and have both RFID tags installed properly.',
        laneTips: const [
          LaneTip(
            title: 'Transition Plaza Approach',
            description:
                'Slow down to 20 km/h when approaching Plaza A3 / B1 boundary. RFID scanners require 2-3 car lengths separation.',
            icon: 'speed',
          ),
          LaneTip(
            title: 'Dedicated ETC vs Mixed Lanes',
            description:
                'Extreme left lanes are dedicated RFID only. If your RFID tag is new, stay in middle lanes for operator assist.',
            icon: 'alt_route',
          ),
          LaneTip(
            title: 'Connector Speed Enforcement',
            description:
                'Metro Connector has an 80 km/h strict speed limit with average speed cameras between Plaza A3 and Plaza B1.',
            icon: 'visibility',
          ),
        ],
        restStops: const [
          RestStop(
            name: 'Alpha Mega Service Area',
            location: 'Alpha Tollway KM 44 (Northbound & Southbound)',
            kilometer: 'KM 44',
            amenities: ['Gasoline & Diesel', 'Fast Food & Dining', 'Clean Restrooms', '24/7 ATM'],
          ),
          RestStop(
            name: 'Beta Central Oasis',
            location: 'Beta Tollway KM 18',
            kilometer: 'KM 18',
            amenities: ['Fuel & EV Rapid Charging', 'Convenience Store', 'Tire & Battery Check', 'Restrooms'],
          ),
        ],
        exitConfusions: const [
          ExitWarning(
            location: 'Plaza A2 Fork (Industrial Bypass vs Central)',
            warning: 'Right 2 lanes exit to Industrial Bypass with no return loop to the expressway.',
            tip: 'Stay on the left 2 lanes 1 km before Plaza A2 if continuing toward Plaza A3.',
          ),
          ExitWarning(
            location: 'Plaza B2 / Boulevard Flyover Split',
            warning: 'Split occurs immediately after toll barrier with tight curve.',
            tip: 'Pre-position in leftmost lane before toll gantry for the elevated expressway bypass.',
          ),
        ],
        lastUpdated: DateTime(2025, 1, 15),
        isActive: true,
      ),
      RouteBriefing(
        id: 'briefing_sample_route_autosweep_only',
        routeId: 'sample_route_autosweep_only',
        routeName: 'Sample Alpha Corridor (Plaza A1 → Plaza A3)',
        generalAdvice:
            'Single-operator Autosweep corridor. Fast-moving traffic with dedicated express ETC gantries.',
        laneTips: const [
          LaneTip(
            title: 'RFID Sensor Clearance',
            description: 'Maintain 30 km/h maximum through barrier-less open road tolling sections.',
            icon: 'sensors',
          ),
          LaneTip(
            title: 'Overtaking Lane Etiquette',
            description: 'Keep right except when overtaking. Highway patrol strictly monitors tailgating.',
            icon: 'swap_horiz',
          ),
        ],
        restStops: const [
          RestStop(
            name: 'Alpha Gateway Travel Plaza',
            location: 'Alpha Tollway KM 12',
            kilometer: 'KM 12',
            amenities: ['Fuel Station', 'Coffee & Snacks', 'Restrooms'],
          ),
        ],
        exitConfusions: const [
          ExitWarning(
            location: 'Plaza A3 Interchange',
            warning: 'Heavy merging traffic from coastal access ramp.',
            tip: 'Yield to accelerating traffic and watch for sudden merges on right side.',
          ),
        ],
        lastUpdated: DateTime(2025, 1, 15),
        isActive: true,
      ),
      RouteBriefing(
        id: 'briefing_sample_route_easytrip_only',
        routeId: 'sample_route_easytrip_only',
        routeName: 'Sample Beta Corridor (Plaza B1 → Plaza B3)',
        generalAdvice:
            'Single-operator Easytrip corridor connecting commercial terminals with wide 4-lane expressway sections.',
        laneTips: const [
          LaneTip(
            title: 'Heavy Vehicle Lane Restrictions',
            description: 'Buses and trucks are restricted to outer right 2 lanes at all times.',
            icon: 'local_shipping',
          ),
          LaneTip(
            title: 'Automated Number Plate Recognition (ANPR)',
            description: 'Cameras back up RFID tags. Keep front and rear license plates clean and clear.',
            icon: 'camera_alt',
          ),
        ],
        restStops: const [
          RestStop(
            name: 'Beta Northfield Rest Station',
            location: 'Beta Tollway KM 32',
            kilometer: 'KM 32',
            amenities: ['24/7 Fuel', 'Dining & Cafes', 'Air & Water Station', 'Restrooms'],
          ),
        ],
        exitConfusions: const [
          ExitWarning(
            location: 'Plaza B3 Terminal Split',
            warning: 'Terminal exit splits into Airport Expressway and City Center Boulevard.',
            tip: 'Watch overhead green signage 2 km ahead of terminal plaza.',
          ),
        ],
        lastUpdated: DateTime(2025, 1, 15),
        isActive: true,
      ),
    ];

    for (final briefing in sampleBriefings) {
      await _firestoreService.routeBriefingsRef.doc(briefing.id).set(briefing);
    }
  }
}
