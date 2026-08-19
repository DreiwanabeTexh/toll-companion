import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toll_companion/models/emergency_contact.dart';
import 'package:toll_companion/screens/emergency_contacts_screen.dart';
import 'package:toll_companion/services/contacts_service.dart';

class MockContactsService extends ContactsService {
  final Stream<List<EmergencyContact>> Function()? contactsStreamProvider;

  MockContactsService({this.contactsStreamProvider});

  @override
  Stream<List<EmergencyContact>> getEmergencyContacts() {
    final provider = contactsStreamProvider;
    if (provider != null) {
      return provider();
    }
    return Stream.value([]);
  }
}

void main() {
  group('EmergencyContact Model Unit Tests', () {
    test('EmergencyContact model handles verified and unverified dates', () {
      // Unverified contact
      const unverifiedContact = EmergencyContact(
        id: 'unverified_1',
        agencyName: 'Sample Authority',
        agencyShort: 'SA',
        coverageArea: 'All expressways',
        phoneNumber: '0000000000',
        displayNumber: '000-000-0000 (UNVERIFIED)',
        description: 'Expressway safety and regulation.',
        lastVerified: null,
      );

      expect(unverifiedContact.isVerified, isFalse);
      expect(unverifiedContact.telUri, 'tel:0000000000');

      final unverifiedMap = unverifiedContact.toFirestore();
      expect(unverifiedMap['lastVerified'], isNull);

      // Verified contact
      final verifiedDate = DateTime(2025, 1, 15);
      final verifiedContact = EmergencyContact(
        id: 'verified_1',
        agencyName: 'Verified Agency',
        agencyShort: 'VA',
        coverageArea: 'Specific expressway',
        phoneNumber: '+63288888888',
        displayNumber: '(02) 8888-8888',
        description: 'Verified hotline.',
        lastVerified: verifiedDate,
      );

      expect(verifiedContact.isVerified, isTrue);
      expect(verifiedContact.telUri, 'tel:+63288888888');
    });
  });

  group('EmergencyContactsScreen Widget Tests', () {
    final sampleTier1Contacts = [
      const EmergencyContact(
        id: 'contact_trb',
        agencyName: 'Toll Regulatory Board (TRB)',
        agencyShort: 'TRB',
        coverageArea: 'All toll expressways',
        phoneNumber: '0000000000',
        displayNumber: '000-000-0000 (UNVERIFIED)',
        description: 'Toll road regulation, complaints, fare disputes.',
        lastVerified: null, // Unverified
        sortOrder: 1,
        isActive: true,
      ),
      EmergencyContact(
        id: 'contact_smc',
        agencyName: 'SMC Tollways / Autosweep',
        agencyShort: 'AUTOSWEEP',
        coverageArea: 'STAR, SLEX, Skyway, TPLEX, NAIAX',
        phoneNumber: '0000000000',
        displayNumber: '000-000-0000 (UNVERIFIED)',
        description: 'Autosweep assistance and patrol dispatch.',
        lastVerified: DateTime(2025, 1, 10), // Verified
        sortOrder: 2,
        isActive: true,
      ),
    ];

    testWidgets('Renders Tier 1 contacts with coverage and badges',
        (WidgetTester tester) async {
      final mockService = MockContactsService(
        contactsStreamProvider: () => Stream.value(sampleTier1Contacts),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: EmergencyContactsScreen(contactsService: mockService),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Screen Title and Subtitle
      expect(find.text('Emergency'), findsOneWidget);
      expect(find.text('Verified Highway Patrol & Assist'), findsOneWidget);

      // Verify Agency Cards
      expect(find.text('Toll Regulatory Board (TRB)'), findsOneWidget);
      expect(find.text('All toll expressways'), findsOneWidget);

      expect(find.text('SMC Tollways / Autosweep'), findsOneWidget);
      expect(find.text('STAR, SLEX, Skyway, TPLEX, NAIAX'), findsOneWidget);

      // Verify Prominent Verification Badges
      // 1. Unverified warning badge (strictly for lastVerified == null)
      expect(find.text('NOT YET VERIFIED'), findsOneWidget);
      // 2. Verified checkmark badge
      expect(find.text('VERIFIED 01/25'), findsOneWidget);

      // Verify Call Now Action Buttons (Clean CALL NOW label)
      expect(
        find.text('CALL NOW'),
        findsNWidgets(2),
      );
    });

    testWidgets('Displays empty state when no contacts exist',
        (WidgetTester tester) async {
      final mockService = MockContactsService(
        contactsStreamProvider: () => Stream.value([]),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: EmergencyContactsScreen(contactsService: mockService),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('No emergency contacts available yet'), findsOneWidget);
      expect(find.text('Seed Sample Tier 1 Hotlines'), findsOneWidget);
    });

    testWidgets('Displays error state when contacts stream fails',
        (WidgetTester tester) async {
      final mockService = MockContactsService(
        contactsStreamProvider:
            () => Stream.error('Firestore permission denied'),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: EmergencyContactsScreen(contactsService: mockService),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.textContaining('Couldn\'t load emergency contacts'),
          findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });
  });
}
