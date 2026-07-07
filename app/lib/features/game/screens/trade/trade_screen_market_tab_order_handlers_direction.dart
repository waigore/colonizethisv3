// Bid/offer direction-toggle handlers for the Market tab body.

part of 'trade_screen.dart';

extension _MarketTabContentDirectionHandlers on _MarketTabContent {
  void _handleDirectionChanged({
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
        prior?.quantity ?? TradeScreen.marketRowQuantityDefault;
    final int priority =
        prior?.priority ?? TradeScreen.marketRowDefaultPriority;

    int quantity = desiredQuantity;
    if (next == TradeOrderType.bid) {
      // Refs #2993 E5c: clamp the staged bid quantity so the
      // cross-commodity bid total never exceeds the player's
      // tradeCargoCapacity. The row's own prior bid contribution (if
      // any) is added back because it is already included in the
      // running total and will be replaced by `applyTradeOrderForPlayer`.
      final int tradeCargoCapacity =
          cargoHoldsForHomeFleet(game, playerId);
      final int totalStagedBid = _totalStagedBidQuantity(orders, playerId);
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
          projectedNonBidTreasuryDelta: _projectedNonBidTreasuryDelta(
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
