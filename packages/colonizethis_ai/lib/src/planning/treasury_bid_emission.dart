part of 'treasury_planner.dart';

// Bid prioritization, cargo/treasury-budget clamping, and tier alignment for
// the treasury planner (Refs #3122 + #2924 F12/F16), extracted from
// `treasury_planner.dart` for maintainability (Refs #3288 file-split).
// Behaviour-preserving move: same library scope (this is a `part of` the
// treasury-planner library), so imports, shared helpers, and visibility are
// unchanged.

/// Parameter bag for [_emitTradeOrders] (Refs #3967).
///
/// Collapses the 13-field emission signature so [runTreasuryPlanner] forwards
/// one context object instead of re-listing the same scalars at the call site.
final class _EmitTradeOrdersInput {
  const _EmitTradeOrdersInput({
    required this.game,
    required this.playerId,
    required this.bidTypeCap,
    required this.tradeCargoCapacity,
    required this.available,
    required this.need,
    required this.treasuryBudgetForBids,
    required this.offerPriority,
    required this.isRegimentBuildInputMarketSupplier,
    required this.isLiquidityBuyer,
    required this.lockRecoveryUrgent,
    required this.rules,
    this.tradeDealPreferredBidCommodityId,
  });

  final Game game;
  final String playerId;
  final int bidTypeCap;
  final int tradeCargoCapacity;
  final Map<CommodityId, int> available;
  final Map<CommodityId, int> need;
  final int treasuryBudgetForBids;
  final int offerPriority;
  final bool isRegimentBuildInputMarketSupplier;
  final bool isLiquidityBuyer;
  final bool lockRecoveryUrgent;
  final ResourceRules rules;
  final CommodityId? tradeDealPreferredBidCommodityId;
}

/// Builds the final trade-order list (offers followed by prioritized bids) for
/// [runTreasuryPlanner] once the surplus/need maps and the optional trade-deal
/// relation-boost bid-preference hint are resolved. Extracted (Refs #3758
/// file-split) to keep the planner body within the function-size budget;
/// behaviour-preserving move (same library scope, identical emission logic).
List<TradeOrder> _emitTradeOrders(_EmitTradeOrdersInput input) {
  // Refs #3122 + #3127: pass the treasury-budget-aware bid cap (computed in the
  // planner — `rawTreasury - pendingCosts - carryForwardBidNotional`, floored at
  // 0) into the suggester so it never emits bids the validator rule 5 would
  // reject. Subsumes #3127's bare `max(0, treasury)` formulation.
  final suggestion = TradeOrderSuggester.suggest(
    TradeSuggestionContext(
      playerId: input.playerId,
      bidTypeCap: input.bidTypeCap,
      tradeCargoCapacity: input.tradeCargoCapacity,
      availableStockpileByCommodityId: input.available,
      commodityNeedByCommodityId: input.need,
      treasuryBudgetForBids: input.treasuryBudgetForBids,
      worldMarketState: input.game.worldMarketState,
      offerPriority: input.offerPriority,
      bidPriority: kTreasuryBidPriorityRawMaterial,
      // Refs #3758 S9/R10: admit the trade-deal-relation-boost preferred bid
      // commodity ahead of other deficits when the bid-type cap binds. Always
      // `null` in lock-recovery states (gated in the planner), so the
      // liquidity-buyer single-commodity `need` and the legacy alphabetical
      // order are unchanged.
      preferredBidCommodityId: input.tradeDealPreferredBidCommodityId,
    ),
  );

  // Refs #2847 H8-supply market order matching: a lock-recovery supplier
  // releases its surplus at the GP's general `offerPriority` (the urgent tier
  // when broke, the moderate tier otherwise), but the locked buyer bids the
  // build inputs at `_bidPriorityForCommodity` (essential = 1 for the
  // manufactured `lumber` / `castIron` / `fabric` inputs) once it has recovered
  // above the regiment threshold. The DealMatcher crosses offers and bids only
  // **within** the same integer priority tier
  // (SPEC/program/world-market-resolution.md § Step C), so a standing
  // build-input offer and the buyer's standing build-input bid never pair --
  // confirmed on seed 42: a priority-2 `lumber` offer and a priority-1 `lumber`
  // bid coexist every turn yet `filledQuantity == 0`. Re-tag the supplier's
  // build-input supply offers to the same per-commodity tier the buyer bids at
  // so the two cross. Mirrors the bid-side `alignBidPriorityWithUrgentOffers`
  // tier-alignment machinery (Refs #2924 F12/F16).
  // SPEC/ai/treasury-planner.md § Supplier offer-tier alignment.
  final offers = input.isRegimentBuildInputMarketSupplier
      ? _alignBuildInputSupplyOfferTiers(suggestion.offers)
      : suggestion.offers;
  // Refs #2924 F11/F12: when the designated buyer is affluent its own forecast
  // is above the regiment threshold (offerPriority == moderate); the lock-
  // recovery bid still needs to clear at the urgent integer priority tier so
  // it matches broke GPs' urgent grain offers. forceBidPriority overrides the
  // tier-alignment computation so the synthetic grain bid always goes out at
  // kTreasuryOfferPriorityUrgent regardless of the buyer's own offerPriority.
  final bids = _prioritizedBids(
    rawBids: suggestion.bids,
    need: input.need,
    bidTypeCap: input.bidTypeCap,
    tradeCargoCapacity: input.tradeCargoCapacity,
    offerPriority: input.offerPriority,
    alignBidPriorityWithUrgentOffers:
        input.isLiquidityBuyer || input.lockRecoveryUrgent,
    forceBidPriority:
        input.isLiquidityBuyer ? kTreasuryOfferPriorityUrgent : null,
    preferCommodityId: input.isLiquidityBuyer
        ? _lockRecoveryLiquidityCommodity(input.game.worldMarketState)
        : input.tradeDealPreferredBidCommodityId,
    treasuryBudgetForBids: input.treasuryBudgetForBids,
    worldMarketState: input.game.worldMarketState,
    resourceRules: input.rules,
  );

  return [...offers, ...bids];
}

List<TradeOrder> _prioritizedBids({
  required List<TradeOrder> rawBids,
  required Map<CommodityId, int> need,
  required int bidTypeCap,
  required int tradeCargoCapacity,
  required int offerPriority,
  required bool alignBidPriorityWithUrgentOffers,
  required int treasuryBudgetForBids,
  required WorldMarketState worldMarketState,
  required ResourceRules resourceRules,
  int? forceBidPriority,
  CommodityId? preferCommodityId,
}) {
  if (rawBids.isEmpty || bidTypeCap <= 0 || tradeCargoCapacity <= 0) {
    return const <TradeOrder>[];
  }
  final byCommodity = <CommodityId, TradeOrder>{
    for (final bid in rawBids) bid.commodityId: bid,
  };
  final orderedIds = need.keys.toList(growable: false)
    ..sort((a, b) {
      if (preferCommodityId != null) {
        if (a == preferCommodityId) return -1;
        if (b == preferCommodityId) return 1;
      }
      final priorityCmp =
          _bidPriorityForCommodity(a).compareTo(_bidPriorityForCommodity(b));
      if (priorityCmp != 0) return priorityCmp;
      return a.compareTo(b);
    });

  final result = <TradeOrder>[];
  var remainingCargo = tradeCargoCapacity;
  var remainingTreasuryBudget =
      treasuryBudgetForBids < 0 ? 0 : treasuryBudgetForBids;
  var admitted = 0;
  for (final commodityId in orderedIds) {
    if (admitted >= bidTypeCap) break;
    if (remainingCargo <= 0) break;
    final bid = byCommodity[commodityId];
    if (bid == null) continue;
    final cargoClampedQty = bid.quantity < remainingCargo
        ? bid.quantity
        : remainingCargo;
    if (cargoClampedQty <= 0) continue;
    // Refs #3122: clamp every bid to the running treasury budget so the
    // matcher (#3115) does not have to truncate to zero/near-zero fills.
    // When the commodity has no effective price (manufactured commodity
    // before in-game price discovery seeds a price), fall back to the
    // cargo-clamped quantity; the matcher applies its own per-tier
    // accounting if such a bid ever clears.
    final pricePerUnit = effectiveMarketPriceForCommodityId(
      commodityId: commodityId,
      worldMarket: worldMarketState,
      resourceRules: resourceRules,
    );
    int cappedQty;
    if (pricePerUnit == null) {
      cappedQty = cargoClampedQty;
    } else if (pricePerUnit <= 0) {
      cappedQty = cargoClampedQty;
    } else {
      final maxAffordable = remainingTreasuryBudget ~/ pricePerUnit;
      cappedQty = cargoClampedQty < maxAffordable
          ? cargoClampedQty
          : maxAffordable;
    }
    if (cappedQty <= 0) continue;
    result.add(
      bid.copyWith(
        quantity: cappedQty,
        priority: forceBidPriority ??
            (alignBidPriorityWithUrgentOffers
                ? offerPriority
                : _bidPriorityForCommodity(commodityId)),
      ),
    );
    remainingCargo -= cappedQty;
    if (pricePerUnit != null && pricePerUnit > 0) {
      remainingTreasuryBudget -= cappedQty * pricePerUnit;
    }
    admitted += 1;
  }
  return result;
}
