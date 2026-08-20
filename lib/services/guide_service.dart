import '../models/guide_entry.dart';
import 'firestore_service.dart';
import 'cache_service.dart';

/// Data service for Quick Guide FAQ entries.
///
/// Handles Firestore queries for general-purpose driver situations
/// with automatic local offline caching.
class GuideService {
  final FirestoreService? _customFirestoreService;
  final CacheService? _customCacheService;

  GuideService({
    FirestoreService? firestoreService,
    CacheService? cacheService,
  })  : _customFirestoreService = firestoreService,
        _customCacheService = cacheService;

  FirestoreService get _firestoreService =>
      _customFirestoreService ?? FirestoreService();

  CacheService get _cacheService =>
      _customCacheService ?? CacheService();

  /// Fetches active guide entries ordered by sortOrder from Firestore.
  /// Automatically saves to local cache.
  Stream<List<GuideEntry>> getGuideEntries() {
    try {
      return _firestoreService.guideEntriesRef
          .where('isActive', isEqualTo: true)
          .orderBy('sortOrder')
          .snapshots()
          .map((snapshot) {
        final entries = snapshot.docs.map((doc) => doc.data()).toList();
        if (entries.isNotEmpty) {
          _cacheService.saveGuideEntries(entries);
        }
        return entries;
      }).handleError((_) => defaultGuideEntries);
    } catch (_) {
      return Stream.value(defaultGuideEntries);
    }
  }

  /// Retrieves locally cached guide entries if offline.
  /// Falls back to default guide entries if local cache has not been populated yet.
  Future<List<GuideEntry>> getCachedGuideEntries() async {
    final cached = await _cacheService.getGuideEntries();
    if (cached != null && cached.isNotEmpty) {
      return cached;
    }
    return defaultGuideEntries;
  }

  /// Fetches active guide entries filtered by category.
  Stream<List<GuideEntry>> getGuideEntriesByCategory(String category) {
    return _firestoreService.guideEntriesRef
        .where('isActive', isEqualTo: true)
        .where('category', isEqualTo: category)
        .orderBy('sortOrder')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  /// Default guide situations for offline fallback and initial seeding.
  static final List<GuideEntry> defaultGuideEntries = [
    GuideEntry(
      id: 'guide_rfid_gantry_issue',
      title: 'What do I do if my RFID is not detected at the toll gantry?',
      shortTitle: 'RFID Not Reading at Toll Plaza',
      category: 'rfid',
      content:
          '1. Stay calm and keep your vehicle in the lane.\n'
          '2. Do NOT reverse or exit your vehicle in an active toll lane.\n'
          '3. Check if your RFID card or sticker is positioned without obstruction.\n'
          '4. Press the intercom / help button on the toll machine or await the toll teller.\n'
          '5. The operator will manually scan your card or barcode to lift the barrier.\n'
          '6. If non-detection happens repeatedly, visit an official RFID customer service center for realignment or sticker replacement.',
      sortOrder: 1,
      tags: const ['rfid', 'autosweep', 'easytrip', 'toll plaza', 'gantry'],
      isActive: true,
      lastUpdated: DateTime(2025, 1, 15),
    ),
    GuideEntry(
      id: 'guide_rfid_low_balance',
      title: 'What do I do if my RFID balance runs out at the toll barrier?',
      shortTitle: 'Insufficient RFID Balance',
      category: 'rfid',
      content:
          '1. Stop at the barrier and await teller assistance.\n'
          '2. Keep cash or an e-wallet ready for manual payment if permitted by the lane operator.\n'
          '3. The operator will issue an emergency reload or manual ticket depending on expressway policy.\n'
          '4. After clearing the toll plaza, top up your RFID wallet promptly via online banking or e-wallet to prevent barrier delays on next entry.',
      sortOrder: 2,
      tags: const ['rfid', 'balance', 'top-up', 'autosweep', 'easytrip'],
      isActive: true,
      lastUpdated: DateTime(2025, 1, 15),
    ),
    GuideEntry(
      id: 'guide_flat_tire_shoulder',
      title: 'What do I do if I get a flat tire on the expressway shoulder?',
      shortTitle: 'Flat Tire on Highway Shoulder',
      category: 'breakdown',
      content:
          '1. Gradually slow down and steer to the rightmost emergency shoulder or nearest bay.\n'
          '2. Turn on your hazard hazard lights immediately.\n'
          '3. Place your reflective Early Warning Device (EWD) 50-100 meters behind your vehicle.\n'
          '4. Stay on the road embankment or behind guardrails — never linger on the live expressway lane.\n'
          '5. Call the expressway emergency hotline (via the Emergency tab in Aero) for official patrol and roadside assistance.',
      sortOrder: 3,
      tags: const ['breakdown', 'tire', 'shoulder', 'safety', 'hotline'],
      isActive: true,
      lastUpdated: DateTime(2025, 1, 15),
    ),
    GuideEntry(
      id: 'guide_engine_overheating',
      title: 'What do I do if my engine overheats on an elevated expressway?',
      shortTitle: 'Engine Overheating on Elevated Viaduct',
      category: 'breakdown',
      content:
          '1. Turn off your air conditioning immediately and turn on heater if safe to pull heat from the engine.\n'
          '2. Signal and guide vehicle to the nearest emergency lay-by or outermost lane shoulder.\n'
          '3. Switch off the ignition once safely stopped.\n'
          '4. WARNING: Do NOT open the radiator cap while the engine is hot — pressurized steam causes severe burns.\n'
          '5. Contact expressway patrol via Aero Emergency dispatch.',
      sortOrder: 4,
      tags: const ['breakdown', 'overheating', 'radiator', 'skyway', 'safety'],
      isActive: true,
      lastUpdated: DateTime(2025, 1, 15),
    ),
    GuideEntry(
      id: 'guide_missed_exit_interchange',
      title: 'What do I do if I miss my planned expressway exit?',
      shortTitle: 'Missed Expressway Exit',
      category: 'navigation',
      content:
          '1. NEVER stop, reverse, or make a U-turn across expressway median dividers — this is extremely dangerous and illegal.\n'
          '2. Continue safely to the next authorized exit plaza.\n'
          '3. Pay the segment toll and take the designated U-turn slot or service road outside the toll barrier to re-enter in the opposite direction.\n'
          '4. Recalculate your route using the Toll Calculator in Aero.',
      sortOrder: 5,
      tags: const ['navigation', 'exit', 'u-turn', 'safety'],
      isActive: true,
      lastUpdated: DateTime(2025, 1, 15),
    ),
  ];

  /// Seeds generic, general-purpose guide situations if the collection is empty.
  ///
  /// TODO(data): All content below is placeholder guidance for testing and layout verification.
  Future<void> seedPlaceholderDataIfEmpty() async {
    final existing = await _firestoreService.guideEntriesRef.limit(1).get();
    if (existing.docs.isNotEmpty) {
      return; // Already populated
    }

    for (final entry in defaultGuideEntries) {
      await _firestoreService.guideEntriesRef.doc(entry.id).set(entry);
    }
  }
}
