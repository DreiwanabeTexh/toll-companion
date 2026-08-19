import '../models/emergency_contact.dart';
import 'firestore_service.dart';

/// Service for Emergency Contacts data access (Tier 1 official hotlines only).
class ContactsService {
  final FirestoreService? _customFirestoreService;

  ContactsService({FirestoreService? firestoreService})
      : _customFirestoreService = firestoreService;

  FirestoreService get _firestoreService =>
      _customFirestoreService ?? FirestoreService();

  /// Fetches active emergency contacts ordered by sortOrder.
  Stream<List<EmergencyContact>> getEmergencyContacts() {
    return _firestoreService.emergencyContactsRef
        .where('isActive', isEqualTo: true)
        .orderBy('sortOrder')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  /// Seeds official Tier 1 agency hotlines if the collection is empty.
  ///
  /// CRITICAL SAFETY NOTICE:
  /// TODO(data): REQUIRES VERIFICATION — All phone numbers below are fake
  /// placeholders ('000-000-0000') with lastVerified: null.
  /// Do NOT use or distribute these numbers for real emergencies.
  Future<void> seedPlaceholderDataIfEmpty() async {
    final existing =
        await _firestoreService.emergencyContactsRef.limit(1).get();
    if (existing.docs.isNotEmpty) {
      return; // Already seeded
    }

    // TODO(data): Official Tier 1 agencies only — strictly no Tier 2/mechanics
    final sampleContacts = [
      const EmergencyContact(
        id: 'contact_trb',
        agencyName: 'Toll Regulatory Board (TRB)',
        agencyShort: 'TRB',
        coverageArea: 'All toll expressways across the Philippines',
        phoneNumber: '0000000000', // TODO(data): REQUIRES VERIFICATION — fake number
        displayNumber: '000-000-0000 (UNVERIFIED)',
        description: 'Toll road regulation, expressway complaints, and fare dispute resolution.',
        lastVerified: null, // Unverified placeholder
        sortOrder: 1,
        isActive: true,
      ),
      const EmergencyContact(
        id: 'contact_smc_autosweep',
        agencyName: 'SMC Tollways / Autosweep',
        agencyShort: 'AUTOSWEEP',
        coverageArea: 'STAR Tollway, SLEX, Skyway, TPLEX, NAIAX',
        phoneNumber: '0000000000', // TODO(data): REQUIRES VERIFICATION — fake number
        displayNumber: '000-000-0000 (UNVERIFIED)',
        description: 'Autosweep RFID assistance, road incidents, and patrol dispatch on SMC expressways.',
        lastVerified: null, // Unverified placeholder
        sortOrder: 2,
        isActive: true,
      ),
      const EmergencyContact(
        id: 'contact_mptc_easytrip',
        agencyName: 'MPTC / Easytrip',
        agencyShort: 'EASYTRIP',
        coverageArea: 'NLEX, SCTEX, CAVITEX, CALAX, C5 Link, CCLEX',
        phoneNumber: '0000000000', // TODO(data): REQUIRES VERIFICATION — fake number
        displayNumber: '000-000-0000 (UNVERIFIED)',
        description: 'Easytrip RFID assistance, emergency towing, and patrol dispatch on MPTC expressways.',
        lastVerified: null, // Unverified placeholder
        sortOrder: 3,
        isActive: true,
      ),
      const EmergencyContact(
        id: 'contact_mmda',
        agencyName: 'MMDA Traffic Operations',
        agencyShort: 'MMDA',
        coverageArea: 'Metro Manila urban corridors and expressway connectors',
        phoneNumber: '0000000000', // TODO(data): REQUIRES VERIFICATION — fake number
        displayNumber: '000-000-0000 (UNVERIFIED)',
        description: 'Metropolitan traffic management, emergency response, and road obstruction reports.',
        lastVerified: null, // Unverified placeholder
        sortOrder: 4,
        isActive: true,
      ),
      const EmergencyContact(
        id: 'contact_pnp_hpg',
        agencyName: 'PNP Highway Patrol Group (HPG)',
        agencyShort: 'PNP-HPG',
        coverageArea: 'All national highways and expressway networks',
        phoneNumber: '0000000000', // TODO(data): REQUIRES VERIFICATION — fake number
        displayNumber: '000-000-0000 (UNVERIFIED)',
        description: 'Highway law enforcement, traffic incident investigation, and national road security.',
        lastVerified: null, // Unverified placeholder
        sortOrder: 5,
        isActive: true,
      ),
    ];

    for (final contact in sampleContacts) {
      await _firestoreService.emergencyContactsRef
          .doc(contact.id)
          .set(contact);
    }
  }
}
