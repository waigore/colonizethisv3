import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../../constants.dart';
import '../orders_application_helpers.dart';
import '../purchase_land_work_completion.dart';
import 'explore_work_handler.dart';
import 'shared_work_assignment.dart';
import 'work_order_handler.dart';

typedef SimpleWorkApply =
    bool Function(
      WorkOrderExecutionContext context,
      WorkOrder order,
      Unit unit,
      String targetTileKey,
      bool hasValidTarget,
    );

/// Parameterized [WorkOrderHandler] for targets that share a single assignment path.
class SimpleWorkOrderHandler implements WorkOrderHandler {
  SimpleWorkOrderHandler({required this.supportedTarget, required this.apply});

  final String supportedTarget;
  final SimpleWorkApply apply;

  @override
  bool supports(String target) => target == supportedTarget;

  @override
  bool tryApply(
    WorkOrderExecutionContext context,
    WorkOrder order,
    Unit unit,
    String targetTileKey,
    bool hasValidTarget,
  ) => apply(context, order, unit, targetTileKey, hasValidTarget);
}

bool _applyExploreWorkOrder(
  WorkOrderExecutionContext context,
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

bool _applyStealTechWorkOrder(
  WorkOrderExecutionContext context,
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

bool _applyCounterSpyWorkOrder(
  WorkOrderExecutionContext context,
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

bool _applyProspectWorkOrder(
  WorkOrderExecutionContext context,
  WorkOrder order,
  Unit unit,
  String targetTileKey,
  bool hasValidTarget,
) {
  if (!isExplorerUnit(unit.type) ||
      unit.currentWork != null ||
      !hasValidTarget ||
      targetTileKey.isEmpty) {
    return false;
  }
  if (!isMineralEligibleTile(
    context.state.game,
    context.state.tileMapByRegion,
    targetTileKey,
  )) {
    return false;
  }
  final existing =
      context.state.game.worldState.playerProspectedTiles[context.player.id] ??
      const <String>{};
  if (existing.contains(targetTileKey)) {
    return false;
  }
  return tryAssignFixedDurationWorkOrder(
    order: order,
    unit: unit,
    targetTileKey: targetTileKey,
    target: kWorkTargetProspect,
    totalTurns: totalTurnsForWork(kWorkTargetProspect),
    remainingTurns: totalTurnsForWork(kWorkTargetProspect),
    updateUnit: context.updateUnit,
  );
}

bool _applyPurchaseLandWorkOrder(
  WorkOrderExecutionContext context,
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
  if (!purchaseLandEligibleAtAssign(
    state: context.state,
    player: context.player,
    unit: unit,
    targetTileKey: targetTileKey,
    treasury: context.treasury,
    purchasedTilesByTileKey: context.purchasedTilesByTileKey,
    provinceById: context.provinceById,
  )) {
    return false;
  }
  return tryAssignFixedDurationWorkOrder(
    order: order,
    unit: unit,
    targetTileKey: targetTileKey,
    target: kWorkTargetPurchaseLand,
    totalTurns: totalTurnsForWork(kWorkTargetPurchaseLand),
    remainingTurns: totalTurnsForWork(kWorkTargetPurchaseLand),
    updateUnit: context.updateUnit,
  );
}

final WorkOrderHandler exploreWorkOrderHandler = SimpleWorkOrderHandler(
  supportedTarget: kWorkTargetExplore,
  apply: _applyExploreWorkOrder,
);

final WorkOrderHandler purchaseLandWorkOrderHandler = SimpleWorkOrderHandler(
  supportedTarget: kWorkTargetPurchaseLand,
  apply: _applyPurchaseLandWorkOrder,
);

final WorkOrderHandler stealTechWorkOrderHandler = SimpleWorkOrderHandler(
  supportedTarget: kWorkTargetStealTech,
  apply: _applyStealTechWorkOrder,
);

final WorkOrderHandler counterSpyWorkOrderHandler = SimpleWorkOrderHandler(
  supportedTarget: kWorkTargetCounterSpy,
  apply: _applyCounterSpyWorkOrder,
);

final WorkOrderHandler prospectWorkOrderHandler = SimpleWorkOrderHandler(
  supportedTarget: kWorkTargetProspect,
  apply: _applyProspectWorkOrder,
);
