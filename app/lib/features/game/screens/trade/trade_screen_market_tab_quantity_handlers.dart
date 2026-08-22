// Shared bid-total helpers for Market tab order-mutation handler parts.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_orders/colonizethis_orders.dart'
    show tradeOrderForPlayerCommodity, applyTradeOrderForPlayer;

import 'package:colonizethis_models/colonizethis_models.dart';

import '../../../../providers/games_provider.dart';
import 'trade_screen_contract_market.dart';
import 'trade_screen_market_tab.dart';
import 'trade_screen_market_tab_bid_totals.dart';

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
      final int tradeCargoCapacity = cargoHoldsForHomeFleet(game, playerId);
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
      final int rowCap =
          offerCapByCommodityId(
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
