// Recruit-worker order mutations and immediate disband helpers for the
// Production panel Labour controls section.
// SPEC/ui/production-panel.md § Labour Controls, SPEC/game/workers-and-population.md.

part of 'production_labour_helpers.dart';

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
