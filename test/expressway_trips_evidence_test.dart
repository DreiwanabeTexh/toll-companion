import 'package:flutter_test/flutter_test.dart';
import 'package:toll_companion/models/toll_charge_rule.dart';
import 'package:toll_companion/services/toll_service.dart';

void main() {
  group('Aero Multi-Expressway Verified Route Trip Evidence (3 Complete Routes Per Expressway)', () {
    final tollService = TollService();

    // -------------------------------------------------------------------------
    // 1. STAR TOLLWAY
    // -------------------------------------------------------------------------
    group('1. STAR Tollway Route Evidence', () {
      test('STAR Route 1: Batangas City to Sto. Tomas End-to-End (₱121.00)', () {
        final r = tollService.calculateExitToExitFareSync(
          originPlazaId: 'star_batangas',
          destinationPlazaId: 'star_sto_tomas',
          vehicleClass: 1,
        );
        expect(r.totalFare, 121.0);
        expect(r.fareByOperator['autosweep'], 121.0);
        expect(r.tollCharges.first.verificationStatus, TollVerificationStatus.verified);
      });

      test('STAR Route 2: Lipa City to Sto. Tomas (₱64.00)', () {
        final r = tollService.calculateExitToExitFareSync(
          originPlazaId: 'star_lipa',
          destinationPlazaId: 'star_sto_tomas',
          vehicleClass: 1,
        );
        expect(r.totalFare, 64.0);
        expect(r.tollCharges.first.tollRuleId, 'rule_star_lipa_sto_tomas');
        expect(r.tollCharges.first.verificationStatus, TollVerificationStatus.verified);
      });

      test('STAR Route 3: Ibaan to Tanauan (₱83.00)', () {
        final r = tollService.calculateExitToExitFareSync(
          originPlazaId: 'star_ibaan',
          destinationPlazaId: 'star_tanauan',
          vehicleClass: 1,
        );
        expect(r.totalFare, 83.0);
        expect(r.tollCharges.first.tollRuleId, 'rule_star_ibaan_tanauan');
      });
    });

    // -------------------------------------------------------------------------
    // 2. SLEX (SOUTH LUZON EXPRESSWAY)
    // -------------------------------------------------------------------------
    group('2. SLEX Route Evidence', () {
      test('SLEX Route 1: Calamba to Alabang (₱137.00)', () {
        final r = tollService.calculateExitToExitFareSync(
          originPlazaId: 'slex_calamba',
          destinationPlazaId: 'slex_alabang',
          vehicleClass: 1,
        );
        expect(r.totalFare, 137.0);
        expect(r.fareByOperator['autosweep'], 137.0);
        expect(r.tollCharges.first.verificationStatus, TollVerificationStatus.verified);
      });

      test('SLEX Route 2: Sto. Tomas to Alabang (₱174.00)', () {
        final r = tollService.calculateExitToExitFareSync(
          originPlazaId: 'slex_sto_tomas',
          destinationPlazaId: 'slex_alabang',
          vehicleClass: 1,
        );
        expect(r.totalFare, 174.0);
        expect(r.tollCharges.first.verificationStatus, TollVerificationStatus.verified);
      });

      test('SLEX Route 3: Santa Rosa to Susana Heights (₱58.00)', () {
        final r = tollService.calculateExitToExitFareSync(
          originPlazaId: 'slex_santa_rosa',
          destinationPlazaId: 'slex_susana_heights',
          vehicleClass: 1,
        );
        expect(r.totalFare, 58.0);
        expect(r.tollCharges.first.verificationStatus, TollVerificationStatus.verified);
      });
    });

    // -------------------------------------------------------------------------
    // 3. SKYWAY STAGES 1, 2, 3
    // -------------------------------------------------------------------------
    group('3. Skyway Elevated Viaduct Route Evidence', () {
      test('Skyway Route 1: Alabang to Buendia Main Viaduct (₱164.00)', () {
        final r = tollService.calculateExitToExitFareSync(
          originPlazaId: 'skyway_alabang',
          destinationPlazaId: 'skyway_buendia',
          vehicleClass: 1,
          useSkyway: true,
        );
        expect(r.totalFare, 164.0);
        expect(r.tollCharges.first.verificationStatus, TollVerificationStatus.verified);
      });

      test('Skyway Route 2: Buendia to Balintawak Bypass (₱264.00)', () {
        final r = tollService.calculateExitToExitFareSync(
          originPlazaId: 'skyway_buendia',
          destinationPlazaId: 'skyway_balintawak',
          vehicleClass: 1,
          useSkyway: true,
        );
        expect(r.totalFare, 264.0);
        expect(r.tollCharges.first.verificationStatus, TollVerificationStatus.verified);
      });

      test('Skyway Route 3: Buendia to Quezon Ave Ramp (₱105.00)', () {
        final r = tollService.calculateExitToExitFareSync(
          originPlazaId: 'skyway_buendia',
          destinationPlazaId: 'skyway_quezon_ave',
          vehicleClass: 1,
          useSkyway: true,
        );
        expect(r.totalFare, 105.0);
        expect(r.tollCharges.first.verificationStatus, TollVerificationStatus.verified);
      });
    });

    // -------------------------------------------------------------------------
    // 4. CALAX (CAVITE-LAGUNA EXPRESSWAY)
    // -------------------------------------------------------------------------
    group('4. CALAX Route Evidence', () {
      test('CALAX Route 1: Mamplasan to Governor Drive End-to-End (₱117.00)', () {
        final r = tollService.calculateExitToExitFareSync(
          originPlazaId: 'calax_mamplasan',
          destinationPlazaId: 'calax_gov_drive',
          vehicleClass: 1,
        );
        expect(r.totalFare, 117.0);
        expect(r.tollCharges.first.verificationStatus, TollVerificationStatus.verified);
      });

      test('CALAX Route 2: Santa Rosa to Silang East (₱27.00)', () {
        final r = tollService.calculateExitToExitFareSync(
          originPlazaId: 'calax_santa_rosa',
          destinationPlazaId: 'calax_silang_east',
          vehicleClass: 1,
        );
        expect(r.totalFare, 27.0);
        expect(r.tollCharges.first.verificationStatus, TollVerificationStatus.verified);
      });

      test('CALAX Route 3: Laguna Boulevard to Governor Drive (₱86.00)', () {
        final r = tollService.calculateExitToExitFareSync(
          originPlazaId: 'calax_laguna_blvd',
          destinationPlazaId: 'calax_gov_drive',
          vehicleClass: 1,
        );
        expect(r.totalFare, 86.0);
        expect(r.tollCharges.first.verificationStatus, TollVerificationStatus.verified);
      });
    });

    // -------------------------------------------------------------------------
    // 5. TPLEX (TARLAC-PANGASINAN-LA UNION EXPRESSWAY)
    // -------------------------------------------------------------------------
    group('5. TPLEX Route Evidence', () {
      test('TPLEX Route 1: Tarlac/La Paz to Rosario End-to-End (₱311.00)', () {
        final r = tollService.calculateExitToExitFareSync(
          originPlazaId: 'tplex_tarlac',
          destinationPlazaId: 'tplex_rosario',
          vehicleClass: 1,
        );
        expect(r.totalFare, 311.0);
        expect(r.tollCharges.first.verificationStatus, TollVerificationStatus.verified);
      });

      test('TPLEX Route 2: Victoria to Urdaneta (₱186.00)', () {
        final r = tollService.calculateExitToExitFareSync(
          originPlazaId: 'tplex_victoria',
          destinationPlazaId: 'tplex_urdaneta',
          vehicleClass: 1,
        );
        expect(r.totalFare, 186.0);
        expect(r.tollCharges.first.verificationStatus, TollVerificationStatus.verified);
      });

      test('TPLEX Route 3: Carmen to Rosario (₱147.00)', () {
        final r = tollService.calculateExitToExitFareSync(
          originPlazaId: 'tplex_carmen',
          destinationPlazaId: 'tplex_rosario',
          vehicleClass: 1,
        );
        expect(r.totalFare, 147.0);
        expect(r.tollCharges.first.verificationStatus, TollVerificationStatus.verified);
      });
    });

    // -------------------------------------------------------------------------
    // 6. MCX (MUNTINLUPA-CAVITE EXPRESSWAY)
    // -------------------------------------------------------------------------
    group('6. MCX Route Evidence', () {
      test('MCX Route 1: Susana Heights to Daang Hari Class 1 (₱17.00)', () {
        final r = tollService.calculateExitToExitFareSync(
          originPlazaId: 'slex_susana_heights',
          destinationPlazaId: 'mcx_daang_hari',
          vehicleClass: 1,
        );
        expect(r.totalFare, 17.0);
        expect(r.fareByOperator['autosweep'], 17.0);
        expect(r.tollCharges.first.verificationStatus, TollVerificationStatus.verified);
      });

      test('MCX Route 2: Susana Heights to Daang Hari Class 2 (₱34.00)', () {
        final r = tollService.calculateExitToExitFareSync(
          originPlazaId: 'slex_susana_heights',
          destinationPlazaId: 'mcx_daang_hari',
          vehicleClass: 2,
        );
        expect(r.totalFare, 34.0);
      });

      test('MCX Route 3: Susana Heights to Daang Hari Class 3 (₱51.00)', () {
        final r = tollService.calculateExitToExitFareSync(
          originPlazaId: 'slex_susana_heights',
          destinationPlazaId: 'mcx_daang_hari',
          vehicleClass: 3,
        );
        expect(r.totalFare, 51.0);
      });
    });

    // -------------------------------------------------------------------------
    // 7. NAIAX (NAIA EXPRESSWAY)
    // -------------------------------------------------------------------------
    group('7. NAIAX Route Evidence', () {
      test('NAIAX Route 1: Skyway to Terminal 3 Mainline (₱45.00)', () {
        final r = tollService.calculateExitToExitFareSync(
          originPlazaId: 'naiax_skyway',
          destinationPlazaId: 'naiax_terminal3',
          vehicleClass: 1,
        );
        expect(r.totalFare, 45.0);
        expect(r.tollCharges.first.verificationStatus, TollVerificationStatus.verified);
      });

      test('NAIAX Route 2: Skyway to Terminal 1 & 2 Ramp (₱45.00)', () {
        final r = tollService.calculateExitToExitFareSync(
          originPlazaId: 'naiax_skyway',
          destinationPlazaId: 'naiax_terminal1_2',
          vehicleClass: 1,
        );
        expect(r.totalFare, 45.0);
      });

      test('NAIAX Route 3: Terminal 3 to Skyway Class 2 (₱90.00)', () {
        final r = tollService.calculateExitToExitFareSync(
          originPlazaId: 'naiax_terminal3',
          destinationPlazaId: 'naiax_skyway',
          vehicleClass: 2,
        );
        expect(r.totalFare, 90.0);
      });
    });

    // -------------------------------------------------------------------------
    // 8. NLEX CONNECTOR
    // -------------------------------------------------------------------------
    group('8. NLEX Connector Route Evidence', () {
      test('NLEX Connector Route 1: C3 Caloocan to Magsaysay Class 1 (₱119.00)', () {
        final r = tollService.calculateExitToExitFareSync(
          originPlazaId: 'nlex_connector_c3',
          destinationPlazaId: 'nlex_connector_magsaysay',
          vehicleClass: 1,
        );
        expect(r.totalFare, 119.0);
        expect(r.fareByOperator['easytrip'], 119.0);
        expect(r.tollCharges.first.verificationStatus, TollVerificationStatus.verified);
      });

      test('NLEX Connector Route 2: C3 Caloocan to Magsaysay Class 2 (₱299.00)', () {
        final r = tollService.calculateExitToExitFareSync(
          originPlazaId: 'nlex_connector_c3',
          destinationPlazaId: 'nlex_connector_magsaysay',
          vehicleClass: 2,
        );
        expect(r.totalFare, 299.0);
      });

      test('NLEX Connector Route 3: C3 Caloocan to Magsaysay Class 3 (₱358.00)', () {
        final r = tollService.calculateExitToExitFareSync(
          originPlazaId: 'nlex_connector_c3',
          destinationPlazaId: 'nlex_connector_magsaysay',
          vehicleClass: 3,
        );
        expect(r.totalFare, 358.0);
      });
    });

    // -------------------------------------------------------------------------
    // 9. CAVITEX & C5 SOUTH LINK
    // -------------------------------------------------------------------------
    group('9. CAVITEX Route Evidence', () {
      test('CAVITEX Route 1: Seaside to Parañaque Barrier (₱39.00)', () {
        final r = tollService.calculateExitToExitFareSync(
          originPlazaId: 'cavitex_seaside',
          destinationPlazaId: 'cavitex_paranaque',
          vehicleClass: 1,
        );
        expect(r.totalFare, 39.0);
        expect(r.tollCharges.first.verificationStatus, TollVerificationStatus.verified);
      });

      test('CAVITEX Route 2: Seaside to Kawit Extension (₱127.00)', () {
        final r = tollService.calculateExitToExitFareSync(
          originPlazaId: 'cavitex_seaside',
          destinationPlazaId: 'cavitex_kawit',
          vehicleClass: 1,
        );
        expect(r.totalFare, 127.0); // ₱39 Parañaque + ₱88 Kawit
        expect(r.tollCharges.first.verificationStatus, TollVerificationStatus.verified);
      });

      test('CAVITEX Route 3: C5 South Link Merville (₱35.00)', () {
        final r = tollService.calculateExitToExitFareSync(
          originPlazaId: 'cavitex_c5_merville',
          destinationPlazaId: 'cavitex_c5_taguig',
          vehicleClass: 1,
        );
        expect(r.totalFare, 35.0);
        expect(r.tollCharges.first.verificationStatus, TollVerificationStatus.verified);
      });
    });

    // -------------------------------------------------------------------------
    // 10. NLEX (NORTH LUZON EXPRESSWAY)
    // -------------------------------------------------------------------------
    group('10. NLEX Route Evidence', () {
      test('NLEX Route 1: Balintawak to Marilao Open System (₱69.00)', () {
        final r = tollService.calculateExitToExitFareSync(
          originPlazaId: 'nlex_balintawak',
          destinationPlazaId: 'nlex_marilao',
          vehicleClass: 1,
        );
        expect(r.totalFare, 69.0);
        expect(r.tollCharges.first.verificationStatus, TollVerificationStatus.verified);
      });

      test('NLEX Route 2: Balintawak to Sta. Ines Open+Closed (₱509.00)', () {
        final r = tollService.calculateExitToExitFareSync(
          originPlazaId: 'nlex_balintawak',
          destinationPlazaId: 'nlex_sta_ines',
          vehicleClass: 1,
        );
        expect(r.totalFare, 509.0); // ₱69 open + ₱440 closed
      });

      test('NLEX Route 3: Mindanao Ave to San Fernando (₱383.00)', () {
        final r = tollService.calculateExitToExitFareSync(
          originPlazaId: 'nlex_mindanao_ave',
          destinationPlazaId: 'nlex_san_fernando',
          vehicleClass: 1,
        );
        expect(r.totalFare, 383.0); // ₱69 open + ₱314 closed
      });
    });

    // -------------------------------------------------------------------------
    // 11. SCTEX (SUBIC-CLARK-TARLAC EXPRESSWAY)
    // -------------------------------------------------------------------------
    group('11. SCTEX Route Evidence', () {
      test('SCTEX Route 1: Subic/Tipo to Tarlac End-to-End (₱647.00)', () {
        final r = tollService.calculateExitToExitFareSync(
          originPlazaId: 'sctex_subic_tipo',
          destinationPlazaId: 'sctex_tarlac',
          vehicleClass: 1,
        );
        expect(r.totalFare, 647.0);
        expect(r.tollCharges.first.verificationStatus, TollVerificationStatus.verified);
      });

      test('SCTEX Route 2: Clark North to Tarlac (₱203.00)', () {
        final r = tollService.calculateExitToExitFareSync(
          originPlazaId: 'sctex_clark_north',
          destinationPlazaId: 'sctex_tarlac',
          vehicleClass: 1,
        );
        expect(r.totalFare, 203.0);
      });

      test('SCTEX Route 3: Dinalupihan to Clark South (₱280.00)', () {
        final r = tollService.calculateExitToExitFareSync(
          originPlazaId: 'sctex_dinalupihan',
          destinationPlazaId: 'sctex_clark_south',
          vehicleClass: 1,
        );
        expect(r.totalFare, 280.0);
      });
    });

    // -------------------------------------------------------------------------
    // 12. CCLEX (CEBU-CORDOVA LINK EXPRESSWAY)
    // -------------------------------------------------------------------------
    group('12. CCLEX Route Evidence (Honest needsManualReview status)', () {
      test('CCLEX Route 1: Cebu SRP to Cordova Bridge Class 1 (₱90.00, needsManualReview)', () {
        final r = tollService.calculateExitToExitFareSync(
          originPlazaId: 'cclex_cebu_srp',
          destinationPlazaId: 'cclex_cordova',
          vehicleClass: 1,
        );
        expect(r.totalFare, 90.0);
        expect(r.tollCharges.first.verificationStatus, TollVerificationStatus.needsManualReview);
      });

      test('CCLEX Route 2: Cebu SRP to Cordova Bridge Class 2 (₱180.00, needsManualReview)', () {
        final r = tollService.calculateExitToExitFareSync(
          originPlazaId: 'cclex_cebu_srp',
          destinationPlazaId: 'cclex_cordova',
          vehicleClass: 2,
        );
        expect(r.totalFare, 180.0);
        expect(r.tollCharges.first.verificationStatus, TollVerificationStatus.needsManualReview);
      });

      test('CCLEX Route 3: Cebu SRP to Cordova Bridge Class 3 (₱270.00, needsManualReview)', () {
        final r = tollService.calculateExitToExitFareSync(
          originPlazaId: 'cclex_cebu_srp',
          destinationPlazaId: 'cclex_cordova',
          vehicleClass: 3,
        );
        expect(r.totalFare, 270.0);
        expect(r.tollCharges.first.verificationStatus, TollVerificationStatus.needsManualReview);
      });
    });
  });
}
