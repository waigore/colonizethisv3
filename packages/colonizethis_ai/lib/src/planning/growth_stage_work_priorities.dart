// Growth-stage civilian work candidate ordering. SPEC/ai/growth-stage-planner.md.


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

/// Infrastructure feedstock resources (castIron / lumber inputs), excluding the
/// fabric feedstock which is routed at a higher priority during bootstrap.
const Set<String> _kInfraOnlyFeedstockResourceIds = {'timber', 'iron', 'coal'};

/// Growth-stage feedstock resource-id preference for civilian build routing
/// (Refs #3371 AC1/AC2). Returns which feedstock resources a GP should route an
/// idle Builder onto this turn, split into the high-priority **fabric** chain
/// (`wool` / `cotton`) and the lower-priority **infrastructure** chain
/// (`timber` / `iron` / `coal`). Empty sets when the growth-stage planner is off
/// or the GP has no active growth need, so legacy routing is unchanged.
class GrowthStageFeedstockPreference {
  const GrowthStageFeedstockPreference({
    required this.fabricFeedstockResourceIds,
    required this.infraFeedstockResourceIds,
  });

  final Set<String> fabricFeedstockResourceIds;
  final Set<String> infraFeedstockResourceIds;

  static const none = GrowthStageFeedstockPreference(
    fabricFeedstockResourceIds: <String>{},
    infraFeedstockResourceIds: <String>{},
  );
}

/// Computes the [GrowthStageFeedstockPreference] for one GP from its growth
/// [stage] and current fabric reserve. Fabric feedstock is requested while the
/// GP still needs worker growth and holds less than [kReserveTarget] fabric;
/// infrastructure feedstock is requested while infrastructure priority is high.
GrowthStageFeedstockPreference growthStageFeedstockPreference({
  required Game game,
  required String playerId,
  required GrowthStage stage,
  bool growthStagePlannerEnabled = kGrowthStagePlannerEnabled,
}) {
  if (!growthStagePlannerEnabled) return GrowthStageFeedstockPreference.none;
  final player = game.playerById(playerId);
  if (player == null) return GrowthStageFeedstockPreference.none;
  final fabricHeld = player.stockpile.quantityOf(CommodityCatalog.fabric.id);
  final wantsFabric =
      stage.workerGrowthPriority > 0.3 && fabricHeld < kReserveTarget;
  final wantsInfra = stage.infrastructurePriority > 0.3;
  return GrowthStageFeedstockPreference(
    fabricFeedstockResourceIds:
        wantsFabric ? _kFabricFeedstockResourceIds : const <String>{},
    infraFeedstockResourceIds:
        wantsInfra ? _kInfraOnlyFeedstockResourceIds : const <String>{},
  );
}

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
