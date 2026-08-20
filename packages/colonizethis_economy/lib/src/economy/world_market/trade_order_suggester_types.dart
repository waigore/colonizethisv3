/// Input/output types for [TradeOrderSuggester].
///
/// SPEC/game/world-market.md § Trade orders,
/// SPEC/program/world-market-resolution.md § Trade order suggestion API.
library;

import 'package:colonizethis_data/colonizethis_data.dart' as data;
import 'package:colonizethis_models/colonizethis_models.dart';

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

  data.ResourceRules get resourceRulesOrDefault =>
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
