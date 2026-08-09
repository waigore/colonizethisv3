import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'economy_consumption.dart';
import 'economy_consumption_phases.dart';
import 'labour_readiness_types.dart';
import 'military_navy_food_counts.dart';
import 'worker_economy.dart';

CommodityId _luxuryIdForTier(WorkerTierKey tier) {
  return switch (tier) {
    WorkerTierKey.master => CommodityCatalog.furHats.id,
    WorkerTierKey.journeyman => CommodityCatalog.cigars.id,
    WorkerTierKey.apprentice => CommodityCatalog.refinedSugar.id,
    WorkerTierKey.peasant => throw StateError('peasants have no luxury'),
  };
}

int _labourPerTier(WorkerTierKey tier) {
  return switch (tier) {
    WorkerTierKey.peasant => WorkerPool.labourPerPeasantTurn,
    WorkerTierKey.apprentice => WorkerPool.labourPerApprenticeTurn,
    WorkerTierKey.journeyman => WorkerPool.labourPerJourneymanTurn,
    WorkerTierKey.master => WorkerPool.labourPerMasterTurn,
  };
}

int _poolCount(WorkerPool pool, WorkerTierKey tier) {
  return switch (tier) {
    WorkerTierKey.peasant => pool.peasants,
    WorkerTierKey.apprentice => pool.apprentices,
    WorkerTierKey.journeyman => pool.journeymen,
    WorkerTierKey.master => pool.masters,
  };
}

int _workingCount(WorkerIdleCounts working, WorkerTierKey tier) {
  return switch (tier) {
    WorkerTierKey.peasant => working.peasants,
    WorkerTierKey.apprentice => working.apprentices,
    WorkerTierKey.journeyman => working.journeymen,
    WorkerTierKey.master => working.masters,
  };
}

int _fedCountForTier(WorkerConsumptionBreakdown breakdown, WorkerTierKey tier) {
  return switch (tier) {
    WorkerTierKey.peasant => breakdown.fedPeasants,
    WorkerTierKey.apprentice => breakdown.fedApprentices,
    WorkerTierKey.journeyman => breakdown.fedJourneymen,
    WorkerTierKey.master => breakdown.fedMasters,
  };
}

int _foodLabourLost({
  required WorkerPool workers,
  required WorkerConsumptionBreakdown breakdown,
}) {
  var lost = 0;
  for (final tier in WorkerTierKey.values) {
    final unfed = _poolCount(workers, tier) - _fedCountForTier(breakdown, tier);
    if (unfed <= 0) continue;
    lost += unfed * _labourPerTier(tier);
  }
  return lost;
}

List<LabourLuxuryShortfall> _luxuryShortfallsFromBreakdown(
  WorkerConsumptionBreakdown breakdown,
) {
  final shortfalls = <LabourLuxuryShortfall>[];
  void add(WorkerTierKey tier, int fed, int withLuxury) {
    final short = fed - withLuxury;
    if (short <= 0) return;
    shortfalls.add(
      LabourLuxuryShortfall(
        tier: tier,
        commodityId: _luxuryIdForTier(tier),
        labourLost: short * _labourPerTier(tier),
      ),
    );
  }

  add(WorkerTierKey.master, breakdown.fedMasters, breakdown.mastersWithLuxury);
  add(
    WorkerTierKey.journeyman,
    breakdown.fedJourneymen,
    breakdown.journeymenWithLuxury,
  );
  add(
    WorkerTierKey.apprentice,
    breakdown.fedApprentices,
    breakdown.apprenticesWithLuxury,
  );
  return shortfalls;
}

LabourReadinessCauseKind? _primaryCauseKind(int foodLabourLost, int luxuryLabourLost) {
  if (foodLabourLost > luxuryLabourLost) return LabourReadinessCauseKind.food;
  if (luxuryLabourLost > foodLabourLost) return LabourReadinessCauseKind.luxury;
  if (foodLabourLost > 0) return LabourReadinessCauseKind.food;
  if (luxuryLabourLost > 0) return LabourReadinessCauseKind.luxury;
  return null;
}

LabourLuxuryShortfall? _worstLuxuryShortfall(List<LabourLuxuryShortfall> shortfalls) {
  LabourLuxuryShortfall? worst;
  for (final s in shortfalls) {
    if (worst == null || s.labourLost > worst.labourLost) {
      worst = s;
    }
  }
  return worst;
}

/// Computes labour readiness from post-extraction preview inputs.
///
/// Uses the same consumption/strike rules as [effectiveLabourForWorkers].
/// SPEC/ui/production-panel.md § Labour readiness; SPEC/game/workers-and-population.md.
LabourReadinessSnapshot computeLabourReadiness({
  required WorkerPool workers,
  required Stockpile stockpile,
  MilitaryNavyFoodCounts foodCounts = const MilitaryNavyFoodCounts(),
}) {
  final breakdown = previewWorkerConsumptionBreakdown(
    stockpile: stockpile,
    workers: workers,
    foodCounts: foodCounts,
  );
  final effectiveLabour = effectiveLabourFromIdleCounts(breakdown.workingCounts);
  final fullCapacity = workers.labourSupplyPerTurn;

  final tierStatuses = <WorkerTierLabourStatus>[
    for (final tier in WorkerTierKey.values)
      WorkerTierLabourStatus(
        tier: tier,
        poolCount: _poolCount(workers, tier),
        workingCount: _workingCount(breakdown.workingCounts, tier),
      ),
  ];

  if (effectiveLabour >= fullCapacity) {
    return LabourReadinessSnapshot(
      effectiveLabour: effectiveLabour,
      fullCapacity: fullCapacity,
      tierStatuses: tierStatuses,
    );
  }

  final foodLabourLost = _foodLabourLost(workers: workers, breakdown: breakdown);
  final luxuryShortfalls = _luxuryShortfallsFromBreakdown(breakdown);
  final luxuryLabourLost = luxuryShortfalls.fold<int>(
    0,
    (sum, s) => sum + s.labourLost,
  );
  final primaryKind = _primaryCauseKind(foodLabourLost, luxuryLabourLost);
  final worstLuxury = _worstLuxuryShortfall(luxuryShortfalls);

  return LabourReadinessSnapshot(
    effectiveLabour: effectiveLabour,
    fullCapacity: fullCapacity,
    tierStatuses: tierStatuses,
    primaryCauseKind: primaryKind,
    primaryLuxuryCommodityId: worstLuxury?.commodityId,
    primaryLuxuryTier: worstLuxury?.tier,
    militaryOrNavyConsumesFoodBeforeWorkers:
        breakdown.militaryOrNavyConsumesFoodBeforeWorkers,
  );
}

/// Same rules as [previewWorkerIdleLabour] with per-tier fed/luxury detail.
WorkerConsumptionBreakdown previewWorkerConsumptionBreakdown({
  required Stockpile stockpile,
  required WorkerPool workers,
  MilitaryNavyFoodCounts foodCounts = const MilitaryNavyFoodCounts(),
}) {
  final grainId = CommodityCatalog.grain.id;
  final meatId = CommodityCatalog.meat.id;
  final foodBeforeMilitary =
      stockpile.quantityOf(grainId) + stockpile.quantityOf(meatId);

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

  final foodAfterMilitaryNavy =
      afterNavy.quantityOf(grainId) + afterNavy.quantityOf(meatId);
  final militaryOrNavyConsumesFoodBeforeWorkers =
      foodBeforeMilitary > foodAfterMilitaryNavy &&
      (totalRegiments > 0 || totalShips > 0);

  final fed = consumeWorkerFood(stockpile: afterNavy, workers: workers);
  var current = fed.stockpile;

  final (s1, mastersWithLuxury) = assignWorkerLuxury(
    stockpile: current,
    foodFedCount: fed.fedMasters,
    luxuryId: CommodityCatalog.furHats.id,
  );
  current = s1;

  final (s2, journeymenWithLuxury) = assignWorkerLuxury(
    stockpile: current,
    foodFedCount: fed.fedJourneymen,
    luxuryId: CommodityCatalog.cigars.id,
  );
  current = s2;

  final (s3, apprenticesWithLuxury) = assignWorkerLuxury(
    stockpile: current,
    foodFedCount: fed.fedApprentices,
    luxuryId: CommodityCatalog.refinedSugar.id,
  );

  final workingCounts = WorkerIdleCounts(
    peasants: fed.fedPeasants,
    apprentices: apprenticesWithLuxury,
    journeymen: journeymenWithLuxury,
    masters: mastersWithLuxury,
  );

  return WorkerConsumptionBreakdown(
    workingCounts: workingCounts,
    fedPeasants: fed.fedPeasants,
    fedApprentices: fed.fedApprentices,
    fedJourneymen: fed.fedJourneymen,
    fedMasters: fed.fedMasters,
    apprenticesWithLuxury: apprenticesWithLuxury,
    journeymenWithLuxury: journeymenWithLuxury,
    mastersWithLuxury: mastersWithLuxury,
    militaryOrNavyConsumesFoodBeforeWorkers:
        militaryOrNavyConsumesFoodBeforeWorkers,
  );
}
