import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'economy_consumption_food_units.dart';
import 'economy_consumption_fully_fed.dart';

/// Land military food phase.
///
/// Demand is per-type `foodUpkeep` from [RegimentEconomyCatalog] when
/// [regimentCountsById] is set, else 2 food per regiment when only
/// [militaryUnits] is given. Returns (updatedStockpile, totalRegiments,
/// fullyFedRegiments, foodDemand).
(Stockpile, int, int, int) consumeMilitaryFood({
  required Stockpile stockpile,
  int militaryUnits = 0,
  Map<String, int> regimentCountsById = const {},
}) {
  var current = stockpile;
  int totalRegiments = 0;
  int totalFoodDemand = 0;

  if (regimentCountsById.isNotEmpty) {
    for (final entry in regimentCountsById.entries) {
      final count = entry.value;
      if (count <= 0) continue;
      totalRegiments += count;
      final econ = RegimentEconomyCatalog.byId[entry.key];
      final perRegimentFood = econ?.foodUpkeep ?? 0;
      if (perRegimentFood > 0) {
        totalFoodDemand += perRegimentFood * count;
      }
    }
  } else if (militaryUnits > 0) {
    totalRegiments = militaryUnits;
    totalFoodDemand = militaryUnits * 2;
  }

  var fullyFedRegiments = 0;
  if (totalFoodDemand > 0 && totalRegiments > 0) {
    final (nextStockpile, consumed) = consumeFoodUnits(
      stockpile: current,
      required: totalFoodDemand,
    );
    current = nextStockpile;
    fullyFedRegiments = fullyFedCountFromConsumed(
      consumed: consumed,
      totalDemand: totalFoodDemand,
      count: totalRegiments,
    );
  }

  return (current, totalRegiments, fullyFedRegiments, totalFoodDemand);
}
