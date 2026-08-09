import '../util/orders_builder.dart';
import 'expand_phase_planner_economy.dart';
import 'growth_stage.dart';
import 'planner_context.dart';
import 'planning_imports.dart';

final _recruitLog = packageLogger('domain_planner_orchestrator_economy');

/// Appends a single peasant recruit-worker order into [ordersBuilder] when the
/// growth-stage worker-growth priority (Refs #3371) or the legacy castIron
/// labour expand boost authorizes it and the GP can afford it.
void appendEconomyPeasantRecruit({
  required PlannerContext ctx,
  required ExpandEconomyPlan expandEconomy,
  required GrowthStage? growthStage,
  required bool growthStagePlannerEnabled,
  required OrdersBuilder ordersBuilder,
}) {
  final growthStagePeasantRecruit =
      growthStage != null && growthStage.workerGrowthPriority > 0.1;
  if (growthStagePeasantRecruit ||
      (!growthStagePlannerEnabled &&
          expandEconomy.boostCastIronLabourPeasantRecruitment)) {
    final recruitCandidates = ctx.suggestionAPI.suggestRecruitWorkerOrders(
      ctx.view,
      ctx.game,
      ctx.topology,
      ordersBuilder.build(),
    );
    RecruitWorkerOrder? peasantRecruit;
    for (final candidate in recruitCandidates) {
      if (candidate.targetTier == WorkerTier.peasant) {
        peasantRecruit = candidate;
        break;
      }
    }
    if (peasantRecruit != null) {
      final player = ctx.game.playerById(ctx.nationId);
      final affordable =
          player != null &&
          canAffordRecruitWorker(
            player,
            peasantRecruit,
            player.workerPool,
            player.stockpile,
            player.treasury,
          ).canAfford;
      if (affordable) {
        _recruitLog.i(
          growthStagePeasantRecruit
              ? 'growth-stage peasant recruit nationId=${ctx.nationId} '
                    'workerGrowth=${growthStage.workerGrowthPriority.toStringAsFixed(2)}'
              : 'castIron labour peasant recruit nationId=${ctx.nationId} '
                    'targetTier=${peasantRecruit.targetTier.name}',
        );
        ordersBuilder.appendRecruitWorkerOrders(ctx.nationId, [peasantRecruit]);
      } else {
        _recruitLog.d(
          growthStagePeasantRecruit
              ? 'growth-stage peasant recruit deferred nationId=${ctx.nationId} '
                    'reason=unaffordable'
              : 'castIron labour peasant recruit deferred nationId=${ctx.nationId} '
                    'reason=fabric_short',
        );
      }
    }
  }
}
