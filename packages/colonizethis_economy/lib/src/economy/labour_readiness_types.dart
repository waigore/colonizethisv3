import 'package:colonizethis_models/colonizethis_models.dart';

import 'worker_economy.dart';

/// Worker tier keys for labour-readiness breakdown rows.
enum WorkerTierKey { peasant, apprentice, journeyman, master }

/// Primary cause when effective labour is below full pool capacity.
enum LabourReadinessCauseKind { food, luxury }

/// One trained tier's luxury shortfall (food-fed but no luxury).
class LabourLuxuryShortfall {
  const LabourLuxuryShortfall({
    required this.tier,
    required this.commodityId,
    required this.labourLost,
  });

  final WorkerTierKey tier;
  final CommodityId commodityId;
  final int labourLost;
}

/// Per-tier working vs not-working headcounts for labour details.
class WorkerTierLabourStatus {
  const WorkerTierLabourStatus({
    required this.tier,
    required this.poolCount,
    required this.workingCount,
  });

  final WorkerTierKey tier;
  final int poolCount;
  final int workingCount;

  int get notWorkingCount => poolCount - workingCount;
}

/// Snapshot for Production panel labour readiness (Refs #4237).
class LabourReadinessSnapshot {
  const LabourReadinessSnapshot({
    required this.effectiveLabour,
    required this.fullCapacity,
    required this.tierStatuses,
    this.primaryCauseKind,
    this.primaryLuxuryCommodityId,
    this.primaryLuxuryTier,
    this.militaryOrNavyConsumesFoodBeforeWorkers = false,
  });

  final int effectiveLabour;
  final int fullCapacity;
  final List<WorkerTierLabourStatus> tierStatuses;
  final LabourReadinessCauseKind? primaryCauseKind;
  final CommodityId? primaryLuxuryCommodityId;
  final WorkerTierKey? primaryLuxuryTier;
  final bool militaryOrNavyConsumesFoodBeforeWorkers;

  bool get isFullCapacity => effectiveLabour >= fullCapacity;
}

/// Intermediate consumption counts for labour-readiness diagnostics.
class WorkerConsumptionBreakdown {
  const WorkerConsumptionBreakdown({
    required this.workingCounts,
    required this.fedPeasants,
    required this.fedApprentices,
    required this.fedJourneymen,
    required this.fedMasters,
    required this.apprenticesWithLuxury,
    required this.journeymenWithLuxury,
    required this.mastersWithLuxury,
    required this.militaryOrNavyConsumesFoodBeforeWorkers,
  });

  final WorkerIdleCounts workingCounts;
  final int fedPeasants;
  final int fedApprentices;
  final int fedJourneymen;
  final int fedMasters;
  final int apprenticesWithLuxury;
  final int journeymenWithLuxury;
  final int mastersWithLuxury;
  final bool militaryOrNavyConsumesFoodBeforeWorkers;
}
