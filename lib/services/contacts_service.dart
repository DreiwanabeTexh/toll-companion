import '../models/emergency_contact.dart';
import 'firestore_service.dart';
import 'cache_service.dart';

/// Service for Emergency Contacts data access (Tier 1 official hotlines only).
class ContactsService {
  final FirestoreService? _customFirestoreService;
  final CacheService? _customCacheService;

  ContactsService({
    FirestoreService? firestoreService,
    CacheService? cacheService,
  })  : _customFirestoreService = firestoreService,
        _customCacheService = cacheService;

  FirestoreService get _firestoreService =>
      _customFirestoreService ?? FirestoreService();

  CacheService get _cacheService =>
      _customCacheService ?? CacheService();

  /// Fetches active emergency contacts ordered by sortOrder from Firestore.
  /// Automatically writes successful reads to local cache for offline resilience.
  Stream<List<EmergencyContact>> getEmergencyContacts() {
    try {
      return _firestoreService.emergencyContactsRef
          .where('isActive', isEqualTo: true)
          .orderBy('sortOrder')
          .snapshots()
          .map((snapshot) {
        final contacts = snapshot.docs.map((doc) => doc.data()).map((contact) {
          // Upgrade any obsolete placeholder data from prior sessions
          if (contact.phoneNumber == '0000000000' || !contact.isVerified) {
            final matched = defaultContacts.firstWhere(
              (d) => d.id == contact.id,
              orElse: () => contact,
            );
            return matched;
          }
          return contact;
        }).toList();
        if (contacts.isNotEmpty) {
          _cacheService.saveEmergencyContacts(contacts);
        }
        return contacts;
      }).handleError((_) => defaultContacts);
    } catch (_) {
      return Stream.value(defaultContacts);
    }
  }

  /// Retrieves locally cached emergency contacts if offline.
  /// Falls back to default Tier 1 hotlines if local cache has not been populated yet
  /// or contains obsolete unverified placeholders.
  Future<List<EmergencyContact>> getCachedEmergencyContacts() async {
    final cached = await _cacheService.getEmergencyContacts();
    if (cached != null && cached.isNotEmpty) {
      final hasObsoletePlaceholders =
          cached.any((c) => c.phoneNumber == '0000000000' || !c.isVerified);
      if (!hasObsoletePlaceholders) {
        return cached;
      }
    }
    // Refresh local cache with verified production contacts
    await _cacheService.saveEmergencyContacts(defaultContacts);
    return defaultContacts;
  }

  /// Official Tier 1 emergency contacts verified against official sources on 2026-08-19.
  static final List<EmergencyContact> defaultContacts = [
    EmergencyContact(
      id: 'contact_trb',
      agencyName: 'Toll Regulatory Board (TRB)',
      agencyShort: 'TRB',
      coverageArea: 'Nationwide — all toll expressways',
      phoneNumber: '+63286315901',
      displayNumber: '(02) 8631-5901',
      description:
          'Toll road regulation, expressway complaints, and fare dispute resolution. Hotlines: Mon-Fri 8AM-5PM; SMS/email accepted 24/7. Secondary: (02) 8833-7627.',
      lastVerified: DateTime(2026, 8, 19),
      sortOrder: 1,
      isActive: true,
    ),
    EmergencyContact(
      id: 'contact_smc_autosweep',
      agencyName: 'SMC Tollways / Autosweep',
      agencyShort: 'AUTOSWEEP',
      coverageArea: 'STAR, Skyway (Stages 1,2,3), SLEX, TPLEX, NAIAX, MCX',
      phoneNumber: '+63253188655',
      displayNumber: '(02) 5318-8655',
      description:
          '24/7 patrol, towing, and emergency paramedical response across all SMC expressways.',
      lastVerified: DateTime(2026, 8, 19),
      sortOrder: 2,
      isActive: true,
    ),
    EmergencyContact(
      id: 'contact_mptc_easytrip',
      agencyName: 'MPTC / Easytrip',
      agencyShort: 'EASYTRIP',
      coverageArea:
          'NLEX, SCTEX, CAVITEX, CALAX, C5 Southlink, NLEX Connector, CCLEX',
      phoneNumber: '135000',
      displayNumber: '1-35000',
      description:
          '24/7 centralized dispatch, emergency roadside assistance, and customer support.',
      lastVerified: DateTime(2026, 8, 19),
      sortOrder: 3,
      isActive: true,
    ),
    EmergencyContact(
      id: 'contact_mmda',
      agencyName: 'MMDA',
      agencyShort: 'MMDA',
      coverageArea:
          'Metro Manila surface roads, arterial corridors, expressway entry/exit choke points within NCR',
      phoneNumber: '136',
      displayNumber: '136',
      description:
          '24/7 Metro Manila traffic operations, emergency rescue, and road obstruction response.',
      lastVerified: DateTime(2026, 8, 19),
      sortOrder: 4,
      isActive: true,
    ),
    EmergencyContact(
      id: 'contact_pnp_hpg',
      agencyName: 'PNP Highway Patrol Group (HPG)',
      agencyShort: 'PNP-HPG',
      coverageArea: 'Nationwide highway law enforcement',
      phoneNumber: '+63287230401',
      displayNumber: '(02) 8723-0401',
      description:
          '24/7 nationwide highway law enforcement, anti-carnapping, and incident response. (National Emergency: 911).',
      lastVerified: DateTime(2026, 8, 19),
      sortOrder: 5,
      isActive: true,
    ),
  ];

  /// Seeds or updates official Tier 1 agency hotlines in Firestore.
  Future<void> seedPlaceholderDataIfEmpty() async {
    for (final contact in defaultContacts) {
      await _firestoreService.emergencyContactsRef
          .doc(contact.id)
          .set(contact);
    }
  }
}
