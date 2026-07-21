import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../diplomatic_access_helpers.dart';
import '../order_validation_result.dart';
import 'work_order_target_prechecks_shared.dart';

OrderValidationResult? precheckCounterSpy(
  WorkOrderTargetPrecheckContext ctx,
  WorkOrder order,
  String? targetProvinceId,
  String? provinceOwnerId,
  String unitType,
) {
  if (provinceOwnerId != ctx.playerId) {
    return OrderValidationResult.rejected(
      'counter_spy target must be your own province',
    );
  }
  return null;
}

OrderValidationResult? precheckExplorerConsulateInMinorTribe(
  WorkOrderTargetPrecheckContext ctx,
  WorkOrder order,
  String? targetProvinceId,
  String? provinceOwnerId,
  String unitType,
) {
  return rejectExplorerWithoutConsulateInMinorTribeProvince(
    game: ctx.game,
    playerId: ctx.playerId,
    unitType: unitType,
    workTarget: order.target,
    provinceOwnerId: provinceOwnerId,
    factionMembership: ctx.factionMembership,
  );
}

OrderValidationResult? precheckDefaultForeignProvince(
  WorkOrderTargetPrecheckContext ctx,
  WorkOrder order,
  String? targetProvinceId,
  String? provinceOwnerId,
  String unitType,
) {
  if (isExplorerUnit(unitType) ||
      kWorkTargetsSkippingDefaultForeignProvinceCheck.contains(order.target)) {
    return null;
  }
  return rejectIfUncontrolledWithoutEmbassyWork(
    ctx,
    order.targetTileKey,
    unitType: unitType,
    provinceOwnerId: provinceOwnerId,
    message: 'Cannot work in foreign province',
  );
}
