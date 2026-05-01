import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../constants.dart';
import '../world/province_lookup.dart';
import 'build_rail_work_rules.dart';
import 'orders_application_context.dart';
import 'work_handlers/counter_spy_work_handler.dart';
import 'work_handlers/explore_work_handler.dart';
import 'work_handlers/prospect_work_handler.dart';
import 'work_handlers/purchase_land_handler.dart';
import 'work_handlers/steal_tech_work_handler.dart';
import 'work_handlers/standard_work_handler.dart';

abstract class _WorkOrderHandler {
  bool supports(String target);

  bool tryApply(
    _WorkOrderExecutionContext context,
    WorkOrder order,
    Unit unit,
    String targetTileKey,
    bool hasValidTarget,
  );
}

class _WorkOrderExecutionContext {
  _WorkOrderExecutionContext({required this.state, required this.player})
    : stockpile = player.stockpile,
      workers = player.workerPool,
      treasury = player.treasury,
      purchasedTilesByTileKey = Map<String, String>.from(
        state.work.purchasedTilesByTileKey,
      );

  BuildWorkState state;
  final Player player;
  Stockpile stockpile;
  WorkerPool workers;
  int treasury;
  Map<String, String> purchasedTilesByTileKey;

  Unit? lookupUnit(String unitId) =>
      state.work.oldUnitsById[unitId] ?? state.work.newUnitsById[unitId];

  void updateUnit(String unitId, Unit updated) {
    if (state.work.oldUnitsById.containsKey(unitId)) {
      state = state.copyWith(
        work: state.work.copyWith(
          oldUnitsById: Map<String, Unit>.from(state.work.oldUnitsById)
            ..[unitId] = updated,
        ),
      );
    } else {
      state = state.copyWith(
        work: state.work.copyWith(
          newUnitsById: Map<String, Unit>.from(state.work.newUnitsById)
            ..[unitId] = updated,
        ),
      );
    }
  }

  String regionForUnit(String unitId) =>
      state.work.oldUnitsById.containsKey(unitId)
      ? kRegionOldWorld
      : kRegionNewWorld;

  Province? provinceById(String id) => state.game.worldState.tryGetProvince(id);

  bool canAffordMaterialCost(WorkOrderCost cost) {
    for (final e in cost.entries) {
      if (stockpile.quantityOf(e.key) < e.value) return false;
    }
    return true;
  }

  void deductMaterialCost(WorkOrderCost cost) {
    for (final e in cost.entries) {
      stockpile = stockpile.applyDelta(e.key, -e.value);
    }
  }

  void persistPlayerSnapshot() {
    state = state.copyWith(
      work: state.work.copyWith(
        purchasedTilesByTileKey: purchasedTilesByTileKey,
        updatedPlayers: [
          ...state.work.updatedPlayers,
          player.copyWith(
            stockpile: stockpile,
            workerPool: workers,
            treasury: treasury,
          ),
        ],
      ),
    );
  }
}

class _PurchaseLandWorkOrderHandler implements _WorkOrderHandler {
  const _PurchaseLandWorkOrderHandler();

  @override
  bool supports(String target) => target == kWorkTargetPurchaseLand;

  @override
  bool tryApply(
    _WorkOrderExecutionContext context,
    WorkOrder order,
    Unit unit,
    String targetTileKey,
    bool hasValidTarget,
  ) {
    if (!isWorkOrderTargetAllowedForUnitType(
          unit.type,
          kWorkTargetPurchaseLand,
        ) ||
        unit.currentWork != null ||
        !hasValidTarget) {
      return false;
    }
    final land = applyPurchaseLandWorkOrder(
      state: context.state,
      player: context.player,
      unit: unit,
      targetTileKey: targetTileKey,
      treasury: context.treasury,
      purchasedTilesByTileKey: context.purchasedTilesByTileKey,
      provinceById: context.provinceById,
      updateUnit: context.updateUnit,
    );
    context.treasury = land.treasury;
    context.purchasedTilesByTileKey = land.purchasedTilesByTileKey;
    context.state = context.state.copyWith(
      work: context.state.work.copyWith(
        purchasedTilesByTileKey: context.purchasedTilesByTileKey,
      ),
    );
    return true;
  }
}

class _StealTechWorkOrderHandler implements _WorkOrderHandler {
  const _StealTechWorkOrderHandler();

  @override
  bool supports(String target) => target == kWorkTargetStealTech;

  @override
  bool tryApply(
    _WorkOrderExecutionContext context,
    WorkOrder order,
    Unit unit,
    String targetTileKey,
    bool hasValidTarget,
  ) {
    return tryAssignStealTechWorkOrder(
      order: order,
      unit: unit,
      targetTileKey: targetTileKey,
      updateUnit: context.updateUnit,
    );
  }
}

class _CounterSpyWorkOrderHandler implements _WorkOrderHandler {
  const _CounterSpyWorkOrderHandler();

  @override
  bool supports(String target) => target == kWorkTargetCounterSpy;

  @override
  bool tryApply(
    _WorkOrderExecutionContext context,
    WorkOrder order,
    Unit unit,
    String targetTileKey,
    bool hasValidTarget,
  ) {
    return tryAssignCounterSpyWorkOrder(
      order: order,
      unit: unit,
      targetTileKey: targetTileKey,
      updateUnit: context.updateUnit,
    );
  }
}

class _ProspectWorkOrderHandler implements _WorkOrderHandler {
  const _ProspectWorkOrderHandler();

  @override
  bool supports(String target) => target == kWorkTargetProspect;

  @override
  bool tryApply(
    _WorkOrderExecutionContext context,
    WorkOrder order,
    Unit unit,
    String targetTileKey,
    bool hasValidTarget,
  ) {
    context.state = context.state.copyWith(
      game: tryApplyProspectWorkOrder(
        game: context.state.game,
        tileMapByRegion: context.state.tileMapByRegion,
        player: context.player,
        unit: unit,
        targetTileKey: targetTileKey,
        updateUnit: context.updateUnit,
      ),
    );
    return true;
  }
}

class _BuildImprovementWorkOrderHandler implements _WorkOrderHandler {
  const _BuildImprovementWorkOrderHandler();

  @override
  bool supports(String target) => target == kWorkTargetBuildImprovement;

  @override
  bool tryApply(
    _WorkOrderExecutionContext context,
    WorkOrder order,
    Unit unit,
    String targetTileKey,
    bool hasValidTarget,
  ) {
    return applyStandardWorkOrder(
      order: order,
      unit: unit,
      targetTileKey: targetTileKey,
      hasValidTarget: hasValidTarget,
      orderTarget: kWorkTargetBuildImprovement,
      tileState: context.state.work.tileState,
      provinceById: context.provinceById,
      canAffordMaterialCost: context.canAffordMaterialCost,
      deductMaterialCost: context.deductMaterialCost,
      updateUnit: context.updateUnit,
    );
  }
}

class _ExploreWorkOrderHandler implements _WorkOrderHandler {
  const _ExploreWorkOrderHandler();

  @override
  bool supports(String target) => target == kWorkTargetExplore;

  @override
  bool tryApply(
    _WorkOrderExecutionContext context,
    WorkOrder order,
    Unit unit,
    String targetTileKey,
    bool hasValidTarget,
  ) {
    if (!isExplorerUnit(unit.type) ||
        unit.currentWork != null ||
        !hasValidTarget) {
      return false;
    }
    return tryApplyExploreWorkOrder(
      game: context.state.game,
      order: order,
      unit: unit,
      targetTileKey: targetTileKey,
      regionForUnit: context.regionForUnit,
      updateUnit: context.updateUnit,
    );
  }
}

class _RemainingStandardBuildTargetsWorkOrderHandler
    implements _WorkOrderHandler {
  const _RemainingStandardBuildTargetsWorkOrderHandler();

  @override
  bool supports(String target) {
    return target == kWorkTargetBuildRoad ||
        target == kWorkTargetBuildPort ||
        target == kWorkTargetUpgradeTown ||
        target == kWorkTargetBuildFort ||
        target == kWorkTargetBuildRail;
  }

  @override
  bool tryApply(
    _WorkOrderExecutionContext context,
    WorkOrder order,
    Unit unit,
    String targetTileKey,
    bool hasValidTarget,
  ) {
    return tryApplyRemainingStandardBuildTargets(
      workTarget: order.target,
      order: order,
      player: context.player,
      unit: unit,
      targetTileKey: targetTileKey,
      hasValidTarget: hasValidTarget,
      tileState: context.state.work.tileState,
      provinceById: context.provinceById,
      canAffordMaterialCost: context.canAffordMaterialCost,
      deductMaterialCost: context.deductMaterialCost,
      updateUnit: context.updateUnit,
      terrain: terrainTypeForTileKey(
        context.state.tileMapByRegion,
        targetTileKey,
      ),
    );
  }
}

const List<_WorkOrderHandler> _workOrderHandlers = [
  _PurchaseLandWorkOrderHandler(),
  _StealTechWorkOrderHandler(),
  _CounterSpyWorkOrderHandler(),
  _ProspectWorkOrderHandler(),
  _BuildImprovementWorkOrderHandler(),
  _ExploreWorkOrderHandler(),
  _RemainingStandardBuildTargetsWorkOrderHandler(),
];

BuildWorkState runWorkPhase(
  BuildWorkState state,
  BuildWorkState Function(BuildWorkState, Unit, String) applyExploreCompletion,
  BuildWorkState Function(
    BuildWorkState,
    Unit,
    CurrentWork,
    List<Province> Function(),
    WorkOrderState Function(WorkOrderState, List<Province>),
  )
  applyCompletedWorkTarget,
) {
  final workOrders = state.workOrders;
  var current = state;

  for (final player in current.game.players) {
    final context = _WorkOrderExecutionContext(state: current, player: player);

    for (final order in workOrders[player.id] ?? const []) {
      final u = context.lookupUnit(order.unitId);
      if (u == null) continue;
      final targetTileKey = order.targetTileKey;
      final hasValidTarget = targetTileKey.isNotEmpty;
      for (final handler in _workOrderHandlers) {
        if (!handler.supports(order.target)) continue;
        if (handler.tryApply(
          context,
          order,
          u,
          targetTileKey,
          hasValidTarget,
        )) {
          break;
        }
      }
    }

    context.persistPlayerSnapshot();
    current = context.state;
  }

  return current;
}
