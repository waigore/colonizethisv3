import 'package:colonizethis_models/colonizethis_models.dart';

import '../order_work_constants.dart';
import '../order_validation_result.dart';
import 'work_order_target_prechecks_explore.dart';
import 'work_order_target_prechecks_improvement.dart';
import 'work_order_target_prechecks_purchase.dart';
import 'work_order_target_prechecks_shared.dart';

export 'work_order_target_prechecks_explore.dart';
export 'work_order_target_prechecks_improvement.dart';
export 'work_order_target_prechecks_purchase.dart';
export 'work_order_target_prechecks_shared.dart';

/// Map dispatch for target-specific validation before generic work rules.
final Map<String, WorkOrderTargetPrecheck> workOrderTargetPrechecks = {
  kWorkTargetUpgradeTown: precheckUpgradeTown,
  kWorkTargetCounterSpy: precheckCounterSpy,
  kWorkTargetPurchaseLand: precheckPurchaseLand,
  kWorkTargetBuildImprovement: precheckBuildImprovement,
};

/// Shared territory checks that run for every work target after any
/// target-specific precheck (Refs #3877).
const List<WorkOrderTargetPrecheck> _sharedWorkOrderTargetPrechecks = [
  precheckExplorerConsulateInMinorTribe,
  precheckDefaultForeignProvince,
  precheckDevExclusiveTileConflict,
];

/// Runs target-specific prechecks, then shared territory rules.
OrderValidationResult? runWorkOrderTargetPrecheck(
  WorkOrderTargetPrecheckContext ctx,
  WorkOrder order,
  String? targetProvinceId,
  String? provinceOwnerId,
  String unitType,
) {
  final targetFn = workOrderTargetPrechecks[order.target];
  if (targetFn != null) {
    final targetResult = targetFn(
      ctx,
      order,
      targetProvinceId,
      provinceOwnerId,
      unitType,
    );
    if (targetResult != null) {
      return targetResult;
    }
  }
  for (final sharedFn in _sharedWorkOrderTargetPrechecks) {
    final sharedResult = sharedFn(
      ctx,
      order,
      targetProvinceId,
      provinceOwnerId,
      unitType,
    );
    if (sharedResult != null) {
      return sharedResult;
    }
  }
  return null;
}
