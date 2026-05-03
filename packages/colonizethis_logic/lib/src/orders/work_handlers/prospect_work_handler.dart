import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../../constants.dart';
import '../orders_application_helpers.dart';
import 'shared_work_assignment.dart';
import 'work_order_handler.dart';

class ProspectWorkOrderHandler implements WorkOrderHandler {
  const ProspectWorkOrderHandler();

  @override
  bool supports(String target) => target == kWorkTargetProspect;

  @override
  bool tryApply(
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
}
