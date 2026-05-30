/// Trade-order validation for the world market.
///
/// SPEC/game/world-market.md § Trade orders,
/// SPEC/program/world-market-resolution.md § Trade order validation.
///
/// The validator is **pure**: deterministic for fixed inputs, silent (no
/// logger calls), and safe to call from order-submission, AI suggestion, and
/// resolver-prep paths under the 15-second turn-resolution budget per
/// `.cursor/rules/colonizethis-turn-resolution-budget.mdc`.
///
/// `OrderEngine` slot wiring for `tradeOrdersByPlayerId` is deferred to a
/// follow-up commit on #2989; this layer is independently consumable by the
/// upcoming suggestion API (#2989 A6) and by UI / AI integration.
library;

import 'package:colonizethis_data/colonizethis_data.dart' as data;
import 'package:colonizethis_models/colonizethis_models.dart';

import '../../orders/order_validation_result.dart';

/// Stable rejection-reason codes returned by [TradeOrderValidator.validate].
///
/// UI, suggestion code, and tests should branch on these constants rather
/// than parsing the free-text [OrderValidationResult.reason]. Codes line up
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
  static const String bidTypeCapExceeded =
      'trade_order_bid_type_cap_exceeded';

  /// Rule 5 — Per-commodity bid quantity exceeds `tradeCargoCapacity`.
  static const String bidExceedsCargoCapacity =
      'trade_order_bid_exceeds_cargo_capacity';

  /// Rule 6 — Per-commodity offer quantity exceeds
  /// `availableStockpileByCommodityId[commodityId] ?? 0`.
  static const String offerExceedsStockpile =
      'trade_order_offer_exceeds_stockpile';
}

/// Inputs for one [TradeOrderValidator.validate] pass.
///
/// All fields are pre-computed by the caller. The validator never touches
/// the `Game` directly — keeping it pure makes it trivially reusable from
/// the order engine, AI planner, and tests without mocking.
class TradeOrderValidationContext {
  const TradeOrderValidationContext({
    required this.playerId,
    required this.bidTypeCap,
    required this.tradeCargoCapacity,
    required this.availableStockpileByCommodityId,
  });

  /// Submitting faction id. Informational; the validator does no cross-player
  /// checks.
  final String playerId;

  /// `0 / 3 / 6` cap on distinct bid commodities for this player this turn.
  /// Pre-computed via `worldMarketBidTypeCap` in
  /// `packages/colonizethis_logic/lib/src/diplomacy/diplomacy_subsidies_relations_resolver.dart`.
  final int bidTypeCap;

  /// Cross-commodity cargo budget for this player's bids this turn (units).
  /// Per `SPEC/game/world-market.md` § Cargo:
  /// `max(0, totalHomeFleetCargoHolds - overseasExtractionActualTonnage)`.
  /// Wired by the phase handler (Issue B / #2990).
  final int tradeCargoCapacity;

  /// Per-commodity quantity available to **offer** this turn, after committed
  /// industry allocation has been subtracted from the projected
  /// post-production stockpile (`stockpile[id] - industryAllocation[id]`,
  /// clamped at 0). Missing entries are treated as `0`. Riches commodities
  /// should not be present (they are rejected by rule 2 anyway).
  final Map<CommodityId, int> availableStockpileByCommodityId;
}

/// Validates a single player's full set of [TradeOrder] entries for the turn.
class TradeOrderValidator {
  TradeOrderValidator._();

  /// Returns a parallel `List<OrderValidationResult>` aligned to
  /// [proposedOrders]. Each entry is `accepted` or `rejected` with one of
  /// the [tradeOrderRejectionReasons] stable codes.
  ///
  /// The validator applies rules in deterministic order
  /// (1 → 2 → 3 → 4 → 5/6) and records the **first** failing rule for each
  /// rejected order. Pre-pass classifiers (mutual exclusion, bid type
  /// admission set) are computed once for the whole submission so result
  /// stability does not depend on intra-submission interleaving.
  static List<OrderValidationResult> validate({
    required TradeOrderValidationContext context,
    required List<TradeOrder> proposedOrders,
  }) {
    if (proposedOrders.isEmpty) {
      return const <OrderValidationResult>[];
    }

    final mutuallyExcludedCommodityIds = _commoditiesWithBidAndOffer(
      proposedOrders,
    );
    final admittedBidCommodityIds = _admittedBidCommodityIds(
      proposedOrders: proposedOrders,
      bidTypeCap: context.bidTypeCap,
      mutuallyExcludedCommodityIds: mutuallyExcludedCommodityIds,
    );

    final results = <OrderValidationResult>[];
    for (final order in proposedOrders) {
      results.add(
        _validateOne(
          order: order,
          context: context,
          mutuallyExcludedCommodityIds: mutuallyExcludedCommodityIds,
          admittedBidCommodityIds: admittedBidCommodityIds,
        ),
      );
    }
    return results;
  }

  static OrderValidationResult _validateOne({
    required TradeOrder order,
    required TradeOrderValidationContext context,
    required Set<CommodityId> mutuallyExcludedCommodityIds,
    required Set<CommodityId> admittedBidCommodityIds,
  }) {
    if (order.quantity <= 0) {
      return OrderValidationResult.rejected(
        TradeOrderRejectionReasons.invalidQuantity,
      );
    }
    if (data.richesCommodityIds.contains(order.commodityId)) {
      return OrderValidationResult.rejected(
        TradeOrderRejectionReasons.richesNotTradeable,
      );
    }
    if (mutuallyExcludedCommodityIds.contains(order.commodityId)) {
      return OrderValidationResult.rejected(
        TradeOrderRejectionReasons.mutualExclusion,
      );
    }
    if (order.type == TradeOrderType.bid) {
      if (!admittedBidCommodityIds.contains(order.commodityId)) {
        return OrderValidationResult.rejected(
          TradeOrderRejectionReasons.bidTypeCapExceeded,
        );
      }
      if (order.quantity > context.tradeCargoCapacity) {
        return OrderValidationResult.rejected(
          TradeOrderRejectionReasons.bidExceedsCargoCapacity,
        );
      }
      return OrderValidationResult.accepted();
    }
    final available =
        context.availableStockpileByCommodityId[order.commodityId] ?? 0;
    if (order.quantity > available) {
      return OrderValidationResult.rejected(
        TradeOrderRejectionReasons.offerExceedsStockpile,
      );
    }
    return OrderValidationResult.accepted();
  }

  /// Commodity ids that appear in [proposedOrders] as **both** a bid and an
  /// offer. Used to reject every order on either side per rule 3.
  static Set<CommodityId> _commoditiesWithBidAndOffer(
    List<TradeOrder> proposedOrders,
  ) {
    final bidCommodities = <CommodityId>{};
    final offerCommodities = <CommodityId>{};
    for (final order in proposedOrders) {
      if (order.type == TradeOrderType.bid) {
        bidCommodities.add(order.commodityId);
      } else {
        offerCommodities.add(order.commodityId);
      }
    }
    if (bidCommodities.isEmpty || offerCommodities.isEmpty) {
      return const <CommodityId>{};
    }
    return bidCommodities.intersection(offerCommodities);
  }

  /// Returns the set of bid commodity ids admitted under [bidTypeCap], in
  /// submission order. Excludes commodities already rejected by rule 3
  /// (mutual exclusion) so they do not consume a cap slot.
  static Set<CommodityId> _admittedBidCommodityIds({
    required List<TradeOrder> proposedOrders,
    required int bidTypeCap,
    required Set<CommodityId> mutuallyExcludedCommodityIds,
  }) {
    if (bidTypeCap <= 0) return const <CommodityId>{};
    final admitted = <CommodityId>{};
    for (final order in proposedOrders) {
      if (order.type != TradeOrderType.bid) continue;
      if (order.quantity <= 0) continue;
      if (data.richesCommodityIds.contains(order.commodityId)) continue;
      if (mutuallyExcludedCommodityIds.contains(order.commodityId)) continue;
      if (admitted.contains(order.commodityId)) continue;
      if (admitted.length >= bidTypeCap) break;
      admitted.add(order.commodityId);
    }
    return admitted;
  }
}
