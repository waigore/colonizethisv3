// Shared bid-total helpers for Market tab order-mutation handler parts.

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

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../../../../providers/games_provider.dart';
import 'trade_screen_contract_market.dart';
import 'trade_screen_market_tab.dart';

int projectedNonBidTreasuryDelta(
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
int totalStagedBidQuantity(Orders orders, String playerId) {
  final List<TradeOrder>? list = orders.tradeOrdersByPlayerId[playerId];
  if (list == null || list.isEmpty) return 0;
  int total = 0;
  for (final TradeOrder o in list) {
    if (o.type == TradeOrderType.bid) total += o.quantity;
  }
  return total;
}

extension MarketTabContentDirectionHandlers on MarketTabContent {
  void handleDirectionChanged({
    required CurrentOrdersNotifier ordersNotifier,
    required Orders orders,
    required Map<CommodityId, int> productionInputConsumption,
    required int? projectedTreasuryDelta,
    required CommodityId commodityId,
    required TradeOrderType? next,
  }) {
    if (next == null) {
      final Orders updated = removeTradeOrderForPlayer(
        orders: orders,
        playerId: playerId,
        commodityId: commodityId,
      );
      if (!identical(updated, orders)) ordersNotifier.replaceAll(updated);
      return;
    }
    final TradeOrder? prior = tradeOrderForPlayerCommodity(
      orders,
      playerId,
      commodityId,
    );
    final int desiredQuantity =
        prior?.quantity ?? TradeScreenMarketKeys.marketRowQuantityDefault;
    final int priority =
        prior?.priority ?? TradeScreenMarketKeys.marketRowDefaultPriority;

    int quantity = desiredQuantity;
    if (next == TradeOrderType.bid) {
      // Refs #2993 E5c: clamp the staged bid quantity so the
      // cross-commodity bid total never exceeds the player's
      // tradeCargoCapacity. The row's own prior bid contribution (if
      // any) is added back because it is already included in the
      // running total and will be replaced by `applyTradeOrderForPlayer`.
      final int tradeCargoCapacity =
          cargoHoldsForHomeFleet(game, playerId);
      final int totalStagedBid = totalStagedBidQuantity(orders, playerId);
      final int priorBidContribution =
          prior?.type == TradeOrderType.bid ? prior!.quantity : 0;
      final int maxAllowedBidQuantity =
          (tradeCargoCapacity - totalStagedBid) + priorBidContribution;
      if (maxAllowedBidQuantity <= 0) {
        // Cargo budget exhausted — refuse the toggle so the row stays
        // in its prior direction (or remains `None`). The warning row
        // is already mounted (or will mount as soon as a bid lands).
        return;
      }
      if (desiredQuantity > maxAllowedBidQuantity) {
        quantity = maxAllowedBidQuantity;
      }
      // Refs #3093 — treasury bid budget cap. The cross-commodity bid
      // total spend (`Σ qty × effectiveMarketPrice`) must not exceed
      // the player's `treasuryAvailableForBidsByPlayer` (today: raw
      // treasury; pending-cost subtraction is a documented follow-up
      // per `SPEC/game/world-market.md` § Treasury budget for bids).
      // Subtract the row's own prior bid contribution to the running
      // spend total so this row's *replacement* quantity is measured
      // against the fresh headroom.
      //
      // When `rowPrice` is null (manufactured commodities whose first
      // market price is discovered in-game and the catalog has no
      // default — the row's price text reads as the em-dash) the
      // treasury clamp is **skipped** so the cargo cap remains the
      // only constraint. The validator-side enforcement (follow-up)
      // covers the spend-over-treasury case independently.
      final int? rowPrice = effectiveMarketPriceForCommodityId(
        commodityId: commodityId,
        worldMarket: game.worldMarketState,
        resourceRules: ResourceRules.defaultRules,
      );
      if (rowPrice != null && rowPrice > 0) {
        final int totalStagedBidSpend = stagedBidTotalSpendByPlayer(
          orders: orders,
          playerId: playerId,
          game: game,
          resourceRules: ResourceRules.defaultRules,
        );
        final int treasuryBudget = treasuryAvailableForBidsByPlayer(
          game: game,
          playerId: playerId,
          projectedNonBidTreasuryDelta: projectedNonBidTreasuryDelta(
            projectedTreasuryDelta,
            totalStagedBidSpend,
          ),
        );
        final int priorRowBidSpend = prior?.type == TradeOrderType.bid
            ? prior!.quantity * rowPrice
            : 0;
        final int otherBidSpend = totalStagedBidSpend - priorRowBidSpend;
        final int treasuryHeadroom = treasuryBudget - otherBidSpend;
        if (treasuryHeadroom < rowPrice) {
          // Not enough treasury to bid even 1 unit at the row's price
          // → silent no-op so the row stays in its prior direction.
          return;
        }
        final int treasuryQuantityCap = treasuryHeadroom ~/ rowPrice;
        if (quantity > treasuryQuantityCap) {
          quantity = treasuryQuantityCap;
        }
        if (quantity <= 0) return;
      }
    } else if (next == TradeOrderType.offer) {
      // Refs #3093 — sellable clamp slice. The per-commodity offer cap
      // is `max(0, stockpile − industryAllocation)`. Industry
      // allocation is the per-commodity input consumption projected
      // from the player's current production allocations via
      // `productionInputConsumptionByCommodityIdForAssignments`
      // (`SPEC/program/order-projections.md` § Production input
      // consumption projection). Mutual exclusion guarantees the row
      // is the only staged offer for the commodity, so the cap is
      // applied directly to the row's quantity without subtracting
      // sibling offers.
      final int rowCap = offerCapByCommodityId(
        game: game,
        playerId: playerId,
        productionInputConsumptionByCommodityId: productionInputConsumption,
      )[commodityId] ??
          0;
      if (rowCap <= 0) {
        // Stockpile exhausted — refuse the toggle so the row stays in
        // its prior direction (or remains `None`).
        return;
      }
      if (desiredQuantity > rowCap) {
        quantity = rowCap;
      }
    }
    final TradeOrder nextOrder = TradeOrder(
      commodityId: commodityId,
      type: next,
      quantity: quantity,
      priority: priority,
    );
    final Orders updated = applyTradeOrderForPlayer(
      orders: orders,
      playerId: playerId,
      order: nextOrder,
    );
    ordersNotifier.replaceAll(updated);
  }
}

extension MarketTabContentQuantityHandlers on MarketTabContent {
  void handleQuantityDelta({
    required CurrentOrdersNotifier ordersNotifier,
    required Orders orders,
    required Map<CommodityId, int> productionInputConsumption,
    required int? projectedTreasuryDelta,
    required CommodityId commodityId,
    required int delta,
  }) {
    final TradeOrder? prior = tradeOrderForPlayerCommodity(
      orders,
      playerId,
      commodityId,
    );
    if (prior == null) return; // No staged direction → ignore.
    final int rawNext = prior.quantity + delta;
    if (rawNext < TradeScreenMarketKeys.marketRowQuantityMin) return;
    if (rawNext == prior.quantity) return;
    if (prior.type == TradeOrderType.bid && delta > 0) {
      // Refs #2993 E5c: increment is blocked when the cross-commodity
      // bid budget is exhausted. The row's own current quantity is
      // already part of `totalStagedBid` — we only need any unused
      // headroom to grow it by `delta`.
      final int tradeCargoCapacity =
          cargoHoldsForHomeFleet(game, playerId);
      final int totalStagedBid = totalStagedBidQuantity(orders, playerId);
      if (totalStagedBid + delta > tradeCargoCapacity) return;
      // Refs #3093 — treasury bid budget cap. Block the `+` tap when
      // the cross-commodity bid total spend would exceed the player's
      // available treasury. The row's own current spend is already
      // part of `totalStagedBidSpend` — we only need the extra `delta`
      // at the row's effective per-unit price to fit inside the
      // remaining treasury budget.
      //
      // When `rowPrice` is null (manufactured commodities with no
      // catalog default — the row's price reads as the em-dash) the
      // treasury check is **skipped** so the cargo cap remains the
      // only constraint; the validator-side enforcement (follow-up)
      // catches over-spend cases independently.
      final int? rowPrice = effectiveMarketPriceForCommodityId(
        commodityId: commodityId,
        worldMarket: game.worldMarketState,
        resourceRules: ResourceRules.defaultRules,
      );
      if (rowPrice != null && rowPrice > 0) {
        final int totalStagedBidSpend = stagedBidTotalSpendByPlayer(
          orders: orders,
          playerId: playerId,
          game: game,
          resourceRules: ResourceRules.defaultRules,
        );
        final int treasuryBudget = treasuryAvailableForBidsByPlayer(
          game: game,
          playerId: playerId,
          projectedNonBidTreasuryDelta: projectedNonBidTreasuryDelta(
            projectedTreasuryDelta,
            totalStagedBidSpend,
          ),
        );
        if (totalStagedBidSpend + delta * rowPrice > treasuryBudget) return;
      }
    } else if (prior.type == TradeOrderType.offer && delta > 0) {
      // Refs #3093 — sellable clamp slice. Block the `+` tap when the
      // per-commodity offer cap (`max(0, stockpile −
      // industryAllocation)`) is exhausted. Industry allocation comes
      // from the player's current production assignments via
      // `productionInputConsumptionByCommodityIdForAssignments`.
      // Mutual exclusion guarantees the row is the only staged offer
      // for the commodity, so the cap is applied directly to
      // `prior.quantity + delta`.
      final int rowCap = offerCapByCommodityId(
        game: game,
        playerId: playerId,
        productionInputConsumptionByCommodityId: productionInputConsumption,
      )[commodityId] ??
          0;
      if (prior.quantity + delta > rowCap) return;
    }
    final TradeOrder nextOrder = prior.copyWith(quantity: rawNext);
    final Orders updated = applyTradeOrderForPlayer(
      orders: orders,
      playerId: playerId,
      order: nextOrder,
    );
    ordersNotifier.replaceAll(updated);
  }
}
