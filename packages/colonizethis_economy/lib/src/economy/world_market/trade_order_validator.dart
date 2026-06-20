/// Trade-order validation rules for the world market.
///
/// SPEC/game/world-market.md § Trade orders,
/// SPEC/program/world-market-resolution.md § Trade order validation.
///
/// The validator is **pure**: deterministic for fixed inputs, silent (no
/// logger calls), and safe to call from order-submission, AI suggestion, and
/// resolver-prep paths under the 15-second turn-resolution budget per
/// `.cursor/rules/colonizethis-turn-resolution-budget.mdc`.
///
/// The context-building concern ([TradeOrderValidationContext], the
/// [TradeOrderRejectionReasons] codes, and `tradeOrderValidationContextFromGame`)
/// lives in `trade_order_validation_context.dart`; both files are re-exported
/// from the `colonizethis_economy` barrel so callers import from one path.
///
library;

import 'package:colonizethis_data/colonizethis_data.dart' as data;
import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_economy/src/validation/order_validation_result.dart';
import 'trade_order_validation_context.dart';
import 'treasury_bid_budget.dart' show effectiveMarketPriceForCommodityId;

/// Validates a single player's full set of [TradeOrder] entries for the turn.
class TradeOrderValidator {
  TradeOrderValidator._();

  /// Returns a parallel `List<OrderValidationResult>` aligned to
  /// [proposedOrders]. Each entry is `accepted` or `rejected` with one of
  /// the [tradeOrderRejectionReasons] stable codes.
  ///
  /// The validator applies rules in deterministic order
  /// (1 → 2 → 3 → 4 → 5 → 6 → 7) and records the **first** failing rule for each
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
    var runningBidTreasurySpend = 0;
    for (final order in proposedOrders) {
      final outcome = _validateOne(
        order: order,
        context: context,
        mutuallyExcludedCommodityIds: mutuallyExcludedCommodityIds,
        admittedBidCommodityIds: admittedBidCommodityIds,
        runningBidTreasurySpend: runningBidTreasurySpend,
      );
      results.add(outcome.result);
      if (outcome.result.isAccepted && order.type == TradeOrderType.bid) {
        runningBidTreasurySpend = outcome.nextRunningBidTreasurySpend;
      }
    }
    return results;
  }

  static ({OrderValidationResult result, int nextRunningBidTreasurySpend})
  _validateOne({
    required TradeOrder order,
    required TradeOrderValidationContext context,
    required Set<CommodityId> mutuallyExcludedCommodityIds,
    required Set<CommodityId> admittedBidCommodityIds,
    required int runningBidTreasurySpend,
  }) {
    if (order.quantity <= 0) {
      return (
        result: OrderValidationResult.rejected(
          TradeOrderRejectionReasons.invalidQuantity,
        ),
        nextRunningBidTreasurySpend: runningBidTreasurySpend,
      );
    }
    if (data.richesCommodityIds.contains(order.commodityId)) {
      return (
        result: OrderValidationResult.rejected(
          TradeOrderRejectionReasons.richesNotTradeable,
        ),
        nextRunningBidTreasurySpend: runningBidTreasurySpend,
      );
    }
    if (mutuallyExcludedCommodityIds.contains(order.commodityId)) {
      return (
        result: OrderValidationResult.rejected(
          TradeOrderRejectionReasons.mutualExclusion,
        ),
        nextRunningBidTreasurySpend: runningBidTreasurySpend,
      );
    }
    if (order.type == TradeOrderType.bid) {
      if (!admittedBidCommodityIds.contains(order.commodityId)) {
        return (
          result: OrderValidationResult.rejected(
            TradeOrderRejectionReasons.bidTypeCapExceeded,
          ),
          nextRunningBidTreasurySpend: runningBidTreasurySpend,
        );
      }
      final int orderSpend = _bidOrderTreasurySpend(order, context);
      if (runningBidTreasurySpend + orderSpend >
          context.treasuryBudgetForBids) {
        return (
          result: OrderValidationResult.rejected(
            TradeOrderRejectionReasons.bidExceedsTreasuryBudget,
          ),
          nextRunningBidTreasurySpend: runningBidTreasurySpend,
        );
      }
      if (order.quantity > context.tradeCargoCapacity) {
        return (
          result: OrderValidationResult.rejected(
            TradeOrderRejectionReasons.bidExceedsCargoCapacity,
          ),
          nextRunningBidTreasurySpend: runningBidTreasurySpend,
        );
      }
      return (
        result: OrderValidationResult.accepted(),
        nextRunningBidTreasurySpend: runningBidTreasurySpend + orderSpend,
      );
    }
    final available =
        context.availableStockpileByCommodityId[order.commodityId] ?? 0;
    if (order.quantity > available) {
      return (
        result: OrderValidationResult.rejected(
          TradeOrderRejectionReasons.offerExceedsStockpile,
        ),
        nextRunningBidTreasurySpend: runningBidTreasurySpend,
      );
    }
    return (
      result: OrderValidationResult.accepted(),
      nextRunningBidTreasurySpend: runningBidTreasurySpend,
    );
  }

  static int _bidOrderTreasurySpend(
    TradeOrder order,
    TradeOrderValidationContext context,
  ) {
    final int? price = effectiveMarketPriceForCommodityId(
      commodityId: order.commodityId,
      worldMarket: context.worldMarketState,
      resourceRules: context.resourceRules,
    );
    if (price == null) return 0;
    return order.quantity * price;
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
