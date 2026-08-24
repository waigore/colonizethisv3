import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'economy_consumption_food_units.dart';
import 'economy_consumption_fully_fed.dart';
import 'economy_consumption_unknown_ship.dart';

/// Navy food phase. Demand is per-type `foodUpkeep` from [ShipEconomyCatalog].
/// Returns (updatedStockpile, totalShips, fullyFedShips, foodDemand).
///
/// Throws [ConsumptionUnknownShipTypeException] if [shipCountsById] contains a
/// type id not present in [ShipEconomyCatalog]; validation runs before any food
/// is deducted.
(Stockpile, int, int, int) consumeNavyFood({
  required Stockpile stockpile,
  Map<String, int> shipCountsById = const {},
}) {
  for (final id in shipCountsById.keys) {
    if (!ShipEconomyCatalog.byId.containsKey(id)) {
      throw ConsumptionUnknownShipTypeException(id);
    }
  }

  var current = stockpile;
  int totalShips = 0;
  int totalNavyFoodDemand = 0;
  for (final entry in shipCountsById.entries) {
    final count = entry.value;
    if (count <= 0) continue;
    totalShips += count;
    final upkeep = ShipEconomyCatalog.byId[entry.key]!.foodUpkeep;
    if (upkeep > 0) {
      totalNavyFoodDemand += upkeep * count;
    }
  }

  var fullyFedShips = 0;
  if (totalNavyFoodDemand > 0 && totalShips > 0) {
    final (nextStockpile, consumed) = consumeFoodUnits(
      stockpile: current,
      required: totalNavyFoodDemand,
    );
    current = nextStockpile;
    fullyFedShips = fullyFedCountFromConsumed(
      consumed: consumed,
      totalDemand: totalNavyFoodDemand,
      count: totalShips,
    );
  }

  return (current, totalShips, fullyFedShips, totalNavyFoodDemand);
}
