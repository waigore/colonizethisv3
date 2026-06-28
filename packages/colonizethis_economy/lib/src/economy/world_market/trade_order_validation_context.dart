/// Trade-order validation context and rejection-reason codes for the world
/// market.
///
/// SPEC/game/world-market.md § Trade orders,
/// SPEC/program/world-market-resolution.md § Trade order validation.
///
/// This file carries the *context-building* concern: the stable rejection
/// reason codes and the pre-computed [TradeOrderValidationContext] inputs. The
/// Game-scoped factory (`tradeOrderValidationContextFromGame`) lives in
/// `world_market_player_context.dart` alongside the shared snapshot facade
/// (Refs #3615 Cluster 2). Rule evaluation lives in `trade_order_validator.dart`.
/// All are re-exported from the same `colonizethis_economy` barrel, so callers
/// are unaffected by the split.
///
library;

import 'package:colonizethis_data/colonizethis_data.dart' as data;
import 'package:colonizethis_models/colonizethis_models.dart';

import 'world_market_context_base.dart';

/// Stable rejection-reason codes returned by `TradeOrderValidator.validate`.
///
/// UI, suggestion code, and tests should branch on these constants rather
/// than parsing the free-text `OrderValidationResult.reason`. Codes line up
/// 1:1 with the rules table in
/// `SPEC/program/world-market-resolution.md § Validation rules`.
abstract final class TradeOrderRejectionReasons {
  /// Rule 1 — `TradeOrder.quantity > 0`.
  static const String invalidQuantity = 'trade_order_invalid_quantity';

  /// Rule 2 — Commodity is in `richesCommodityIds` and may not trade on the
  /// world market.
  static const String richesNotTradeable = 'trade_order_riches_not_tradeable';

  /// Rule 3 — The same commodity appears as both a bid and an offer in the
  /// submitted set. Both sides are rejected.
  static const String mutualExclusion = 'trade_order_mutual_exclusion';

  /// Rule 4 — Distinct bid commodity count exceeds the player's
  /// `worldMarketBidTypeCap`.
  static const String bidTypeCapExceeded = 'trade_order_bid_type_cap_exceeded';

  /// Rule 5 — Cross-commodity bid spend would exceed `treasuryBudgetForBids`.
  static const String bidExceedsTreasuryBudget =
      'trade_order_bid_exceeds_treasury_budget';

  /// Rule 6 — Per-commodity bid quantity exceeds `tradeCargoCapacity`.
  static const String bidExceedsCargoCapacity =
      'trade_order_bid_exceeds_cargo_capacity';

  /// Rule 7 — Per-commodity offer quantity exceeds
  /// `availableStockpileByCommodityId[commodityId] ?? 0`.
  static const String offerExceedsStockpile =
      'trade_order_offer_exceeds_stockpile';
}

/// Inputs for one `TradeOrderValidator.validate` pass.
///
/// All fields are pre-computed by the caller. The validator never touches
/// the `Game` directly — keeping it pure makes it trivially reusable from
/// the order engine, AI planner, and tests without mocking.
class TradeOrderValidationContext extends WorldMarketContextBase {
  TradeOrderValidationContext({
    required super.playerId,
    required super.bidTypeCap,
    required super.tradeCargoCapacity,
    required super.availableStockpileByCommodityId,
    required this.treasuryBudgetForBids,
    this.worldMarketState = const WorldMarketState(),
    data.ResourceRules? resourceRules,
  }) : resourceRules = resourceRules ?? data.ResourceRules.defaultRules;

  /// Maximum `Σ (quantity × effectiveMarketPrice)` across admitted bids this
  /// turn (`SPEC/game/world-market.md` § Treasury budget for bids).
  final int treasuryBudgetForBids;

  /// Market prices used to price bid spend (integer treasury units).
  final WorldMarketState worldMarketState;

  /// Catalog fallback prices when [worldMarketState.prices] lacks an entry.
  final data.ResourceRules resourceRules;
}
