// Shared bid-total helpers for Market tab order-mutation handler parts.

part of 'trade_screen.dart';

/// Projected treasury change this turn from the player's **non-bid**
/// staged orders (build / recruit / civilian / subsidy commitments).
///
/// Reads [projectedDelta], which is the signed treasury delta from
/// `projectOrderEffects` over the **current** `Orders` (which already
/// includes the player's staged bids). Adding the player's running bid
/// spend back nets the bid contribution out of the projection so the
/// helper passes a non-bid-only delta into
/// `treasuryAvailableForBidsByPlayer` per `SPEC/ui/trade-screen.md` §
/// Market tab — treasury bid cap.
///
/// Returns `0` when [projectedDelta] is `null` — typical for Widgetbook
/// stories and isolated widget tests that run without `gameServiceProvider`
/// map data.
int _projectedNonBidTreasuryDelta(
  int? projectedDelta,
  int stagedBidSpend,
) {
  if (projectedDelta == null) return 0;
  return projectedDelta + stagedBidSpend;
}

/// Returns the sum of `TradeOrder.quantity` across all staged
/// `TradeOrderType.bid` orders for [playerId] in [orders]. Offers do
/// not consume cargo (per `#2988` § Cargo Constraint Model) and are
/// excluded from the sum.
int _totalStagedBidQuantity(Orders orders, String playerId) {
  final List<TradeOrder>? list = orders.tradeOrdersByPlayerId[playerId];
  if (list == null || list.isEmpty) return 0;
  int total = 0;
  for (final TradeOrder o in list) {
    if (o.type == TradeOrderType.bid) total += o.quantity;
  }
  return total;
}
