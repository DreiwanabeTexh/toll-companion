import '../models/toll_plaza.dart';
import '../models/toll_segment.dart';
import '../models/toll_charge_rule.dart';
import '../models/toll_charge_breakdown.dart';
import '../models/route_model.dart';
import '../models/route_result.dart';
import '../models/route_calculation_debug.dart';
import '../data/toll_rates_data.dart';
import 'firestore_service.dart';
import 'cache_service.dart';

/// Internal graph edge representation for Dijkstra routing
class _DijkstraEdge {
  final String targetPlazaId;
  final double weightKm;
  final TollSegment segment;

  const _DijkstraEdge({
    required this.targetPlazaId,
    required this.weightKm,
    required this.segment,
  });
}

/// Data and routing engine service for the Toll Calculator.
///
/// Implements:
/// 1. Physical navigation graph traversal using Dijkstra's shortest-path algorithm (weighted by distance).
/// 2. Toll charging engine based on Philippine TRB toll collection rules:
///    - Closed-system exact Origin-Destination (OD) fare lookups (STAR, SLEX, CALAX, SCTEX, TPLEX)
///    - Open-system flat barrier charges and deduplication (NLEX Open, Skyway 1-3, MCX, NAIAX, NLEX-C)
/// 3. Strict per-operator partitioning (Autosweep vs Easytrip).
/// 4. Offline resilience with local SharedPreferences caching and embedded fallback catalog.
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
  // PLAZAS & TOLL RULES STREAM & CACHE GETTERS
  // ===========================================================================

  /// Fetches all active toll plazas from Firestore.
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
  Future<List<TollPlaza>> getCachedPlazas() async {
    final cached = await _cacheService.getPlazas();
    if (cached != null && cached.isNotEmpty) {
      return cached;
    }
    return defaultPlazas;
  }

  /// Fetches active toll charge rules from Firestore.
  Stream<List<TollChargeRule>> getActiveTollRules() {
    try {
      return _firestoreService.tollChargeRulesRef
          .where('isActive', isEqualTo: true)
          .snapshots()
          .map((snapshot) {
        final rules = snapshot.docs.map((doc) => doc.data()).toList();
        if (rules.isNotEmpty) {
          _cacheService.saveTollRules(rules);
        }
        return rules.isNotEmpty ? rules : defaultTollRules;
      }).handleError((_) => defaultTollRules);
    } catch (_) {
      return Stream.value(defaultTollRules);
    }
  }

  /// Retrieves locally cached toll charge rules if offline.
  Future<List<TollChargeRule>> getCachedTollRules() async {
    final cached = await _cacheService.getTollRules();
    if (cached != null && cached.isNotEmpty) {
      return cached;
    }
    return defaultTollRules;
  }

  // ===========================================================================
  // 1. DIJKSTRA-BASED PHYSICAL ROAD GRAPH NAVIGATION
  // ===========================================================================

  /// Synchronously finds the optimal physical road path of [TollSegment]s from
  /// [originPlazaId] to [destinationPlazaId] using Dijkstra's shortest-path algorithm.
  List<TollSegment> findPathSync(
    String originPlazaId,
    String destinationPlazaId, {
    List<TollPlaza>? plazas,
    List<TollSegment>? segments,
    bool useSkyway = true,
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

    final originIsSkyway = originPlazaId.startsWith('skyway_');
    final destIsSkyway = destinationPlazaId.startsWith('skyway_');
    final originIsAtGrade = originPlazaId == 'slex_magallanes' || originPlazaId.contains('atgrade');
    final destIsAtGrade = destinationPlazaId == 'slex_magallanes' || destinationPlazaId.contains('atgrade');
    final allowSkyway = useSkyway || originIsSkyway || destIsSkyway;

    // Build directed weighted adjacency graph
    final Map<String, List<_DijkstraEdge>> adj = {};
    for (final p in allPlazas) {
      adj[p.id] = [];
    }

    for (final seg in allSegments) {
      // If user opted out of Skyway and neither origin nor destination is on Skyway, exclude Skyway segments
      if (!allowSkyway && seg.expressway == 'SKYWAY') {
        continue;
      }

      final u = seg.entryPoint;
      final v = seg.exitPoint;
      final weight = seg.effectiveDistanceKm;

      if (adj.containsKey(u) && adj.containsKey(v)) {
        adj[u]!.add(_DijkstraEdge(targetPlazaId: v, weightKm: weight, segment: seg));
        if (seg.direction == 'both') {
          final reverseSeg = TollSegment(
            id: '${seg.id}_rev',
            expressway: seg.expressway,
            expresswayName: seg.expresswayName,
            operator: seg.operator,
            entryPoint: v,
            exitPoint: u,
            distanceKm: seg.distanceKm,
            direction: 'both',
            isActive: seg.isActive,
            lastUpdated: seg.lastUpdated,
            lastVerified: seg.lastVerified,
            notes: seg.notes,
          );
          adj[v]!.add(_DijkstraEdge(targetPlazaId: u, weightKm: weight, segment: reverseSeg));
        }
      }
    }

    // Add zero-distance interchange connectors between connecting plazas
    for (final p in allPlazas) {
      for (final targetId in p.connectsTo) {
        // If user opted out of Skyway, exclude transfers into or out of Skyway
        if (!allowSkyway && (p.id.startsWith('skyway_') || targetId.startsWith('skyway_'))) {
          continue;
        }

        // When Skyway is enabled, do not shortcut elevated corridor via surface SLEX-NLEX connector
        if (allowSkyway && !originIsAtGrade && !destIsAtGrade) {
          if ((p.id == 'slex_magallanes' && targetId == 'nlex_balintawak') ||
              (p.id == 'nlex_balintawak' && targetId == 'slex_magallanes')) {
            continue;
          }
        }

        if (adj.containsKey(p.id) && adj.containsKey(targetId)) {
          final targetPlaza = plazaMap[targetId];
          final connectorSeg = TollSegment(
            id: 'interchange_${p.id}_$targetId',
            expressway: targetPlaza?.expressway ?? p.expressway,
            expresswayName: 'Interchange Connector',
            operator: targetPlaza?.operator ?? p.operator,
            entryPoint: p.id,
            exitPoint: targetId,
            distanceKm: 0.1, // Zero-cost connector
            direction: 'both',
            isActive: true,
            lastUpdated: DateTime(2026, 8, 19),
            lastVerified: DateTime(2026, 8, 19),
            notes: 'Transfer between ${p.expressway} and ${targetPlaza?.expressway}',
          );
          adj[p.id]!.add(_DijkstraEdge(targetPlazaId: targetId, weightKm: 0.1, segment: connectorSeg));
        }
      }
    }

    // Dijkstra's Shortest Path Algorithm
    final Map<String, double> dist = {originPlazaId: 0.0};
    final Map<String, _DijkstraEdge> parentEdge = {};
    final Set<String> settled = {};
    final List<String> queue = [originPlazaId];

    while (queue.isNotEmpty) {
      // Find unvisited node with minimum distance
      queue.sort((a, b) => (dist[a] ?? double.infinity).compareTo(dist[b] ?? double.infinity));
      final current = queue.removeAt(0);

      if (settled.contains(current)) continue;
      settled.add(current);

      if (current == destinationPlazaId) {
        break;
      }

      final currentDist = dist[current] ?? double.infinity;
      for (final edge in adj[current] ?? []) {
        if (settled.contains(edge.targetPlazaId)) continue;

        final newDist = currentDist + edge.weightKm;
        if (newDist < (dist[edge.targetPlazaId] ?? double.infinity)) {
          dist[edge.targetPlazaId] = newDist;
          parentEdge[edge.targetPlazaId] = edge;
          if (!queue.contains(edge.targetPlazaId)) {
            queue.add(edge.targetPlazaId);
          }
        }
      }
    }

    if (!dist.containsKey(destinationPlazaId)) {
      return [];
    }

    // Reconstruct path
    final List<TollSegment> path = [];
    String curr = destinationPlazaId;
    while (curr != originPlazaId) {
      final edge = parentEdge[curr];
      if (edge == null) break;
      if (!edge.segment.id.startsWith('interchange_')) {
        path.insert(0, edge.segment);
      }
      curr = edge.segment.entryPoint;
    }

    return path;
  }

  /// Finds the optimal physical road path connecting [originPlazaId] to [destinationPlazaId].
  Future<List<TollSegment>> findPathBetweenPlazas(
    String originPlazaId,
    String destinationPlazaId, {
    bool useSkyway = true,
  }) async {
    final allPlazas = await getCachedPlazas();
    return findPathSync(
      originPlazaId,
      destinationPlazaId,
      plazas: allPlazas,
      useSkyway: useSkyway,
    );
  }

  // ===========================================================================
  // 2. TOLL CHARGE CALCULATION ENGINE (PHILIPPINE TRB RULES)
  // ===========================================================================

  /// Synchronously calculates the itemized toll charges and fare breakdown for a resolved route.
  RouteResult calculateRouteChargesSync({
    required List<TollSegment> segments,
    required String originPlazaId,
    required String destinationPlazaId,
    int vehicleClass = 1,
    List<TollPlaza>? plazas,
    List<TollChargeRule>? rules,
    bool useSkyway = true,
  }) {
    // 0. Same origin and destination check
    if (originPlazaId == destinationPlazaId) {
      return RouteResult.calculate(
        segments: [],
        tollCharges: [],
        orderedPlazaIds: [originPlazaId],
        warnings: [],
        vehicleClass: vehicleClass,
        debugInfo: RouteCalculationDebug(
          chosenOrderedPlazaPath: [originPlazaId],
          excludedPathAlternatives: [],
          matchedRuleIds: [],
          consideredNotChargedRules: [],
          operatorSubtotalCalculations: {
            'autosweep': [],
            'easytrip': [],
          },
        ),
      );
    }

    if (segments.isEmpty) {
      return RouteResult.calculate(
        segments: [],
        tollCharges: [],
        orderedPlazaIds: [originPlazaId, destinationPlazaId],
        warnings: [
          'Fare data unavailable: No valid road path found connecting $originPlazaId to $destinationPlazaId.'
        ],
        vehicleClass: vehicleClass,
        debugInfo: RouteCalculationDebug(
          chosenOrderedPlazaPath: [originPlazaId, destinationPlazaId],
          excludedPathAlternatives: [],
          matchedRuleIds: [],
          consideredNotChargedRules: [],
          operatorSubtotalCalculations: {
            'autosweep': [],
            'easytrip': [],
          },
        ),
      );
    }

    final allPlazas = plazas ?? defaultPlazas;
    final allRules = rules ?? defaultTollRules;
    final plazaMap = {for (final p in allPlazas) p.id: p};

    // 1. Reconstruct ordered list of traversed plazas
    final List<String> orderedPlazas = [originPlazaId];
    for (final seg in segments) {
      if (orderedPlazas.isEmpty || orderedPlazas.last != seg.entryPoint) {
        if (!orderedPlazas.contains(seg.entryPoint)) {
          orderedPlazas.add(seg.entryPoint);
        }
      }
      if (!orderedPlazas.contains(seg.exitPoint)) {
        orderedPlazas.add(seg.exitPoint);
      }
    }
    if (orderedPlazas.last != destinationPlazaId) {
      orderedPlazas.add(destinationPlazaId);
    }

    final List<TollChargeBreakdown> chargeList = [];
    final List<String> warnings = [];
    final Set<String> appliedRuleIds = {};
    final List<Map<String, String>> excludedAlternatives = [];
    final List<Map<String, String>> consideredNotCharged = [];

    // Document routing mode alternatives
    if (!useSkyway) {
      excludedAlternatives.add({
        'path': 'Skyway Stages 1–3 Elevated Viaduct',
        'reason': 'Excluded per user preference (useSkyway=false). Route routed via SLEX At-Grade surface road.',
      });
    } else {
      excludedAlternatives.add({
        'path': 'SLEX At-Grade Surface Section',
        'reason': 'Elevated Skyway viaduct selected for direct elevated transit.',
      });
    }

    // 2. Group contiguous segments by expressway corridor
    final List<List<TollSegment>> corridors = [];
    List<TollSegment> currentCorridor = [];

    for (final seg in segments) {
      if (currentCorridor.isEmpty) {
        currentCorridor.add(seg);
      } else if (currentCorridor.last.expressway == seg.expressway) {
        currentCorridor.add(seg);
      } else {
        corridors.add(List.from(currentCorridor));
        currentCorridor = [seg];
      }
    }
    if (currentCorridor.isNotEmpty) {
      corridors.add(currentCorridor);
    }

    // 3. Process each corridor according to its TRB collection system
    for (final corridorSegments in corridors) {
      final expressway = corridorSegments.first.expressway;
      final corridorEntry = corridorSegments.first.entryPoint;
      final corridorExit = corridorSegments.last.exitPoint;
      final corridorOperator = corridorSegments.first.operator;

      // Determine corridor direction
      final entryPlaza = plazaMap[corridorEntry];
      final exitPlaza = plazaMap[corridorExit];
      final isNorthbound = (entryPlaza != null && exitPlaza != null)
          ? entryPlaza.orderIndex < exitPlaza.orderIndex
          : true;
      final directionStr = isNorthbound ? 'northbound' : 'southbound';

      // --- A. CLOSED SYSTEM EXPRESSWAYS (Exact OD Matrix Lookup) ---
      if (expressway == 'STAR' ||
          expressway == 'SLEX' ||
          expressway == 'CALAX' ||
          expressway == 'SCTEX' ||
          expressway == 'TPLEX') {

        final corridorPlazas = corridorSegments.expand((s) => [s.entryPoint, s.exitPoint]).toSet();

        // Special handling for SLEX if route combines Closed System + At-Grade section (Alabang <-> Magallanes)
        if (expressway == 'SLEX' &&
            ((corridorEntry != 'slex_alabang' && corridorExit == 'slex_magallanes') ||
             (corridorEntry == 'slex_magallanes' && corridorExit != 'slex_alabang') ||
             (corridorPlazas.contains('slex_alabang') && corridorPlazas.contains('slex_magallanes') && corridorEntry != 'slex_alabang'))) {
          final closedEntry = corridorEntry == 'slex_magallanes' ? 'slex_alabang' : corridorEntry;
          final closedExit = corridorExit == 'slex_magallanes' ? 'slex_alabang' : corridorExit;

          // 1. Closed system charge to/from Alabang
          final closedRule = _findMatchingClosedRule(allRules, 'SLEX', closedEntry, closedExit, directionStr);
          if (closedRule != null) {
            appliedRuleIds.add(closedRule.id);
            final fare = closedRule.getFareForClass(vehicleClass);
            chargeList.add(TollChargeBreakdown(
              tollRuleId: closedRule.id,
              expressway: 'SLEX',
              operator: closedRule.operator,
              collectionType: 'closedSystem',
              entryPlazaId: closedEntry,
              exitPlazaId: closedExit,
              vehicleClass: vehicleClass,
              amount: fare,
              sourceName: closedRule.sourceName,
              sourceUrl: closedRule.sourceUrl,
              effectiveFrom: closedRule.effectiveFrom,
              ratesLastUpdated: closedRule.ratesLastUpdated,
              verificationStatus: closedRule.verificationStatus,
              explanation: 'SLEX Closed-System Toll (${plazaMap[closedEntry]?.name ?? closedEntry} → ${plazaMap[closedExit]?.name ?? closedExit})',
            ));
          }

          // 2. At-Grade surface toll (Alabang <-> Magallanes)
          final atGradeRule = allRules.firstWhere(
            (r) => r.id == 'rule_slex_alabang_magallanes_atgrade',
            orElse: () => const TollChargeRule(
              id: 'rule_slex_alabang_magallanes_atgrade',
              expressway: 'SLEX',
              operator: 'autosweep',
              collectionType: 'closedSystem',
              direction: 'both',
              entryPlazaId: 'slex_alabang',
              exitPlazaId: 'slex_magallanes',
              fareClass1: 45.0,
              fareClass2: 90.0,
              fareClass3: 135.0,
              effectiveFrom: null,
              sourceName: 'TRB SLEX At-Grade Rate',
              sourceUrl: 'https://trb.gov.ph/index.php/toll-rates/slex',
            ),
          );
          appliedRuleIds.add(atGradeRule.id);
          final atGradeFare = atGradeRule.getFareForClass(vehicleClass);
          chargeList.add(TollChargeBreakdown(
            tollRuleId: atGradeRule.id,
            expressway: 'SLEX',
            operator: atGradeRule.operator,
            collectionType: 'closedSystem',
            entryPlazaId: 'slex_alabang',
            exitPlazaId: 'slex_magallanes',
            vehicleClass: vehicleClass,
            amount: atGradeFare,
            sourceName: atGradeRule.sourceName,
            sourceUrl: atGradeRule.sourceUrl,
            effectiveFrom: atGradeRule.effectiveFrom,
            ratesLastUpdated: atGradeRule.ratesLastUpdated,
            verificationStatus: atGradeRule.verificationStatus,
            explanation: 'SLEX At-Grade Surface Section (Alabang ↔ Magallanes/EDSA)',
          ));
        } else {
          // Standard Closed System OD lookup
          final matchedRule = _findMatchingClosedRule(allRules, expressway, corridorEntry, corridorExit, directionStr);

          if (matchedRule != null) {
            appliedRuleIds.add(matchedRule.id);
            final fare = matchedRule.getFareForClass(vehicleClass);
            chargeList.add(TollChargeBreakdown(
              tollRuleId: matchedRule.id,
              expressway: expressway,
              operator: matchedRule.operator,
              collectionType: 'closedSystem',
              entryPlazaId: corridorEntry,
              exitPlazaId: corridorExit,
              vehicleClass: vehicleClass,
              amount: fare,
              sourceName: matchedRule.sourceName,
              sourceUrl: matchedRule.sourceUrl,
              effectiveFrom: matchedRule.effectiveFrom,
              ratesLastUpdated: matchedRule.ratesLastUpdated,
              verificationStatus: matchedRule.verificationStatus,
              explanation:
                  '$expressway Closed-System Toll (${entryPlaza?.name ?? corridorEntry} → ${exitPlaza?.name ?? corridorExit})',
            ));
          } else {
            warnings.add('Rate not yet available for this route.');
            chargeList.add(TollChargeBreakdown(
              tollRuleId: 'unverified_${expressway}_${corridorEntry}_$corridorExit',
              expressway: expressway,
              operator: corridorOperator,
              collectionType: 'closedSystem',
              entryPlazaId: corridorEntry,
              exitPlazaId: corridorExit,
              vehicleClass: vehicleClass,
              amount: 0.0,
              sourceName: 'TRB Rate Matrix Pending',
              verificationStatus: TollVerificationStatus.needsManualReview,
              explanation: 'Rate not yet available for this route.',
            ));
          }
        }
      }

      // --- B. SKYWAY STAGES 1, 2, 3 (Open Barrier / Segment Gantries) ---
      else if (expressway == 'SKYWAY') {
        final corridorPlazaSet = corridorSegments.expand((s) => [s.entryPoint, s.exitPoint]).toSet();

        // Skyway Stage 1 & 2 (Alabang to Buendia elevated):
        final usesStage12 = corridorPlazaSet.contains('skyway_alabang') ||
            corridorPlazaSet.contains('skyway_sucat') ||
            corridorPlazaSet.contains('skyway_bicutan') ||
            corridorPlazaSet.contains('skyway_naiax') ||
            corridorPlazaSet.contains('skyway_magallanes') ||
            corridorPlazaSet.contains('skyway_don_bosco');

        final reachesBuendiaOrNorth = corridorPlazaSet.contains('skyway_buendia') ||
            corridorPlazaSet.contains('skyway_quirino') ||
            corridorPlazaSet.contains('skyway_nagtahan') ||
            corridorPlazaSet.contains('skyway_e_rodriguez') ||
            corridorPlazaSet.contains('skyway_quezon_ave') ||
            corridorPlazaSet.contains('skyway_sgt_rivera') ||
            corridorPlazaSet.contains('skyway_balintawak');

        if (usesStage12 && reachesBuendiaOrNorth && !appliedRuleIds.contains('rule_skyway_stage12_alabang_buendia')) {
          appliedRuleIds.add('rule_skyway_stage12_alabang_buendia');
          final rule = allRules.firstWhere(
            (r) => r.id == 'rule_skyway_stage12_alabang_buendia',
            orElse: () => const TollChargeRule(
              id: 'rule_skyway_stage12_alabang_buendia',
              expressway: 'SKYWAY',
              operator: 'autosweep',
              collectionType: 'openBarrier',
              direction: 'both',
              barrierPlazaId: 'skyway_alabang',
              fareClass1: 147.0,
              fareClass2: 294.0,
              fareClass3: 441.0,
              effectiveFrom: null,
              sourceName: 'TRB Skyway Rate Matrix',
              sourceUrl: 'https://trb.gov.ph/index.php/toll-rates/skyway-1-2',
            ),
          );
          final fare = rule.getFareForClass(vehicleClass);
          chargeList.add(TollChargeBreakdown(
            tollRuleId: rule.id,
            expressway: 'SKYWAY',
            operator: rule.operator,
            collectionType: 'openBarrier',
            chargedAtPlazaId: 'skyway_alabang',
            vehicleClass: vehicleClass,
            amount: fare,
            sourceName: rule.sourceName,
            sourceUrl: rule.sourceUrl,
            effectiveFrom: rule.effectiveFrom,
            ratesLastUpdated: rule.ratesLastUpdated,
            verificationStatus: rule.verificationStatus,
            explanation: 'Skyway Stages 1 & 2 Main Elevated Viaduct (Alabang ↔ Buendia)',
          ));
        }

        // Skyway Stage 3 Ramps & Mainline:
        final hasBuendia = corridorPlazaSet.contains('skyway_buendia') || corridorPlazaSet.contains('skyway_quirino') || corridorPlazaSet.contains('skyway_nagtahan');
        final hasQuezonAve = corridorPlazaSet.contains('skyway_quezon_ave') || corridorPlazaSet.contains('skyway_e_rodriguez');
        final hasBalintawak = corridorPlazaSet.contains('skyway_balintawak') || corridorPlazaSet.contains('skyway_sgt_rivera');

        if (hasBuendia && hasBalintawak && !appliedRuleIds.contains('rule_skyway_stage3_buendia_balintawak')) {
          appliedRuleIds.add('rule_skyway_stage3_buendia_balintawak');
          final rule = allRules.firstWhere(
            (r) => r.id == 'rule_skyway_stage3_buendia_balintawak',
            orElse: () => const TollChargeRule(
              id: 'rule_skyway_stage3_buendia_balintawak',
              expressway: 'SKYWAY',
              operator: 'autosweep',
              collectionType: 'openBarrier',
              barrierPlazaId: 'skyway_balintawak',
              fareClass1: 264.0,
              fareClass2: 528.0,
              fareClass3: 792.0,
              effectiveFrom: null,
              sourceName: 'TRB Skyway Stage 3 Matrix',
              sourceUrl: 'https://trb.gov.ph/index.php/toll-rates/skyway-3',
            ),
          );
          final fare = rule.getFareForClass(vehicleClass);
          chargeList.add(TollChargeBreakdown(
            tollRuleId: rule.id,
            expressway: 'SKYWAY',
            operator: rule.operator,
            collectionType: 'openBarrier',
            chargedAtPlazaId: 'skyway_balintawak',
            vehicleClass: vehicleClass,
            amount: fare,
            sourceName: rule.sourceName,
            sourceUrl: rule.sourceUrl,
            effectiveFrom: rule.effectiveFrom,
            ratesLastUpdated: rule.ratesLastUpdated,
            verificationStatus: rule.verificationStatus,
            explanation: 'Skyway Stage 3 Metro Manila Bypass (Buendia ↔ Balintawak)',
          ));
        } else if (hasBuendia && hasQuezonAve && !hasBalintawak && !appliedRuleIds.contains('rule_skyway_stage3_buendia_quezonave')) {
          appliedRuleIds.add('rule_skyway_stage3_buendia_quezonave');
          final rule = allRules.firstWhere(
            (r) => r.id == 'rule_skyway_stage3_buendia_quezonave',
            orElse: () => const TollChargeRule(
              id: 'rule_skyway_stage3_buendia_quezonave',
              expressway: 'SKYWAY',
              operator: 'autosweep',
              collectionType: 'openBarrier',
              barrierPlazaId: 'skyway_quezon_ave',
              fareClass1: 105.0,
              fareClass2: 210.0,
              fareClass3: 315.0,
              effectiveFrom: null,
              sourceName: 'TRB Skyway Stage 3 Matrix',
              sourceUrl: 'https://trb.gov.ph/index.php/toll-rates/skyway-3',
            ),
          );
          final fare = rule.getFareForClass(vehicleClass);
          chargeList.add(TollChargeBreakdown(
            tollRuleId: rule.id,
            expressway: 'SKYWAY',
            operator: rule.operator,
            collectionType: 'openBarrier',
            chargedAtPlazaId: 'skyway_quezon_ave',
            vehicleClass: vehicleClass,
            amount: fare,
            sourceName: rule.sourceName,
            sourceUrl: rule.sourceUrl,
            effectiveFrom: rule.effectiveFrom,
            ratesLastUpdated: rule.ratesLastUpdated,
            verificationStatus: rule.verificationStatus,
            explanation: 'Skyway Stage 3 Section (Buendia ↔ Quezon Ave Ramp)',
          ));
        } else if (!hasBuendia && hasQuezonAve && hasBalintawak && !appliedRuleIds.contains('rule_skyway_stage3_quezonave_balintawak')) {
          appliedRuleIds.add('rule_skyway_stage3_quezonave_balintawak');
          final rule = allRules.firstWhere(
            (r) => r.id == 'rule_skyway_stage3_quezonave_balintawak',
            orElse: () => const TollChargeRule(
              id: 'rule_skyway_stage3_quezonave_balintawak',
              expressway: 'SKYWAY',
              operator: 'autosweep',
              collectionType: 'openBarrier',
              barrierPlazaId: 'skyway_balintawak',
              fareClass1: 129.0,
              fareClass2: 258.0,
              fareClass3: 387.0,
              effectiveFrom: null,
              sourceName: 'TRB Skyway Stage 3 Matrix',
              sourceUrl: 'https://trb.gov.ph/index.php/toll-rates/skyway-3',
            ),
          );
          final fare = rule.getFareForClass(vehicleClass);
          chargeList.add(TollChargeBreakdown(
            tollRuleId: rule.id,
            expressway: 'SKYWAY',
            operator: rule.operator,
            collectionType: 'openBarrier',
            chargedAtPlazaId: 'skyway_balintawak',
            vehicleClass: vehicleClass,
            amount: fare,
            sourceName: rule.sourceName,
            sourceUrl: rule.sourceUrl,
            effectiveFrom: rule.effectiveFrom,
            ratesLastUpdated: rule.ratesLastUpdated,
            verificationStatus: rule.verificationStatus,
            explanation: 'Skyway Stage 3 Section (Quezon Ave ↔ Balintawak Ramp)',
          ));
        }
      }

      // --- C. NLEX (Open System Flat Barrier & Closed System Northbound) ---
      else if (expressway == 'NLEX') {
        final corridorPlazaSet = corridorSegments.expand((s) => [s.entryPoint, s.exitPoint]).toSet();

        // NLEX Open System Flat Rate (Balintawak / Mindanao Ave / Karuhatan / Meycauayan / Marilao):
        final inOpenSystem = corridorPlazaSet.contains('nlex_balintawak') ||
            corridorPlazaSet.contains('nlex_mindanao_ave') ||
            corridorPlazaSet.contains('nlex_valenzuela') ||
            corridorPlazaSet.contains('nlex_meycauayan') ||
            corridorPlazaSet.contains('nlex_marilao');

        if (inOpenSystem && !appliedRuleIds.contains('rule_nlex_open_system')) {
          appliedRuleIds.add('rule_nlex_open_system');
          final rule = allRules.firstWhere(
            (r) => r.id == 'rule_nlex_open_system',
            orElse: () => const TollChargeRule(
              id: 'rule_nlex_open_system',
              expressway: 'NLEX',
              operator: 'easytrip',
              collectionType: 'openBarrier',
              barrierPlazaId: 'nlex_balintawak',
              fareClass1: 69.0,
              fareClass2: 172.0,
              fareClass3: 206.0,
              effectiveFrom: null,
              sourceName: 'TRB Approved Toll Rate Matrix for NLEX Open System (June 2024)',
              sourceUrl: 'https://trb.gov.ph/index.php/toll-rates/nlex',
            ),
          );
          final fare = rule.getFareForClass(vehicleClass);
          chargeList.add(TollChargeBreakdown(
            tollRuleId: rule.id,
            expressway: 'NLEX',
            operator: rule.operator,
            collectionType: 'openBarrier',
            chargedAtPlazaId: corridorPlazaSet.contains('nlex_mindanao_ave') ? 'nlex_mindanao_ave' : 'nlex_balintawak',
            vehicleClass: vehicleClass,
            amount: fare,
            sourceName: rule.sourceName,
            sourceUrl: rule.sourceUrl,
            effectiveFrom: rule.effectiveFrom,
            ratesLastUpdated: rule.ratesLastUpdated,
            verificationStatus: rule.verificationStatus,
            explanation: 'NLEX Open System Flat Rate (Balintawak / Mindanao Ave ↔ Marilao)',
          ));
        }

        // NLEX Closed System (North of Marilao: Bocaue to Sta. Ines):
        final reachesNorthOfMarilao = corridorPlazaSet.any((p) {
          final idx = plazaMap[p]?.orderIndex ?? 0;
          return idx > 5; // Beyond Marilao
        });

        if (reachesNorthOfMarilao && !appliedRuleIds.contains('rule_nlex_closed_portion')) {
          appliedRuleIds.add('rule_nlex_closed_portion');
          final closedRule = _findMatchingClosedRule(allRules, 'NLEX', 'nlex_marilao', corridorExit, directionStr);
          final fare = closedRule != null ? closedRule.getFareForClass(vehicleClass) : (vehicleClass == 2 ? 168.0 : vehicleClass == 3 ? 202.0 : 67.0);
          chargeList.add(TollChargeBreakdown(
            tollRuleId: closedRule?.id ?? 'rule_nlex_closed_portion',
            expressway: 'NLEX',
            operator: 'easytrip',
            collectionType: 'closedSystem',
            entryPlazaId: 'nlex_marilao',
            exitPlazaId: corridorExit,
            vehicleClass: vehicleClass,
            amount: fare,
            sourceName: closedRule?.sourceName ?? 'NLEX Corp / TRB Matrix',
            sourceUrl: closedRule?.sourceUrl ?? 'https://trb.gov.ph/index.php/toll-rates/nlex',
            effectiveFrom: closedRule?.effectiveFrom,
            ratesLastUpdated: closedRule?.ratesLastUpdated,
            verificationStatus: closedRule?.verificationStatus ?? TollVerificationStatus.verified,
            explanation: 'NLEX Closed System Toll (Marilao → ${plazaMap[corridorExit]?.name ?? corridorExit})',
          ));
        }
      }

      // --- D. MCX, NAIAX, NLEX CONNECTOR, CAVITEX, CCLEX (Fixed Barriers) ---
      else if (expressway == 'MCX') {
        if (!appliedRuleIds.contains('rule_mcx_flat')) {
          appliedRuleIds.add('rule_mcx_flat');
          final rule = allRules.firstWhere(
            (r) => r.id == 'rule_mcx_flat',
            orElse: () => const TollChargeRule(
              id: 'rule_mcx_flat',
              expressway: 'MCX',
              operator: 'autosweep',
              collectionType: 'openBarrier',
              barrierPlazaId: 'mcx_daang_hari',
              fareClass1: 17.0,
              fareClass2: 34.0,
              fareClass3: 51.0,
              effectiveFrom: null,
              sourceName: 'TRB Approved Toll Rate Matrix for MCX',
              sourceUrl: 'https://trb.gov.ph/index.php/toll-rates/mcx',
            ),
          );
          final fare = rule.getFareForClass(vehicleClass);
          chargeList.add(TollChargeBreakdown(
            tollRuleId: rule.id,
            expressway: 'MCX',
            operator: rule.operator,
            collectionType: 'openBarrier',
            chargedAtPlazaId: 'mcx_daang_hari',
            vehicleClass: vehicleClass,
            amount: fare,
            sourceName: rule.sourceName,
            sourceUrl: rule.sourceUrl,
            effectiveFrom: rule.effectiveFrom,
            ratesLastUpdated: rule.ratesLastUpdated,
            verificationStatus: rule.verificationStatus,
            explanation: 'Muntinlupa-Cavite Expressway Flat Barrier Toll',
          ));
        }
      } else if (expressway == 'NAIAX') {
        if (!appliedRuleIds.contains('rule_naiax_flat')) {
          appliedRuleIds.add('rule_naiax_flat');
          final rule = allRules.firstWhere(
            (r) => r.id == 'rule_naiax_mainline_flat' || r.id == 'rule_naiax_flat',
            orElse: () => const TollChargeRule(
              id: 'rule_naiax_mainline_flat',
              expressway: 'NAIAX',
              operator: 'autosweep',
              collectionType: 'openBarrier',
              barrierPlazaId: 'naiax_terminal3',
              fareClass1: 45.0,
              fareClass2: 90.0,
              fareClass3: 135.0,
              effectiveFrom: null,
              sourceName: 'TRB Approved Toll Rate Matrix for NAIAX',
              sourceUrl: 'https://trb.gov.ph/index.php/toll-rates/naiax',
            ),
          );
          final fare = rule.getFareForClass(vehicleClass);
          chargeList.add(TollChargeBreakdown(
            tollRuleId: rule.id,
            expressway: 'NAIAX',
            operator: rule.operator,
            collectionType: 'openBarrier',
            chargedAtPlazaId: 'naiax_terminal3',
            vehicleClass: vehicleClass,
            amount: fare,
            sourceName: rule.sourceName,
            sourceUrl: rule.sourceUrl,
            effectiveFrom: rule.effectiveFrom,
            ratesLastUpdated: rule.ratesLastUpdated,
            verificationStatus: rule.verificationStatus,
            explanation: 'NAIA Expressway Airport Viaduct Flat Toll',
          ));
        }
      } else if (expressway == 'NLEX-C') {
        if (!appliedRuleIds.contains('rule_nlex_connector_flat')) {
          appliedRuleIds.add('rule_nlex_connector_flat');
          final rule = allRules.firstWhere(
            (r) => r.id == 'rule_nlex_connector_flat',
            orElse: () => const TollChargeRule(
              id: 'rule_nlex_connector_flat',
              expressway: 'NLEX-C',
              operator: 'easytrip',
              collectionType: 'openBarrier',
              barrierPlazaId: 'nlex_connector_c3',
              fareClass1: 86.0,
              fareClass2: 215.0,
              fareClass3: 258.0,
              effectiveFrom: null,
              sourceName: 'TRB Approved Toll Rate Matrix for NLEX Connector',
              sourceUrl: 'https://trb.gov.ph/index.php/toll-rates/nlex-connector',
            ),
          );
          final fare = rule.getFareForClass(vehicleClass);
          chargeList.add(TollChargeBreakdown(
            tollRuleId: rule.id,
            expressway: 'NLEX-C',
            operator: rule.operator,
            collectionType: 'openBarrier',
            chargedAtPlazaId: 'nlex_connector_c3',
            vehicleClass: vehicleClass,
            amount: fare,
            sourceName: rule.sourceName,
            sourceUrl: rule.sourceUrl,
            effectiveFrom: rule.effectiveFrom,
            ratesLastUpdated: rule.ratesLastUpdated,
            verificationStatus: rule.verificationStatus,
            explanation: 'NLEX Connector Elevated Viaduct Toll',
          ));
        }
      } else if (expressway == 'CAVITEX') {
        final corridorPlazaSet = corridorSegments.expand((s) => [s.entryPoint, s.exitPoint]).toSet();

        // 1. C5 South Link Section
        if ((corridorPlazaSet.contains('cavitex_c5_merville') || corridorPlazaSet.contains('cavitex_c5_taguig')) &&
            !appliedRuleIds.contains('rule_cavitex_c5_southlink')) {
          appliedRuleIds.add('rule_cavitex_c5_southlink');
          final rule = allRules.firstWhere(
            (r) => r.id == 'rule_cavitex_c5_southlink',
            orElse: () => const TollChargeRule(
              id: 'rule_cavitex_c5_southlink',
              expressway: 'CAVITEX',
              operator: 'easytrip',
              collectionType: 'openBarrier',
              barrierPlazaId: 'cavitex_c5_merville',
              fareClass1: 35.0,
              fareClass2: 70.0,
              fareClass3: 105.0,
              effectiveFrom: null,
              sourceName: 'TRB Approved Toll Rate Matrix for CAVITEX C5 South Link',
              sourceUrl: 'https://trb.gov.ph/index.php/toll-rates/cavitex-toll-rate',
            ),
          );
          final fare = rule.getFareForClass(vehicleClass);
          chargeList.add(TollChargeBreakdown(
            tollRuleId: rule.id,
            expressway: 'CAVITEX',
            operator: rule.operator,
            collectionType: 'openBarrier',
            chargedAtPlazaId: 'cavitex_c5_merville',
            vehicleClass: vehicleClass,
            amount: fare,
            sourceName: rule.sourceName,
            sourceUrl: rule.sourceUrl,
            effectiveFrom: rule.effectiveFrom,
            ratesLastUpdated: rule.ratesLastUpdated,
            verificationStatus: rule.verificationStatus,
            explanation: 'CAVITEX C5 South Link Barrier Toll',
          ));
        }

        // 2. Kawit Extension Section
        if (corridorPlazaSet.contains('cavitex_kawit') && !appliedRuleIds.contains('rule_cavitex_kawit_extension')) {
          appliedRuleIds.add('rule_cavitex_kawit_extension');
          final rule = allRules.firstWhere(
            (r) => r.id == 'rule_cavitex_kawit_extension',
            orElse: () => const TollChargeRule(
              id: 'rule_cavitex_kawit_extension',
              expressway: 'CAVITEX',
              operator: 'easytrip',
              collectionType: 'openBarrier',
              barrierPlazaId: 'cavitex_kawit',
              fareClass1: 88.0,
              fareClass2: 176.0,
              fareClass3: 264.0,
              effectiveFrom: null,
              sourceName: 'TRB Approved Toll Rate Matrix for CAVITEX',
              sourceUrl: 'https://trb.gov.ph/index.php/toll-rates/cavitex-toll-rate',
            ),
          );
          final fare = rule.getFareForClass(vehicleClass);
          chargeList.add(TollChargeBreakdown(
            tollRuleId: rule.id,
            expressway: 'CAVITEX',
            operator: rule.operator,
            collectionType: 'openBarrier',
            chargedAtPlazaId: 'cavitex_kawit',
            vehicleClass: vehicleClass,
            amount: fare,
            sourceName: rule.sourceName,
            sourceUrl: rule.sourceUrl,
            effectiveFrom: rule.effectiveFrom,
            ratesLastUpdated: rule.ratesLastUpdated,
            verificationStatus: rule.verificationStatus,
            explanation: 'CAVITEX R-1 Kawit Extension Barrier Toll',
          ));
        }

        // 3. Parañaque Mainline Barrier
        if ((corridorPlazaSet.contains('cavitex_paranaque') || corridorPlazaSet.contains('cavitex_seaside')) &&
            !corridorPlazaSet.contains('cavitex_c5_merville') &&
            !corridorPlazaSet.contains('cavitex_c5_taguig') &&
            !appliedRuleIds.contains('rule_cavitex_paranaque_flat')) {
          appliedRuleIds.add('rule_cavitex_paranaque_flat');
          final rule = allRules.firstWhere(
            (r) => r.id == 'rule_cavitex_paranaque_flat',
            orElse: () => const TollChargeRule(
              id: 'rule_cavitex_paranaque_flat',
              expressway: 'CAVITEX',
              operator: 'easytrip',
              collectionType: 'openBarrier',
              barrierPlazaId: 'cavitex_paranaque',
              fareClass1: 39.0,
              fareClass2: 78.0,
              fareClass3: 117.0,
              effectiveFrom: null,
              sourceName: 'TRB Approved Toll Rate Matrix for CAVITEX',
              sourceUrl: 'https://trb.gov.ph/index.php/toll-rates/cavitex-toll-rate',
            ),
          );
          final fare = rule.getFareForClass(vehicleClass);
          chargeList.add(TollChargeBreakdown(
            tollRuleId: rule.id,
            expressway: 'CAVITEX',
            operator: rule.operator,
            collectionType: 'openBarrier',
            chargedAtPlazaId: 'cavitex_paranaque',
            vehicleClass: vehicleClass,
            amount: fare,
            sourceName: rule.sourceName,
            sourceUrl: rule.sourceUrl,
            effectiveFrom: rule.effectiveFrom,
            ratesLastUpdated: rule.ratesLastUpdated,
            verificationStatus: rule.verificationStatus,
            explanation: 'CAVITEX Parañaque Mainline Barrier Toll',
          ));
        }
      } else if (expressway == 'CCLEX') {
        if (!appliedRuleIds.contains('rule_cclex_flat')) {
          appliedRuleIds.add('rule_cclex_flat');
          final rule = allRules.firstWhere(
            (r) => r.id == 'rule_cclex_flat',
            orElse: () => const TollChargeRule(
              id: 'rule_cclex_flat',
              expressway: 'CCLEX',
              operator: 'easytrip',
              collectionType: 'openBarrier',
              barrierPlazaId: 'cclex_cordova',
              fareClass1: 90.0,
              fareClass2: 180.0,
              fareClass3: 270.0,
              effectiveFrom: null,
              sourceName: 'CCLEC Official Toll Rate Matrix for CCLEX',
              sourceUrl: 'https://cclex.com.ph/toll-rates',
            ),
          );
          final fare = rule.getFareForClass(vehicleClass);
          chargeList.add(TollChargeBreakdown(
            tollRuleId: rule.id,
            expressway: 'CCLEX',
            operator: rule.operator,
            collectionType: 'openBarrier',
            chargedAtPlazaId: 'cclex_cordova',
            vehicleClass: vehicleClass,
            amount: fare,
            sourceName: rule.sourceName,
            sourceUrl: rule.sourceUrl,
            effectiveFrom: rule.effectiveFrom,
            ratesLastUpdated: rule.ratesLastUpdated,
            verificationStatus: rule.verificationStatus,
            explanation: 'Cebu-Cordova Link Expressway Bridge Toll',
          ));
        }
      }
    }

    // 4. Trace considered-not-charged rules at interchanges along the route
    final traversedPlazaSet = orderedPlazas.toSet();
    if (traversedPlazaSet.contains('slex_mamplasan') && !traversedPlazaSet.any((p) => p.startsWith('calax_'))) {
      consideredNotCharged.add({
        'ruleId': 'rule_calax_mamplasan_santarosa',
        'reason': 'Vehicle remained on SLEX mainline; did not traverse CALAX entry connector at Mamplasan interchange.',
      });
    }
    if (traversedPlazaSet.contains('slex_susana_heights') && !traversedPlazaSet.contains('mcx_daang_hari')) {
      consideredNotCharged.add({
        'ruleId': 'rule_mcx_flat',
        'reason': 'Vehicle remained on SLEX mainline; did not exit into MCX Daang Hari connector.',
      });
    }
    if (traversedPlazaSet.contains('skyway_sales') && !traversedPlazaSet.any((p) => p.startsWith('naiax_'))) {
      consideredNotCharged.add({
        'ruleId': 'rule_naiax_mainline_flat',
        'reason': 'Vehicle remained on Skyway mainline; did not exit into NAIAX Airport Viaduct.',
      });
    }
    if (traversedPlazaSet.contains('nlex_balintawak') && !traversedPlazaSet.any((p) => p.startsWith('nlex_connector_'))) {
      consideredNotCharged.add({
        'ruleId': 'rule_nlex_connector_flat',
        'reason': 'Vehicle remained on NLEX mainline; did not enter NLEX Connector elevated ramp.',
      });
    }

    // 5. Itemize operator subtotal calculations
    final Map<String, List<Map<String, dynamic>>> operatorSubtotals = {
      'autosweep': [],
      'easytrip': [],
    };
    for (final charge in chargeList) {
      final opKey = charge.operator.toLowerCase().trim();
      operatorSubtotals.putIfAbsent(opKey, () => []).add({
        'ruleId': charge.tollRuleId,
        'expressway': charge.expressway,
        'amount': charge.amount,
        'status': charge.verificationStatus.name,
      });
    }

    final debugTrace = RouteCalculationDebug(
      chosenOrderedPlazaPath: orderedPlazas,
      excludedPathAlternatives: excludedAlternatives,
      matchedRuleIds: chargeList.map((c) => c.tollRuleId).toList(),
      consideredNotChargedRules: consideredNotCharged,
      operatorSubtotalCalculations: operatorSubtotals,
    );

    return RouteResult.calculate(
      segments: segments,
      tollCharges: chargeList,
      orderedPlazaIds: orderedPlazas,
      warnings: warnings,
      vehicleClass: vehicleClass,
      debugInfo: debugTrace,
    );
  }

  static TollChargeRule? _findMatchingClosedRule(
    List<TollChargeRule> rules,
    String expressway,
    String entryPlazaId,
    String exitPlazaId,
    String directionStr,
  ) {
    for (final rule in rules) {
      if (rule.expressway == expressway &&
          rule.collectionType == 'closedSystem' &&
          rule.isActive) {
        final matchesForward = rule.entryPlazaId == entryPlazaId &&
            rule.exitPlazaId == exitPlazaId &&
            (rule.direction == directionStr || rule.direction == 'both');

        final matchesReverse = rule.entryPlazaId == exitPlazaId &&
            rule.exitPlazaId == entryPlazaId &&
            rule.direction == 'both';

        if (matchesForward || matchesReverse) {
          return rule;
        }
      }
    }
    return null;
  }

  /// Synchronously calculates the full fare breakdown from [originPlazaId] to [destinationPlazaId]
  /// for the specified [vehicleClass].
  RouteResult calculateExitToExitFareSync({
    required String originPlazaId,
    required String destinationPlazaId,
    int vehicleClass = 1,
    List<TollPlaza>? plazas,
    List<TollSegment>? segments,
    List<TollChargeRule>? rules,
    bool useSkyway = true,
  }) {
    final path = findPathSync(
      originPlazaId,
      destinationPlazaId,
      plazas: plazas,
      segments: segments,
      useSkyway: useSkyway,
    );

    return calculateRouteChargesSync(
      segments: path,
      originPlazaId: originPlazaId,
      destinationPlazaId: destinationPlazaId,
      vehicleClass: vehicleClass,
      plazas: plazas,
      rules: rules,
    );
  }

  /// Calculates the full fare breakdown from [originPlazaId] to [destinationPlazaId]
  /// for the specified [vehicleClass].
  Future<RouteResult> calculateExitToExitFare({
    required String originPlazaId,
    required String destinationPlazaId,
    int vehicleClass = 1,
    bool useSkyway = true,
  }) async {
    final allPlazas = await getCachedPlazas();
    final allRules = await getCachedTollRules();

    final segments = findPathSync(
      originPlazaId,
      destinationPlazaId,
      plazas: allPlazas,
      useSkyway: useSkyway,
    );

    return calculateRouteChargesSync(
      segments: segments,
      originPlazaId: originPlazaId,
      destinationPlazaId: destinationPlazaId,
      vehicleClass: vehicleClass,
      plazas: allPlazas,
      rules: allRules,
    );
  }

  /// Calculates the fare breakdown for given segments and vehicle class.
  RouteResult calculateFare({
    required List<TollSegment> segments,
    int vehicleClass = 1,
  }) {
    if (segments.isEmpty) {
      return RouteResult.calculate(segments: [], vehicleClass: vehicleClass);
    }
    return calculateRouteChargesSync(
      segments: segments,
      originPlazaId: segments.first.entryPoint,
      destinationPlazaId: segments.last.exitPoint,
      vehicleClass: vehicleClass,
    );
  }

  // ===========================================================================
  // PREDEFINED ROUTES (BACKWARD COMPATIBILITY)
  // ===========================================================================

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

  Future<List<RouteModel>> getCachedRoutes() async {
    final cached = await _cacheService.getRoutes();
    if (cached != null && cached.isNotEmpty) {
      return cached;
    }
    return defaultRoutes;
  }

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

  Future<Map<String, dynamic>?> getLastCalculation() {
    return _cacheService.getLastTripCalculation();
  }

  // ===========================================================================
  // EMBEDDED TOLL PLAZAS CATALOG (ALL SUPPORTED EXPRESSWAYS)
  // ===========================================================================

  static final List<TollPlaza> defaultPlazas = [
    // 1. STAR TOLLWAY (Autosweep)
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

    // 2. SLEX - South Luzon Expressway (Autosweep)
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
    const TollPlaza(
      id: 'slex_sucat_atgrade',
      name: 'Sucat Exit (At-Grade)',
      expressway: 'SLEX',
      expresswayName: 'South Luzon Expressway',
      operator: 'autosweep',
      orderIndex: 15,
    ),
    const TollPlaza(
      id: 'slex_bicutan_atgrade',
      name: 'Bicutan Exit (At-Grade)',
      expressway: 'SLEX',
      expresswayName: 'South Luzon Expressway',
      operator: 'autosweep',
      orderIndex: 16,
    ),
    const TollPlaza(
      id: 'slex_magallanes',
      name: 'Magallanes / EDSA (SLEX At-Grade)',
      expressway: 'SLEX',
      expresswayName: 'South Luzon Expressway',
      operator: 'autosweep',
      orderIndex: 17,
      isInterchange: true,
      connectsTo: ['nlex_balintawak'],
    ),

    // 3. MCX - Muntinlupa-Cavite Expressway (Autosweep)
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

    // 4. SKYWAY STAGES 1, 2, 3 (Autosweep)
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

    // 5. NAIAX - NAIA Expressway (Autosweep)
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

    // 6. NLEX - North Luzon Expressway (Easytrip)
    const TollPlaza(
      id: 'nlex_balintawak',
      name: 'Balintawak Barrier (NLEX)',
      expressway: 'NLEX',
      expresswayName: 'North Luzon Expressway',
      operator: 'easytrip',
      orderIndex: 1,
      isInterchange: true,
      connectsTo: ['skyway_balintawak', 'nlex_connector_c3', 'slex_magallanes'],
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

    // 7. NLEX CONNECTOR (Easytrip)
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

    // 8. SCTEX - Subic-Clark-Tarlac Expressway (Easytrip)
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

    // 9. TPLEX - Tarlac-Pangasinan-La Union (Autosweep)
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

    // 10. CALAX - Cavite-Laguna Expressway (Easytrip)
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

    // 11. CAVITEX & C5 SOUTH LINK (Easytrip)
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

    // 12. CCLEX - Cebu-Cordova Link Expressway (Easytrip)
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

  // ===========================================================================
  // EMBEDDED PHYSICAL ROAD SEGMENTS (TOPOLOGY & DISTANCE KM ONLY)
  // ===========================================================================

  static final List<TollSegment> defaultSegments = [
    // 1. STAR TOLLWAY (Physical Links)
    TollSegment(
      id: 'seg_star_batangas_ibaan',
      expressway: 'STAR',
      expresswayName: 'STAR Tollway',
      operator: 'autosweep',
      entryPoint: 'star_batangas',
      exitPoint: 'star_ibaan',
      distanceKm: 8.5,
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
      distanceKm: 13.5,
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
      distanceKm: 7.2,
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
      distanceKm: 6.8,
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
      distanceKm: 5.6,
      direction: 'both',
      isActive: true,
      lastUpdated: DateTime(2026, 8, 19),
      lastVerified: DateTime(2026, 8, 19),
    ),

    // 2. SLEX (Physical Links)
    TollSegment(
      id: 'seg_slex_stotomas_calamba',
      expressway: 'SLEX',
      expresswayName: 'South Luzon Expressway',
      operator: 'autosweep',
      entryPoint: 'slex_sto_tomas',
      exitPoint: 'slex_calamba',
      distanceKm: 7.8,
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
      distanceKm: 4.5,
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
      distanceKm: 3.2,
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
      distanceKm: 3.8,
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
      distanceKm: 5.1,
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
      distanceKm: 2.8,
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
      distanceKm: 2.1,
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
      distanceKm: 3.4,
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
      distanceKm: 5.7,
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
      distanceKm: 4.2,
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
      distanceKm: 3.9,
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
      distanceKm: 4.8,
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
      distanceKm: 2.3,
      direction: 'both',
      isActive: true,
      lastUpdated: DateTime(2026, 8, 19),
      lastVerified: DateTime(2026, 8, 19),
    ),
    TollSegment(
      id: 'seg_slex_alabang_sucat_atgrade',
      expressway: 'SLEX',
      expresswayName: 'South Luzon Expressway',
      operator: 'autosweep',
      entryPoint: 'slex_alabang',
      exitPoint: 'slex_sucat_atgrade',
      distanceKm: 4.6,
      direction: 'both',
      isActive: true,
      lastUpdated: DateTime(2026, 8, 19),
      lastVerified: DateTime(2026, 8, 19),
    ),
    TollSegment(
      id: 'seg_slex_sucat_bicutan_atgrade',
      expressway: 'SLEX',
      expresswayName: 'South Luzon Expressway',
      operator: 'autosweep',
      entryPoint: 'slex_sucat_atgrade',
      exitPoint: 'slex_bicutan_atgrade',
      distanceKm: 3.9,
      direction: 'both',
      isActive: true,
      lastUpdated: DateTime(2026, 8, 19),
      lastVerified: DateTime(2026, 8, 19),
    ),
    TollSegment(
      id: 'seg_slex_bicutan_magallanes_atgrade',
      expressway: 'SLEX',
      expresswayName: 'South Luzon Expressway',
      operator: 'autosweep',
      entryPoint: 'slex_bicutan_atgrade',
      exitPoint: 'slex_magallanes',
      distanceKm: 5.8,
      direction: 'both',
      isActive: true,
      lastUpdated: DateTime(2026, 8, 19),
      lastVerified: DateTime(2026, 8, 19),
    ),

    // 3. MCX (Physical Link)
    TollSegment(
      id: 'seg_mcx_susana_daanghari',
      expressway: 'MCX',
      expresswayName: 'Muntinlupa-Cavite Expressway',
      operator: 'autosweep',
      entryPoint: 'mcx_susana_heights',
      exitPoint: 'mcx_daang_hari',
      distanceKm: 4.0,
      direction: 'both',
      isActive: true,
      lastUpdated: DateTime(2026, 8, 19),
      lastVerified: DateTime(2026, 8, 19),
    ),

    // 4. SKYWAY STAGES 1, 2, 3 (Physical Elevated Links)
    TollSegment(
      id: 'seg_skyway_alabang_sucat',
      expressway: 'SKYWAY',
      expresswayName: 'Skyway Stage 1-3',
      operator: 'autosweep',
      entryPoint: 'skyway_alabang',
      exitPoint: 'skyway_sucat',
      distanceKm: 4.5,
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
      distanceKm: 3.8,
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
      distanceKm: 3.5,
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
      distanceKm: 3.2,
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
      distanceKm: 1.8,
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
      distanceKm: 2.1,
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
      distanceKm: 3.8,
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
      distanceKm: 2.2,
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
      distanceKm: 3.1,
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
      distanceKm: 2.6,
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
      distanceKm: 2.9,
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
      distanceKm: 3.5,
      direction: 'both',
      isActive: true,
      lastUpdated: DateTime(2026, 8, 19),
      lastVerified: DateTime(2026, 8, 19),
    ),

    // 5. NAIAX (Physical Links)
    TollSegment(
      id: 'seg_naiax_skyway_t3',
      expressway: 'NAIAX',
      expresswayName: 'NAIA Expressway',
      operator: 'autosweep',
      entryPoint: 'naiax_skyway',
      exitPoint: 'naiax_terminal3',
      distanceKm: 3.2,
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
      distanceKm: 4.1,
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
      distanceKm: 3.8,
      direction: 'both',
      isActive: true,
      lastUpdated: DateTime(2026, 8, 19),
      lastVerified: DateTime(2026, 8, 19),
    ),

    // 6. NLEX (Physical Links)
    TollSegment(
      id: 'seg_nlex_balintawak_mindanao',
      expressway: 'NLEX',
      expresswayName: 'North Luzon Expressway',
      operator: 'easytrip',
      entryPoint: 'nlex_balintawak',
      exitPoint: 'nlex_mindanao_ave',
      distanceKm: 3.0,
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
      distanceKm: 4.2,
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
      distanceKm: 5.6,
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
      distanceKm: 4.8,
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
      distanceKm: 3.5,
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
      distanceKm: 4.1,
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
      distanceKm: 5.2,
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
      distanceKm: 6.0,
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
      distanceKm: 8.5,
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
      distanceKm: 9.8,
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
      distanceKm: 11.2,
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
      distanceKm: 7.6,
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
      distanceKm: 8.9,
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
      distanceKm: 6.4,
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
      distanceKm: 4.8,
      direction: 'both',
      isActive: true,
      lastUpdated: DateTime(2026, 8, 19),
      lastVerified: DateTime(2026, 8, 19),
    ),

    // 7. NLEX CONNECTOR (Physical Links)
    TollSegment(
      id: 'seg_nlex_c_c3_espana',
      expressway: 'NLEX-C',
      expresswayName: 'NLEX Connector',
      operator: 'easytrip',
      entryPoint: 'nlex_connector_c3',
      exitPoint: 'nlex_connector_espana',
      distanceKm: 5.1,
      direction: 'both',
      isActive: true,
      lastUpdated: DateTime(2026, 8, 19),
      lastVerified: DateTime(2026, 8, 19),
    ),
    TollSegment(
      id: 'seg_nlex_c_espana_magsaysay',
      expressway: 'NLEX-C',
      expresswayName: 'NLEX Connector',
      operator: 'easytrip',
      entryPoint: 'nlex_connector_espana',
      exitPoint: 'nlex_connector_magsaysay',
      distanceKm: 2.9,
      direction: 'both',
      isActive: true,
      lastUpdated: DateTime(2026, 8, 19),
      lastVerified: DateTime(2026, 8, 19),
    ),

    // 8. SCTEX (Physical Links)
    TollSegment(
      id: 'seg_sctex_subic_dinalupihan',
      expressway: 'SCTEX',
      expresswayName: 'Subic-Clark-Tarlac Expressway',
      operator: 'easytrip',
      entryPoint: 'sctex_subic_tipo',
      exitPoint: 'sctex_dinalupihan',
      distanceKm: 12.5,
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
      distanceKm: 14.8,
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
      distanceKm: 11.2,
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
      distanceKm: 9.6,
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
      distanceKm: 7.4,
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
      distanceKm: 10.8,
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
      distanceKm: 8.5,
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
      distanceKm: 11.4,
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
      distanceKm: 9.2,
      direction: 'both',
      isActive: true,
      lastUpdated: DateTime(2026, 8, 19),
      lastVerified: DateTime(2026, 8, 19),
    ),

    // 9. TPLEX (Physical Links)
    TollSegment(
      id: 'seg_tplex_tarlac_victoria',
      expressway: 'TPLEX',
      expresswayName: 'Tarlac-Pangasinan-La Union',
      operator: 'autosweep',
      entryPoint: 'tplex_tarlac',
      exitPoint: 'tplex_victoria',
      distanceKm: 9.5,
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
      distanceKm: 7.8,
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
      distanceKm: 6.2,
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
      distanceKm: 14.5,
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
      distanceKm: 13.8,
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
      distanceKm: 8.4,
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
      distanceKm: 10.2,
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
      distanceKm: 7.9,
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
      distanceKm: 11.5,
      direction: 'both',
      isActive: true,
      lastUpdated: DateTime(2026, 8, 19),
      lastVerified: DateTime(2026, 8, 19),
    ),

    // 10. CALAX (Physical Links)
    TollSegment(
      id: 'seg_calax_mamplasan_technopark',
      expressway: 'CALAX',
      expresswayName: 'Cavite-Laguna Expressway',
      operator: 'easytrip',
      entryPoint: 'calax_mamplasan',
      exitPoint: 'calax_technopark',
      distanceKm: 3.2,
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
      distanceKm: 2.8,
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
      distanceKm: 3.9,
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
      distanceKm: 5.6,
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
      distanceKm: 4.8,
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
      distanceKm: 6.2,
      direction: 'both',
      isActive: true,
      lastUpdated: DateTime(2026, 8, 19),
      lastVerified: DateTime(2026, 8, 19),
    ),

    // 11. CAVITEX (Physical Links)
    TollSegment(
      id: 'seg_cavitex_seaside_paranaque',
      expressway: 'CAVITEX',
      expresswayName: 'Manila-Cavite Expressway',
      operator: 'easytrip',
      entryPoint: 'cavitex_seaside',
      exitPoint: 'cavitex_paranaque',
      distanceKm: 5.2,
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
      distanceKm: 4.6,
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
      distanceKm: 7.8,
      direction: 'both',
      isActive: true,
      lastUpdated: DateTime(2026, 8, 19),
      lastVerified: DateTime(2026, 8, 19),
    ),
    TollSegment(
      id: 'seg_cavitex_c5_merville_taguig',
      expressway: 'CAVITEX',
      expresswayName: 'C5 South Link Expressway',
      operator: 'easytrip',
      entryPoint: 'cavitex_c5_merville',
      exitPoint: 'cavitex_c5_taguig',
      distanceKm: 7.7,
      direction: 'both',
      isActive: true,
      lastUpdated: DateTime(2026, 8, 19),
      lastVerified: DateTime(2026, 8, 19),
    ),

    // 12. CCLEX (Physical Link)
    TollSegment(
      id: 'seg_cclex_srp_cordova',
      expressway: 'CCLEX',
      expresswayName: 'Cebu-Cordova Link Expressway',
      operator: 'easytrip',
      entryPoint: 'cclex_cebu_srp',
      exitPoint: 'cclex_cordova',
      distanceKm: 8.9,
      direction: 'both',
      isActive: true,
      lastUpdated: DateTime(2026, 8, 19),
      lastVerified: DateTime(2026, 8, 19),
    ),
  ];

  // ===========================================================================
  // EMBEDDED TOLL CHARGE RULES (TRB OFFICIAL MATRICES & BARRIER RATES)
  // All editable rates are located in `lib/data/toll_rates_data.dart`
  // ===========================================================================

  static final List<TollChargeRule> defaultTollRules = tollRatesData;

  // Predefined default routes for quick access
  static final List<RouteModel> defaultRoutes = [
    RouteModel(
      id: 'route_slex_southbound',
      name: 'SLEX Southbound',
      origin: 'slex_alabang',
      destination: 'slex_calamba',
      segmentIds: [
        'seg_slex_filinvest_alabang',
        'seg_slex_susana_filinvest',
        'seg_slex_sanpedro_susana',
        'seg_slex_southwoods_sanpedro',
        'seg_slex_mamplasan_southwoods',
        'seg_slex_greenfield_mamplasan',
        'seg_slex_eton_greenfield',
        'seg_slex_santarosa_eton',
        'seg_slex_cabuyao_santarosa',
        'seg_slex_silangan_cabuyao',
        'seg_slex_canlubang_silangan',
        'seg_slex_calamba_canlubang',
      ],
      isActive: true,
      lastVerified: DateTime(2026, 8, 19),
    ),
  ];
}
