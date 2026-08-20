/// Trade-order suggestion for the world market.
///
/// SPEC/game/world-market.md § Trade orders,
/// SPEC/program/world-market-resolution.md § Trade order suggestion API.
///
/// The suggester is **pure**: deterministic for fixed inputs, silent (no
/// logger calls), and safe to call from order-submission, AI suggestion, and
/// resolver-prep paths under the 15-second turn-resolution budget per
/// `.cursor/rules/colonizethis-turn-resolution-budget.mdc`.
///
/// By construction, every `TradeOrder` returned by `TradeOrderSuggester.suggest`
/// passes `TradeOrderValidator.validate` against the same numeric context
/// (`bidTypeCap`, `tradeCargoCapacity`, `availableStockpileByCommodityId`).
/// Callers (UI prompts, AI `TreasuryPlanner` per Issue F / #2994) may rank or
/// re-prioritize the suggestions but never need to re-clamp them for validity.
library;

import 'package:colonizethis_models/colonizethis_models.dart';

import 'trade_order_admission.dart' show isWorldMarketTradeableCommodity;
import 'trade_order_suggester_types.dart';
import 'treasury_bid_budget.dart'
    show
        bidTreasurySpendForOrder,
        capBidQuantityForBudgets,
        effectiveMarketPriceForCommodityId;

export 'trade_order_suggester_types.dart';

/// Computes validator-clean offer and bid suggestions for one player's turn.
class TradeOrderSuggester {
  TradeOrderSuggester._();

  /// Returns a [TradeSuggestionResult] derived from [context]. The result is
  /// deterministic for fixed inputs (commodities are iterated in alphabetical
  /// id order) and respects every rule of `TradeOrderValidator`.
  static TradeSuggestionResult suggest(TradeSuggestionContext context) {
    if (context.tradeCargoCapacity < 0) {
      // Defensive guard: negative capacity is treated as zero so no bid
      // can be emitted and no offer is mistakenly produced from a malformed
      // input. Callers should clamp upstream per
      // SPEC/game/world-market.md § Cargo.
      return TradeSuggestionResult.empty;
    }
    final candidateCommodityIds = <CommodityId>{
      ...context.availableStockpileByCommodityId.keys,
      ...context.commodityNeedByCommodityId.keys,
    };
    if (candidateCommodityIds.isEmpty) {
      return TradeSuggestionResult.empty;
    }
    final sortedCommodityIds = candidateCommodityIds.toList()..sort();
    // Refs #3758 S9/R10: when a preferred bid commodity is supplied and present,
    // move it to the front so a capped bid set admits it ahead of other
    // deficits. `null`/absent leaves the legacy alphabetical order untouched.
    final orderedCommodityIds = _withPreferredCommodityFirst(
      sortedCommodityIds,
      context.preferredBidCommodityId,
    );

    final offers = <TradeOrder>[];
    final bids = <TradeOrder>[];
    var remainingCargoBudget = context.tradeCargoCapacity;
    var remainingTreasuryBudget = context.treasuryBudgetForBids;
    var admittedBidCount = 0;
    final allowBids = context.bidTypeCap > 0;

    for (final commodityId in orderedCommodityIds) {
      if (!isWorldMarketTradeableCommodity(commodityId)) {
        continue;
      }
      final available =
          context.availableStockpileByCommodityId[commodityId] ?? 0;
      final need = context.commodityNeedByCommodityId[commodityId] ?? 0;
      if (available < 0 || need < 0) {
        // Guard against malformed inputs without throwing — pure functions
        // in this layer never throw on hot paths under the 15s budget.
        continue;
      }
      final net = available - need;
      if (net > 0) {
        offers.add(
          TradeOrder(
            commodityId: commodityId,
            type: TradeOrderType.offer,
            quantity: net,
            priority: context.offerPriority,
          ),
        );
        continue;
      }
      if (!allowBids) continue;
      if (admittedBidCount >= context.bidTypeCap) continue;
      final bidQuantity = -net; // need > available => positive deficit
      if (bidQuantity <= 0) continue;
      final int? unitPrice = effectiveMarketPriceForCommodityId(
        commodityId: commodityId,
        worldMarket: context.worldMarketState,
        resourceRules: context.resourceRulesOrDefault,
      );
      final cappedQty = capBidQuantityForBudgets(
        bidQuantity: bidQuantity,
        remainingCargoBudget: remainingCargoBudget,
        remainingTreasuryBudget: remainingTreasuryBudget,
        unitPrice: unitPrice,
      );
      if (cappedQty <= 0) continue;
      bids.add(
        TradeOrder(
          commodityId: commodityId,
          type: TradeOrderType.bid,
          quantity: cappedQty,
          priority: context.bidPriority,
        ),
      );
      remainingCargoBudget -= cappedQty;
      remainingTreasuryBudget -= bidTreasurySpendForOrder(
        order: TradeOrder(
          commodityId: commodityId,
          type: TradeOrderType.bid,
          quantity: cappedQty,
          priority: context.bidPriority,
        ),
        worldMarket: context.worldMarketState,
        resourceRules: context.resourceRulesOrDefault,
      );
      admittedBidCount += 1;
    }

    return TradeSuggestionResult(offers: offers, bids: bids);
  }

  /// Returns [sortedCommodityIds] with [preferred] moved to the front when it is
  /// non-null and present; otherwise returns the list unchanged. Deterministic.
  static List<CommodityId> _withPreferredCommodityFirst(
    List<CommodityId> sortedCommodityIds,
    CommodityId? preferred,
  ) {
    if (preferred == null || !sortedCommodityIds.contains(preferred)) {
      return sortedCommodityIds;
    }
    return <CommodityId>[
      preferred,
      for (final id in sortedCommodityIds)
        if (id != preferred) id,
    ];
  }
}
