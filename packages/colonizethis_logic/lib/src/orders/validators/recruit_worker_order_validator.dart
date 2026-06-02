import 'package:colonizethis_models/colonizethis_models.dart';

import '../../economy/worker_action_cost.dart';
import '../order_validation_result.dart';

import 'stateful_validator.dart';

/// Validates `RecruitWorkerOrder`s for a single player in submission order.
///
/// Mutates internal economy state (workerPool, stockpile, treasury) when an
/// order is accepted so subsequent orders in the same player's chain — both
/// recruit orders and (downstream) `BuildUnitOrder` peasant consumes — see the
/// post-deduction state. This is the **peasant reservation ledger** required
/// by `SPEC/game/workers-and-population.md` § Peasant reservation.
///
/// Spec:
/// - `SPEC/game/workers-and-population.md` § Recruiting, Training, and
///   Disbanding (cost table, rejection reasons, peasant reservation).
/// - `SPEC/program/orders.md` § RecruitWorkerOrder.
/// - `SPEC/program/turn-resolution-phase-details.md` § Build / work
///   (worker pool orders resolve before [BuildUnitOrder]).
class RecruitWorkerOrderValidator extends StatefulValidator {
  RecruitWorkerOrderValidator({required Player player})
    : _player = player,
      super(
        stockpileState: player.stockpile,
        treasuryState: player.treasury,
        workerPoolState: player.workerPool,
      );

  /// Allows the order engine to seed projected economy state (e.g. after a
  /// previous validator phase deducted treasury). Mirrors
  /// `BuildOrderValidator.withProjectedEconomy`.
  RecruitWorkerOrderValidator.withProjectedEconomy({
    required Player player,
    required Stockpile stockpile,
    required int treasury,
    required WorkerPool workerPool,
  }) : _player = player,
       super(
         stockpileState: stockpile,
         treasuryState: treasury,
         workerPoolState: workerPool,
       );

  final Player _player;

  WorkerPool get workers => workerPoolState;
  Stockpile get stockpile => stockpileState;
  int get treasury => treasuryState;

  /// Validates one [RecruitWorkerOrder] against the running economy snapshot.
  /// When accepted, deducts the cost row from [workers] / [stockpile] /
  /// [treasury] so the next order in the chain sees the post-deduction state.
  ///
  /// Rejection reasons come from `worker_action_cost.dart` and match the GDD
  /// vocabulary (`Insufficient workers`, `Insufficient materials`,
  /// `Insufficient treasury`, `Required technology not unlocked`).
  OrderValidationResult validate(
    RecruitWorkerOrder order, {
    required bool previousRejected,
  }) {
    return shortCircuitIfPreviousRejected(
      previousRejected: previousRejected,
      body: () {
        final check = canAffordRecruitWorker(
          _player,
          order,
          workerPoolState,
          stockpileState,
          treasuryState,
        );
        if (!check.canAfford) {
          return OrderValidationResult.rejected(
            check.reason ?? kRecruitWorkerInsufficientMaterials,
          );
        }
        final after = applyRecruitWorkerCostDeduction(
          order,
          workerPoolState,
          stockpileState,
          treasuryState,
        );
        workerPoolState = after.workers;
        stockpileState = after.stockpile;
        treasuryState = after.treasury;
        return OrderValidationResult.accepted();
      },
    );
  }
}
