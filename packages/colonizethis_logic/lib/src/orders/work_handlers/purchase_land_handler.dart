import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../../constants.dart';
import '../orders_application_context.dart';
import '../purchase_land_work_completion.dart';
import 'shared_work_assignment.dart';
import 'work_order_handler.dart';

class PurchaseLandWorkOrderHandler implements WorkOrderHandler {
  const PurchaseLandWorkOrderHandler();

  @override
  bool supports(String target) => target == kWorkTargetPurchaseLand;

  @override
  bool tryApply(
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
}
