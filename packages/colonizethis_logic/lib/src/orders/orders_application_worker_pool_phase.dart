import '../economy/worker_action_cost.dart';
import 'orders_application_context.dart';

/// Worker pool sub-phase of Build / work (phase 12).
///
/// Applies queued `RecruitWorkerOrder`s per player, in submission order, so
/// the WorkerPool deltas settle **before** the unit build loop in
/// [runBuildPhase] (subsequent military / naval builds therefore see the
/// post-recruit peasant headcount; civilian builds do not consume peasants).
///
/// SPEC sources:
/// - `SPEC/game/workers-and-population.md` § Recruiting, Training, and
///   Disbanding (cost table, peasant reservation, tech gates).
/// - `SPEC/program/turn-resolution-phase-details.md` § Build / work
///   (worker pool orders resolve first).
/// - `SPEC/program/orders.md` § RecruitWorkerOrder.
BuildWorkState runWorkerPoolPhase(BuildWorkState state) {
  final recruitOrdersByPlayerId = state.recruitWorkerOrders;
  if (recruitOrdersByPlayerId.isEmpty) {
    return state;
  }

  var current = state;
  for (final player in current.game.players) {
    final orders = recruitOrdersByPlayerId[player.id];
    if (orders == null || orders.isEmpty) continue;

    var workers = player.workerPool;
    var stockpile = player.stockpile;
    var treasury = player.treasury;

    for (final order in orders) {
      final check = canAffordRecruitWorker(
        player,
        order,
        workers,
        stockpile,
        treasury,
      );
      if (!check.canAfford) continue;

      final after = applyRecruitWorkerCostDeduction(
        order,
        workers,
        stockpile,
        treasury,
      );
      workers = after.workers;
      stockpile = after.stockpile;
      treasury = after.treasury;
    }

    current = current.copyWith(
      game: current.game.copyWith(
        players: current.game.players
            .map(
              (p) => p.id == player.id
                  ? p.copyWith(
                      workerPool: workers,
                      stockpile: stockpile,
                      treasury: treasury,
                    )
                  : p,
            )
            .toList(),
      ),
    );
  }

  return current;
}
