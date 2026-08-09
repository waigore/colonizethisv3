export 'regiment_economy_catalog.dart';
export 'regiment_economy_model.dart';

import 'regiment_economy_catalog.dart';

/// Minimum [RegimentEconomy.buildTreasuryCost] across the catalog.
///
/// Shared by AI planners and world-market lock-recovery (Refs #2924).
/// Linear in catalog size; cached callers should memoize if hot.
int cheapestRegimentBuildTreasuryCost() {
  var min = 999999999;
  for (final econ in RegimentEconomyCatalog.byId.values) {
    if (econ.buildTreasuryCost < min) {
      min = econ.buildTreasuryCost;
    }
  }
  return min;
}
