// Shared bid-total helpers for Market tab order-mutation handler parts.

import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_orders/colonizethis_orders.dart'
    show Orders, TradeOrder, TradeOrderType, tradeOrderForPlayerCommodity;

import 'package:colonizethis_models/colonizethis_models.dart';

/// Returns the sum of `TradeOrder.quantity` across all staged
/// `TradeOrderType.bid` orders for [playerId] in [orders]. Offers do
/// not consume cargo (per `#2988` § Cargo Constraint Model) and are
/// excluded from the sum.
int totalStagedBidQuantity(Orders orders, String playerId) {
  final List<TradeOrder>? list = orders.tradeOrdersByPlayerId[playerId];
  if (list == null || list.isEmpty) return 0;
  int total = 0;
  for (final TradeOrder o in list) {
    if (o.type == TradeOrderType.bid) total += o.quantity;
  }
  return total;
}

/// Returns the count of distinct commodities with a staged
/// `TradeOrderType.bid` for [playerId] (Refs #4170). Offers are
/// excluded; repeat bids on the same commodity count once.
int stagedDistinctBidCommodityCount(Orders orders, String playerId) {
  final List<TradeOrder>? list = orders.tradeOrdersByPlayerId[playerId];
  if (list == null || list.isEmpty) return 0;
  final Set<CommodityId> distinct = <CommodityId>{};
  for (final TradeOrder o in list) {
    if (o.type == TradeOrderType.bid) distinct.add(o.commodityId);
  }
  return distinct.length;
}

/// True when the player may stage (or re-stage) a `Bid` on
/// [commodityId] without exceeding `worldMarketBidTypeCap` (Refs
/// #4170). Replacing an existing bid on the same commodity never
/// consumes an additional slot.
bool canStageBidOnCommodity({
  required Orders orders,
  required String playerId,
  required CommodityId commodityId,
  required int bidTypeCap,
}) {
  final TradeOrder? prior = tradeOrderForPlayerCommodity(
    orders,
    playerId,
    commodityId,
  );
  if (prior?.type == TradeOrderType.bid) return true;
  return stagedDistinctBidCommodityCount(orders, playerId) < bidTypeCap;
}
