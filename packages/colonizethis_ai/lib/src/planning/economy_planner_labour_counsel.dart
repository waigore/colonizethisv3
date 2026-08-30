import 'package:colonizethis_economy/colonizethis_economy.dart';

import 'economy_planner_labour_input.dart';
import 'growth_stage.dart';

bool delegatesToIndustryCounselCore(LabourAllocationInput input) {
  if (input.castIronLabourPeasantRecruitFabricBoost) return false;
  if (input.feedstockReserveOutputIds.isNotEmpty) return false;
  if (input.militaryRebuildCrisis) return false;
  if (input.regimentBuildInputProductionBoost) return false;
  if (input.missingRegimentBuildInputIds.isNotEmpty) return false;
  if (input.supplierReleaseImprovementInputIds.isNotEmpty) return false;
  if (input.growthStage != null && !kGrowthStagePlannerEnabled) return false;
  return true;
}

IndustryCounselGrowthStage? industryCounselGrowthStage(GrowthStage? stage) {
  if (stage == null) return null;
  return IndustryCounselGrowthStage(
    workerGrowthPriority: stage.workerGrowthPriority,
    infrastructurePriority: stage.infrastructurePriority,
    resourceProductionPriority: stage.resourceProductionPriority,
    militaryPriority: stage.militaryPriority,
  );
}
