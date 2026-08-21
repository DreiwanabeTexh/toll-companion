import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Firestore Security Rules Compliance Tests', () {
    late String rulesContent;

    setUpAll(() {
      final file = File('firestore.rules');
      expect(file.existsSync(), isTrue, reason: 'firestore.rules must exist');
      rulesContent = file.readAsStringSync();
    });

    test('Declares rules_version = "2"', () {
      expect(rulesContent.contains("rules_version = '2';"), isTrue);
    });

    test('Grants public read-only access to reference collections and forbids writes', () {
      final readOnlyCollections = [
        'tollSegments',
        'tollPlazas',
        'routes',
        'emergencyContacts',
        'guideEntries',
        'checklistItems',
        'routeBriefings',
      ];

      for (final col in readOnlyCollections) {
        expect(
          rulesContent.contains('match /$col/{doc}'),
          isTrue,
          reason: 'Collection $col must be explicitly declared in rules',
        );
      }
    });

    test('Restricts dataReports collection to write-only client submissions with strict schema validation', () {
      expect(rulesContent.contains('match /dataReports/{doc}'), isTrue);
      expect(rulesContent.contains('allow read, update, delete: if false;'), isTrue);
      expect(rulesContent.contains('hasOnly(['), isTrue);
      expect(rulesContent.contains('hasAll(['), isTrue);
      expect(rulesContent.contains("request.resource.data.timestamp == request.time"), isTrue);
      expect(rulesContent.contains("isValidContextMap"), isTrue);
      // Verify 'status' is NOT in the allowed keys list
      expect(rulesContent.contains("'status',"), isFalse);
      expect(rulesContent.contains(", 'status'"), isFalse);
    });

    test('Contains default catch-all denial for all other collections', () {
      expect(rulesContent.contains('match /{document=**}'), isTrue);
      expect(rulesContent.contains('allow read, write: if false;'), isTrue);
    });
  });
}
