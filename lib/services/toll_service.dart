import '../models/toll_segment.dart';
import '../models/route_model.dart';
import '../models/route_result.dart';
import 'firestore_service.dart';

/// Data service for Toll Calculator routes and segment fares.
///
/// Implements Firestore queries and per-operator fare calculation logic.
class TollService {
  final FirestoreService? _customFirestoreService;

  TollService({FirestoreService? firestoreService})
      : _customFirestoreService = firestoreService;

  FirestoreService get _firestoreService =>
      _customFirestoreService ?? FirestoreService();

  /// Fetches all active toll segments from Firestore.
  Stream<List<TollSegment>> getActiveSegments() {
    return _firestoreService.tollSegmentsRef
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  /// Fetches all active predefined routes from Firestore.
  Stream<List<RouteModel>> getActiveRoutes() {
    return _firestoreService.routesRef
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  /// Fetches the ordered list of [TollSegment]s for a given [RouteModel].
  Future<List<TollSegment>> getSegmentsForRoute(RouteModel route) async {
    if (route.segmentIds.isEmpty) {
      return [];
    }

    final segmentsSnapshot = await _firestoreService.tollSegmentsRef.get();
    final allSegments = {
      for (final doc in segmentsSnapshot.docs) doc.id: doc.data()
    };

    final List<TollSegment> orderedSegments = [];
    for (final segmentId in route.segmentIds) {
      final segment = allSegments[segmentId];
      if (segment != null) {
        orderedSegments.add(segment);
      }
    }

    return orderedSegments;
  }

  /// Calculates the fare breakdown for the given segments and vehicle class.
  RouteResult calculateFare({
    required List<TollSegment> segments,
    int vehicleClass = 1,
  }) {
    return RouteResult.calculate(
      segments: segments,
      vehicleClass: vehicleClass,
    );
  }

  /// Seeds generic sample placeholder routes & segments into Firestore if empty (for local testing).
  ///
  /// TODO(data): All data below is for testing and structure verification only.
  Future<void> seedPlaceholderDataIfEmpty() async {
    final existingRoutes = await _firestoreService.routesRef.limit(1).get();
    if (existingRoutes.docs.isNotEmpty) {
      return; // Already seeded
    }

    // TODO(data): Sample generic toll segments crossing multiple operators
    final sampleSegments = [
      TollSegment(
        id: 'sample_segment_alpha_1',
        expressway: 'ALPHA_EXPRESSWAY',
        expresswayName: 'Alpha Tollway',
        operator: 'autosweep',
        entryPoint: 'Plaza A1',
        exitPoint: 'Plaza A2',
        fareClass1: 50.0, // TODO(data): Placeholder fare
        fareClass2: 100.0,
        fareClass3: 150.0,
        direction: 'both',
        isActive: true,
        lastUpdated: DateTime(2025, 1, 15),
      ),
      TollSegment(
        id: 'sample_segment_alpha_2',
        expressway: 'ALPHA_EXPRESSWAY',
        expresswayName: 'Alpha Tollway',
        operator: 'autosweep',
        entryPoint: 'Plaza A2',
        exitPoint: 'Plaza A3',
        fareClass1: 75.0, // TODO(data): Placeholder fare
        fareClass2: 150.0,
        fareClass3: 225.0,
        direction: 'both',
        isActive: true,
        lastUpdated: DateTime(2025, 1, 15),
      ),
      TollSegment(
        id: 'sample_segment_connector',
        expressway: 'METRO_CONNECTOR',
        expresswayName: 'Metro Connector Expressway',
        operator: 'autosweep',
        entryPoint: 'Plaza A3',
        exitPoint: 'Plaza B1',
        fareClass1: 160.0, // TODO(data): Placeholder fare
        fareClass2: 320.0,
        fareClass3: 480.0,
        direction: 'both',
        isActive: true,
        lastUpdated: DateTime(2025, 1, 15),
      ),
      TollSegment(
        id: 'sample_segment_beta_1',
        expressway: 'BETA_EXPRESSWAY',
        expresswayName: 'Beta Tollway',
        operator: 'easytrip',
        entryPoint: 'Plaza B1',
        exitPoint: 'Plaza B2',
        fareClass1: 85.0, // TODO(data): Placeholder fare
        fareClass2: 170.0,
        fareClass3: 255.0,
        direction: 'both',
        isActive: true,
        lastUpdated: DateTime(2025, 1, 15),
      ),
      TollSegment(
        id: 'sample_segment_beta_2',
        expressway: 'BETA_EXPRESSWAY',
        expresswayName: 'Beta Tollway',
        operator: 'easytrip',
        entryPoint: 'Plaza B2',
        exitPoint: 'Plaza B3',
        fareClass1: 65.0, // TODO(data): Placeholder fare
        fareClass2: 130.0,
        fareClass3: 195.0,
        direction: 'both',
        isActive: true,
        lastUpdated: DateTime(2025, 1, 15),
      ),
    ];

    for (final segment in sampleSegments) {
      await _firestoreService.tollSegmentsRef.doc(segment.id).set(segment);
    }

    // TODO(data): Sample routes (Multi-operator corridor, Autosweep-only, Easytrip-only)
    final sampleRoutes = [
      const RouteModel(
        id: 'sample_route_multi_operator',
        name: 'Sample Multi-Operator Corridor (Plaza A1 → Plaza B3)',
        origin: 'Plaza A1 Terminal',
        destination: 'Plaza B3 Terminal',
        segmentIds: [
          'sample_segment_alpha_1',
          'sample_segment_alpha_2',
          'sample_segment_connector',
          'sample_segment_beta_1',
          'sample_segment_beta_2',
        ],
        isActive: true,
      ),
      const RouteModel(
        id: 'sample_route_autosweep_only',
        name: 'Sample Alpha Corridor (Plaza A1 → Plaza A3)',
        origin: 'Plaza A1 Terminal',
        destination: 'Plaza A3 Interchange',
        segmentIds: [
          'sample_segment_alpha_1',
          'sample_segment_alpha_2',
        ],
        isActive: true,
      ),
      const RouteModel(
        id: 'sample_route_easytrip_only',
        name: 'Sample Beta Corridor (Plaza B1 → Plaza B3)',
        origin: 'Plaza B1 Interchange',
        destination: 'Plaza B3 Terminal',
        segmentIds: [
          'sample_segment_beta_1',
          'sample_segment_beta_2',
        ],
        isActive: true,
      ),
    ];

    for (final route in sampleRoutes) {
      await _firestoreService.routesRef.doc(route.id).set(route);
    }
  }
}
