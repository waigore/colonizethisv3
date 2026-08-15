// Queue projection and recruit-worker affordance helpers for the Production
// panel Labour controls section.
// SPEC/ui/production-panel.md § Labour Controls, SPEC/game/workers-and-population.md.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart'
    show
        applyRecruitWorkerCostDeduction,
        canAffordRecruitWorker,
        kRecruitWorkerInsufficientMaterials;
import 'package:colonizethis_models/colonizethis_models.dart';

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

/// Result of probing whether one more recruit/train at [candidateTier]
/// would pass [canAffordRecruitWorker] after queued recruit deductions
/// and military/naval peasant reservation.
class RecruitWorkerAppendCheck {
  const RecruitWorkerAppendCheck({
    required this.canAppend,
    this.reason,
    this.insufficientMaterialIds = const <String>{},
  });

  final bool canAppend;
  final String? reason;
  final Set<String> insufficientMaterialIds;
}

/// Affordance + refusal for appending one [RecruitWorkerOrder] at
/// [candidateTier]. Applies queued recruit deductions, then subtracts
/// pending military/naval peasant consumes from the projected pool so
/// [canAffordRecruitWorker] sees the reserved ledger (tech → workers →
/// treasury → materials).
RecruitWorkerAppendCheck recruitWorkerAppendCheck({
  required Player player,
  required Orders currentOrders,
  required WorkerTier candidateTier,
  ({WorkerPool workers, Stockpile stockpile, int treasury})? projected,
}) {
  final snapshot =
      projected ??
      projectedEconomyAfterQueuedRecruitWorkerOrders(
        player: player,
        currentOrders: currentOrders,
      );
  final row = WorkerActionEconomyCatalog.forTier(candidateTier);
  var workers = snapshot.workers;
  if (row.consumesPeasant) {
    final reserved =
        workers.peasants -
        _militaryAndNavalPeasantConsumes(
          currentOrders: currentOrders,
          playerId: player.id,
        );
    workers = workers.copyWith(peasants: reserved < 0 ? 0 : reserved);
  }
  final candidate = RecruitWorkerOrder(targetTier: candidateTier);
  final check = canAffordRecruitWorker(
    player,
    candidate,
    workers,
    snapshot.stockpile,
    snapshot.treasury,
  );
  if (check.canAfford) {
    return const RecruitWorkerAppendCheck(canAppend: true);
  }
  final insufficient = <String>{};
  if (check.reason == kRecruitWorkerInsufficientMaterials) {
    for (final entry in row.materialCosts.entries) {
      if (snapshot.stockpile.quantityOf(entry.key) < entry.value) {
        insufficient.add(entry.key);
      }
    }
  }
  return RecruitWorkerAppendCheck(
    canAppend: false,
    reason: check.reason,
    insufficientMaterialIds: insufficient,
  );
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
  return recruitWorkerAppendCheck(
    player: player,
    currentOrders: currentOrders,
    candidateTier: candidateTier,
  ).canAppend;
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
