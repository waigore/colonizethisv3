import 'package:colonizethis_models/colonizethis_models.dart';

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
  final priorList =
      orders.tradeOrdersByPlayerId[playerId] ?? const <TradeOrder>[];
  final next = <TradeOrder>[
    for (final TradeOrder o in priorList)
      if (o.commodityId != order.commodityId) o,
    order,
  ];
  return orders.copyWith(
    tradeOrdersByPlayerId: {...orders.tradeOrdersByPlayerId, playerId: next},
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
