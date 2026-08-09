import '../util/orders_builder.dart';
import 'economy_phase_gates.dart';
import 'growth_stage.dart';
import 'growth_stage_builder_relocation.dart';
import 'growth_stage_work_priorities.dart';
import 'goal_manager.dart';
import 'phase_planner_work_order_filter.dart';
import 'planner_context.dart';
import 'planning_imports.dart';

final _civilianWorkLog = packageLogger('domain_planner_orchestrator_economy');

/// Runs civilian-work selection and appends orders into [ordersBuilder].
List<WorkOrder> runEconomyCivilianWorkPass({
  required PlannerContext ctx,
  required EconomyPhaseGates economyPhaseGates,
  required OrdersBuilder ordersBuilder,
  required List<WorkOrder> workCandidates,
  required GrowthStage? growthStage,
  required bool growthStagePlannerEnabled,
  Map<String, TileMapResult>? tileMapByRegion,
}) {
  final developPhase = economyPhaseGates.developActive;
  var candidates = growthStage != null
      ? prioritizeWorkOrdersForGrowthStage(
          workCandidates: workCandidates,
          game: ctx.game,
          playerId: ctx.nationId,
          stage: growthStage,
        )
      : workCandidates;
  final feedstockPreference = growthStage != null
      ? growthStageFeedstockPreference(
          game: ctx.game,
          playerId: ctx.nationId,
          stage: growthStage,
          growthStagePlannerEnabled: growthStagePlannerEnabled,
        )
      : GrowthStageFeedstockPreference.none;
  if (growthStage != null) {
    final relocation = suggestGrowthStageBuilderFeedstockRelocation(
      game: ctx.game,
      view: ctx.view,
      topology: ctx.topology,
      currentOrders: ordersBuilder.build(),
      suggestionAPI: ctx.suggestionAPI,
      stage: growthStage,
      feedstockPreference: feedstockPreference,
      growthStagePlannerEnabled: growthStagePlannerEnabled,
    );
    if (relocation != null) {
      _civilianWorkLog.i(
        'growth_stage_builder_relocate nationId=${ctx.nationId} '
        'unitId=${relocation.unitId} '
        'destinationTileKey=${relocation.destinationTileKey}',
      );
      ordersBuilder.appendMoveOrders(ctx.nationId, [relocation]);
      final movedUnitIds = {relocation.unitId};
      candidates = candidates
          .where((w) => !movedUnitIds.contains(w.unitId))
          .toList();
    }
  }
  final selection = selectFullAiCivilianWorkOrders(
    workSuggestions: candidates,
    view: ctx.view,
    game: ctx.game,
    tileMapByRegion: tileMapByRegion,
    topology: ctx.topology,
    growthStageFabricFeedstockResourceIds:
        feedstockPreference.fabricFeedstockResourceIds,
    growthStageInfraFeedstockResourceIds:
        feedstockPreference.infraFeedstockResourceIds,
    spyDevelopPhase: developPhase,
  );
  for (final w in selection.workOrders) {
    final unitType = ctx.view.ownUnitsById[w.unitId]?.type ?? 'unknown';
    _civilianWorkLog.i(
      'civilian_work_assigned nationId=${ctx.nationId} unitId=${w.unitId} '
      'unitType=$unitType target=${w.target} targetTileKey=${w.targetTileKey}',
    );
  }
  for (final idle in selection.idleEvents) {
    _civilianWorkLog.i(
      'civilian_work_idle nationId=${ctx.nationId} unitId=${idle.unitId} '
      'unitType=${idle.unitType} reason=${idle.reason}',
    );
  }
  if (selection.workOrders.isNotEmpty) {
    ordersBuilder.appendWorkOrders(ctx.nationId, selection.workOrders);
  }
  return candidates;
}
