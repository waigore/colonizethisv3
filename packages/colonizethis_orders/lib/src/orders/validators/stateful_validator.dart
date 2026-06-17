import 'package:colonizethis_models/colonizethis_models.dart';

import '../order_validation_result.dart';

/// Base for validators that mutate economy fields while validating a player's
/// orders in submission order. [stockpileState] and [workerPoolState] are
/// carried for [WorkOrderValidator] / [BuildOrderValidator]; diplomatic
/// validation mutates [treasuryState] only. SPEC/program/orders.md.
abstract class StatefulValidator extends OrderValidator {
  StatefulValidator({
    required Stockpile stockpileState,
    required int treasuryState,
    required WorkerPool workerPoolState,
  }) : stockpileState = stockpileState,
       treasuryState = treasuryState,
       workerPoolState = workerPoolState,
       super();

  /// Seeds economy fields from a projected snapshot (after replaying prior
  /// orders in submission order). Shared by build and recruit validators.
  StatefulValidator.withProjectedEconomy({
    required Stockpile stockpile,
    required int treasury,
    required WorkerPool workerPool,
  }) : stockpileState = stockpile,
       treasuryState = treasury,
       workerPoolState = workerPool,
       super();

  Stockpile stockpileState;
  int treasuryState;
  WorkerPool workerPoolState;

  /// When [check.canAfford], runs [applyDeduction] and accepts; otherwise
  /// rejects using [check.reason] or [defaultRejectionReason].
  OrderValidationResult applyCostIfAffordable({
    required ({bool canAfford, String? reason}) check,
    required void Function() applyDeduction,
    String defaultRejectionReason = 'Insufficient resources',
  }) {
    if (!check.canAfford) {
      return OrderValidationResult.rejected(
        check.reason ?? defaultRejectionReason,
      );
    }
    applyDeduction();
    return OrderValidationResult.accepted();
  }
}
