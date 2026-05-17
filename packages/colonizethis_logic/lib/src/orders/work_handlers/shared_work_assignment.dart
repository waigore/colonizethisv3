import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/src/logging.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../../constants.dart';

bool tryAssignFixedDurationWorkOrder({
  required WorkOrder order,
  required Unit unit,
  required String targetTileKey,
  required String target,
  required int totalTurns,
  required int remainingTurns,
  required void Function(String, Unit) updateUnit,
}) {
  if (!isWorkOrderTargetAllowedForUnitType(unit.type, target)) return false;
  if (unit.currentWork != null || targetTileKey.isEmpty) return false;
  logicLog.d(
    'work order accepted and assigned unit=${order.unitId} target=$target targetTileKey=$targetTileKey totalTurns=$totalTurns',
  );
  updateUnit(
    order.unitId,
    unit.copyWith(
      status: UnitStatus.working,
      tileKey: targetTileKey,
      originTileKey: unit.originTileKey ?? unit.tileKey,
      assignedTileKey: targetTileKey,
      currentWork: CurrentWork(
        workTarget: target,
        tileKey: targetTileKey,
        totalTurns: totalTurns,
        remainingTurns: remainingTurns,
      ),
    ),
  );
  return true;
}

bool tryAssignStealTechWorkOrder({
  required WorkOrder order,
  required Unit unit,
  required String targetTileKey,
  required void Function(String, Unit) updateUnit,
}) {
  return tryAssignFixedDurationWorkOrder(
    order: order,
    unit: unit,
    targetTileKey: targetTileKey,
    target: kWorkTargetStealTech,
    totalTurns: totalTurnsForWork(kWorkTargetStealTech),
    remainingTurns: totalTurnsForWork(kWorkTargetStealTech),
    updateUnit: updateUnit,
  );
}

bool tryAssignCounterSpyWorkOrder({
  required WorkOrder order,
  required Unit unit,
  required String targetTileKey,
  required void Function(String, Unit) updateUnit,
}) {
  return tryAssignFixedDurationWorkOrder(
    order: order,
    unit: unit,
    targetTileKey: targetTileKey,
    target: kWorkTargetCounterSpy,
    totalTurns: totalTurnsForWork(kWorkTargetCounterSpy),
    remainingTurns: 1,
    updateUnit: updateUnit,
  );
}
