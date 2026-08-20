import '../models/checklist_item.dart';
import 'firestore_service.dart';

/// Data service for Pre-Trip Checklist items (Phase 2).
///
/// Fetches Firestore checklist item definitions and provides seed capabilities.
class ChecklistService {
  final FirestoreService? _customFirestoreService;

  ChecklistService({FirestoreService? firestoreService})
      : _customFirestoreService = firestoreService;

  FirestoreService get _firestoreService =>
      _customFirestoreService ?? FirestoreService();

  /// Fetches active checklist items ordered by sortOrder.
  Stream<List<ChecklistItem>> getChecklistItems() {
    try {
      return _firestoreService.checklistItemsRef
          .where('isActive', isEqualTo: true)
          .orderBy('sortOrder')
          .snapshots()
          .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList())
          .handleError((_) => defaultChecklistItems);
    } catch (_) {
      return Stream.value(defaultChecklistItems);
    }
  }

  /// Default checklist items for offline fallback and initial seeding.
  static const List<ChecklistItem> defaultChecklistItems = [
    ChecklistItem(
      id: 'check_autosweep_rfid',
      title: 'Autosweep RFID Balance',
      description:
          'Confirm sufficient balance for STAR, SLEX, Skyway, TPLEX, or NAIAX sectors.',
      category: 'rfid',
      operator: 'autosweep',
      sortOrder: 1,
      isActive: true,
    ),
    ChecklistItem(
      id: 'check_easytrip_rfid',
      title: 'Easytrip RFID Balance',
      description:
          'Confirm sufficient balance for NLEX, SCTEX, CAVITEX, CALAX, C5 Link, or CCLEX.',
      category: 'rfid',
      operator: 'easytrip',
      sortOrder: 2,
      isActive: true,
    ),
    ChecklistItem(
      id: 'check_tires_pressure',
      title: 'Tire Pressure & Spare Tire',
      description:
          'Check PSI on all 4 road tires and ensure spare tire is properly inflated with a working tire wrench.',
      category: 'vehicle',
      sortOrder: 3,
      isActive: true,
    ),
    ChecklistItem(
      id: 'check_engine_fluids',
      title: 'Engine Fluids & Brakes',
      description:
          'Verify engine oil, coolant/radiator reservoir, brake fluid, and windshield washer fluid levels.',
      category: 'vehicle',
      sortOrder: 4,
      isActive: true,
    ),
    ChecklistItem(
      id: 'check_fuel_battery',
      title: 'Fuel Level / Battery Range',
      description:
          'Ensure at least 50% tank or adequate EV charge to avoid running out in express lanes with spaced service plazas.',
      category: 'vehicle',
      sortOrder: 5,
      isActive: true,
    ),
    ChecklistItem(
      id: 'check_physical_documents',
      title: 'Driver\'s License & Vehicle OR/CR',
      description:
          'Carry physical original/certified copies of Driver\'s License and valid Vehicle Registration (OR/CR).',
      category: 'documents',
      sortOrder: 6,
      isActive: true,
    ),
    ChecklistItem(
      id: 'check_phone_powerbank',
      title: 'Mobile Phone & Power Bank',
      description:
          'Fully charge driver navigation device and keep a functional USB car charger or backup battery pack.',
      category: 'emergency',
      sortOrder: 7,
      isActive: true,
    ),
    ChecklistItem(
      id: 'check_ewd_tools',
      title: 'Early Warning Device (EWD) & Jack',
      description:
          'Verify presence of mandatory reflective triangular Early Warning Device, working jack, and flashlight.',
      category: 'emergency',
      sortOrder: 8,
      isActive: true,
    ),
  ];

  /// Seeds general-purpose pre-trip checklist items if collection is empty.
  ///
  /// TODO(data): All items below are generic trip preparation placeholders.
  Future<void> seedPlaceholderDataIfEmpty() async {
    final existing =
        await _firestoreService.checklistItemsRef.limit(1).get();
    if (existing.docs.isNotEmpty) {
      return; // Already seeded
    }

    for (final item in defaultChecklistItems) {
      await _firestoreService.checklistItemsRef.doc(item.id).set(item);
    }
  }
}
