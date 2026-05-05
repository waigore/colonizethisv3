import 'package:colonizethis_data/colonizethis_data.dart';

final Set<String> _debugConsoleSupportedCommodityIdsSet = CommodityCatalog
    .byId
    .keys
    .toSet();

/// Canonical commodity ids accepted by debug-console `/add_resource`.
Set<String> get debugConsoleSupportedCommodityIds =>
    _debugConsoleSupportedCommodityIdsSet;

/// Stable lexicographic commodity ids for `/help` display.
List<String> get debugConsoleSupportedCommodityIdsSorted {
  final sorted = debugConsoleSupportedCommodityIds.toList(growable: false)
    ..sort();
  return sorted;
}
