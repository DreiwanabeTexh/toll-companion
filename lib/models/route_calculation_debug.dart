/// Developer-only debug trace capturing the internal decision process of the
/// Dijkstra router and TRB toll charging engine.
class RouteCalculationDebug {
  /// The chosen ordered sequence of toll plazas from origin to destination.
  final List<String> chosenOrderedPlazaPath;

  /// Excluded alternative paths and the exact reason for exclusion.
  /// Example: `[{'alternative': 'Skyway Stage 1-3 Viaduct', 'reason': 'useSkyway=false'}]`
  final List<Map<String, String>> excludedPathAlternatives;

  /// List of rule IDs that matched and were applied as actual toll charges.
  final List<String> matchedRuleIds;

  /// List of rules considered along the corridor or at interchanges that were NOT charged.
  /// Example: `[{'ruleId': 'rule_calax_mamplasan_santarosa', 'reason': 'Traversed SLEX mainline only; CALAX interchange not entered'}]`
  final List<Map<String, String>> consideredNotChargedRules;

  /// Exact operator subtotal mathematical calculation trace.
  final Map<String, List<Map<String, dynamic>>> operatorSubtotalCalculations;

  const RouteCalculationDebug({
    required this.chosenOrderedPlazaPath,
    required this.excludedPathAlternatives,
    required this.matchedRuleIds,
    required this.consideredNotChargedRules,
    required this.operatorSubtotalCalculations,
  });

  Map<String, dynamic> toJson() {
    return {
      'chosenOrderedPlazaPath': chosenOrderedPlazaPath,
      'excludedPathAlternatives': excludedPathAlternatives,
      'matchedRuleIds': matchedRuleIds,
      'consideredNotChargedRules': consideredNotChargedRules,
      'operatorSubtotalCalculations': operatorSubtotalCalculations,
    };
  }

  factory RouteCalculationDebug.fromJson(Map<String, dynamic> json) {
    return RouteCalculationDebug(
      chosenOrderedPlazaPath: (json['chosenOrderedPlazaPath'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      excludedPathAlternatives: (json['excludedPathAlternatives'] as List<dynamic>?)
              ?.map((e) => Map<String, String>.from(e as Map))
              .toList() ??
          [],
      matchedRuleIds: (json['matchedRuleIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      consideredNotChargedRules: (json['consideredNotChargedRules'] as List<dynamic>?)
              ?.map((e) => Map<String, String>.from(e as Map))
              .toList() ??
          [],
      operatorSubtotalCalculations: (json['operatorSubtotalCalculations'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(
                    k,
                    (v as List<dynamic>)
                        .map((e) => Map<String, dynamic>.from(e as Map))
                        .toList(),
                  )) ??
          {},
    );
  }
}
