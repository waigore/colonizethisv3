/// Canonical [WorkerPool] tier field names for debug-console `/add_worker`.
///
/// Data source is fixed ids (not economy catalog lookup). SPEC/ui/debug-console-panel.md.
final Set<String> _debugConsoleSupportedWorkerTierIdsSet = {
  'apprentices',
  'journeymen',
  'masters',
  'peasants',
};

/// Canonical worker tier ids accepted by debug-console `/add_worker`.
Set<String> get debugConsoleSupportedWorkerTierIds =>
    _debugConsoleSupportedWorkerTierIdsSet;

/// Stable lexicographic tier ids for `/help` display (same source as parser validation).
List<String> get debugConsoleSupportedWorkerTierIdsSorted {
  final sorted = debugConsoleSupportedWorkerTierIds.toList(growable: false)
    ..sort();
  return sorted;
}
