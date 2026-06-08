import 'package:colonizethis_data/colonizethis_data.dart';

final Set<String> _debugConsoleSupportedRegimentTypeIdsSet =
    RegimentEconomyCatalog.byId.keys.toSet();

/// Canonical regiment ids accepted by debug-console `/spawn_regiment`.
Set<String> get debugConsoleSupportedRegimentTypeIds =>
    _debugConsoleSupportedRegimentTypeIdsSet;

/// Stable lexicographic regiment ids for `/help` display.
List<String> get debugConsoleSupportedRegimentTypeIdsSorted {
  final sorted = debugConsoleSupportedRegimentTypeIds.toList(growable: false)
    ..sort();
  return sorted;
}
