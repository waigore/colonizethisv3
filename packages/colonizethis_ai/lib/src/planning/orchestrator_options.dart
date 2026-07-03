import 'package:colonizethis_data/colonizethis_data.dart' show TileMapResult;
import 'package:colonizethis_logic/ai_api.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'build_planner.dart' show kCivilianBuildPlannerEnabled;
import 'growth_stage.dart' show kGrowthStagePlannerEnabled;
import 'phase_planner_dispatch.dart';

/// Bundles optional parameters for [runDomainPlannersWithOutcome] (Refs #3822
/// Phase 3). Required orchestrator inputs stay on the entry function; callers
/// pass [OrchestratorOptions.defaults] when no overrides are needed.
class OrchestratorOptions {
  const OrchestratorOptions({
    this.tileMapByRegion,
    this.onStagedPlannerProgress,
    this.sameTurnPriorDiplomaticOrders,
    this.phasePlan,
    this.recomputeTradeOrdersWithPendingCosts = false,
    this.growthStagePlannerEnabled = kGrowthStagePlannerEnabled,
    this.civilianBuildPlannerEnabled = kCivilianBuildPlannerEnabled,
    this.extractionById,
  });

  static const defaults = OrchestratorOptions();

  final Map<String, TileMapResult>? tileMapByRegion;
  final void Function(String phaseId)? onStagedPlannerProgress;
  final Orders? sameTurnPriorDiplomaticOrders;
  final PhasePlanOutcome? phasePlan;
  final bool recomputeTradeOrdersWithPendingCosts;
  final bool growthStagePlannerEnabled;
  final bool civilianBuildPlannerEnabled;
  final Map<String, ExtractionTotals>? extractionById;
}
