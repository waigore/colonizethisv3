import 'package:colonizethis_models/colonizethis_models.dart';

import 'economy_consumption_phases.dart';
import 'military_navy_food_counts.dart';

/// Military then navy food allocation on a post-extraction stockpile.
///
/// Shared by [allocateConsumption] and [previewForceFeeding] so catalog
/// `foodUpkeep` is walked once per phase. Does not feed workers.
class MilitaryNavyFoodAllocation {
  const MilitaryNavyFoodAllocation({
    required this.stockpile,
    required this.totalRegiments,
    required this.fullyFedRegiments,
    required this.totalShips,
    required this.fullyFedShips,
    required this.forcesFoodDemand,
  });

  final Stockpile stockpile;
  final int totalRegiments;
  final int fullyFedRegiments;
  final int totalShips;
  final int fullyFedShips;
  final int forcesFoodDemand;
}

/// Land military → navy consumption prefix. SPEC/game/workers-and-population.md
MilitaryNavyFoodAllocation allocateMilitaryNavyFood({
  required Stockpile stockpile,
  MilitaryNavyFoodCounts foodCounts = const MilitaryNavyFoodCounts(),
}) {
  final (
    afterMilitary,
    totalRegiments,
    fullyFedRegiments,
    militaryDemand,
  ) = consumeMilitaryFood(
    stockpile: stockpile,
    militaryUnits: foodCounts.militaryUnits,
    regimentCountsById: foodCounts.regimentCountsById,
  );

  final (afterNavy, totalShips, fullyFedShips, navyDemand) = consumeNavyFood(
    stockpile: afterMilitary,
    shipCountsById: foodCounts.shipCountsById,
  );

  return MilitaryNavyFoodAllocation(
    stockpile: afterNavy,
    totalRegiments: totalRegiments,
    fullyFedRegiments: fullyFedRegiments,
    totalShips: totalShips,
    fullyFedShips: fullyFedShips,
    forcesFoodDemand: militaryDemand + navyDemand,
  );
}
