import '../models/guide_entry.dart';
import 'firestore_service.dart';

/// Data service for Quick Guide FAQ entries.
///
/// Handles Firestore queries for general-purpose driver situations
/// and provides local placeholder seeding for testing.
class GuideService {
  final FirestoreService? _customFirestoreService;

  GuideService({FirestoreService? firestoreService})
      : _customFirestoreService = firestoreService;

  FirestoreService get _firestoreService =>
      _customFirestoreService ?? FirestoreService();

  /// Fetches active guide entries ordered by sortOrder.
  Stream<List<GuideEntry>> getGuideEntries() {
    return _firestoreService.guideEntriesRef
        .where('isActive', isEqualTo: true)
        .orderBy('sortOrder')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
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

  /// Seeds generic, general-purpose guide situations if the collection is empty.
  ///
  /// TODO(data): All content below is placeholder guidance for testing and layout verification.
  Future<void> seedPlaceholderDataIfEmpty() async {
    final existing = await _firestoreService.guideEntriesRef.limit(1).get();
    if (existing.docs.isNotEmpty) {
      return; // Already populated
    }

    final sampleEntries = [
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
        tags: ['rfid', 'autosweep', 'easytrip', 'toll plaza', 'gantry'],
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
        tags: ['rfid', 'balance', 'top-up', 'autosweep', 'easytrip'],
        isActive: true,
        lastUpdated: DateTime(2025, 1, 15),
      ),
      GuideEntry(
        id: 'guide_flat_tire_shoulder',
        title: 'What do I do if I get a flat tire on the expressway shoulder?',
        shortTitle: 'Flat Tire on Shoulder',
        category: 'breakdown',
        content:
            '1. Turn on your hazard lights immediately.\n'
            '2. Carefully steer your vehicle onto the rightmost emergency shoulder as far from active traffic as possible.\n'
            '3. Set up your Early Warning Device (EWD) 4 meters behind the vehicle if safe to do so.\n'
            '4. Passengers should exit through the right-side doors and stand safely behind the guardrail away from moving vehicles.\n'
            '5. If changing the tire safely is not possible, stay behind the guardrail and call the expressway patrol hotline for roadside assistance.',
        sortOrder: 3,
        tags: ['flat tire', 'breakdown', 'shoulder', 'safety', 'ewd'],
        isActive: true,
        lastUpdated: DateTime(2025, 1, 15),
      ),
      GuideEntry(
        id: 'guide_missed_exit',
        title: 'What do I do if I miss my planned expressway exit?',
        shortTitle: 'Missed Expressway Exit',
        category: 'navigation',
        content:
            '1. NEVER stop, reverse, or make a U-turn on the expressway.\n'
            '2. Continue safely to the very next available exit toll plaza.\n'
            '3. Exit the expressway and pay the corresponding toll fare for that segment.\n'
            '4. Use the designated roundabout or interchange beyond the toll plaza to safely re-enter in the opposite direction.\n'
            '5. Re-plan your route before re-entering.',
        sortOrder: 4,
        tags: ['missed exit', 'navigation', 'wrong way', 'u-turn'],
        isActive: true,
        lastUpdated: DateTime(2025, 1, 15),
      ),
      GuideEntry(
        id: 'guide_traffic_standstill',
        title: 'What do I do if traffic comes to a sudden complete standstill?',
        shortTitle: 'Expressway Traffic Gridlock',
        category: 'safety',
        content:
            '1. Turn on hazard lights briefly to alert drivers braking behind you.\n'
            '2. Keep a safe following distance from the vehicle in front (at least one car length).\n'
            '3. Do NOT drive or stop on the emergency shoulder — keep it clear for ambulances and patrol vehicles.\n'
            '4. Keep doors locked and stay inside your vehicle.\n'
            '5. Monitor official traffic updates or expressway radio if available.',
        sortOrder: 5,
        tags: ['traffic', 'gridlock', 'standstill', 'safety', 'shoulder'],
        isActive: true,
        lastUpdated: DateTime(2025, 1, 15),
      ),
    ];

    for (final entry in sampleEntries) {
      await _firestoreService.guideEntriesRef.doc(entry.id).set(entry);
    }
  }
}
