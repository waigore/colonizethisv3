import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/package_logger.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../../constants.dart';
import 'work_order_handler.dart';

bool tryApplyExploreWorkOrder({
  required Game game,
  required WorkOrder order,
  required Unit unit,
  required String targetTileKey,
  required String Function(String) regionForUnit,
  required void Function(String, Unit) updateUnit,
}) {
  final regionId = regionForUnit(order.unitId);
  final provinceId =
      Unit.provinceIdFromTileKey(targetTileKey) ?? unit.locationProvinceId;
  final byProvince = game.worldState.tileKeysByRegionAndProvince[regionId];
  if (byProvince == null || byProvince.isEmpty) return false;

  final tilesInP = byProvince[provinceId]?.length ?? 0;
  if (tilesInP <= 0) return false;

  var maxTiles = 1;
  for (final list in byProvince.values) {
    if (list.length > maxTiles) maxTiles = list.length;
  }
  final totalTurns = (3 * tilesInP / maxTiles).ceil().clamp(1, 999);
  logicLog.d(
    'work order accepted and assigned unit=${order.unitId} target=explore targetTileKey=$targetTileKey totalTurns=$totalTurns',
  );
  updateUnit(
    order.unitId,
    unit.copyWith(
      status: UnitStatus.working,
      tileKey: targetTileKey,
      originTileKey: unit.originTileKey ?? unit.tileKey,
      assignedTileKey: targetTileKey,
      currentWork: CurrentWork(
        workTarget: kWorkTargetExplore,
        tileKey: targetTileKey,
        totalTurns: totalTurns,
        remainingTurns: totalTurns,
      ),
    ),
  );
  return true;
}

class ExploreWorkOrderHandler implements WorkOrderHandler {
  const ExploreWorkOrderHandler();

  @override
  bool supports(String target) => target == kWorkTargetExplore;

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
