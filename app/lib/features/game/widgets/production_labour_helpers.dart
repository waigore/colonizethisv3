// Pure helpers for the Production panel Labour controls section.
// SPEC/ui/production-panel.md § Labour Controls, SPEC/game/workers-and-population.md.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

/// Render order for the four Labour rows. Peasant first, then trained tiers
/// in tech-tier order — matches the Workers grid above and the worker tier
/// table in SPEC/game/workers-and-population.md § Worker Tiers.
const List<WorkerTier> kProductionLabourTierOrder = <WorkerTier>[
  WorkerTier.peasant,
  WorkerTier.apprentice,
  WorkerTier.journeyman,
  WorkerTier.master,
];

/// Callbacks emitted by Labour controls. The screen wires these to
/// `currentOrdersProvider` (recruit queue) and `currentGameProvider`
/// (immediate disband).
class ProductionLabourCallbacks {
  const ProductionLabourCallbacks({
    required this.onAppendRecruitOrder,
    required this.onPopLastRecruitOrder,
    required this.onDisband,
  });

  /// Append one [RecruitWorkerOrder] at [tier] to the viewed player's queue.
  final void Function(WorkerTier tier) onAppendRecruitOrder;

  /// Remove the last queued [RecruitWorkerOrder] at [tier] (LIFO).
  final void Function(WorkerTier tier) onPopLastRecruitOrder;

  /// Immediately apply disband on one [tier] worker. Peasant is invalid
  /// per SPEC § Disband; callers must filter trained tiers only.
  final void Function(WorkerTier tier) onDisband;
}

/// Inputs needed to render one tier row's stepper + disband controls.
class ProductionLabourTierRowData {
  const ProductionLabourTierRowData({
    required this.tier,
    required this.poolCount,
    required this.queuedCount,
    required this.canAppend,
    required this.canPop,
    required this.canDisband,
  });

  final WorkerTier tier;
  final int poolCount;
  final int queuedCount;
  final bool canAppend;
  final bool canPop;
  final bool canDisband;
}

/// Pure builder that maps a [Player] + [Orders] snapshot to one row data
/// per tier in canonical render order. Kept side-effect-free so tests can
/// assert affordance and queue counts without mounting the widget.
List<ProductionLabourTierRowData> buildProductionLabourRowData({
  required Player player,
  required Orders currentOrders,
  required bool canEdit,
}) {
  final queued = queuedRecruitWorkerCountsByTier(
    currentOrders: currentOrders,
    playerId: player.id,
  );
  final rows = <ProductionLabourTierRowData>[];
  for (final tier in kProductionLabourTierOrder) {
    final poolCount = workerPoolTierCount(player.workerPool, tier);
    final queuedCount = queued[tier] ?? 0;
    final canAppend = canEdit &&
        canAppendRecruitWorkerOrder(
          player: player,
          currentOrders: currentOrders,
          candidateTier: tier,
        );
    final canPop = canEdit && queuedCount > 0;
    final canDisband =
        canEdit && tier != WorkerTier.peasant && poolCount > 0;
    rows.add(
      ProductionLabourTierRowData(
        tier: tier,
        poolCount: poolCount,
        queuedCount: queuedCount,
        canAppend: canAppend,
        canPop: canPop,
        canDisband: canDisband,
      ),
    );
  }
  return rows;
}

/// Per-tier queued recruit-worker counts for [playerId] from [currentOrders].
///
/// Returns a dense map for every [WorkerTier] (zero when absent) so callers
/// can render rows without nullable lookups.
Map<WorkerTier, int> queuedRecruitWorkerCountsByTier({
  required Orders currentOrders,
  required String playerId,
}) {
  final counts = <WorkerTier, int>{
    for (final tier in WorkerTier.values) tier: 0,
  };
  final orders =
      currentOrders.recruitWorkerOrdersByPlayerId[playerId] ??
      const <RecruitWorkerOrder>[];
  for (final order in orders) {
    counts[order.targetTier] = (counts[order.targetTier] ?? 0) + 1;
  }
  return counts;
}

/// Pending peasant consumes from the human player's queued orders for
/// peasant-reservation gating. Matches the AI recruitment planner's
/// `_pendingPeasantConsumes` (SPEC/game/workers-and-population.md
/// § Peasant reservation): every queued non-peasant [RecruitWorkerOrder]
/// plus every queued military/naval [BuildUnitOrder] reserves one peasant.
int pendingPeasantConsumesForPlayer({
  required Orders currentOrders,
  required String playerId,
}) {
  var count = 0;
  final recruits =
      currentOrders.recruitWorkerOrdersByPlayerId[playerId] ??
      const <RecruitWorkerOrder>[];
  for (final order in recruits) {
    final row = WorkerActionEconomyCatalog.forTier(order.targetTier);
    if (row.consumesPeasant) count += 1;
  }
  final builds =
      currentOrders.buildUnitOrdersByPlayerId[playerId] ??
      const <BuildUnitOrder>[];
  for (final order in builds) {
    final category = buildUnitCategoryForUnitType(order.unitType);
    if (category == BuildUnitCategory.military ||
        category == BuildUnitCategory.naval) {
      count += 1;
    }
  }
  return count;
}

/// Returns the worker pool snapshot after applying every queued
/// recruit-worker order for [playerId] in submission order, so the
/// affordance helper can probe whether **one more** order at [candidateTier]
/// would still be acceptable against the projected economy.
///
/// Defensively skips queued orders that are no longer affordable against
/// the running snapshot (mirrors the resolver's per-order validation chain
/// in `RecruitWorkerOrderValidator`). This guards UI affordance lookups
/// when external state changes (e.g. debug treasury credit, prior turn
/// failure) leave a queued order in a state the resolver would reject.
({WorkerPool workers, Stockpile stockpile, int treasury})
projectedEconomyAfterQueuedRecruitWorkerOrders({
  required Player player,
  required Orders currentOrders,
}) {
  var workers = player.workerPool;
  var stockpile = player.stockpile;
  var treasury = player.treasury;
  final queued =
      currentOrders.recruitWorkerOrdersByPlayerId[player.id] ??
      const <RecruitWorkerOrder>[];
  for (final order in queued) {
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
  return (workers: workers, stockpile: stockpile, treasury: treasury);
}

/// True when appending one more [RecruitWorkerOrder] at [candidateTier] for
/// [player] would be accepted by [canAffordRecruitWorker] after every
/// already-queued recruit order has been deducted, **and** after applying
/// the pending peasant reservation for military/naval builds for that
/// player (peasant consumes counted on top of the projected pool).
///
/// Returns `false` when tech gates, treasury, materials, or the peasant
/// ledger would reject the candidate.
bool canAppendRecruitWorkerOrder({
  required Player player,
  required Orders currentOrders,
  required WorkerTier candidateTier,
}) {
  final projected = projectedEconomyAfterQueuedRecruitWorkerOrders(
    player: player,
    currentOrders: currentOrders,
  );
  final row = WorkerActionEconomyCatalog.forTier(candidateTier);
  if (row.consumesPeasant) {
    final militaryNavalConsumes = _militaryAndNavalPeasantConsumes(
      currentOrders: currentOrders,
      playerId: player.id,
    );
    if (projected.workers.peasants - militaryNavalConsumes < 1) {
      return false;
    }
  }
  final candidate = RecruitWorkerOrder(targetTier: candidateTier);
  final check = canAffordRecruitWorker(
    player,
    candidate,
    projected.workers,
    projected.stockpile,
    projected.treasury,
  );
  return check.canAfford;
}

int _militaryAndNavalPeasantConsumes({
  required Orders currentOrders,
  required String playerId,
}) {
  final builds =
      currentOrders.buildUnitOrdersByPlayerId[playerId] ??
      const <BuildUnitOrder>[];
  var count = 0;
  for (final order in builds) {
    final category = buildUnitCategoryForUnitType(order.unitType);
    if (category == BuildUnitCategory.military ||
        category == BuildUnitCategory.naval) {
      count += 1;
    }
  }
  return count;
}

/// Returns the value of `WorkerPool.<tier>` for the given enum without
/// switching at each call site.
int workerPoolTierCount(WorkerPool pool, WorkerTier tier) {
  switch (tier) {
    case WorkerTier.peasant:
      return pool.peasants;
    case WorkerTier.apprentice:
      return pool.apprentices;
    case WorkerTier.journeyman:
      return pool.journeymen;
    case WorkerTier.master:
      return pool.masters;
  }
}

/// Appends one [RecruitWorkerOrder] at [tier] for [playerId] and returns
/// the new [Orders] value. Preserves the prior order list ordering.
Orders ordersWithAppendedRecruitWorkerOrder({
  required Orders currentOrders,
  required String playerId,
  required WorkerTier tier,
}) {
  final next =
      Map<String, List<RecruitWorkerOrder>>.from(
        currentOrders.recruitWorkerOrdersByPlayerId,
      );
  final existing = List<RecruitWorkerOrder>.from(
    next[playerId] ?? const <RecruitWorkerOrder>[],
  );
  existing.add(RecruitWorkerOrder(targetTier: tier));
  next[playerId] = existing;
  return currentOrders.copyWith(recruitWorkerOrdersByPlayerId: next);
}

/// Removes the **last** queued [RecruitWorkerOrder] of [tier] for
/// [playerId] (LIFO) and returns the new [Orders] value. Returns
/// [currentOrders] unchanged when no matching order exists.
Orders ordersWithLastRecruitWorkerOrderRemoved({
  required Orders currentOrders,
  required String playerId,
  required WorkerTier tier,
}) {
  final existing =
      currentOrders.recruitWorkerOrdersByPlayerId[playerId] ??
      const <RecruitWorkerOrder>[];
  if (existing.isEmpty) return currentOrders;
  final lastIndex = _lastIndexWhereTier(existing, tier);
  if (lastIndex < 0) return currentOrders;
  final updated = List<RecruitWorkerOrder>.from(existing)
    ..removeAt(lastIndex);
  final next =
      Map<String, List<RecruitWorkerOrder>>.from(
        currentOrders.recruitWorkerOrdersByPlayerId,
      );
  if (updated.isEmpty) {
    next.remove(playerId);
  } else {
    next[playerId] = updated;
  }
  return currentOrders.copyWith(recruitWorkerOrdersByPlayerId: next);
}

int _lastIndexWhereTier(List<RecruitWorkerOrder> orders, WorkerTier tier) {
  for (var i = orders.length - 1; i >= 0; i--) {
    if (orders[i].targetTier == tier) return i;
  }
  return -1;
}

/// Applies an immediate disband action for [tier] on [player]: returns a
/// new [Player] with `pool.tier` decremented by 1 and `pool.peasants`
/// incremented by 1. Returns `null` when [tier] is `peasant` (no disband
/// row per SPEC § Disband) or when the pool count is zero.
Player? playerWithImmediateDisband({
  required Player player,
  required WorkerTier tier,
}) {
  if (tier == WorkerTier.peasant) return null;
  final pool = player.workerPool;
  if (workerPoolTierCount(pool, tier) <= 0) return null;
  final nextPool = _applyDisbandToPool(pool, tier);
  return player.copyWith(workerPool: nextPool);
}

WorkerPool _applyDisbandToPool(WorkerPool pool, WorkerTier tier) {
  switch (tier) {
    case WorkerTier.peasant:
      return pool;
    case WorkerTier.apprentice:
      return pool.copyWith(
        apprentices: pool.apprentices - 1,
        peasants: pool.peasants + 1,
      );
    case WorkerTier.journeyman:
      return pool.copyWith(
        journeymen: pool.journeymen - 1,
        peasants: pool.peasants + 1,
      );
    case WorkerTier.master:
      return pool.copyWith(
        masters: pool.masters - 1,
        peasants: pool.peasants + 1,
      );
  }
}

/// Returns a new [Game] where the viewed player's [workerPool] reflects
/// an immediate disband of one [tier] worker. Returns `null` (no change)
/// when the player cannot be found or the disband would underflow.
Game? gameWithImmediateDisband({
  required Game game,
  required String playerId,
  required WorkerTier tier,
}) {
  final players = game.players;
  Player? found;
  for (final p in players) {
    if (p.id == playerId) {
      found = p;
      break;
    }
  }
  if (found == null) return null;
  final updated = playerWithImmediateDisband(player: found, tier: tier);
  if (updated == null) return null;
  final nextPlayers = players
      .map((p) => p.id == playerId ? updated : p)
      .toList(growable: false);
  return game.copyWith(players: nextPlayers);
}
