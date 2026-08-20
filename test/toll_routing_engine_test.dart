import 'package:flutter_test/flutter_test.dart';
import 'package:toll_companion/models/toll_charge_rule.dart';
import 'package:toll_companion/services/toll_service.dart';

void main() {
  group('Toll Routing & TRB Calculation Engine Comprehensive Test Suite', () {
    final tollService = TollService();

    // =========================================================================
    // 1. Same Origin and Destination: ₱0, 0 Charges
    // =========================================================================
    test('1. Same origin and destination returns ₱0.00 and 0 charges', () {
      final result = tollService.calculateExitToExitFareSync(
        originPlazaId: 'star_lipa',
        destinationPlazaId: 'star_lipa',
        vehicleClass: 1,
      );

      expect(result.totalFare, 0.0);
      expect(result.fareByOperator['autosweep'] ?? 0.0, 0.0);
      expect(result.fareByOperator['easytrip'] ?? 0.0, 0.0);
      expect(result.tollCharges, isEmpty);
      expect(result.segments, isEmpty);
      expect(result.debugInfo, isNotNull);
      expect(result.debugInfo!.matchedRuleIds, isEmpty);
    });

    // =========================================================================
    // 2. Adjacent Plazas on Closed-System Roads (TRB Verified Fares)
    // =========================================================================
    group('2. Adjacent Plazas on Closed-System Roads', () {
      test('STAR Adjacent: Malvar to Tanauan (₱17.00)', () {
        final result = tollService.calculateExitToExitFareSync(
          originPlazaId: 'star_malvar',
          destinationPlazaId: 'star_tanauan',
          vehicleClass: 1,
        );
        expect(result.totalFare, 17.0);
        expect(result.tollCharges.length, 1);
        expect(result.tollCharges.first.tollRuleId, 'rule_star_malvar_tanauan');
      });

      test('STAR Adjacent: Lipa to Malvar (₱33.00)', () {
        final result = tollService.calculateExitToExitFareSync(
          originPlazaId: 'star_lipa',
          destinationPlazaId: 'star_malvar',
          vehicleClass: 1,
        );
        expect(result.totalFare, 33.0);
        expect(result.tollCharges.first.tollRuleId, 'rule_star_lipa_malvar');
      });

      test('STAR Adjacent: Tanauan to Sto. Tomas (₱14.00)', () {
        final result = tollService.calculateExitToExitFareSync(
          originPlazaId: 'star_tanauan',
          destinationPlazaId: 'star_sto_tomas',
          vehicleClass: 1,
        );
        expect(result.totalFare, 14.0);
        expect(result.tollCharges.first.tollRuleId, 'rule_star_tanauan_sto_tomas');
      });

      test('SLEX Adjacent: Calamba to Canlubang (₱16.00)', () {
        final result = tollService.calculateExitToExitFareSync(
          originPlazaId: 'slex_calamba',
          destinationPlazaId: 'slex_canlubang',
          vehicleClass: 1,
        );
        expect(result.totalFare, 16.0);
        expect(result.tollCharges.first.tollRuleId, 'rule_slex_canlubang_calamba');
      });

      test('SLEX Adjacent: Santa Rosa to Eton City (₱9.00)', () {
        final result = tollService.calculateExitToExitFareSync(
          originPlazaId: 'slex_santa_rosa',
          destinationPlazaId: 'slex_eton_city',
          vehicleClass: 1,
        );
        expect(result.totalFare, 9.0);
        expect(result.tollCharges.first.tollRuleId, 'rule_slex_santa_rosa_eton_city');
      });

      test('SLEX Adjacent: San Pedro to Susana Heights (₱8.00)', () {
        final result = tollService.calculateExitToExitFareSync(
          originPlazaId: 'slex_san_pedro',
          destinationPlazaId: 'slex_susana_heights',
          vehicleClass: 1,
        );
        expect(result.totalFare, 8.0);
        expect(result.tollCharges.first.tollRuleId, 'rule_slex_san_pedro_susana_heights');
      });

      test('CALAX Adjacent: Mamplasan to Technopark (₱15.00)', () {
        final result = tollService.calculateExitToExitFareSync(
          originPlazaId: 'calax_mamplasan',
          destinationPlazaId: 'calax_technopark',
          vehicleClass: 1,
        );
        expect(result.totalFare, 15.0);
        expect(result.tollCharges.first.tollRuleId, 'rule_calax_mamplasan_technopark');
      });

      test('CALAX Adjacent: Santa Rosa to Silang East (₱27.00)', () {
        final result = tollService.calculateExitToExitFareSync(
          originPlazaId: 'calax_santa_rosa',
          destinationPlazaId: 'calax_silang_east',
          vehicleClass: 1,
        );
        expect(result.totalFare, 27.0);
        expect(result.tollCharges.first.tollRuleId, 'rule_calax_silang_east_santa_rosa');
      });
    });

    // =========================================================================
    // 3. Middle-to-Middle OD Pairs (STAR & SLEX)
    // =========================================================================
    group('3. Middle-to-Middle OD Pairs for STAR and SLEX', () {
      test('STAR Middle-to-Middle: Lipa to Tanauan (₱50.00)', () {
        final result = tollService.calculateExitToExitFareSync(
          originPlazaId: 'star_lipa',
          destinationPlazaId: 'star_tanauan',
          vehicleClass: 1,
        );
        expect(result.totalFare, 50.0);
        expect(result.tollCharges.first.tollRuleId, 'rule_star_lipa_tanauan');
      });

      test('STAR Middle-to-Middle: Ibaan to Malvar (₱66.00)', () {
        final result = tollService.calculateExitToExitFareSync(
          originPlazaId: 'star_ibaan',
          destinationPlazaId: 'star_malvar',
          vehicleClass: 1,
        );
        expect(result.totalFare, 66.0);
        expect(result.tollCharges.first.tollRuleId, 'rule_star_ibaan_malvar');
      });

      test('STAR Middle-to-Middle: Ibaan to Tanauan (₱83.00)', () {
        final result = tollService.calculateExitToExitFareSync(
          originPlazaId: 'star_ibaan',
          destinationPlazaId: 'star_tanauan',
          vehicleClass: 1,
        );
        expect(result.totalFare, 83.0);
        expect(result.tollCharges.first.tollRuleId, 'rule_star_ibaan_tanauan');
      });

      test('SLEX Middle-to-Middle: Canlubang to Santa Rosa (₱42.00)', () {
        final result = tollService.calculateExitToExitFareSync(
          originPlazaId: 'slex_canlubang',
          destinationPlazaId: 'slex_santa_rosa',
          vehicleClass: 1,
        );
        expect(result.totalFare, 42.0);
        expect(result.tollCharges.first.tollRuleId, 'rule_slex_canlubang_santa_rosa');
      });

      test('SLEX Middle-to-Middle: Southwoods to Filinvest (₱43.00)', () {
        final result = tollService.calculateExitToExitFareSync(
          originPlazaId: 'slex_southwoods',
          destinationPlazaId: 'slex_filinvest',
          vehicleClass: 1,
        );
        expect(result.totalFare, 43.0);
        expect(result.tollCharges.first.tollRuleId, 'rule_slex_southwoods_filinvest');
      });

      test('SLEX Middle-to-Middle: Cabuyao to Santa Rosa (₱26.00)', () {
        final result = tollService.calculateExitToExitFareSync(
          originPlazaId: 'slex_cabuyao',
          destinationPlazaId: 'slex_santa_rosa',
          vehicleClass: 1,
        );
        expect(result.totalFare, 26.0);
        expect(result.tollCharges.first.tollRuleId, 'rule_slex_cabuyao_santa_rosa');
      });
    });

    // =========================================================================
    // 4. Directional Symmetry (Northbound vs Southbound)
    // =========================================================================
    group('4. Directional Symmetry Tests', () {
      test('STAR Batangas <-> Sto. Tomas (₱121.00 each way)', () {
        final nb = tollService.calculateExitToExitFareSync(
          originPlazaId: 'star_batangas',
          destinationPlazaId: 'star_sto_tomas',
          vehicleClass: 1,
        );
        final sb = tollService.calculateExitToExitFareSync(
          originPlazaId: 'star_sto_tomas',
          destinationPlazaId: 'star_batangas',
          vehicleClass: 1,
        );
        expect(nb.totalFare, 121.0);
        expect(sb.totalFare, 121.0);
        expect(nb.totalFare, sb.totalFare);
      });

      test('SLEX Calamba <-> Alabang (₱137.00 each way)', () {
        final nb = tollService.calculateExitToExitFareSync(
          originPlazaId: 'slex_calamba',
          destinationPlazaId: 'slex_alabang',
          vehicleClass: 1,
        );
        final sb = tollService.calculateExitToExitFareSync(
          originPlazaId: 'slex_alabang',
          destinationPlazaId: 'slex_calamba',
          vehicleClass: 1,
        );
        expect(nb.totalFare, 137.0);
        expect(sb.totalFare, 137.0);
        expect(nb.totalFare, sb.totalFare);
      });

      test('CALAX Mamplasan <-> Gov Drive (₱117.00 each way)', () {
        final wb = tollService.calculateExitToExitFareSync(
          originPlazaId: 'calax_mamplasan',
          destinationPlazaId: 'calax_gov_drive',
          vehicleClass: 1,
        );
        final eb = tollService.calculateExitToExitFareSync(
          originPlazaId: 'calax_gov_drive',
          destinationPlazaId: 'calax_mamplasan',
          vehicleClass: 1,
        );
        expect(wb.totalFare, 117.0);
        expect(eb.totalFare, 117.0);
      });
    });

    // =========================================================================
    // 5. Origin and Destination Directly on Skyway
    // =========================================================================
    group('5. Direct Skyway-Only Trips', () {
      test('Skyway Internal: Buendia to Quezon Ave Ramp (₱105.00)', () {
        final result = tollService.calculateExitToExitFareSync(
          originPlazaId: 'skyway_buendia',
          destinationPlazaId: 'skyway_quezon_ave',
          vehicleClass: 1,
          useSkyway: true,
        );
        expect(result.totalFare, 105.0);
        expect(result.fareByOperator['autosweep'], 105.0);
        expect(result.tollCharges.first.tollRuleId, 'rule_skyway_stage3_buendia_quezonave');
      });

      test('Skyway Internal: Quezon Ave to Balintawak Ramp (₱129.00)', () {
        final result = tollService.calculateExitToExitFareSync(
          originPlazaId: 'skyway_quezon_ave',
          destinationPlazaId: 'skyway_balintawak',
          vehicleClass: 1,
          useSkyway: true,
        );
        expect(result.totalFare, 129.0);
        expect(result.fareByOperator['autosweep'], 129.0);
        expect(result.tollCharges.first.tollRuleId, 'rule_skyway_stage3_quezonave_balintawak');
      });

      test('Skyway Stages 1&2: Alabang to Buendia (₱164.00)', () {
        final result = tollService.calculateExitToExitFareSync(
          originPlazaId: 'skyway_alabang',
          destinationPlazaId: 'skyway_buendia',
          vehicleClass: 1,
          useSkyway: true,
        );
        expect(result.totalFare, 164.0);
        expect(result.fareByOperator['autosweep'], 164.0);
        expect(result.tollCharges.first.tollRuleId, 'rule_skyway_stage12_alabang_buendia');
      });
    });

    // =========================================================================
    // 6. Cross-Expressway Coverage across All 12 Expressways
    // =========================================================================
    group('6. Coverage Across All 12 Philippine Expressways', () {
      test('MCX: Flat Rate (₱17.00)', () {
        final result = tollService.calculateExitToExitFareSync(
          originPlazaId: 'slex_susana_heights',
          destinationPlazaId: 'mcx_daang_hari',
          vehicleClass: 1,
        );
        expect(result.totalFare, 17.0);
        expect(result.tollCharges.first.tollRuleId, 'rule_mcx_flat');
        expect(result.tollCharges.first.operator, 'autosweep');
      });

      test('NAIAX: Mainline / Terminal 3 Flat Rate (₱45.00)', () {
        final result = tollService.calculateExitToExitFareSync(
          originPlazaId: 'naiax_skyway',
          destinationPlazaId: 'naiax_terminal3',
          vehicleClass: 1,
        );
        expect(result.totalFare, 45.0);
        expect(result.tollCharges.first.tollRuleId, 'rule_naiax_mainline_flat');
      });

      test('NLEX Connector: C3 Caloocan Viaduct (₱119.00)', () {
        final result = tollService.calculateExitToExitFareSync(
          originPlazaId: 'nlex_connector_c3',
          destinationPlazaId: 'nlex_connector_magsaysay',
          vehicleClass: 1,
        );
        expect(result.totalFare, 119.0);
        expect(result.tollCharges.first.tollRuleId, 'rule_nlex_connector_flat');
        expect(result.tollCharges.first.operator, 'easytrip');
      });

      test('CAVITEX: Parañaque Barrier Flat Rate (₱39.00)', () {
        final result = tollService.calculateExitToExitFareSync(
          originPlazaId: 'cavitex_seaside',
          destinationPlazaId: 'cavitex_paranaque',
          vehicleClass: 1,
        );
        expect(result.totalFare, 39.0);
        expect(result.tollCharges.first.tollRuleId, 'rule_cavitex_paranaque_flat');
        expect(result.tollCharges.first.operator, 'easytrip');
      });

      test('SCTEX: Clark North to Tarlac (₱203.00)', () {
        final result = tollService.calculateExitToExitFareSync(
          originPlazaId: 'sctex_clark_north',
          destinationPlazaId: 'sctex_tarlac',
          vehicleClass: 1,
        );
        expect(result.totalFare, 203.0);
        expect(result.tollCharges.first.tollRuleId, 'rule_sctex_tarlac_clark_north');
      });

      test('TPLEX: Tarlac to Rosario (₱311.00)', () {
        final result = tollService.calculateExitToExitFareSync(
          originPlazaId: 'tplex_tarlac',
          destinationPlazaId: 'tplex_rosario',
          vehicleClass: 1,
        );
        expect(result.totalFare, 311.0);
        expect(result.tollCharges.first.tollRuleId, 'rule_tplex_rosario_tarlac');
      });

      test('CCLEX: Cebu SRP to Cordova Bridge (₱90.00)', () {
        final result = tollService.calculateExitToExitFareSync(
          originPlazaId: 'cclex_cebu_srp',
          destinationPlazaId: 'cclex_cordova',
          vehicleClass: 1,
        );
        expect(result.totalFare, 90.0);
        expect(result.tollCharges.first.tollRuleId, 'rule_cclex_flat');
      });
    });

    // =========================================================================
    // 7. Non-Charging Interchange Invariant
    // =========================================================================
    test('7. Route passing near Mamplasan/Susana Heights on SLEX does not charge CALAX or MCX', () {
      final result = tollService.calculateExitToExitFareSync(
        originPlazaId: 'slex_calamba',
        destinationPlazaId: 'slex_alabang',
        vehicleClass: 1,
      );

      // SLEX Calamba to Alabang is exactly ₱137.00
      expect(result.totalFare, 137.0);
      expect(result.tollCharges.length, 1);
      expect(result.tollCharges.first.expressway, 'SLEX');

      // Check debug trace: considered-not-charged rules must document Mamplasan (CALAX) and Susana Heights (MCX)
      expect(result.debugInfo, isNotNull);
      final consideredRuleIds = result.debugInfo!.consideredNotChargedRules.map((c) => c['ruleId']).toList();
      expect(consideredRuleIds, contains('rule_calax_mamplasan_santarosa'));
      expect(consideredRuleIds, contains('rule_mcx_flat'));
    });

    // =========================================================================
    // 8. Single Open Barrier Deduplication
    // =========================================================================
    test('8. Route across NLEX Open System charges open barrier only once (₱69.00)', () {
      final result = tollService.calculateExitToExitFareSync(
        originPlazaId: 'nlex_balintawak',
        destinationPlazaId: 'nlex_marilao',
        vehicleClass: 1,
      );

      expect(result.totalFare, 69.0);
      expect(result.fareByOperator['easytrip'], 69.0);
      final nlexOpenCharges = result.tollCharges.where((c) => c.tollRuleId == 'rule_nlex_open_system');
      expect(nlexOpenCharges.length, 1);
    });

    // =========================================================================
    // 9. Unsupported Routes Return Warning and Zero Guessed Fare
    // =========================================================================
    test('9. Unsupported route returns explicit warning and never guesses rate from distance', () {
      final result = tollService.calculateExitToExitFareSync(
        originPlazaId: 'star_batangas',
        destinationPlazaId: 'cclex_cordova',
        vehicleClass: 1,
      );

      expect(result.totalFare, 0.0);
      expect(result.tollCharges, isEmpty);
      expect(result.warnings.isNotEmpty, isTrue);
      expect(result.warnings.first, contains('Fare data unavailable'));
    });

    // =========================================================================
    // 10. Strict Verification Status Logic
    // =========================================================================
    test('10. Strict Verification Status Logic for rules', () {
      final verifiedRule = TollChargeRule(
        id: 'test_verified',
        expressway: 'STAR',
        operator: 'autosweep',
        collectionType: 'closedSystem',
        fareClass1: 100,
        fareClass2: 200,
        fareClass3: 300,
        effectiveFrom: DateTime(2024, 1, 1),
        sourceName: 'TRB Test Matrix',
        sourceUrl: 'https://trb.gov.ph/test',
        lastVerified: DateTime(2026, 8, 19),
      );
      expect(verifiedRule.verificationStatus, TollVerificationStatus.verified);

      final missingSourceRule = TollChargeRule(
        id: 'test_missing_source',
        expressway: 'STAR',
        operator: 'autosweep',
        collectionType: 'closedSystem',
        fareClass1: 100,
        fareClass2: 200,
        fareClass3: 300,
        effectiveFrom: DateTime(2024, 1, 1),
        sourceName: 'TRB Test Matrix',
        sourceUrl: null,
        lastVerified: DateTime(2026, 8, 19),
      );
      expect(missingSourceRule.verificationStatus, TollVerificationStatus.missingSource);

      final staleRule = TollChargeRule(
        id: 'test_stale',
        expressway: 'STAR',
        operator: 'autosweep',
        collectionType: 'closedSystem',
        fareClass1: 100,
        fareClass2: 200,
        fareClass3: 300,
        effectiveFrom: DateTime(2024, 1, 1),
        sourceName: 'TRB Test Matrix',
        sourceUrl: 'https://trb.gov.ph/test',
        lastVerified: DateTime(2025, 1, 1),
      );
      expect(staleRule.verificationStatus, TollVerificationStatus.stale);

      final manualReviewRule = TollChargeRule(
        id: 'test_manual_review',
        expressway: 'CCLEX',
        operator: 'easytrip',
        collectionType: 'openBarrier',
        fareClass1: 90,
        fareClass2: 180,
        fareClass3: 270,
        effectiveFrom: DateTime(2022, 7, 1),
        sourceName: 'CCLEC Matrix',
        sourceUrl: 'https://cclex.com.ph/toll-rates',
        lastVerified: DateTime(2026, 8, 19),
        manualStatus: TollVerificationStatus.needsManualReview,
      );
      expect(manualReviewRule.verificationStatus, TollVerificationStatus.needsManualReview);
    });

    // =========================================================================
    // 11. Multi-Class Multipliers (Classes 1, 2, and 3)
    // =========================================================================
    group('11. Multi-Class Rate Calculation Tests', () {
      test('STAR Batangas to Sto. Tomas for Classes 1, 2, and 3', () {
        final c1 = tollService.calculateExitToExitFareSync(
          originPlazaId: 'star_batangas',
          destinationPlazaId: 'star_sto_tomas',
          vehicleClass: 1,
        );
        final c2 = tollService.calculateExitToExitFareSync(
          originPlazaId: 'star_batangas',
          destinationPlazaId: 'star_sto_tomas',
          vehicleClass: 2,
        );
        final c3 = tollService.calculateExitToExitFareSync(
          originPlazaId: 'star_batangas',
          destinationPlazaId: 'star_sto_tomas',
          vehicleClass: 3,
        );

        expect(c1.totalFare, 121.0);
        expect(c2.totalFare, 242.0);
        expect(c3.totalFare, 363.0);
      });

      test('TPLEX Tarlac to Rosario for Classes 1, 2, and 3', () {
        final c1 = tollService.calculateExitToExitFareSync(
          originPlazaId: 'tplex_tarlac',
          destinationPlazaId: 'tplex_rosario',
          vehicleClass: 1,
        );
        final c2 = tollService.calculateExitToExitFareSync(
          originPlazaId: 'tplex_tarlac',
          destinationPlazaId: 'tplex_rosario',
          vehicleClass: 2,
        );
        final c3 = tollService.calculateExitToExitFareSync(
          originPlazaId: 'tplex_tarlac',
          destinationPlazaId: 'tplex_rosario',
          vehicleClass: 3,
        );

        expect(c1.totalFare, 311.0);
        expect(c2.totalFare, 778.0);
        expect(c3.totalFare, 933.0);
      });
    });
  });
}
