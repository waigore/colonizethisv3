import 'package:colonizethis_models/colonizethis_models.dart';

/// Appends one [DiplomaticOrder] for [playerId] to the turn draft.
/// SPEC/program/orders.md.
Orders ordersWithAppendedDiplomaticOrder(
  Orders orders,
  String playerId,
  DiplomaticOrder order,
) {
  final list = List<DiplomaticOrder>.from(
    orders.diplomaticOrdersByPlayerId[playerId] ?? const <DiplomaticOrder>[],
  )..add(order);
  return orders.copyWith(
    diplomaticOrdersByPlayerId: {
      ...orders.diplomaticOrdersByPlayerId,
      playerId: list,
    },
  );
}

/// Applies a human naval move to the turn draft: replaces any prior naval move for
/// the same [fleetId] and removes naval mission orders for that fleet.
/// SPEC/program/naval-movement-resolution.md.
Orders applyNavalMoveOrderForPlayer(
  Orders orders,
  String playerId,
  NavalMoveOrder newOrder,
) {
  final nextMoves = List<NavalMoveOrder>.from(
    orders.navalMoveOrdersByPlayerId[playerId] ?? const [],
  )..removeWhere((o) => o.fleetId == newOrder.fleetId);
  nextMoves.add(newOrder);

  final nextMissions = List<NavalMissionOrder>.from(
    orders.navalMissionOrdersByPlayerId[playerId] ?? const [],
  )..removeWhere((o) => o.fleetId == newOrder.fleetId);

  return orders.copyWith(
    navalMoveOrdersByPlayerId: {
      ...orders.navalMoveOrdersByPlayerId,
      playerId: nextMoves,
    },
    navalMissionOrdersByPlayerId: {
      ...orders.navalMissionOrdersByPlayerId,
      playerId: nextMissions,
    },
  );
}

/// Replaces any prior army move for the same [armyId] for this turn draft.
/// SPEC/game/military-armies.md.
Orders applyArmyMoveOrderForPlayer(
  Orders orders,
  String playerId,
  ArmyMoveOrder newOrder,
) {
  final next = List<ArmyMoveOrder>.from(
    orders.armyMoveOrdersByPlayerId[playerId] ?? const [],
  )..removeWhere((o) => o.armyId == newOrder.armyId);
  next.add(newOrder);
  return orders.copyWith(
    armyMoveOrdersByPlayerId: {
      ...orders.armyMoveOrdersByPlayerId,
      playerId: next,
    },
  );
}

/// Drops naval mission orders for fleets that have a naval move order this turn.
/// SPEC/program/naval-movement-resolution.md.
Map<String, List<NavalMissionOrder>> navalMissionOrdersRespectingNavalMoves(
  Map<String, List<NavalMissionOrder>> navalMissionOrdersByPlayerId,
  Map<String, List<NavalMoveOrder>> navalMoveOrdersByPlayerId,
) {
  final out = <String, List<NavalMissionOrder>>{};
  navalMissionOrdersByPlayerId.forEach((playerId, list) {
    final movedFleetIds = {
      for (final o in navalMoveOrdersByPlayerId[playerId] ?? const <NavalMoveOrder>[])
        o.fleetId,
    };
    final filtered = [
      for (final o in list)
        if (!movedFleetIds.contains(o.fleetId)) o,
    ];
    if (filtered.isNotEmpty) out[playerId] = filtered;
  });
  return out;
}

/// Removes the pending civilian work order at [index] for [playerId] in this
/// turn's draft [orders]. No-op if the list is missing or [index] is out of
/// range. SPEC/program/orders.md.
Orders removePendingWorkOrderAt(
  Orders orders,
  String playerId,
  int index,
) {
  final list = orders.workOrdersByPlayerId[playerId];
  if (list == null || index < 0 || index >= list.length) {
    return orders;
  }
  final next = List<WorkOrder>.from(list)..removeAt(index);
  return orders.copyWith(
    workOrdersByPlayerId: {
      ...orders.workOrdersByPlayerId,
      playerId: next,
    },
  );
}

/// Returns the pending [TradeOrder] keyed by [commodityId] for [playerId]
/// in the turn draft [orders], or `null` if none is staged.
///
/// SPEC/game/world-market.md § Trade orders. The Trade Screen Market tab
/// (#2993 E5b) keys staged trade orders by commodity id (one TradeOrder
/// per (player, commodityId)); this helper exposes that lookup so the
/// UI can render the current direction (bid / offer) and quantity for
/// a row without scanning the full list.
TradeOrder? tradeOrderForPlayerCommodity(
  Orders orders,
  String playerId,
  CommodityId commodityId,
) {
  final list = orders.tradeOrdersByPlayerId[playerId];
  if (list == null) return null;
  for (final order in list) {
    if (order.commodityId == commodityId) return order;
  }
  return null;
}

/// Adds or replaces a single [TradeOrder] for [playerId] keyed by
/// `order.commodityId` in the turn draft [orders].
///
/// **Mutual exclusion** (SPEC/game/world-market.md § Trade orders):
/// any prior pending [TradeOrder] for the same commodity (regardless of
/// `bid` vs `offer`) is removed before [order] is appended, so each
/// (player, commodityId) pair carries at most one staged direction. This
/// matches the per-commodity mutual-exclusion rule enforced later by
/// [TradeOrderValidator] (#2989) — staging the orders this way means the
/// UI can never produce a draft that the validator would reject under
/// rule 3 (`trade_order_mutual_exclusion`).
Orders applyTradeOrderForPlayer({
  required Orders orders,
  required String playerId,
  required TradeOrder order,
}) {
  final priorList = orders.tradeOrdersByPlayerId[playerId] ??
      const <TradeOrder>[];
  final next = <TradeOrder>[
    for (final TradeOrder o in priorList)
      if (o.commodityId != order.commodityId) o,
    order,
  ];
  return orders.copyWith(
    tradeOrdersByPlayerId: {
      ...orders.tradeOrdersByPlayerId,
      playerId: next,
    },
  );
}

/// Removes any pending [TradeOrder] for [playerId] keyed by
/// [commodityId] in the turn draft [orders]. No-op when no matching
/// order is staged. SPEC/game/world-market.md § Trade orders.
Orders removeTradeOrderForPlayer({
  required Orders orders,
  required String playerId,
  required CommodityId commodityId,
}) {
  final priorList = orders.tradeOrdersByPlayerId[playerId];
  if (priorList == null || priorList.isEmpty) return orders;
  final filtered = <TradeOrder>[
    for (final TradeOrder o in priorList)
      if (o.commodityId != commodityId) o,
  ];
  if (filtered.length == priorList.length) return orders;
  return orders.copyWith(
    tradeOrdersByPlayerId: {
      ...orders.tradeOrdersByPlayerId,
      playerId: filtered,
    },
  );
}
