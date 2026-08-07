// Trade Counsel Apply/Agree handlers. SPEC/ui/counsel-panel.md (Refs #4282).

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_orders/colonizethis_orders.dart'
    show applyTradeOrderForPlayer;

/// Replaces the player's entire staged trade book with [book].
Orders tradeCounselOrdersAfterApplyBook({
  required Orders currentOrders,
  required String playerId,
  required List<TradeOrder> book,
}) {
  return currentOrders.copyWith(
    tradeOrdersByPlayerId: {
      ...currentOrders.tradeOrdersByPlayerId,
      playerId: List<TradeOrder>.from(book),
    },
  );
}

/// Stages or replaces one counsel line; mutual exclusion per commodity.
Orders? tradeCounselOrdersAfterAgree({
  required Orders currentOrders,
  required String playerId,
  required TradeOrder order,
}) {
  if (order.quantity <= 0) return null;
  return applyTradeOrderForPlayer(
    orders: currentOrders,
    playerId: playerId,
    order: order,
  );
}
