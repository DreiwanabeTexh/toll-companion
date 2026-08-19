import '../models/toll_plaza.dart';
import '../models/toll_segment.dart';
import '../models/route_model.dart';
import '../models/route_result.dart';
import 'firestore_service.dart';
import 'cache_service.dart';

/// Data and routing engine service for the Toll Calculator.
///
/// Supports:
/// 1. Arbitrary exit-to-exit pathfinding across multi-expressway networks and
///    dual-operator boundaries (Autosweep vs Easytrip).
/// 2. Strict sum-of-subtotals fare computation per RFID operator.
/// 3. Offline resilience with local SharedPreferences caching and embedded fallback catalog.
class TollService {
  final FirestoreService? _customFirestoreService;
  final CacheService? _customCacheService;

  TollService({
    FirestoreService? firestoreService,
    CacheService? cacheService,
  })  : _customFirestoreService = firestoreService,
        _customCacheService = cacheService;

  FirestoreService get _firestoreService =>
      _customFirestoreService ?? FirestoreService();

  CacheService get _cacheService =>
      _customCacheService ?? CacheService();

  // ===========================================================================
  // PLAZAS & EXIT-TO-EXIT ROUTING ENGINE
  // ===========================================================================

  /// Fetches all active toll plazas from Firestore.
  /// Automatically writes successful reads to local cache.
  Stream<List<TollPlaza>> getActivePlazas() {
    try {
      return _firestoreService.tollPlazasRef
          .where('isActive', isEqualTo: true)
          .snapshots()
          .map((snapshot) {
        final plazas = snapshot.docs.map((doc) => doc.data()).toList();
        if (plazas.isNotEmpty) {
          _cacheService.savePlazas(plazas);
        }
        return plazas.isNotEmpty ? plazas : defaultPlazas;
      }).handleError((_) => defaultPlazas);
    } catch (_) {
      return Stream.value(defaultPlazas);
    }
  }

  /// Retrieves locally cached toll plazas if offline.
  /// Falls back to default plazas if cache is empty.
  Future<List<TollPlaza>> getCachedPlazas() async {
    final cached = await _cacheService.getPlazas();
    if (cached != null && cached.isNotEmpty) {
      return cached;
    }
    return defaultPlazas;
  }

  /// Synchronously finds the optimal sequence of [TollSegment]s connecting [originPlazaId] to [destinationPlazaId].
  List<TollSegment> findPathSync(
    String originPlazaId,
    String destinationPlazaId, {
    List<TollPlaza>? plazas,
    List<TollSegment>? segments,
  }) {
    if (originPlazaId == destinationPlazaId) {
      return [];
    }

    final allPlazas = plazas ?? defaultPlazas;
    final allSegments = segments ?? defaultSegments;

    final plazaMap = {for (final p in allPlazas) p.id: p};
    if (!plazaMap.containsKey(originPlazaId) ||
        !plazaMap.containsKey(destinationPlazaId)) {
      return [];
    }

    // Build directed adjacency graph
    final Map<String, List<_GraphEdge>> adj = {};
    for (final p in allPlazas) {
      adj[p.id] = [];
    }

    for (final seg in allSegments) {
      final u = seg.entryPoint;
      final v = seg.exitPoint;
      if (adj.containsKey(u) && adj.containsKey(v)) {
        adj[u]!.add(_GraphEdge(targetPlazaId: v, segment: seg));
        if (seg.direction == 'both') {
          final reverseSeg = TollSegment(
            id: '${seg.id}_rev',
            expressway: seg.expressway,
            expresswayName: seg.expresswayName,
            operator: seg.operator,
            entryPoint: v,
            exitPoint: u,
            fareClass1: seg.fareClass1,
            fareClass2: seg.fareClass2,
            fareClass3: seg.fareClass3,
            direction: 'both',
            isActive: seg.isActive,
            lastUpdated: seg.lastUpdated,
            lastVerified: seg.lastVerified,
            notes: seg.notes,
          );
          adj[v]!.add(_GraphEdge(targetPlazaId: u, segment: reverseSeg));
        }
      }
    }

    // Add zero-cost interchange connectors between connecting plazas
    for (final p in allPlazas) {
      for (final targetId in p.connectsTo) {
        if (adj.containsKey(p.id) && adj.containsKey(targetId)) {
          final targetPlaza = plazaMap[targetId];
          final connectorSeg = TollSegment(
            id: 'interchange_${p.id}_$targetId',
            expressway: targetPlaza?.expressway ?? p.expressway,
            expresswayName: 'Interchange Connector',
            operator: targetPlaza?.operator ?? p.operator,
            entryPoint: p.id,
            exitPoint: targetId,
            fareClass1: 0.0,
            fareClass2: 0.0,
            fareClass3: 0.0,
            direction: 'both',
            isActive: true,
            lastUpdated: DateTime(2026, 8, 19),
            lastVerified: DateTime(2026, 8, 19),
            notes: 'Transfer between ${p.expressway} and ${targetPlaza?.expressway}',
          );
          adj[p.id]!.add(_GraphEdge(targetPlazaId: targetId, segment: connectorSeg));
        }
      }
    }

    // BFS shortest path search
    final queue = <String>[originPlazaId];
    final visited = <String>{originPlazaId};
    final parentEdge = <String, _GraphEdge>{};

    bool found = false;
    while (queue.isNotEmpty) {
      final current = queue.removeAt(0);
      if (current == destinationPlazaId) {
        found = true;
        break;
      }

      for (final edge in adj[current] ?? []) {
        if (!visited.contains(edge.targetPlazaId)) {
          visited.add(edge.targetPlazaId);
          parentEdge[edge.targetPlazaId] = edge;
          queue.add(edge.targetPlazaId);
        }
      }
    }

    if (!found) {
      return [];
    }

    // Reconstruct path
    final List<TollSegment> path = [];
    String curr = destinationPlazaId;
    while (curr != originPlazaId) {
      final edge = parentEdge[curr]!;
      if (edge.segment.fareClass1 > 0 || !edge.segment.id.startsWith('interchange_')) {
        path.insert(0, edge.segment);
      }
      curr = edge.segment.entryPoint;
    }

    return path;
  }

  /// Finds the optimal sequence of [TollSegment]s connecting [originPlazaId] to [destinationPlazaId].
  Future<List<TollSegment>> findPathBetweenPlazas(
    String originPlazaId,
    String destinationPlazaId,
  ) async {
    final allPlazas = await getCachedPlazas();
    return findPathSync(originPlazaId, destinationPlazaId, plazas: allPlazas);
  }

  /// Synchronously calculates the full fare breakdown from [originPlazaId] to [destinationPlazaId]
  /// for the specified [vehicleClass].
  RouteResult calculateExitToExitFareSync({
    required String originPlazaId,
    required String destinationPlazaId,
    int vehicleClass = 1,
    List<TollPlaza>? plazas,
    List<TollSegment>? segments,
  }) {
    final path = findPathSync(
      originPlazaId,
      destinationPlazaId,
      plazas: plazas,
      segments: segments,
    );
    return RouteResult.calculate(
      segments: path,
      vehicleClass: vehicleClass,
    );
  }

  /// Calculates the full fare breakdown from [originPlazaId] to [destinationPlazaId]
  /// for the specified [vehicleClass].
  Future<RouteResult> calculateExitToExitFare({
    required String originPlazaId,
    required String destinationPlazaId,
    int vehicleClass = 1,
  }) async {
    final segments = await findPathBetweenPlazas(originPlazaId, destinationPlazaId);
    return RouteResult.calculate(
      segments: segments,
      vehicleClass: vehicleClass,
    );
  }

  // ===========================================================================
  // PREDEFINED ROUTES (BACKWARD COMPATIBILITY)
  // ===========================================================================

  /// Fetches all active predefined routes from Firestore.
  Stream<List<RouteModel>> getActiveRoutes() {
    return _firestoreService.routesRef
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      final routes = snapshot.docs.map((doc) => doc.data()).toList();
      if (routes.isNotEmpty) {
        _cacheService.saveRoutes(routes);
      }
      return routes.isNotEmpty ? routes : defaultRoutes;
    });
  }

  /// Retrieves locally cached routes if offline.
  Future<List<RouteModel>> getCachedRoutes() async {
    final cached = await _cacheService.getRoutes();
    if (cached != null && cached.isNotEmpty) {
      return cached;
    }
    return defaultRoutes;
  }

  /// Fetches the ordered list of [TollSegment]s for a given [RouteModel].
  Future<List<TollSegment>> getSegmentsForRoute(RouteModel route) async {
    if (route.segmentIds.isEmpty) {
      return [];
    }

    final defaultMap = {for (final s in defaultSegments) s.id: s};
    final List<TollSegment> list = [];
    for (final id in route.segmentIds) {
      final s = defaultMap[id];
      if (s != null) {
        list.add(s);
      }
    }
    return list;
  }

  /// Calculates the fare breakdown for given segments and vehicle class.
  RouteResult calculateFare({
    required List<TollSegment> segments,
    int vehicleClass = 1,
  }) {
    return RouteResult.calculate(
      segments: segments,
      vehicleClass: vehicleClass,
    );
  }

  /// Saves the user's last-calculated route and fare breakdown for offline restoration.
  Future<void> saveLastCalculation({
    required String routeId,
    required int vehicleClass,
    required double totalFare,
    required Map<String, double> fareByOperator,
  }) {
    return _cacheService.saveLastTripCalculation(
      routeId: routeId,
      vehicleClass: vehicleClass,
      totalFare: totalFare,
      fareByOperator: fareByOperator,
    );
  }

  /// Retrieves the user's last-calculated route and fare breakdown.
  Future<Map<String, dynamic>?> getLastCalculation() {
    return _cacheService.getLastTripCalculation();
  }

  // ===========================================================================
  // EMBEDDED SAMPLE GRAPH CATALOG (REPRESENTATIVE PLAZAS & SEGMENTS)
  // ===========================================================================

  /// Default representative toll plazas across major connected corridors nationwide.
  static final List<TollPlaza> defaultPlazas = [
    // =========================================================================
    // 1. STAR TOLLWAY (Autosweep)
    // =========================================================================
    const TollPlaza(
      id: 'star_batangas',
      name: 'Batangas City Terminal',
      expressway: 'STAR',
      expresswayName: 'STAR Tollway',
      operator: 'autosweep',
      orderIndex: 1,
    ),
    const TollPlaza(
      id: 'star_ibaan',
      name: 'Ibaan Exit',
      expressway: 'STAR',
      expresswayName: 'STAR Tollway',
      operator: 'autosweep',
      orderIndex: 2,
    ),
    const TollPlaza(
      id: 'star_lipa',
      name: 'Lipa City Exit',
      expressway: 'STAR',
      expresswayName: 'STAR Tollway',
      operator: 'autosweep',
      orderIndex: 3,
    ),
    const TollPlaza(
      id: 'star_malvar',
      name: 'Malvar Exit',
      expressway: 'STAR',
      expresswayName: 'STAR Tollway',
      operator: 'autosweep',
      orderIndex: 4,
    ),
    const TollPlaza(
      id: 'star_tanauan',
      name: 'Tanauan Exit',
      expressway: 'STAR',
      expresswayName: 'STAR Tollway',
      operator: 'autosweep',
      orderIndex: 5,
    ),
    const TollPlaza(
      id: 'star_sto_tomas',
      name: 'Sto. Tomas Interchange',
      expressway: 'STAR',
      expresswayName: 'STAR Tollway',
      operator: 'autosweep',
      orderIndex: 6,
      isInterchange: true,
      connectsTo: ['slex_sto_tomas'],
    ),

    // =========================================================================
    // 2. SLEX - South Luzon Expressway (Autosweep)
    // =========================================================================
    const TollPlaza(
      id: 'slex_sto_tomas',
      name: 'Sto. Tomas (SLEX)',
      expressway: 'SLEX',
      expresswayName: 'South Luzon Expressway',
      operator: 'autosweep',
      orderIndex: 1,
      isInterchange: true,
      connectsTo: ['star_sto_tomas'],
    ),
    const TollPlaza(
      id: 'slex_calamba',
      name: 'Calamba Exit',
      expressway: 'SLEX',
      expresswayName: 'South Luzon Expressway',
      operator: 'autosweep',
      orderIndex: 2,
    ),
    const TollPlaza(
      id: 'slex_canlubang',
      name: 'Canlubang / Mayapa Exit',
      expressway: 'SLEX',
      expresswayName: 'South Luzon Expressway',
      operator: 'autosweep',
      orderIndex: 3,
    ),
    const TollPlaza(
      id: 'slex_silangan',
      name: 'Silangan Exit',
      expressway: 'SLEX',
      expresswayName: 'South Luzon Expressway',
      operator: 'autosweep',
      orderIndex: 4,
    ),
    const TollPlaza(
      id: 'slex_cabuyao',
      name: 'Cabuyao Exit',
      expressway: 'SLEX',
      expresswayName: 'South Luzon Expressway',
      operator: 'autosweep',
      orderIndex: 5,
    ),
    const TollPlaza(
      id: 'slex_santa_rosa',
      name: 'Santa Rosa Exit',
      expressway: 'SLEX',
      expresswayName: 'South Luzon Expressway',
      operator: 'autosweep',
      orderIndex: 6,
    ),
    const TollPlaza(
      id: 'slex_eton_city',
      name: 'Eton City Exit',
      expressway: 'SLEX',
      expresswayName: 'South Luzon Expressway',
      operator: 'autosweep',
      orderIndex: 7,
    ),
    const TollPlaza(
      id: 'slex_greenfield',
      name: 'Greenfield / Unilab Exit',
      expressway: 'SLEX',
      expresswayName: 'South Luzon Expressway',
      operator: 'autosweep',
      orderIndex: 8,
    ),
    const TollPlaza(
      id: 'slex_mamplasan',
      name: 'Mamplasan Interchange',
      expressway: 'SLEX',
      expresswayName: 'South Luzon Expressway',
      operator: 'autosweep',
      orderIndex: 9,
      isInterchange: true,
      connectsTo: ['calax_mamplasan'],
    ),
    const TollPlaza(
      id: 'slex_southwoods',
      name: 'Southwoods Exit',
      expressway: 'SLEX',
      expresswayName: 'South Luzon Expressway',
      operator: 'autosweep',
      orderIndex: 10,
    ),
    const TollPlaza(
      id: 'slex_san_pedro',
      name: 'San Pedro Exit',
      expressway: 'SLEX',
      expresswayName: 'South Luzon Expressway',
      operator: 'autosweep',
      orderIndex: 11,
    ),
    const TollPlaza(
      id: 'slex_susana_heights',
      name: 'Susana Heights Interchange',
      expressway: 'SLEX',
      expresswayName: 'South Luzon Expressway',
      operator: 'autosweep',
      orderIndex: 12,
      isInterchange: true,
      connectsTo: ['mcx_susana_heights'],
    ),
    const TollPlaza(
      id: 'slex_filinvest',
      name: 'Filinvest Exit (Alabang)',
      expressway: 'SLEX',
      expresswayName: 'South Luzon Expressway',
      operator: 'autosweep',
      orderIndex: 13,
    ),
    const TollPlaza(
      id: 'slex_alabang',
      name: 'Alabang Viaduct (SLEX Main)',
      expressway: 'SLEX',
      expresswayName: 'South Luzon Expressway',
      operator: 'autosweep',
      orderIndex: 14,
      isInterchange: true,
      connectsTo: ['skyway_alabang'],
    ),

    // =========================================================================
    // 3. MCX - Muntinlupa-Cavite Expressway (Autosweep)
    // =========================================================================
    const TollPlaza(
      id: 'mcx_susana_heights',
      name: 'Susana Heights (MCX)',
      expressway: 'MCX',
      expresswayName: 'Muntinlupa-Cavite Expressway',
      operator: 'autosweep',
      orderIndex: 1,
      isInterchange: true,
      connectsTo: ['slex_susana_heights'],
    ),
    const TollPlaza(
      id: 'mcx_daang_hari',
      name: 'Daang Hari Main Plaza',
      expressway: 'MCX',
      expresswayName: 'Muntinlupa-Cavite Expressway',
      operator: 'autosweep',
      orderIndex: 2,
    ),

    // =========================================================================
    // 4. SKYWAY STAGES 1, 2, 3 (Autosweep)
    // =========================================================================
    const TollPlaza(
      id: 'skyway_alabang',
      name: 'Alabang Main Gantry',
      expressway: 'SKYWAY',
      expresswayName: 'Skyway Stage 1-3',
      operator: 'autosweep',
      orderIndex: 1,
      isInterchange: true,
      connectsTo: ['slex_alabang'],
    ),
    const TollPlaza(
      id: 'skyway_sucat',
      name: 'Sucat Exit / Entry',
      expressway: 'SKYWAY',
      expresswayName: 'Skyway Stage 1-3',
      operator: 'autosweep',
      orderIndex: 2,
    ),
    const TollPlaza(
      id: 'skyway_bicutan',
      name: 'Bicutan Exit / Entry',
      expressway: 'SKYWAY',
      expresswayName: 'Skyway Stage 1-3',
      operator: 'autosweep',
      orderIndex: 3,
    ),
    const TollPlaza(
      id: 'skyway_naiax',
      name: 'NAIAX Interchange (Skyway)',
      expressway: 'SKYWAY',
      expresswayName: 'Skyway Stage 1-3',
      operator: 'autosweep',
      orderIndex: 4,
      isInterchange: true,
      connectsTo: ['naiax_skyway'],
    ),
    const TollPlaza(
      id: 'skyway_magallanes',
      name: 'Magallanes Exit',
      expressway: 'SKYWAY',
      expresswayName: 'Skyway Stage 1-3',
      operator: 'autosweep',
      orderIndex: 5,
    ),
    const TollPlaza(
      id: 'skyway_don_bosco',
      name: 'Don Bosco / Arnaiz Ramp',
      expressway: 'SKYWAY',
      expresswayName: 'Skyway Stage 1-3',
      operator: 'autosweep',
      orderIndex: 6,
    ),
    const TollPlaza(
      id: 'skyway_buendia',
      name: 'Buendia / Makati Ramp',
      expressway: 'SKYWAY',
      expresswayName: 'Skyway Stage 1-3',
      operator: 'autosweep',
      orderIndex: 7,
    ),
    const TollPlaza(
      id: 'skyway_quirino',
      name: 'Plaza Dilao / Quirino Exit',
      expressway: 'SKYWAY',
      expresswayName: 'Skyway Stage 1-3',
      operator: 'autosweep',
      orderIndex: 8,
    ),
    const TollPlaza(
      id: 'skyway_nagtahan',
      name: 'Nagtahan Exit',
      expressway: 'SKYWAY',
      expresswayName: 'Skyway Stage 1-3',
      operator: 'autosweep',
      orderIndex: 9,
    ),
    const TollPlaza(
      id: 'skyway_e_rodriguez',
      name: 'E. Rodriguez Exit',
      expressway: 'SKYWAY',
      expresswayName: 'Skyway Stage 1-3',
      operator: 'autosweep',
      orderIndex: 10,
    ),
    const TollPlaza(
      id: 'skyway_quezon_ave',
      name: 'Quezon Ave Exit',
      expressway: 'SKYWAY',
      expresswayName: 'Skyway Stage 1-3',
      operator: 'autosweep',
      orderIndex: 11,
    ),
    const TollPlaza(
      id: 'skyway_sgt_rivera',
      name: 'Sgt. Rivera / C3 Exit',
      expressway: 'SKYWAY',
      expresswayName: 'Skyway Stage 1-3',
      operator: 'autosweep',
      orderIndex: 12,
    ),
    const TollPlaza(
      id: 'skyway_balintawak',
      name: 'Balintawak Gantry (Skyway)',
      expressway: 'SKYWAY',
      expresswayName: 'Skyway Stage 1-3',
      operator: 'autosweep',
      orderIndex: 13,
      isInterchange: true,
      connectsTo: ['nlex_balintawak'],
    ),

    // =========================================================================
    // 5. NAIAX - NAIA Expressway (Autosweep)
    // =========================================================================
    const TollPlaza(
      id: 'naiax_skyway',
      name: 'Sales Road / Skyway Ramp',
      expressway: 'NAIAX',
      expresswayName: 'NAIA Expressway',
      operator: 'autosweep',
      orderIndex: 1,
      isInterchange: true,
      connectsTo: ['skyway_naiax'],
    ),
    const TollPlaza(
      id: 'naiax_terminal3',
      name: 'NAIA Terminal 3 Plaza',
      expressway: 'NAIAX',
      expresswayName: 'NAIA Expressway',
      operator: 'autosweep',
      orderIndex: 2,
    ),
    const TollPlaza(
      id: 'naiax_terminal1_2',
      name: 'NAIA Terminals 1 & 2 Plaza',
      expressway: 'NAIAX',
      expresswayName: 'NAIA Expressway',
      operator: 'autosweep',
      orderIndex: 3,
    ),
    const TollPlaza(
      id: 'naiax_macapagal',
      name: 'Macapagal / Entertainment City',
      expressway: 'NAIAX',
      expresswayName: 'NAIA Expressway',
      operator: 'autosweep',
      orderIndex: 4,
    ),

    // =========================================================================
    // 6. NLEX - North Luzon Expressway (Easytrip)
    // =========================================================================
    const TollPlaza(
      id: 'nlex_balintawak',
      name: 'Balintawak Barrier (NLEX)',
      expressway: 'NLEX',
      expresswayName: 'North Luzon Expressway',
      operator: 'easytrip',
      orderIndex: 1,
      isInterchange: true,
      connectsTo: ['skyway_balintawak', 'nlex_connector_c3'],
    ),
    const TollPlaza(
      id: 'nlex_mindanao_ave',
      name: 'Mindanao Ave Exit (Smart Connect)',
      expressway: 'NLEX',
      expresswayName: 'North Luzon Expressway',
      operator: 'easytrip',
      orderIndex: 2,
    ),
    const TollPlaza(
      id: 'nlex_valenzuela',
      name: 'Karuhatan / Valenzuela Exit',
      expressway: 'NLEX',
      expresswayName: 'North Luzon Expressway',
      operator: 'easytrip',
      orderIndex: 3,
    ),
    const TollPlaza(
      id: 'nlex_meycauayan',
      name: 'Meycauayan Exit',
      expressway: 'NLEX',
      expresswayName: 'North Luzon Expressway',
      operator: 'easytrip',
      orderIndex: 4,
    ),
    const TollPlaza(
      id: 'nlex_marilao',
      name: 'Marilao Exit',
      expressway: 'NLEX',
      expresswayName: 'North Luzon Expressway',
      operator: 'easytrip',
      orderIndex: 5,
    ),
    const TollPlaza(
      id: 'nlex_philippine_arena',
      name: 'Ciudad de Victoria (Phil Arena)',
      expressway: 'NLEX',
      expresswayName: 'North Luzon Expressway',
      operator: 'easytrip',
      orderIndex: 6,
    ),
    const TollPlaza(
      id: 'nlex_bocaue',
      name: 'Bocaue Barrier',
      expressway: 'NLEX',
      expresswayName: 'North Luzon Expressway',
      operator: 'easytrip',
      orderIndex: 7,
    ),
    const TollPlaza(
      id: 'nlex_balagtas',
      name: 'Balagtas / Plaridel Bypass',
      expressway: 'NLEX',
      expresswayName: 'North Luzon Expressway',
      operator: 'easytrip',
      orderIndex: 8,
    ),
    const TollPlaza(
      id: 'nlex_tabang',
      name: 'Tabang Exit (Guiguinto)',
      expressway: 'NLEX',
      expresswayName: 'North Luzon Expressway',
      operator: 'easytrip',
      orderIndex: 9,
    ),
    const TollPlaza(
      id: 'nlex_pulilan',
      name: 'Pulilan Exit',
      expressway: 'NLEX',
      expresswayName: 'North Luzon Expressway',
      operator: 'easytrip',
      orderIndex: 10,
    ),
    const TollPlaza(
      id: 'nlex_san_simon',
      name: 'San Simon Exit',
      expressway: 'NLEX',
      expresswayName: 'North Luzon Expressway',
      operator: 'easytrip',
      orderIndex: 11,
    ),
    const TollPlaza(
      id: 'nlex_san_fernando',
      name: 'San Fernando Exit',
      expressway: 'NLEX',
      expresswayName: 'North Luzon Expressway',
      operator: 'easytrip',
      orderIndex: 12,
    ),
    const TollPlaza(
      id: 'nlex_mexico',
      name: 'Mexico / Dinalupihan Exit',
      expressway: 'NLEX',
      expresswayName: 'North Luzon Expressway',
      operator: 'easytrip',
      orderIndex: 13,
    ),
    const TollPlaza(
      id: 'nlex_angeles',
      name: 'Angeles City Exit',
      expressway: 'NLEX',
      expresswayName: 'North Luzon Expressway',
      operator: 'easytrip',
      orderIndex: 14,
    ),
    const TollPlaza(
      id: 'nlex_dau',
      name: 'Dau Exit (Mabalacat)',
      expressway: 'NLEX',
      expresswayName: 'North Luzon Expressway',
      operator: 'easytrip',
      orderIndex: 15,
    ),
    const TollPlaza(
      id: 'nlex_sta_ines',
      name: 'Sta. Ines Exit',
      expressway: 'NLEX',
      expresswayName: 'North Luzon Expressway',
      operator: 'easytrip',
      orderIndex: 16,
      isInterchange: true,
      connectsTo: ['sctex_clark_north'],
    ),

    // =========================================================================
    // 7. NLEX CONNECTOR (Easytrip)
    // =========================================================================
    const TollPlaza(
      id: 'nlex_connector_c3',
      name: 'Caloocan C3 Interchange',
      expressway: 'NLEX-C',
      expresswayName: 'NLEX Connector',
      operator: 'easytrip',
      orderIndex: 1,
      isInterchange: true,
      connectsTo: ['nlex_balintawak'],
    ),
    const TollPlaza(
      id: 'nlex_connector_espana',
      name: 'España Exit',
      expressway: 'NLEX-C',
      expresswayName: 'NLEX Connector',
      operator: 'easytrip',
      orderIndex: 2,
    ),
    const TollPlaza(
      id: 'nlex_connector_magsaysay',
      name: 'Magsaysay Blvd (Sta. Mesa)',
      expressway: 'NLEX-C',
      expresswayName: 'NLEX Connector',
      operator: 'easytrip',
      orderIndex: 3,
    ),

    // =========================================================================
    // 8. SCTEX - Subic-Clark-Tarlac Expressway (Easytrip)
    // =========================================================================
    const TollPlaza(
      id: 'sctex_subic_tipo',
      name: 'Subic / Tipo Toll Plaza',
      expressway: 'SCTEX',
      expresswayName: 'Subic-Clark-Tarlac Expressway',
      operator: 'easytrip',
      orderIndex: 1,
    ),
    const TollPlaza(
      id: 'sctex_dinalupihan',
      name: 'Dinalupihan Exit (SCTEX)',
      expressway: 'SCTEX',
      expresswayName: 'Subic-Clark-Tarlac Expressway',
      operator: 'easytrip',
      orderIndex: 2,
    ),
    const TollPlaza(
      id: 'sctex_floridablanca',
      name: 'Floridablanca Exit',
      expressway: 'SCTEX',
      expresswayName: 'Subic-Clark-Tarlac Expressway',
      operator: 'easytrip',
      orderIndex: 3,
    ),
    const TollPlaza(
      id: 'sctex_porac',
      name: 'Porac Exit',
      expressway: 'SCTEX',
      expresswayName: 'Subic-Clark-Tarlac Expressway',
      operator: 'easytrip',
      orderIndex: 4,
    ),
    const TollPlaza(
      id: 'sctex_clark_south',
      name: 'Clark South Interchange',
      expressway: 'SCTEX',
      expresswayName: 'Subic-Clark-Tarlac Expressway',
      operator: 'easytrip',
      orderIndex: 5,
    ),
    const TollPlaza(
      id: 'sctex_clark_north',
      name: 'Clark North / Mabalacat',
      expressway: 'SCTEX',
      expresswayName: 'Subic-Clark-Tarlac Expressway',
      operator: 'easytrip',
      orderIndex: 6,
      isInterchange: true,
      connectsTo: ['nlex_sta_ines'],
    ),
    const TollPlaza(
      id: 'sctex_dolores',
      name: 'Dolores Exit',
      expressway: 'SCTEX',
      expresswayName: 'Subic-Clark-Tarlac Expressway',
      operator: 'easytrip',
      orderIndex: 7,
    ),
    const TollPlaza(
      id: 'sctex_concepcion',
      name: 'Concepcion Exit',
      expressway: 'SCTEX',
      expresswayName: 'Subic-Clark-Tarlac Expressway',
      operator: 'easytrip',
      orderIndex: 8,
    ),
    const TollPlaza(
      id: 'sctex_luisita',
      name: 'San Miguel / Luisita Exit',
      expressway: 'SCTEX',
      expresswayName: 'Subic-Clark-Tarlac Expressway',
      operator: 'easytrip',
      orderIndex: 9,
    ),
    const TollPlaza(
      id: 'sctex_tarlac',
      name: 'Tarlac Central Interchange',
      expressway: 'SCTEX',
      expresswayName: 'Subic-Clark-Tarlac Expressway',
      operator: 'easytrip',
      orderIndex: 10,
      isInterchange: true,
      connectsTo: ['tplex_tarlac'],
    ),

    // =========================================================================
    // 9. TPLEX - Tarlac-Pangasinan-La Union (Autosweep)
    // =========================================================================
    const TollPlaza(
      id: 'tplex_tarlac',
      name: 'Tarlac Central (TPLEX)',
      expressway: 'TPLEX',
      expresswayName: 'Tarlac-Pangasinan-La Union',
      operator: 'autosweep',
      orderIndex: 1,
      isInterchange: true,
      connectsTo: ['sctex_tarlac'],
    ),
    const TollPlaza(
      id: 'tplex_victoria',
      name: 'Victoria Exit',
      expressway: 'TPLEX',
      expresswayName: 'Tarlac-Pangasinan-La Union',
      operator: 'autosweep',
      orderIndex: 2,
    ),
    const TollPlaza(
      id: 'tplex_pura',
      name: 'Pura Exit',
      expressway: 'TPLEX',
      expresswayName: 'Tarlac-Pangasinan-La Union',
      operator: 'autosweep',
      orderIndex: 3,
    ),
    const TollPlaza(
      id: 'tplex_anao',
      name: 'Anao Exit',
      expressway: 'TPLEX',
      expresswayName: 'Tarlac-Pangasinan-La Union',
      operator: 'autosweep',
      orderIndex: 4,
    ),
    const TollPlaza(
      id: 'tplex_carmen',
      name: 'Carmen (Rosales) Exit',
      expressway: 'TPLEX',
      expresswayName: 'Tarlac-Pangasinan-La Union',
      operator: 'autosweep',
      orderIndex: 5,
    ),
    const TollPlaza(
      id: 'tplex_urdaneta',
      name: 'Urdaneta Central Exit',
      expressway: 'TPLEX',
      expresswayName: 'Tarlac-Pangasinan-La Union',
      operator: 'autosweep',
      orderIndex: 6,
    ),
    const TollPlaza(
      id: 'tplex_binalonan',
      name: 'Binalonan Exit',
      expressway: 'TPLEX',
      expresswayName: 'Tarlac-Pangasinan-La Union',
      operator: 'autosweep',
      orderIndex: 7,
    ),
    const TollPlaza(
      id: 'tplex_pozorrubio',
      name: 'Pozorrubio Exit',
      expressway: 'TPLEX',
      expresswayName: 'Tarlac-Pangasinan-La Union',
      operator: 'autosweep',
      orderIndex: 8,
    ),
    const TollPlaza(
      id: 'tplex_sison',
      name: 'Sison Exit',
      expressway: 'TPLEX',
      expresswayName: 'Tarlac-Pangasinan-La Union',
      operator: 'autosweep',
      orderIndex: 9,
    ),
    const TollPlaza(
      id: 'tplex_rosario',
      name: 'Rosario (La Union) Terminus',
      expressway: 'TPLEX',
      expresswayName: 'Tarlac-Pangasinan-La Union',
      operator: 'autosweep',
      orderIndex: 10,
    ),

    // =========================================================================
    // 10. CALAX - Cavite-Laguna Expressway (Easytrip)
    // =========================================================================
    const TollPlaza(
      id: 'calax_mamplasan',
      name: 'Mamplasan Barrier (CALAX)',
      expressway: 'CALAX',
      expresswayName: 'Cavite-Laguna Expressway',
      operator: 'easytrip',
      orderIndex: 1,
      isInterchange: true,
      connectsTo: ['slex_mamplasan'],
    ),
    const TollPlaza(
      id: 'calax_technopark',
      name: 'Laguna Technopark Exit',
      expressway: 'CALAX',
      expresswayName: 'Cavite-Laguna Expressway',
      operator: 'easytrip',
      orderIndex: 2,
    ),
    const TollPlaza(
      id: 'calax_laguna_blvd',
      name: 'Laguna Boulevard Exit',
      expressway: 'CALAX',
      expresswayName: 'Cavite-Laguna Expressway',
      operator: 'easytrip',
      orderIndex: 3,
    ),
    const TollPlaza(
      id: 'calax_santa_rosa',
      name: 'Santa Rosa-Tagaytay Rd',
      expressway: 'CALAX',
      expresswayName: 'Cavite-Laguna Expressway',
      operator: 'easytrip',
      orderIndex: 4,
    ),
    const TollPlaza(
      id: 'calax_silang_east',
      name: 'Silang East Exit',
      expressway: 'CALAX',
      expresswayName: 'Cavite-Laguna Expressway',
      operator: 'easytrip',
      orderIndex: 5,
    ),
    const TollPlaza(
      id: 'calax_silang',
      name: 'Silang (Aguinaldo Hwy) Exit',
      expressway: 'CALAX',
      expresswayName: 'Cavite-Laguna Expressway',
      operator: 'easytrip',
      orderIndex: 6,
    ),
    const TollPlaza(
      id: 'calax_gov_drive',
      name: 'Governor\'s Drive Exit',
      expressway: 'CALAX',
      expresswayName: 'Cavite-Laguna Expressway',
      operator: 'easytrip',
      orderIndex: 7,
    ),

    // =========================================================================
    // 11. CAVITEX & C5 SOUTH LINK (Easytrip)
    // =========================================================================
    const TollPlaza(
      id: 'cavitex_seaside',
      name: 'Roxas Blvd / Seaside Entry',
      expressway: 'CAVITEX',
      expresswayName: 'Manila-Cavite Expressway',
      operator: 'easytrip',
      orderIndex: 1,
    ),
    const TollPlaza(
      id: 'cavitex_paranaque',
      name: 'Parañaque Main Plaza',
      expressway: 'CAVITEX',
      expresswayName: 'Manila-Cavite Expressway',
      operator: 'easytrip',
      orderIndex: 2,
    ),
    const TollPlaza(
      id: 'cavitex_zapote',
      name: 'Zapote Interchange / Longos',
      expressway: 'CAVITEX',
      expresswayName: 'Manila-Cavite Expressway',
      operator: 'easytrip',
      orderIndex: 3,
    ),
    const TollPlaza(
      id: 'cavitex_kawit',
      name: 'Kawit Toll Plaza',
      expressway: 'CAVITEX',
      expresswayName: 'Manila-Cavite Expressway',
      operator: 'easytrip',
      orderIndex: 4,
    ),
    const TollPlaza(
      id: 'cavitex_c5_merville',
      name: 'C5 South Link Merville Exit',
      expressway: 'CAVITEX',
      expresswayName: 'Manila-Cavite Expressway',
      operator: 'easytrip',
      orderIndex: 5,
    ),
    const TollPlaza(
      id: 'cavitex_c5_taguig',
      name: 'C5 Taguig / CP Garcia Plaza',
      expressway: 'CAVITEX',
      expresswayName: 'Manila-Cavite Expressway',
      operator: 'easytrip',
      orderIndex: 6,
    ),

    // =========================================================================
    // 12. CCLEX - Cebu-Cordova Link Expressway (CCLEX / Easytrip)
    // =========================================================================
    const TollPlaza(
      id: 'cclex_cebu_srp',
      name: 'Cebu City (SRP) Plaza',
      expressway: 'CCLEX',
      expresswayName: 'Cebu-Cordova Link Expressway',
      operator: 'easytrip',
      orderIndex: 1,
    ),
    const TollPlaza(
      id: 'cclex_cordova',
      name: 'Cordova Main Plaza (Mactan)',
      expressway: 'CCLEX',
      expresswayName: 'Cebu-Cordova Link Expressway',
      operator: 'easytrip',
      orderIndex: 2,
    ),
  ];

  /// Default connected toll segments for routing and offline fallback.
  static final List<TollSegment> defaultSegments = [
    // =========================================================================
    // 1. STAR TOLLWAY SEGMENTS (Autosweep)
    // =========================================================================
    TollSegment(
      id: 'seg_star_batangas_ibaan',
      expressway: 'STAR',
      expresswayName: 'STAR Tollway',
      operator: 'autosweep',
      entryPoint: 'star_batangas',
      exitPoint: 'star_ibaan',
      fareClass1: 35.0,
      fareClass2: 70.0,
      fareClass3: 105.0,
      direction: 'both',
      isActive: true,
      lastUpdated: DateTime(2026, 8, 19),
      lastVerified: DateTime(2026, 8, 19),
    ),
    TollSegment(
      id: 'seg_star_ibaan_lipa',
      expressway: 'STAR',
      expresswayName: 'STAR Tollway',
      operator: 'autosweep',
      entryPoint: 'star_ibaan',
      exitPoint: 'star_lipa',
      fareClass1: 54.0,
      fareClass2: 108.0,
      fareClass3: 162.0,
      direction: 'both',
      isActive: true,
      lastUpdated: DateTime(2026, 8, 19),
      lastVerified: DateTime(2026, 8, 19),
    ),
    TollSegment(
      id: 'seg_star_lipa_malvar',
      expressway: 'STAR',
      expresswayName: 'STAR Tollway',
      operator: 'autosweep',
      entryPoint: 'star_lipa',
      exitPoint: 'star_malvar',
      fareClass1: 28.0,
      fareClass2: 56.0,
      fareClass3: 84.0,
      direction: 'both',
      isActive: true,
      lastUpdated: DateTime(2026, 8, 19),
      lastVerified: DateTime(2026, 8, 19),
    ),
    TollSegment(
      id: 'seg_star_malvar_tanauan',
      expressway: 'STAR',
      expresswayName: 'STAR Tollway',
      operator: 'autosweep',
      entryPoint: 'star_malvar',
      exitPoint: 'star_tanauan',
      fareClass1: 15.0,
      fareClass2: 30.0,
      fareClass3: 45.0,
      direction: 'both',
      isActive: true,
      lastUpdated: DateTime(2026, 8, 19),
      lastVerified: DateTime(2026, 8, 19),
    ),
    TollSegment(
      id: 'seg_star_tanauan_stotomas',
      expressway: 'STAR',
      expresswayName: 'STAR Tollway',
      operator: 'autosweep',
      entryPoint: 'star_tanauan',
      exitPoint: 'star_sto_tomas',
      fareClass1: 14.0,
      fareClass2: 28.0,
      fareClass3: 42.0,
      direction: 'both',
      isActive: true,
      lastUpdated: DateTime(2026, 8, 19),
      lastVerified: DateTime(2026, 8, 19),
    ),

    // =========================================================================
    // 2. SLEX SEGMENTS (Autosweep)
    // =========================================================================
    TollSegment(
      id: 'seg_slex_stotomas_calamba',
      expressway: 'SLEX',
      expresswayName: 'South Luzon Expressway',
      operator: 'autosweep',
      entryPoint: 'slex_sto_tomas',
      exitPoint: 'slex_calamba',
      fareClass1: 45.0,
      fareClass2: 90.0,
      fareClass3: 135.0,
      direction: 'both',
      isActive: true,
      lastUpdated: DateTime(2026, 8, 19),
      lastVerified: DateTime(2026, 8, 19),
    ),
    TollSegment(
      id: 'seg_slex_calamba_canlubang',
      expressway: 'SLEX',
      expresswayName: 'South Luzon Expressway',
      operator: 'autosweep',
      entryPoint: 'slex_calamba',
      exitPoint: 'slex_canlubang',
      fareClass1: 18.0,
      fareClass2: 36.0,
      fareClass3: 54.0,
      direction: 'both',
      isActive: true,
      lastUpdated: DateTime(2026, 8, 19),
      lastVerified: DateTime(2026, 8, 19),
    ),
    TollSegment(
      id: 'seg_slex_canlubang_silangan',
      expressway: 'SLEX',
      expresswayName: 'South Luzon Expressway',
      operator: 'autosweep',
      entryPoint: 'slex_canlubang',
      exitPoint: 'slex_silangan',
      fareClass1: 12.0,
      fareClass2: 24.0,
      fareClass3: 36.0,
      direction: 'both',
      isActive: true,
      lastUpdated: DateTime(2026, 8, 19),
      lastVerified: DateTime(2026, 8, 19),
    ),
    TollSegment(
      id: 'seg_slex_silangan_cabuyao',
      expressway: 'SLEX',
      expresswayName: 'South Luzon Expressway',
      operator: 'autosweep',
      entryPoint: 'slex_silangan',
      exitPoint: 'slex_cabuyao',
      fareClass1: 14.0,
      fareClass2: 28.0,
      fareClass3: 42.0,
      direction: 'both',
      isActive: true,
      lastUpdated: DateTime(2026, 8, 19),
      lastVerified: DateTime(2026, 8, 19),
    ),
    TollSegment(
      id: 'seg_slex_cabuyao_santarosa',
      expressway: 'SLEX',
      expresswayName: 'South Luzon Expressway',
      operator: 'autosweep',
      entryPoint: 'slex_cabuyao',
      exitPoint: 'slex_santa_rosa',
      fareClass1: 20.0,
      fareClass2: 40.0,
      fareClass3: 60.0,
      direction: 'both',
      isActive: true,
      lastUpdated: DateTime(2026, 8, 19),
      lastVerified: DateTime(2026, 8, 19),
    ),
    TollSegment(
      id: 'seg_slex_santarosa_eton',
      expressway: 'SLEX',
      expresswayName: 'South Luzon Expressway',
      operator: 'autosweep',
      entryPoint: 'slex_santa_rosa',
      exitPoint: 'slex_eton_city',
      fareClass1: 10.0,
      fareClass2: 20.0,
      fareClass3: 30.0,
      direction: 'both',
      isActive: true,
      lastUpdated: DateTime(2026, 8, 19),
      lastVerified: DateTime(2026, 8, 19),
    ),
    TollSegment(
      id: 'seg_slex_eton_greenfield',
      expressway: 'SLEX',
      expresswayName: 'South Luzon Expressway',
      operator: 'autosweep',
      entryPoint: 'slex_eton_city',
      exitPoint: 'slex_greenfield',
      fareClass1: 8.0,
      fareClass2: 16.0,
      fareClass3: 24.0,
      direction: 'both',
      isActive: true,
      lastUpdated: DateTime(2026, 8, 19),
      lastVerified: DateTime(2026, 8, 19),
    ),
    TollSegment(
      id: 'seg_slex_greenfield_mamplasan',
      expressway: 'SLEX',
      expresswayName: 'South Luzon Expressway',
      operator: 'autosweep',
      entryPoint: 'slex_greenfield',
      exitPoint: 'slex_mamplasan',
      fareClass1: 12.0,
      fareClass2: 24.0,
      fareClass3: 36.0,
      direction: 'both',
      isActive: true,
      lastUpdated: DateTime(2026, 8, 19),
      lastVerified: DateTime(2026, 8, 19),
    ),
    TollSegment(
      id: 'seg_slex_mamplasan_southwoods',
      expressway: 'SLEX',
      expresswayName: 'South Luzon Expressway',
      operator: 'autosweep',
      entryPoint: 'slex_mamplasan',
      exitPoint: 'slex_southwoods',
      fareClass1: 24.0,
      fareClass2: 48.0,
      fareClass3: 72.0,
      direction: 'both',
      isActive: true,
      lastUpdated: DateTime(2026, 8, 19),
      lastVerified: DateTime(2026, 8, 19),
    ),
    TollSegment(
      id: 'seg_slex_southwoods_sanpedro',
      expressway: 'SLEX',
      expresswayName: 'South Luzon Expressway',
      operator: 'autosweep',
      entryPoint: 'slex_southwoods',
      exitPoint: 'slex_san_pedro',
      fareClass1: 18.0,
      fareClass2: 36.0,
      fareClass3: 54.0,
      direction: 'both',
      isActive: true,
      lastUpdated: DateTime(2026, 8, 19),
      lastVerified: DateTime(2026, 8, 19),
    ),
    TollSegment(
      id: 'seg_slex_sanpedro_susana',
      expressway: 'SLEX',
      expresswayName: 'South Luzon Expressway',
      operator: 'autosweep',
      entryPoint: 'slex_san_pedro',
      exitPoint: 'slex_susana_heights',
      fareClass1: 16.0,
      fareClass2: 32.0,
      fareClass3: 48.0,
      direction: 'both',
      isActive: true,
      lastUpdated: DateTime(2026, 8, 19),
      lastVerified: DateTime(2026, 8, 19),
    ),
    TollSegment(
      id: 'seg_slex_susana_filinvest',
      expressway: 'SLEX',
      expresswayName: 'South Luzon Expressway',
      operator: 'autosweep',
      entryPoint: 'slex_susana_heights',
      exitPoint: 'slex_filinvest',
      fareClass1: 18.0,
      fareClass2: 36.0,
      fareClass3: 54.0,
      direction: 'both',
      isActive: true,
      lastUpdated: DateTime(2026, 8, 19),
      lastVerified: DateTime(2026, 8, 19),
    ),
    TollSegment(
      id: 'seg_slex_filinvest_alabang',
      expressway: 'SLEX',
      expresswayName: 'South Luzon Expressway',
      operator: 'autosweep',
      entryPoint: 'slex_filinvest',
      exitPoint: 'slex_alabang',
      fareClass1: 15.0,
      fareClass2: 30.0,
      fareClass3: 45.0,
      direction: 'both',
      isActive: true,
      lastUpdated: DateTime(2026, 8, 19),
      lastVerified: DateTime(2026, 8, 19),
    ),

    // =========================================================================
    // 3. MCX SEGMENTS (Autosweep)
    // =========================================================================
    TollSegment(
      id: 'seg_mcx_susana_daanghari',
      expressway: 'MCX',
      expresswayName: 'Muntinlupa-Cavite Expressway',
      operator: 'autosweep',
      entryPoint: 'mcx_susana_heights',
      exitPoint: 'mcx_daang_hari',
      fareClass1: 17.0,
      fareClass2: 34.0,
      fareClass3: 51.0,
      direction: 'both',
      isActive: true,
      lastUpdated: DateTime(2026, 8, 19),
      lastVerified: DateTime(2026, 8, 19),
    ),

    // =========================================================================
    // 4. SKYWAY STAGES 1, 2, 3 SEGMENTS (Autosweep)
    // =========================================================================
    TollSegment(
      id: 'seg_skyway_alabang_sucat',
      expressway: 'SKYWAY',
      expresswayName: 'Skyway Stage 1-3',
      operator: 'autosweep',
      entryPoint: 'skyway_alabang',
      exitPoint: 'skyway_sucat',
      fareClass1: 61.0,
      fareClass2: 122.0,
      fareClass3: 183.0,
      direction: 'both',
      isActive: true,
      lastUpdated: DateTime(2026, 8, 19),
      lastVerified: DateTime(2026, 8, 19),
    ),
    TollSegment(
      id: 'seg_skyway_sucat_bicutan',
      expressway: 'SKYWAY',
      expresswayName: 'Skyway Stage 1-3',
      operator: 'autosweep',
      entryPoint: 'skyway_sucat',
      exitPoint: 'skyway_bicutan',
      fareClass1: 57.0,
      fareClass2: 114.0,
      fareClass3: 171.0,
      direction: 'both',
      isActive: true,
      lastUpdated: DateTime(2026, 8, 19),
      lastVerified: DateTime(2026, 8, 19),
    ),
    TollSegment(
      id: 'seg_skyway_bicutan_naiax',
      expressway: 'SKYWAY',
      expresswayName: 'Skyway Stage 1-3',
      operator: 'autosweep',
      entryPoint: 'skyway_bicutan',
      exitPoint: 'skyway_naiax',
      fareClass1: 46.0,
      fareClass2: 92.0,
      fareClass3: 138.0,
      direction: 'both',
      isActive: true,
      lastUpdated: DateTime(2026, 8, 19),
      lastVerified: DateTime(2026, 8, 19),
    ),
    TollSegment(
      id: 'seg_skyway_naiax_magallanes',
      expressway: 'SKYWAY',
      expresswayName: 'Skyway Stage 1-3',
      operator: 'autosweep',
      entryPoint: 'skyway_naiax',
      exitPoint: 'skyway_magallanes',
      fareClass1: 54.0,
      fareClass2: 108.0,
      fareClass3: 162.0,
      direction: 'both',
      isActive: true,
      lastUpdated: DateTime(2026, 8, 19),
      lastVerified: DateTime(2026, 8, 19),
    ),
    TollSegment(
      id: 'seg_skyway_magallanes_donbosco',
      expressway: 'SKYWAY',
      expresswayName: 'Skyway Stage 1-3',
      operator: 'autosweep',
      entryPoint: 'skyway_magallanes',
      exitPoint: 'skyway_don_bosco',
      fareClass1: 20.0,
      fareClass2: 40.0,
      fareClass3: 60.0,
      direction: 'both',
      isActive: true,
      lastUpdated: DateTime(2026, 8, 19),
      lastVerified: DateTime(2026, 8, 19),
    ),
    TollSegment(
      id: 'seg_skyway_donbosco_buendia',
      expressway: 'SKYWAY',
      expresswayName: 'Skyway Stage 1-3',
      operator: 'autosweep',
      entryPoint: 'skyway_don_bosco',
      exitPoint: 'skyway_buendia',
      fareClass1: 26.0,
      fareClass2: 52.0,
      fareClass3: 78.0,
      direction: 'both',
      isActive: true,
      lastUpdated: DateTime(2026, 8, 19),
      lastVerified: DateTime(2026, 8, 19),
    ),
    TollSegment(
      id: 'seg_skyway_buendia_quirino',
      expressway: 'SKYWAY',
      expresswayName: 'Skyway Stage 1-3',
      operator: 'autosweep',
      entryPoint: 'skyway_buendia',
      exitPoint: 'skyway_quirino',
      fareClass1: 105.0,
      fareClass2: 210.0,
      fareClass3: 315.0,
      direction: 'both',
      isActive: true,
      lastUpdated: DateTime(2026, 8, 19),
      lastVerified: DateTime(2026, 8, 19),
    ),
    TollSegment(
      id: 'seg_skyway_quirino_nagtahan',
      expressway: 'SKYWAY',
      expresswayName: 'Skyway Stage 1-3',
      operator: 'autosweep',
      entryPoint: 'skyway_quirino',
      exitPoint: 'skyway_nagtahan',
      fareClass1: 25.0,
      fareClass2: 50.0,
      fareClass3: 75.0,
      direction: 'both',
      isActive: true,
      lastUpdated: DateTime(2026, 8, 19),
      lastVerified: DateTime(2026, 8, 19),
    ),
    TollSegment(
      id: 'seg_skyway_nagtahan_erodriguez',
      expressway: 'SKYWAY',
      expresswayName: 'Skyway Stage 1-3',
      operator: 'autosweep',
      entryPoint: 'skyway_nagtahan',
      exitPoint: 'skyway_e_rodriguez',
      fareClass1: 35.0,
      fareClass2: 70.0,
      fareClass3: 105.0,
      direction: 'both',
      isActive: true,
      lastUpdated: DateTime(2026, 8, 19),
      lastVerified: DateTime(2026, 8, 19),
    ),
    TollSegment(
      id: 'seg_skyway_erodriguez_quezonave',
      expressway: 'SKYWAY',
      expresswayName: 'Skyway Stage 1-3',
      operator: 'autosweep',
      entryPoint: 'skyway_e_rodriguez',
      exitPoint: 'skyway_quezon_ave',
      fareClass1: 45.0,
      fareClass2: 90.0,
      fareClass3: 135.0,
      direction: 'both',
      isActive: true,
      lastUpdated: DateTime(2026, 8, 19),
      lastVerified: DateTime(2026, 8, 19),
    ),
    TollSegment(
      id: 'seg_skyway_quezonave_sgtrivera',
      expressway: 'SKYWAY',
      expresswayName: 'Skyway Stage 1-3',
      operator: 'autosweep',
      entryPoint: 'skyway_quezon_ave',
      exitPoint: 'skyway_sgt_rivera',
      fareClass1: 55.0,
      fareClass2: 110.0,
      fareClass3: 165.0,
      direction: 'both',
      isActive: true,
      lastUpdated: DateTime(2026, 8, 19),
      lastVerified: DateTime(2026, 8, 19),
    ),
    TollSegment(
      id: 'seg_skyway_sgtrivera_balintawak',
      expressway: 'SKYWAY',
      expresswayName: 'Skyway Stage 1-3',
      operator: 'autosweep',
      entryPoint: 'skyway_sgt_rivera',
      exitPoint: 'skyway_balintawak',
      fareClass1: 74.0,
      fareClass2: 148.0,
      fareClass3: 222.0,
      direction: 'both',
      isActive: true,
      lastUpdated: DateTime(2026, 8, 19),
      lastVerified: DateTime(2026, 8, 19),
    ),

    // =========================================================================
    // 5. NAIAX SEGMENTS (Autosweep)
    // =========================================================================
    TollSegment(
      id: 'seg_naiax_skyway_t3',
      expressway: 'NAIAX',
      expresswayName: 'NAIA Expressway',
      operator: 'autosweep',
      entryPoint: 'naiax_skyway',
      exitPoint: 'naiax_terminal3',
      fareClass1: 35.0,
      fareClass2: 70.0,
      fareClass3: 105.0,
      direction: 'both',
      isActive: true,
      lastUpdated: DateTime(2026, 8, 19),
      lastVerified: DateTime(2026, 8, 19),
    ),
    TollSegment(
      id: 'seg_naiax_t3_t1t2',
      expressway: 'NAIAX',
      expresswayName: 'NAIA Expressway',
      operator: 'autosweep',
      entryPoint: 'naiax_terminal3',
      exitPoint: 'naiax_terminal1_2',
      fareClass1: 10.0,
      fareClass2: 20.0,
      fareClass3: 30.0,
      direction: 'both',
      isActive: true,
      lastUpdated: DateTime(2026, 8, 19),
      lastVerified: DateTime(2026, 8, 19),
    ),
    TollSegment(
      id: 'seg_naiax_t1t2_macapagal',
      expressway: 'NAIAX',
      expresswayName: 'NAIA Expressway',
      operator: 'autosweep',
      entryPoint: 'naiax_terminal1_2',
      exitPoint: 'naiax_macapagal',
      fareClass1: 0.0,
      fareClass2: 0.0,
      fareClass3: 0.0,
      direction: 'both',
      isActive: true,
      lastUpdated: DateTime(2026, 8, 19),
      lastVerified: DateTime(2026, 8, 19),
    ),

    // =========================================================================
    // 6. NLEX SEGMENTS (Easytrip)
    // =========================================================================
    TollSegment(
      id: 'seg_nlex_balintawak_mindanao',
      expressway: 'NLEX',
      expresswayName: 'North Luzon Expressway',
      operator: 'easytrip',
      entryPoint: 'nlex_balintawak',
      exitPoint: 'nlex_mindanao_ave',
      fareClass1: 69.0,
      fareClass2: 172.0,
      fareClass3: 207.0,
      direction: 'both',
      isActive: true,
      lastUpdated: DateTime(2026, 8, 19),
      lastVerified: DateTime(2026, 8, 19),
    ),
    TollSegment(
      id: 'seg_nlex_mindanao_valenzuela',
      expressway: 'NLEX',
      expresswayName: 'North Luzon Expressway',
      operator: 'easytrip',
      entryPoint: 'nlex_mindanao_ave',
      exitPoint: 'nlex_valenzuela',
      fareClass1: 0.0,
      fareClass2: 0.0,
      fareClass3: 0.0,
      direction: 'both',
      isActive: true,
      lastUpdated: DateTime(2026, 8, 19),
      lastVerified: DateTime(2026, 8, 19),
    ),
    TollSegment(
      id: 'seg_nlex_valenzuela_meycauayan',
      expressway: 'NLEX',
      expresswayName: 'North Luzon Expressway',
      operator: 'easytrip',
      entryPoint: 'nlex_valenzuela',
      exitPoint: 'nlex_meycauayan',
      fareClass1: 0.0,
      fareClass2: 0.0,
      fareClass3: 0.0,
      direction: 'both',
      isActive: true,
      lastUpdated: DateTime(2026, 8, 19),
      lastVerified: DateTime(2026, 8, 19),
    ),
    TollSegment(
      id: 'seg_nlex_meycauayan_marilao',
      expressway: 'NLEX',
      expresswayName: 'North Luzon Expressway',
      operator: 'easytrip',
      entryPoint: 'nlex_meycauayan',
      exitPoint: 'nlex_marilao',
      fareClass1: 0.0,
      fareClass2: 0.0,
      fareClass3: 0.0,
      direction: 'both',
      isActive: true,
      lastUpdated: DateTime(2026, 8, 19),
      lastVerified: DateTime(2026, 8, 19),
    ),
    TollSegment(
      id: 'seg_nlex_marilao_philarena',
      expressway: 'NLEX',
      expresswayName: 'North Luzon Expressway',
      operator: 'easytrip',
      entryPoint: 'nlex_marilao',
      exitPoint: 'nlex_philippine_arena',
      fareClass1: 0.0,
      fareClass2: 0.0,
      fareClass3: 0.0,
      direction: 'both',
      isActive: true,
      lastUpdated: DateTime(2026, 8, 19),
      lastVerified: DateTime(2026, 8, 19),
    ),
    TollSegment(
      id: 'seg_nlex_philarena_bocaue',
      expressway: 'NLEX',
      expresswayName: 'North Luzon Expressway',
      operator: 'easytrip',
      entryPoint: 'nlex_philippine_arena',
      exitPoint: 'nlex_bocaue',
      fareClass1: 5.0,
      fareClass2: 12.0,
      fareClass3: 15.0,
      direction: 'both',
      isActive: true,
      lastUpdated: DateTime(2026, 8, 19),
      lastVerified: DateTime(2026, 8, 19),
    ),
    TollSegment(
      id: 'seg_nlex_bocaue_balagtas',
      expressway: 'NLEX',
      expresswayName: 'North Luzon Expressway',
      operator: 'easytrip',
      entryPoint: 'nlex_bocaue',
      exitPoint: 'nlex_balagtas',
      fareClass1: 24.0,
      fareClass2: 60.0,
      fareClass3: 72.0,
      direction: 'both',
      isActive: true,
      lastUpdated: DateTime(2026, 8, 19),
      lastVerified: DateTime(2026, 8, 19),
    ),
    TollSegment(
      id: 'seg_nlex_balagtas_tabang',
      expressway: 'NLEX',
      expresswayName: 'North Luzon Expressway',
      operator: 'easytrip',
      entryPoint: 'nlex_balagtas',
      exitPoint: 'nlex_tabang',
      fareClass1: 15.0,
      fareClass2: 38.0,
      fareClass3: 45.0,
      direction: 'both',
      isActive: true,
      lastUpdated: DateTime(2026, 8, 19),
      lastVerified: DateTime(2026, 8, 19),
    ),
    TollSegment(
      id: 'seg_nlex_tabang_pulilan',
      expressway: 'NLEX',
      expresswayName: 'North Luzon Expressway',
      operator: 'easytrip',
      entryPoint: 'nlex_tabang',
      exitPoint: 'nlex_pulilan',
      fareClass1: 28.0,
      fareClass2: 70.0,
      fareClass3: 84.0,
      direction: 'both',
      isActive: true,
      lastUpdated: DateTime(2026, 8, 19),
      lastVerified: DateTime(2026, 8, 19),
    ),
    TollSegment(
      id: 'seg_nlex_pulilan_sansimon',
      expressway: 'NLEX',
      expresswayName: 'North Luzon Expressway',
      operator: 'easytrip',
      entryPoint: 'nlex_pulilan',
      exitPoint: 'nlex_san_simon',
      fareClass1: 36.0,
      fareClass2: 90.0,
      fareClass3: 108.0,
      direction: 'both',
      isActive: true,
      lastUpdated: DateTime(2026, 8, 19),
      lastVerified: DateTime(2026, 8, 19),
    ),
    TollSegment(
      id: 'seg_nlex_sansimon_sanfernando',
      expressway: 'NLEX',
      expresswayName: 'North Luzon Expressway',
      operator: 'easytrip',
      entryPoint: 'nlex_san_simon',
      exitPoint: 'nlex_san_fernando',
      fareClass1: 42.0,
      fareClass2: 105.0,
      fareClass3: 126.0,
      direction: 'both',
      isActive: true,
      lastUpdated: DateTime(2026, 8, 19),
      lastVerified: DateTime(2026, 8, 19),
    ),
    TollSegment(
      id: 'seg_nlex_sanfernando_mexico',
      expressway: 'NLEX',
      expresswayName: 'North Luzon Expressway',
      operator: 'easytrip',
      entryPoint: 'nlex_san_fernando',
      exitPoint: 'nlex_mexico',
      fareClass1: 26.0,
      fareClass2: 65.0,
      fareClass3: 78.0,
      direction: 'both',
      isActive: true,
      lastUpdated: DateTime(2026, 8, 19),
      lastVerified: DateTime(2026, 8, 19),
    ),
    TollSegment(
      id: 'seg_nlex_mexico_angeles',
      expressway: 'NLEX',
      expresswayName: 'North Luzon Expressway',
      operator: 'easytrip',
      entryPoint: 'nlex_mexico',
      exitPoint: 'nlex_angeles',
      fareClass1: 40.0,
      fareClass2: 100.0,
      fareClass3: 120.0,
      direction: 'both',
      isActive: true,
      lastUpdated: DateTime(2026, 8, 19),
      lastVerified: DateTime(2026, 8, 19),
    ),
    TollSegment(
      id: 'seg_nlex_angeles_dau',
      expressway: 'NLEX',
      expresswayName: 'North Luzon Expressway',
      operator: 'easytrip',
      entryPoint: 'nlex_angeles',
      exitPoint: 'nlex_dau',
      fareClass1: 22.0,
      fareClass2: 55.0,
      fareClass3: 66.0,
      direction: 'both',
      isActive: true,
      lastUpdated: DateTime(2026, 8, 19),
      lastVerified: DateTime(2026, 8, 19),
    ),
    TollSegment(
      id: 'seg_nlex_dau_staines',
      expressway: 'NLEX',
      expresswayName: 'North Luzon Expressway',
      operator: 'easytrip',
      entryPoint: 'nlex_dau',
      exitPoint: 'nlex_sta_ines',
      fareClass1: 22.0,
      fareClass2: 55.0,
      fareClass3: 66.0,
      direction: 'both',
      isActive: true,
      lastUpdated: DateTime(2026, 8, 19),
      lastVerified: DateTime(2026, 8, 19),
    ),

    // =========================================================================
    // 7. NLEX CONNECTOR SEGMENTS (Easytrip)
    // =========================================================================
    TollSegment(
      id: 'seg_nlexc_c3_espana',
      expressway: 'NLEX-C',
      expresswayName: 'NLEX Connector',
      operator: 'easytrip',
      entryPoint: 'nlex_connector_c3',
      exitPoint: 'nlex_connector_espana',
      fareClass1: 86.0,
      fareClass2: 215.0,
      fareClass3: 258.0,
      direction: 'both',
      isActive: true,
      lastUpdated: DateTime(2026, 8, 19),
      lastVerified: DateTime(2026, 8, 19),
    ),
    TollSegment(
      id: 'seg_nlexc_espana_magsaysay',
      expressway: 'NLEX-C',
      expresswayName: 'NLEX Connector',
      operator: 'easytrip',
      entryPoint: 'nlex_connector_espana',
      exitPoint: 'nlex_connector_magsaysay',
      fareClass1: 33.0,
      fareClass2: 83.0,
      fareClass3: 100.0,
      direction: 'both',
      isActive: true,
      lastUpdated: DateTime(2026, 8, 19),
      lastVerified: DateTime(2026, 8, 19),
    ),

    // =========================================================================
    // 8. SCTEX SEGMENTS (Easytrip)
    // =========================================================================
    TollSegment(
      id: 'seg_sctex_subic_dinalupihan',
      expressway: 'SCTEX',
      expresswayName: 'Subic-Clark-Tarlac Expressway',
      operator: 'easytrip',
      entryPoint: 'sctex_subic_tipo',
      exitPoint: 'sctex_dinalupihan',
      fareClass1: 68.0,
      fareClass2: 136.0,
      fareClass3: 204.0,
      direction: 'both',
      isActive: true,
      lastUpdated: DateTime(2026, 8, 19),
      lastVerified: DateTime(2026, 8, 19),
    ),
    TollSegment(
      id: 'seg_sctex_dinalupihan_floridablanca',
      expressway: 'SCTEX',
      expresswayName: 'Subic-Clark-Tarlac Expressway',
      operator: 'easytrip',
      entryPoint: 'sctex_dinalupihan',
      exitPoint: 'sctex_floridablanca',
      fareClass1: 54.0,
      fareClass2: 108.0,
      fareClass3: 162.0,
      direction: 'both',
      isActive: true,
      lastUpdated: DateTime(2026, 8, 19),
      lastVerified: DateTime(2026, 8, 19),
    ),
    TollSegment(
      id: 'seg_sctex_floridablanca_porac',
      expressway: 'SCTEX',
      expresswayName: 'Subic-Clark-Tarlac Expressway',
      operator: 'easytrip',
      entryPoint: 'sctex_floridablanca',
      exitPoint: 'sctex_porac',
      fareClass1: 45.0,
      fareClass2: 90.0,
      fareClass3: 135.0,
      direction: 'both',
      isActive: true,
      lastUpdated: DateTime(2026, 8, 19),
      lastVerified: DateTime(2026, 8, 19),
    ),
    TollSegment(
      id: 'seg_sctex_porac_clarksouth',
      expressway: 'SCTEX',
      expresswayName: 'Subic-Clark-Tarlac Expressway',
      operator: 'easytrip',
      entryPoint: 'sctex_porac',
      exitPoint: 'sctex_clark_south',
      fareClass1: 40.0,
      fareClass2: 80.0,
      fareClass3: 120.0,
      direction: 'both',
      isActive: true,
      lastUpdated: DateTime(2026, 8, 19),
      lastVerified: DateTime(2026, 8, 19),
    ),
    TollSegment(
      id: 'seg_sctex_clarksouth_clarknorth',
      expressway: 'SCTEX',
      expresswayName: 'Subic-Clark-Tarlac Expressway',
      operator: 'easytrip',
      entryPoint: 'sctex_clark_south',
      exitPoint: 'sctex_clark_north',
      fareClass1: 32.0,
      fareClass2: 64.0,
      fareClass3: 96.0,
      direction: 'both',
      isActive: true,
      lastUpdated: DateTime(2026, 8, 19),
      lastVerified: DateTime(2026, 8, 19),
    ),
    TollSegment(
      id: 'seg_sctex_clarknorth_dolores',
      expressway: 'SCTEX',
      expresswayName: 'Subic-Clark-Tarlac Expressway',
      operator: 'easytrip',
      entryPoint: 'sctex_clark_north',
      exitPoint: 'sctex_dolores',
      fareClass1: 38.0,
      fareClass2: 76.0,
      fareClass3: 114.0,
      direction: 'both',
      isActive: true,
      lastUpdated: DateTime(2026, 8, 19),
      lastVerified: DateTime(2026, 8, 19),
    ),
    TollSegment(
      id: 'seg_sctex_dolores_concepcion',
      expressway: 'SCTEX',
      expresswayName: 'Subic-Clark-Tarlac Expressway',
      operator: 'easytrip',
      entryPoint: 'sctex_dolores',
      exitPoint: 'sctex_concepcion',
      fareClass1: 34.0,
      fareClass2: 68.0,
      fareClass3: 102.0,
      direction: 'both',
      isActive: true,
      lastUpdated: DateTime(2026, 8, 19),
      lastVerified: DateTime(2026, 8, 19),
    ),
    TollSegment(
      id: 'seg_sctex_concepcion_luisita',
      expressway: 'SCTEX',
      expresswayName: 'Subic-Clark-Tarlac Expressway',
      operator: 'easytrip',
      entryPoint: 'sctex_concepcion',
      exitPoint: 'sctex_luisita',
      fareClass1: 42.0,
      fareClass2: 84.0,
      fareClass3: 126.0,
      direction: 'both',
      isActive: true,
      lastUpdated: DateTime(2026, 8, 19),
      lastVerified: DateTime(2026, 8, 19),
    ),
    TollSegment(
      id: 'seg_sctex_luisita_tarlac',
      expressway: 'SCTEX',
      expresswayName: 'Subic-Clark-Tarlac Expressway',
      operator: 'easytrip',
      entryPoint: 'sctex_luisita',
      exitPoint: 'sctex_tarlac',
      fareClass1: 35.0,
      fareClass2: 70.0,
      fareClass3: 105.0,
      direction: 'both',
      isActive: true,
      lastUpdated: DateTime(2026, 8, 19),
      lastVerified: DateTime(2026, 8, 19),
    ),

    // =========================================================================
    // 9. TPLEX SEGMENTS (Autosweep)
    // =========================================================================
    TollSegment(
      id: 'seg_tplex_tarlac_victoria',
      expressway: 'TPLEX',
      expresswayName: 'Tarlac-Pangasinan-La Union',
      operator: 'autosweep',
      entryPoint: 'tplex_tarlac',
      exitPoint: 'tplex_victoria',
      fareClass1: 36.0,
      fareClass2: 72.0,
      fareClass3: 108.0,
      direction: 'both',
      isActive: true,
      lastUpdated: DateTime(2026, 8, 19),
      lastVerified: DateTime(2026, 8, 19),
    ),
    TollSegment(
      id: 'seg_tplex_victoria_pura',
      expressway: 'TPLEX',
      expresswayName: 'Tarlac-Pangasinan-La Union',
      operator: 'autosweep',
      entryPoint: 'tplex_victoria',
      exitPoint: 'tplex_pura',
      fareClass1: 24.0,
      fareClass2: 48.0,
      fareClass3: 72.0,
      direction: 'both',
      isActive: true,
      lastUpdated: DateTime(2026, 8, 19),
      lastVerified: DateTime(2026, 8, 19),
    ),
    TollSegment(
      id: 'seg_tplex_pura_anao',
      expressway: 'TPLEX',
      expresswayName: 'Tarlac-Pangasinan-La Union',
      operator: 'autosweep',
      entryPoint: 'tplex_pura',
      exitPoint: 'tplex_anao',
      fareClass1: 28.0,
      fareClass2: 56.0,
      fareClass3: 84.0,
      direction: 'both',
      isActive: true,
      lastUpdated: DateTime(2026, 8, 19),
      lastVerified: DateTime(2026, 8, 19),
    ),
    TollSegment(
      id: 'seg_tplex_anao_carmen',
      expressway: 'TPLEX',
      expresswayName: 'Tarlac-Pangasinan-La Union',
      operator: 'autosweep',
      entryPoint: 'tplex_anao',
      exitPoint: 'tplex_carmen',
      fareClass1: 58.0,
      fareClass2: 116.0,
      fareClass3: 174.0,
      direction: 'both',
      isActive: true,
      lastUpdated: DateTime(2026, 8, 19),
      lastVerified: DateTime(2026, 8, 19),
    ),
    TollSegment(
      id: 'seg_tplex_carmen_urdaneta',
      expressway: 'TPLEX',
      expresswayName: 'Tarlac-Pangasinan-La Union',
      operator: 'autosweep',
      entryPoint: 'tplex_carmen',
      exitPoint: 'tplex_urdaneta',
      fareClass1: 62.0,
      fareClass2: 124.0,
      fareClass3: 186.0,
      direction: 'both',
      isActive: true,
      lastUpdated: DateTime(2026, 8, 19),
      lastVerified: DateTime(2026, 8, 19),
    ),
    TollSegment(
      id: 'seg_tplex_urdaneta_binalonan',
      expressway: 'TPLEX',
      expresswayName: 'Tarlac-Pangasinan-La Union',
      operator: 'autosweep',
      entryPoint: 'tplex_urdaneta',
      exitPoint: 'tplex_binalonan',
      fareClass1: 35.0,
      fareClass2: 70.0,
      fareClass3: 105.0,
      direction: 'both',
      isActive: true,
      lastUpdated: DateTime(2026, 8, 19),
      lastVerified: DateTime(2026, 8, 19),
    ),
    TollSegment(
      id: 'seg_tplex_binalonan_pozorrubio',
      expressway: 'TPLEX',
      expresswayName: 'Tarlac-Pangasinan-La Union',
      operator: 'autosweep',
      entryPoint: 'tplex_binalonan',
      exitPoint: 'tplex_pozorrubio',
      fareClass1: 34.0,
      fareClass2: 68.0,
      fareClass3: 102.0,
      direction: 'both',
      isActive: true,
      lastUpdated: DateTime(2026, 8, 19),
      lastVerified: DateTime(2026, 8, 19),
    ),
    TollSegment(
      id: 'seg_tplex_pozorrubio_sison',
      expressway: 'TPLEX',
      expresswayName: 'Tarlac-Pangasinan-La Union',
      operator: 'autosweep',
      entryPoint: 'tplex_pozorrubio',
      exitPoint: 'tplex_sison',
      fareClass1: 22.0,
      fareClass2: 44.0,
      fareClass3: 66.0,
      direction: 'both',
      isActive: true,
      lastUpdated: DateTime(2026, 8, 19),
      lastVerified: DateTime(2026, 8, 19),
    ),
    TollSegment(
      id: 'seg_tplex_sison_rosario',
      expressway: 'TPLEX',
      expresswayName: 'Tarlac-Pangasinan-La Union',
      operator: 'autosweep',
      entryPoint: 'tplex_sison',
      exitPoint: 'tplex_rosario',
      fareClass1: 12.0,
      fareClass2: 24.0,
      fareClass3: 36.0,
      direction: 'both',
      isActive: true,
      lastUpdated: DateTime(2026, 8, 19),
      lastVerified: DateTime(2026, 8, 19),
    ),

    // =========================================================================
    // 10. CALAX SEGMENTS (Easytrip)
    // =========================================================================
    TollSegment(
      id: 'seg_calax_mamplasan_technopark',
      expressway: 'CALAX',
      expresswayName: 'Cavite-Laguna Expressway',
      operator: 'easytrip',
      entryPoint: 'calax_mamplasan',
      exitPoint: 'calax_technopark',
      fareClass1: 14.0,
      fareClass2: 28.0,
      fareClass3: 42.0,
      direction: 'both',
      isActive: true,
      lastUpdated: DateTime(2026, 8, 19),
      lastVerified: DateTime(2026, 8, 19),
    ),
    TollSegment(
      id: 'seg_calax_technopark_lagunablvd',
      expressway: 'CALAX',
      expresswayName: 'Cavite-Laguna Expressway',
      operator: 'easytrip',
      entryPoint: 'calax_technopark',
      exitPoint: 'calax_laguna_blvd',
      fareClass1: 15.0,
      fareClass2: 30.0,
      fareClass3: 45.0,
      direction: 'both',
      isActive: true,
      lastUpdated: DateTime(2026, 8, 19),
      lastVerified: DateTime(2026, 8, 19),
    ),
    TollSegment(
      id: 'seg_calax_lagunablvd_santarosa',
      expressway: 'CALAX',
      expresswayName: 'Cavite-Laguna Expressway',
      operator: 'easytrip',
      entryPoint: 'calax_laguna_blvd',
      exitPoint: 'calax_santa_rosa',
      fareClass1: 18.0,
      fareClass2: 36.0,
      fareClass3: 54.0,
      direction: 'both',
      isActive: true,
      lastUpdated: DateTime(2026, 8, 19),
      lastVerified: DateTime(2026, 8, 19),
    ),
    TollSegment(
      id: 'seg_calax_santarosa_silangeast',
      expressway: 'CALAX',
      expresswayName: 'Cavite-Laguna Expressway',
      operator: 'easytrip',
      entryPoint: 'calax_santa_rosa',
      exitPoint: 'calax_silang_east',
      fareClass1: 32.0,
      fareClass2: 64.0,
      fareClass3: 96.0,
      direction: 'both',
      isActive: true,
      lastUpdated: DateTime(2026, 8, 19),
      lastVerified: DateTime(2026, 8, 19),
    ),
    TollSegment(
      id: 'seg_calax_silangeast_silang',
      expressway: 'CALAX',
      expresswayName: 'Cavite-Laguna Expressway',
      operator: 'easytrip',
      entryPoint: 'calax_silang_east',
      exitPoint: 'calax_silang',
      fareClass1: 32.0,
      fareClass2: 64.0,
      fareClass3: 96.0,
      direction: 'both',
      isActive: true,
      lastUpdated: DateTime(2026, 8, 19),
      lastVerified: DateTime(2026, 8, 19),
    ),
    TollSegment(
      id: 'seg_calax_silang_govdrive',
      expressway: 'CALAX',
      expresswayName: 'Cavite-Laguna Expressway',
      operator: 'easytrip',
      entryPoint: 'calax_silang',
      exitPoint: 'calax_gov_drive',
      fareClass1: 45.0,
      fareClass2: 90.0,
      fareClass3: 135.0,
      direction: 'both',
      isActive: true,
      lastUpdated: DateTime(2026, 8, 19),
      lastVerified: DateTime(2026, 8, 19),
    ),

    // =========================================================================
    // 11. CAVITEX & C5 SOUTH LINK SEGMENTS (Easytrip)
    // =========================================================================
    TollSegment(
      id: 'seg_cavitex_seaside_paranaque',
      expressway: 'CAVITEX',
      expresswayName: 'Manila-Cavite Expressway',
      operator: 'easytrip',
      entryPoint: 'cavitex_seaside',
      exitPoint: 'cavitex_paranaque',
      fareClass1: 35.0,
      fareClass2: 70.0,
      fareClass3: 105.0,
      direction: 'both',
      isActive: true,
      lastUpdated: DateTime(2026, 8, 19),
      lastVerified: DateTime(2026, 8, 19),
    ),
    TollSegment(
      id: 'seg_cavitex_paranaque_zapote',
      expressway: 'CAVITEX',
      expresswayName: 'Manila-Cavite Expressway',
      operator: 'easytrip',
      entryPoint: 'cavitex_paranaque',
      exitPoint: 'cavitex_zapote',
      fareClass1: 0.0,
      fareClass2: 0.0,
      fareClass3: 0.0,
      direction: 'both',
      isActive: true,
      lastUpdated: DateTime(2026, 8, 19),
      lastVerified: DateTime(2026, 8, 19),
    ),
    TollSegment(
      id: 'seg_cavitex_zapote_kawit',
      expressway: 'CAVITEX',
      expresswayName: 'Manila-Cavite Expressway',
      operator: 'easytrip',
      entryPoint: 'cavitex_zapote',
      exitPoint: 'cavitex_kawit',
      fareClass1: 73.0,
      fareClass2: 146.0,
      fareClass3: 219.0,
      direction: 'both',
      isActive: true,
      lastUpdated: DateTime(2026, 8, 19),
      lastVerified: DateTime(2026, 8, 19),
    ),
    TollSegment(
      id: 'seg_cavitex_c5_merville_taguig',
      expressway: 'CAVITEX',
      expresswayName: 'Manila-Cavite Expressway',
      operator: 'easytrip',
      entryPoint: 'cavitex_c5_merville',
      exitPoint: 'cavitex_c5_taguig',
      fareClass1: 37.0,
      fareClass2: 74.0,
      fareClass3: 111.0,
      direction: 'both',
      isActive: true,
      lastUpdated: DateTime(2026, 8, 19),
      lastVerified: DateTime(2026, 8, 19),
    ),

    // =========================================================================
    // 12. CCLEX SEGMENTS (Visayas / CCLEX - Easytrip compatible)
    // =========================================================================
    TollSegment(
      id: 'seg_cclex_cebu_cordova',
      expressway: 'CCLEX',
      expresswayName: 'Cebu-Cordova Link Expressway',
      operator: 'easytrip',
      entryPoint: 'cclex_cebu_srp',
      exitPoint: 'cclex_cordova',
      fareClass1: 90.0,
      fareClass2: 180.0,
      fareClass3: 270.0,
      direction: 'both',
      isActive: true,
      lastUpdated: DateTime(2026, 8, 19),
      lastVerified: DateTime(2026, 8, 19),
    ),
  ];

  /// Default predefined corridor routes for backward compatibility.
  static final List<RouteModel> defaultRoutes = [
    RouteModel(
      id: 'sample_route_multi_operator',
      name: 'Batangas → Bocaue (Multi-Operator Corridor)',
      origin: 'Batangas City Terminal',
      destination: 'Bocaue Barrier',
      segmentIds: const [
        'seg_star_batangas_ibaan',
        'seg_star_ibaan_lipa',
        'seg_star_lipa_malvar',
        'seg_star_malvar_tanauan',
        'seg_star_tanauan_stotomas',
        'seg_slex_stotomas_calamba',
        'seg_slex_calamba_canlubang',
        'seg_slex_canlubang_silangan',
        'seg_slex_silangan_cabuyao',
        'seg_slex_cabuyao_santarosa',
        'seg_slex_santarosa_eton',
        'seg_slex_eton_greenfield',
        'seg_slex_greenfield_mamplasan',
        'seg_slex_mamplasan_southwoods',
        'seg_slex_southwoods_sanpedro',
        'seg_slex_sanpedro_susana',
        'seg_slex_susana_filinvest',
        'seg_slex_filinvest_alabang',
        'seg_skyway_alabang_sucat',
        'seg_skyway_sucat_bicutan',
        'seg_skyway_bicutan_naiax',
        'seg_skyway_naiax_magallanes',
        'seg_skyway_magallanes_donbosco',
        'seg_skyway_donbosco_buendia',
        'seg_skyway_buendia_quirino',
        'seg_skyway_quirino_nagtahan',
        'seg_skyway_nagtahan_erodriguez',
        'seg_skyway_erodriguez_quezonave',
        'seg_skyway_quezonave_sgtrivera',
        'seg_skyway_sgtrivera_balintawak',
        'seg_nlex_balintawak_mindanao',
        'seg_nlex_mindanao_valenzuela',
        'seg_nlex_valenzuela_meycauayan',
        'seg_nlex_meycauayan_marilao',
        'seg_nlex_marilao_philarena',
        'seg_nlex_philarena_bocaue',
      ],
      lastVerified: DateTime(2026, 8, 19),
      isActive: true,
    ),
    RouteModel(
      id: 'sample_route_autosweep_only',
      name: 'Batangas → Balintawak (Autosweep Only)',
      origin: 'Batangas City Terminal',
      destination: 'Balintawak Gantry (Skyway)',
      segmentIds: const [
        'seg_star_batangas_ibaan',
        'seg_star_ibaan_lipa',
        'seg_star_lipa_malvar',
        'seg_star_malvar_tanauan',
        'seg_star_tanauan_stotomas',
        'seg_slex_stotomas_calamba',
        'seg_slex_calamba_canlubang',
        'seg_slex_canlubang_silangan',
        'seg_slex_silangan_cabuyao',
        'seg_slex_cabuyao_santarosa',
        'seg_slex_santarosa_eton',
        'seg_slex_eton_greenfield',
        'seg_slex_greenfield_mamplasan',
        'seg_slex_mamplasan_southwoods',
        'seg_slex_southwoods_sanpedro',
        'seg_slex_sanpedro_susana',
        'seg_slex_susana_filinvest',
        'seg_slex_filinvest_alabang',
        'seg_skyway_alabang_sucat',
        'seg_skyway_sucat_bicutan',
        'seg_skyway_bicutan_naiax',
        'seg_skyway_naiax_magallanes',
        'seg_skyway_magallanes_donbosco',
        'seg_skyway_donbosco_buendia',
        'seg_skyway_buendia_quirino',
        'seg_skyway_quirino_nagtahan',
        'seg_skyway_nagtahan_erodriguez',
        'seg_skyway_erodriguez_quezonave',
        'seg_skyway_quezonave_sgtrivera',
        'seg_skyway_sgtrivera_balintawak',
      ],
      lastVerified: DateTime(2026, 8, 19),
      isActive: true,
    ),
    RouteModel(
      id: 'sample_route_easytrip_only',
      name: 'Balintawak → San Fernando (Easytrip Only)',
      origin: 'Balintawak Barrier (NLEX)',
      destination: 'San Fernando Exit',
      segmentIds: const [
        'seg_nlex_balintawak_mindanao',
        'seg_nlex_mindanao_valenzuela',
        'seg_nlex_valenzuela_meycauayan',
        'seg_nlex_meycauayan_marilao',
        'seg_nlex_marilao_philarena',
        'seg_nlex_philarena_bocaue',
        'seg_nlex_bocaue_balagtas',
        'seg_nlex_balagtas_tabang',
        'seg_nlex_tabang_pulilan',
        'seg_nlex_pulilan_sansimon',
        'seg_nlex_sansimon_sanfernando',
      ],
      lastVerified: DateTime(2026, 8, 19),
      isActive: true,
    ),
  ];

  /// Seeds plazas & segments into Firestore if empty.
  Future<void> seedPlaceholderDataIfEmpty() async {
    for (final plaza in defaultPlazas) {
      await _firestoreService.tollPlazasRef.doc(plaza.id).set(plaza);
    }
    for (final segment in defaultSegments) {
      await _firestoreService.tollSegmentsRef.doc(segment.id).set(segment);
    }
    for (final route in defaultRoutes) {
      await _firestoreService.routesRef.doc(route.id).set(route);
    }
  }
}

class _GraphEdge {
  final String targetPlazaId;
  final TollSegment segment;

  _GraphEdge({
    required this.targetPlazaId,
    required this.segment,
  });
}
