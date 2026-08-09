import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'economy_consumption_phases.dart';
import 'force_feeding_readiness_types.dart';
import 'military_navy_food_counts.dart';

double _feedingCoverage(int fed, int total) {
  if (total <= 0) return 1.0;
  return fed / total;
}

ForceFeedingCombatTier _combatTierFromCoverage(double coverage) {
  if (coverage >= 1.0) return ForceFeedingCombatTier.full;
  if (coverage >= 0.5) return ForceFeedingCombatTier.moderate;
  return ForceFeedingCombatTier.severe;
}

int _forcesFoodDemand({
  required MilitaryNavyFoodCounts foodCounts,
}) {
  var demand = 0;
  if (foodCounts.regimentCountsById.isNotEmpty) {
    for (final entry in foodCounts.regimentCountsById.entries) {
      final count = entry.value;
      if (count <= 0) continue;
      final econ = RegimentEconomyCatalog.byId[entry.key];
      final perRegiment = econ?.foodUpkeep ?? 0;
      if (perRegiment > 0) {
        demand += perRegiment * count;
      }
    }
  } else if (foodCounts.militaryUnits > 0) {
    demand += foodCounts.militaryUnits * 2;
  }
  for (final entry in foodCounts.shipCountsById.entries) {
    final count = entry.value;
    if (count <= 0) continue;
    final econ = ShipEconomyCatalog.byId[entry.key];
    final perShip = econ?.foodUpkeep ?? 0;
    if (perShip > 0) {
      demand += perShip * count;
    }
  }
  return demand;
}

/// Non-mutating preview of army/navy feeding on a post-extraction stockpile.
///
/// Uses the same military/navy consumption phases as labour readiness and the
/// resolver. SPEC/ui/production-panel.md § Forces food readiness; Refs #4242.
ForceFeedingSnapshot previewForceFeeding({
  required Stockpile stockpile,
  MilitaryNavyFoodCounts foodCounts = const MilitaryNavyFoodCounts(),
}) {
  final (
    afterMilitary,
    totalRegiments,
    fullyFedRegiments,
  ) = consumeMilitaryFood(
    stockpile: stockpile,
    militaryUnits: foodCounts.militaryUnits,
    regimentCountsById: foodCounts.regimentCountsById,
  );

  final (afterNavy, totalShips, fullyFedShips) = consumeNavyFood(
    stockpile: afterMilitary,
    shipCountsById: foodCounts.shipCountsById,
  );

  return ForceFeedingSnapshot(
    totalRegiments: totalRegiments,
    fullyFedRegiments: fullyFedRegiments,
    totalShips: totalShips,
    fullyFedShips: fullyFedShips,
    landCombatTier: _combatTierFromCoverage(
      _feedingCoverage(fullyFedRegiments, totalRegiments),
    ),
    navalCombatTier: _combatTierFromCoverage(
      _feedingCoverage(fullyFedShips, totalShips),
    ),
    forcesFoodDemand: _forcesFoodDemand(foodCounts: foodCounts),
  );
}
