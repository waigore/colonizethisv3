/// Effective market price lookup and bid **spend** composition for the
/// world-market treasury bid clamp (Refs #3093, #4049 phase-7 split).
///
/// SPEC/game/world-market.md § Treasury budget for bids,
/// SPEC/ui/trade-screen.md § Market tab — treasury bid cap.
///
/// The helpers are **pure**: deterministic for fixed inputs, silent (no
/// logger calls), and safe to call from order-submission, AI suggestion,
/// resolver-prep, and per-frame UI paths under the 15-second
/// turn-resolution budget (`.cursor/rules/colonizethis-turn-resolution-budget.mdc`).
///
/// Sibling libraries own the rest of the bid-budget surface:
/// `treasury_bid_available.dart` (available-budget projection) and
/// `treasury_bid_caps.dart` (quantity caps and fill-time decrement); the
/// `treasury_bid_budget.dart` barrel re-exports all three for callers.
library;

import 'package:colonizethis_data/colonizethis_data.dart' as data;
import 'package:colonizethis_models/colonizethis_models.dart';

import 'trade_order_admission.dart' show isWorldMarketTradeableCommodity;

/// Effective per-unit market price used by bid budget logic.
///
/// Reads the integer treasury-unit price stored on
/// [WorldMarketState.prices] (per `SPEC/game/world-market.md` § Price
/// discovery), falling back to
/// `resourceRules.defaultMarketPriceForCommodityId(commodityId)` when
/// the market state lacks an entry for [commodityId] (typically on
/// first-turn games before price discovery runs). The catalog default
/// now covers every tradeable commodity — raw resources (per the
/// `Resource` enum default-price map) and manufactured commodities
/// (per `SPEC/game/commodity-catalog.md` § *Manufactured base prices*) —
/// so `null` is reserved for the defensive case where a future
/// tradeable commodity ships without a catalog default, or when
/// [commodityId] is in [data.richesCommodityIds] (those do not trade on
/// the world market per SPEC § Tradeable commodities).
///
/// Callers should treat a `null` return as "no spend contribution"
/// (`0`) so bid budget math remains defensive against missing-data
/// states — UI consumers cannot stage a bid whose price is unknown
/// because the row's price text reads as the em-dash in that case.
int? effectiveMarketPriceForCommodityId({
  required CommodityId commodityId,
  required WorldMarketState worldMarket,
  required data.ResourceRules resourceRules,
}) {
  if (!isWorldMarketTradeableCommodity(commodityId)) return null;
  final int? stored = worldMarket.prices[commodityId];
  if (stored != null && stored >= 0) return stored;
  return resourceRules.defaultMarketPriceForCommodityId(commodityId);
}

/// Treasury spend for a single bid order: `quantity × effectiveMarketPrice`.
///
/// Returns `0` for offers, non-positive quantities, or when no effective
/// price exists (`null` from [effectiveMarketPriceForCommodityId]).
int bidTreasurySpendForOrder({
  required TradeOrder order,
  required WorldMarketState worldMarket,
  required data.ResourceRules resourceRules,
}) {
  if (order.type != TradeOrderType.bid || order.quantity <= 0) return 0;
  final int? price = effectiveMarketPriceForCommodityId(
    commodityId: order.commodityId,
    worldMarket: worldMarket,
    resourceRules: resourceRules,
  );
  if (price == null) return 0;
  return order.quantity * price;
}

/// Sum of `quantity × effectiveMarketPrice` across every staged
/// `TradeOrderType.bid` for [playerId] in [orders].
///
/// Offers do not contribute to bid spend. Non-positive quantities and
/// bids on commodities with no effective price (missing in both
/// `worldMarket.prices` and the catalog default) are skipped — the UI
/// clamp would not let those bids land in the first place, but the
/// helper stays defensive in case AI or save state injects an
/// out-of-band order.
int stagedBidTotalSpendByPlayer({
  required Orders orders,
  required String playerId,
  required Game game,
  required data.ResourceRules resourceRules,
}) {
  return _sumBidSpend(
    orders: orders.tradeOrdersByPlayerId[playerId],
    game: game,
    resourceRules: resourceRules,
  );
}

/// Sum of `quantity × effectiveMarketPrice` over the bid orders in [orders].
///
/// Shared core for [stagedBidTotalSpendByPlayer] (staged orders) and
/// [carryForwardBidNotionalByPlayer] (carry-forward bids): the only
/// difference between the two callers is the source iterable. Offers,
/// non-positive quantities, and bids on commodities with no effective
/// price are skipped so the total stays defensive against out-of-band
/// orders injected by AI or save state. Returns `0` for a `null` or
/// empty [orders].
int _sumBidSpend({
  required List<TradeOrder>? orders,
  required Game game,
  required data.ResourceRules resourceRules,
}) {
  if (orders == null || orders.isEmpty) return 0;
  int total = 0;
  for (final TradeOrder o in orders) {
    total += bidTreasurySpendForOrder(
      order: o,
      worldMarket: game.worldMarketState,
      resourceRules: resourceRules,
    );
  }
  return total;
}

/// Sum of `quantity × effectiveMarketPrice` across every
/// **carry-forward** `TradeOrderType.bid` for [playerId] held on
/// `game.worldMarketState.carryForwardBidsByFactionId[playerId]`.
///
/// Carry-forward bids are still "live" from the prior turn and will
/// be re-matched at phase 13, so the matcher (#3115) clamps the
/// current-turn buyer treasury against them. AI / planner callers that
/// pre-size new bids must therefore subtract this notional from the
/// raw `player.treasury` before sizing any new bid.
///
/// Non-positive quantities and bids on commodities with no effective
/// price (manufactured commodities until in-game price discovery
/// seeds a price) contribute `0` to the total, matching the validator-
/// side defensive skip in [stagedBidTotalSpendByPlayer].
///
/// Returns `0` when [playerId] has no carry-forward bids.
int carryForwardBidNotionalByPlayer({
  required Game game,
  required String playerId,
  required data.ResourceRules resourceRules,
}) {
  return _sumBidSpend(
    orders: game.worldMarketState.carryForwardBidsByFactionId[playerId],
    game: game,
    resourceRules: resourceRules,
  );
}
