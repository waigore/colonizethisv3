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

import 'package:colonizethis_data/colonizethis_data.dart' as data;
import 'package:colonizethis_models/colonizethis_models.dart';

import 'trade_order_admission.dart' show isWorldMarketTradeableCommodity;
import 'treasury_bid_budget.dart' show effectiveMarketPriceForCommodityId;
import 'world_market_context_base.dart';

/// Inputs for one [TradeOrderSuggester.suggest] pass.
///
/// All fields are pre-computed by the caller. The suggester never touches
/// the `Game` directly — keeping it pure makes it trivially reusable from
/// `OrderSuggestionAPI`, the AI planner, and tests without mocking.
class TradeSuggestionContext extends WorldMarketContextBase {
  const TradeSuggestionContext({
    required super.playerId,
    required super.bidTypeCap,
    required super.tradeCargoCapacity,
    super.availableStockpileByCommodityId,
    this.commodityNeedByCommodityId = const <CommodityId, int>{},
    this.treasuryBudgetForBids = 1 << 30,
    this.worldMarketState = const WorldMarketState(),
    this.resourceRules,
    this.offerPriority = defaultOfferPriority,
    this.bidPriority = defaultBidPriority,
    this.preferredBidCommodityId,
  });

  /// Default offer priority used when the caller does not specify one.
  /// Mid-tier integer (5) leaves room for high-priority overrides above and
  /// low-priority fillers below without affecting matching outcomes inside a
  /// homogeneous suggestion set.
  static const int defaultOfferPriority = 5;

  /// Default bid priority. Same rationale as [defaultOfferPriority].
  static const int defaultBidPriority = 5;

  /// Per-commodity projected deficit in units the player wants to acquire
  /// this turn (forecast consumption + production inputs minus projected
  /// stockpile, clamped at 0). Used for bid suggestions only. Riches entries
  /// are ignored (rule 2).
  final Map<CommodityId, int> commodityNeedByCommodityId;

  /// Priority assigned to suggested offer orders.
  final int offerPriority;

  /// Priority assigned to suggested bid orders.
  final int bidPriority;

  /// Cross-commodity treasury budget for bids this turn — same semantics as
  /// [TradeOrderValidationContext.treasuryBudgetForBids].
  final int treasuryBudgetForBids;

  /// Market prices for [effectiveMarketPriceForCommodityId] when capping bids.
  final WorldMarketState worldMarketState;

  /// Catalog fallback prices when [worldMarketState] lacks an entry.
  final data.ResourceRules? resourceRules;

  /// Optional ordering hint: when set and present among the candidate
  /// commodities, this commodity is considered **first** (ahead of the default
  /// alphabetical order) so a capped bid set ([bidTypeCap]) admits it before
  /// other deficits. Used by the AI treasury planner to steer a bid toward a
  /// faction whose completed deal earns a trade-deal relation boost
  /// (Refs #3758 S9/R10; SPEC/ai/treasury-planner.md
  /// § Trade-deal relation-boost-aware bid preference). `null` (the default)
  /// preserves the legacy alphabetical ordering exactly.
  final CommodityId? preferredBidCommodityId;

  data.ResourceRules get _resourceRules =>
      resourceRules ?? data.ResourceRules.defaultRules;
}

/// Result envelope returned by [TradeOrderSuggester.suggest].
///
/// `offers` and `bids` never share a `commodityId` (mutual exclusion is
/// enforced at suggestion time so the validator's rule 3 cannot trip on
/// suggester output).
class TradeSuggestionResult {
  const TradeSuggestionResult({
    this.offers = const <TradeOrder>[],
    this.bids = const <TradeOrder>[],
  });

  static const empty = TradeSuggestionResult();

  final List<TradeOrder> offers;
  final List<TradeOrder> bids;

  bool get isEmpty => offers.isEmpty && bids.isEmpty;
}

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
      if (remainingCargoBudget <= 0) continue;
      var cappedQty = bidQuantity < remainingCargoBudget
          ? bidQuantity
          : remainingCargoBudget;
      final int? unitPrice = effectiveMarketPriceForCommodityId(
        commodityId: commodityId,
        worldMarket: context.worldMarketState,
        resourceRules: context._resourceRules,
      );
      if (unitPrice != null && unitPrice > 0) {
        final int maxAffordable = remainingTreasuryBudget ~/ unitPrice;
        if (cappedQty > maxAffordable) {
          cappedQty = maxAffordable;
        }
      }
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
      if (unitPrice != null && unitPrice > 0) {
        remainingTreasuryBudget -= cappedQty * unitPrice;
      }
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
