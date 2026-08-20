import 'package:colonizethis_models/colonizethis_models.dart';

import 'economy_consumption_allocation.dart';
import 'economy_worker_consumption_rates.dart';
import 'labour_readiness_types.dart';
import 'military_navy_food_counts.dart';
import 'worker_economy.dart';

int _foodLabourLost({
  required WorkerPool workers,
  required WorkerConsumptionBreakdown breakdown,
}) {
  var lost = 0;
  for (final tier in WorkerTier.values) {
    final unfed = workerPoolCountForTier(workers, tier) -
        breakdown.fedCountForTier(tier);
    if (unfed <= 0) continue;
    lost += unfed * workerLabourPerTurnForTier(tier);
  }
  return lost;
}

List<LabourLuxuryShortfall> _luxuryShortfallsFromBreakdown(
  WorkerConsumptionBreakdown breakdown,
) {
  final shortfalls = <LabourLuxuryShortfall>[];
  for (final tier in WorkerTier.values) {
    if (!tier.isTrained) continue;
    final fed = breakdown.fedCountForTier(tier);
    final withLuxury = breakdown.luxuryCountForTier(tier);
    final short = fed - withLuxury;
    if (short <= 0) continue;
    shortfalls.add(
      LabourLuxuryShortfall(
        tier: tier,
        commodityId: workerLuxuryCommodityIdForTier(tier)!,
        labourLost: short * workerLabourPerTurnForTier(tier),
      ),
    );
  }
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

WorkerConsumptionBreakdown _breakdownFromAllocation(
  ConsumptionAllocation allocation,
) {
  return WorkerConsumptionBreakdown(
    workingCounts: allocation.idleLabour,
    fedPeasants: allocation.fedPeasants,
    fedApprentices: allocation.fedApprentices,
    fedJourneymen: allocation.fedJourneymen,
    fedMasters: allocation.fedMasters,
    apprenticesWithLuxury: allocation.apprenticesWithLuxury,
    journeymenWithLuxury: allocation.journeymenWithLuxury,
    mastersWithLuxury: allocation.mastersWithLuxury,
    militaryOrNavyConsumesFoodBeforeWorkers:
        allocation.militaryOrNavyConsumesFoodBeforeWorkers,
  );
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
    for (final tier in WorkerTier.values)
      WorkerTierLabourStatus(
        tier: tier,
        poolCount: workerPoolCountForTier(workers, tier),
        workingCount: workerIdleCountForTier(breakdown.workingCounts, tier),
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
  return _breakdownFromAllocation(
    allocateConsumption(
      stockpile: stockpile,
      workers: workers,
      foodCounts: foodCounts,
    ),
  );
}
