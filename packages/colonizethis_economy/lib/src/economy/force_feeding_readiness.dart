import 'package:colonizethis_models/colonizethis_models.dart';

import 'economy_military_navy_food_allocation.dart';
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

/// Non-mutating preview of army/navy feeding on a post-extraction stockpile.
///
/// Uses the same military/navy consumption prefix as labour readiness and the
/// resolver. SPEC/ui/production-panel.md § Forces food readiness; Refs #4242.
ForceFeedingSnapshot previewForceFeeding({
  required Stockpile stockpile,
  MilitaryNavyFoodCounts foodCounts = const MilitaryNavyFoodCounts(),
}) {
  final prefix = allocateMilitaryNavyFood(
    stockpile: stockpile,
    foodCounts: foodCounts,
  );

  return ForceFeedingSnapshot(
    totalRegiments: prefix.totalRegiments,
    fullyFedRegiments: prefix.fullyFedRegiments,
    totalShips: prefix.totalShips,
    fullyFedShips: prefix.fullyFedShips,
    landCombatTier: _combatTierFromCoverage(
      _feedingCoverage(prefix.fullyFedRegiments, prefix.totalRegiments),
    ),
    navalCombatTier: _combatTierFromCoverage(
      _feedingCoverage(prefix.fullyFedShips, prefix.totalShips),
    ),
    forcesFoodDemand: prefix.forcesFoodDemand,
  );
}
