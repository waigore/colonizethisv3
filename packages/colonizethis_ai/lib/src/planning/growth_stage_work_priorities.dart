// Growth-stage civilian work candidate ordering. SPEC/ai/growth-stage-planner.md.

import 'package:colonizethis_models/colonizethis_models.dart';

import 'growth_stage.dart';
import 'planning_imports.dart';

const Set<String> _kFabricFeedstockResourceIds = {'wool', 'cotton'};

const Set<String> _kInfrastructureFeedstockResourceIds = {
  'wool',
  'cotton',
  'timber',
  'iron',
  'coal',
};

/// Reorders [workCandidates] so bootstrap / infrastructure-stage GPs prefer
/// feedstock `build_improvement` tiles before other civilian work (Refs #3371).
List<WorkOrder> prioritizeWorkOrdersForGrowthStage({
  required List<WorkOrder> workCandidates,
  required Game game,
  required String playerId,
  required GrowthStage stage,
  bool growthStagePlannerEnabled = kGrowthStagePlannerEnabled,
}) {
  if (!growthStagePlannerEnabled) return workCandidates;
  final player = game.playerById(playerId);
  if (player == null || workCandidates.isEmpty) return workCandidates;

  final fabricHeld = player.stockpile.quantityOf(CommodityCatalog.fabric.id);
  final needsFabricBootstrap =
      stage.workerGrowthPriority > 0.5 && fabricHeld < kReserveTarget;
  final needsInfrastructure =
      stage.infrastructurePriority > 0.3 && fabricHeld < kReserveTarget;
  if (!needsFabricBootstrap && !needsInfrastructure) return workCandidates;

  int score(WorkOrder order) {
    if (order.target != kWorkTargetBuildImprovement) return 0;
    final resourceId = game.worldState.resourceByTileKey[order.targetTileKey];
    if (resourceId == null) return 1;
    if (_kFabricFeedstockResourceIds.contains(resourceId)) return 100;
    if (_kInfrastructureFeedstockResourceIds.contains(resourceId)) return 50;
    return 2;
  }

  final copy = List<WorkOrder>.from(workCandidates);
  copy.sort((a, b) {
    final byScore = score(b).compareTo(score(a));
    if (byScore != 0) return byScore;
    final t = a.target.compareTo(b.target);
    if (t != 0) return t;
    return a.targetTileKey.compareTo(b.targetTileKey);
  });
  return copy;
}
