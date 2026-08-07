/// Bid prioritization and emission for trade counsel (neutral treasury path).
library;

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../world_market/trade_order_suggester.dart';
import '../world_market/treasury_bid_budget.dart'
    show capBidQuantityForBudgets, effectiveMarketPriceForCommodityId;
import 'trade_counsel_constants.dart';
import 'trade_counsel_market_pricing.dart';

final class TradeCounselEmitOrdersInput {
  const TradeCounselEmitOrdersInput({
    required this.game,
    required this.playerId,
    required this.bidTypeCap,
    required this.tradeCargoCapacity,
    required this.available,
    required this.need,
    required this.treasuryBudgetForBids,
    required this.offerPriority,
    this.resourceRules,
  });

  final Game game;
  final String playerId;
  final int bidTypeCap;
  final int tradeCargoCapacity;
  final Map<CommodityId, int> available;
  final Map<CommodityId, int> need;
  final int treasuryBudgetForBids;
  final int offerPriority;
  final ResourceRules? resourceRules;

  ResourceRules get rules => resourceRules ?? ResourceRules.defaultRules;
}

List<TradeOrder> tradeCounselEmitOrders(TradeCounselEmitOrdersInput input) {
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
      bidPriority: kTradeCounselBidPriorityRawMaterial,
      resourceRules: input.rules,
    ),
  );

  final bids = tradeCounselPrioritizedBids(
    rawBids: suggestion.bids,
    need: input.need,
    bidTypeCap: input.bidTypeCap,
    tradeCargoCapacity: input.tradeCargoCapacity,
    treasuryBudgetForBids: input.treasuryBudgetForBids,
    worldMarketState: input.game.worldMarketState,
    resourceRules: input.rules,
  );

  return [...suggestion.offers, ...bids];
}

List<TradeOrder> tradeCounselPrioritizedBids({
  required List<TradeOrder> rawBids,
  required Map<CommodityId, int> need,
  required int bidTypeCap,
  required int tradeCargoCapacity,
  required int treasuryBudgetForBids,
  required WorldMarketState worldMarketState,
  required ResourceRules resourceRules,
}) {
  if (rawBids.isEmpty || bidTypeCap <= 0 || tradeCargoCapacity <= 0) {
    return const <TradeOrder>[];
  }
  final byCommodity = <CommodityId, TradeOrder>{
    for (final bid in rawBids) bid.commodityId: bid,
  };
  final orderedIds = need.keys.toList(growable: false)
    ..sort((a, b) {
      final priorityCmp = tradeCounselBidPriorityForCommodity(a)
          .compareTo(tradeCounselBidPriorityForCommodity(b));
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
    final pricePerUnit = effectiveMarketPriceForCommodityId(
      commodityId: commodityId,
      worldMarket: worldMarketState,
      resourceRules: resourceRules,
    );
    final cappedQty = capBidQuantityForBudgets(
      bidQuantity: cargoClampedQty,
      remainingCargoBudget: remainingCargo,
      remainingTreasuryBudget: remainingTreasuryBudget,
      unitPrice: pricePerUnit,
    );
    if (cappedQty <= 0) continue;
    result.add(
      bid.copyWith(
        quantity: cappedQty,
        priority: tradeCounselBidPriorityForCommodity(commodityId),
      ),
    );
    remainingCargo -= cappedQty;
    if (pricePerUnit != null && pricePerUnit > 0) {
      remainingTreasuryBudget -= cappedQty * pricePerUnit;
    }
    admitted++;
  }
  return result;
}
