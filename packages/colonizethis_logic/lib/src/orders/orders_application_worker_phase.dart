import 'package:colonizethis_models/colonizethis_models.dart';

import '../economy/projected_cost_engine.dart';
import 'orders_application_context.dart';

/// Resolves queued [RecruitWorkerOrder] entries during the Build / work
/// phase, **before** [BuildUnitOrder] processing. Worker pool deltas settle
/// first so any subsequent military/naval build's peasant consume sees the
/// post-recruit headcount.
///
/// SPEC/game/workers-and-population.md § Recruiting, Training, and Disbanding;
/// SPEC/program/turn-resolution-phase-details.md § Build / work (Order
/// within the phase).
///
/// Behaviour mirrors `runBuildPhase`: orders are applied in submission order
/// per player; orders that fail affordability or tech gates at apply time are
/// **skipped** (not partially applied) and the loop continues. Same-turn
/// labour effects: pool changes here affect **next-turn** Consumption and
/// Production — the phase sequence is not re-ordered (SPEC § Phase placement).
BuildWorkState runWorkerPoolPhase(BuildWorkState state) {
  final ordersByPlayer = state.recruitWorkerOrders;
  if (ordersByPlayer.isEmpty) return state;

  var current = state;
  for (final player in current.game.players) {
    final playerOrders =
        ordersByPlayer[player.id] ?? const <RecruitWorkerOrder>[];
    if (playerOrders.isEmpty) continue;

    var workers = player.workerPool;
    var stockpile = player.stockpile;
    var treasury = player.treasury;

    for (final order in playerOrders) {
      final check = ProjectedCostEngine.canAffordRecruitWorkerOrder(
        player,
        order,
        workers,
        stockpile,
        treasury,
      );
      if (!check.canAfford) {
        ordersApplicationLog.d(
          'recruit worker order skipped player=${player.id} '
          'tier=${order.targetTier.id} reason=${check.reason}',
        );
        continue;
      }
      final after = ProjectedCostEngine.applyRecruitWorkerOrderCostDeduction(
        player,
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
                      stockpile: stockpile,
                      workerPool: workers,
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
