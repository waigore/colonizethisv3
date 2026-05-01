import 'package:colonizethis_models/colonizethis_models.dart';

import '../../constants.dart';
import 'shared_work_assignment.dart';
import 'work_order_handler.dart';

class CounterSpyWorkOrderHandler implements WorkOrderHandler {
  const CounterSpyWorkOrderHandler();

  @override
  bool supports(String target) => target == kWorkTargetCounterSpy;

  @override
  bool tryApply(
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
}
