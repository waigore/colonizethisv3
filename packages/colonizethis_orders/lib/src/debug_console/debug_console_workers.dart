/// Canonical `WorkerPool` tier field names accepted by debug-console `/add_worker`.
/// SPEC/game/workers-and-population.md
final Set<String> _debugConsoleSupportedWorkerTierIdsSet = {
  'peasants',
  'apprentices',
  'journeymen',
  'masters',
};

/// Canonical worker tier ids accepted by debug-console `/add_worker`.
Set<String> get debugConsoleSupportedWorkerTierIds =>
    _debugConsoleSupportedWorkerTierIdsSet;

/// Stable lexicographic worker tier ids for `/help` display.
List<String> get debugConsoleSupportedWorkerTierIdsSorted {
  final sorted = debugConsoleSupportedWorkerTierIds.toList(growable: false)
    ..sort();
  return sorted;
}
