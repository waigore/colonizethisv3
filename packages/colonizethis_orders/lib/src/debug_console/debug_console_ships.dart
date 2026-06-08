import 'package:colonizethis_data/colonizethis_data.dart';

final Set<String> _debugConsoleSupportedShipTypeIdsSet = ShipEconomyCatalog
    .byId
    .keys
    .toSet();

/// Canonical ship ids accepted by debug-console `/spawn_ship`.
Set<String> get debugConsoleSupportedShipTypeIds =>
    _debugConsoleSupportedShipTypeIdsSet;

/// Stable lexicographic ship ids for `/help` display.
List<String> get debugConsoleSupportedShipTypeIdsSorted {
  final sorted = debugConsoleSupportedShipTypeIds.toList(growable: false)
    ..sort();
  return sorted;
}
