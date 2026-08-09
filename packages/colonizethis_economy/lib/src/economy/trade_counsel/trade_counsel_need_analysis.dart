/// Surplus / need-map analysis for trade counsel (neutral treasury path).
library;

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'trade_counsel_market_pricing.dart';
import 'trade_counsel_stockpile_projection.dart';

export 'trade_counsel_speculative_bids.dart';
export 'trade_counsel_stockpile_projection.dart';

final class TradeCounselSurplusNeedMapsInput {
  const TradeCounselSurplusNeedMapsInput({
    required this.trackedCommodityIds,
    required this.inputNeeds,
    required this.projected,
    required this.carryForwardOffers,
    required this.carryForwardBids,
    required this.marketPrices,
    required this.available,
    required this.need,
  });

  final Iterable<CommodityId> trackedCommodityIds;
  final Map<CommodityId, int> inputNeeds;
  final Stockpile projected;
  final Map<CommodityId, int> carryForwardOffers;
  final Map<CommodityId, int> carryForwardBids;
  final Map<CommodityId, int> marketPrices;
  final Map<CommodityId, int> available;
  final Map<CommodityId, int> need;
}

void tradeCounselPopulateSurplusAndNeedMaps(
  TradeCounselSurplusNeedMapsInput input,
) {
  for (final id in input.trackedCommodityIds) {
    if (richesCommodityIds.contains(id)) continue;
    final commodity = CommodityCatalog.byId[id];
    if (commodity == null) continue;
    final consumption = tradeCounselConsumptionForecast(
      commodityId: id,
      commodity: commodity,
      inputNeeds: input.inputNeeds,
    );
    final inputs = input.inputNeeds[id] ?? 0;
    final safety = commodity.category == CommodityCategory.food
        ? consumption * 2
        : consumption;
    final reserve = consumption + inputs + safety;
    final projectedQty = input.projected.quantityOf(id);
    final surplus =
        projectedQty - reserve - (input.carryForwardOffers[id] ?? 0);
    if (surplus > 0) {
      input.available[id] = surplus;
    }
    final deficit = (consumption + inputs) -
        projectedQty -
        (input.carryForwardBids[id] ?? 0);
    if (deficit > 0 &&
        tradeCounselMarketPriceBelowProductionCost(id, input.marketPrices)) {
      input.need[id] = deficit;
    }
  }
}

double tradeCounselPriorTurnOfferFillRate(
  WorldMarketState state,
  CommodityId commodityId,
) {
  final activity = state.lastTurnActivity[commodityId];
  if (activity == null) return 1.0;
  final total = activity.totalOfferQuantity;
  if (total <= 0) return 1.0;
  final fillFraction = activity.filledQuantity / total;
  if (fillFraction.isNaN || !fillFraction.isFinite) return 1.0;
  if (fillFraction < 0.0) return 0.0;
  if (fillFraction > 1.0) return 1.0;
  return fillFraction;
}

Map<CommodityId, int> tradeCounselCarryForwardQuantitiesByCommodity({
  required WorldMarketState state,
  required String playerId,
  required TradeOrderType side,
}) {
  final source = switch (side) {
    TradeOrderType.offer => state.carryForwardOffersByFactionId[playerId],
    TradeOrderType.bid => state.carryForwardBidsByFactionId[playerId],
  };
  if (source == null || source.isEmpty) {
    return const <CommodityId, int>{};
  }
  final result = <CommodityId, int>{};
  for (final order in source) {
    if (order.quantity <= 0) continue;
    result[order.commodityId] =
        (result[order.commodityId] ?? 0) + order.quantity;
  }
  return result;
}

int tradeCounselExpectedOfferInflow({
  required Map<CommodityId, int> available,
  required Map<CommodityId, int> marketPrices,
  required WorldMarketState state,
}) {
  if (available.isEmpty) return 0;
  var inflow = 0.0;
  for (final entry in available.entries) {
    final commodityId = entry.key;
    final quantity = entry.value;
    if (quantity <= 0) continue;
    final price = marketPrices[commodityId] ?? 0;
    if (price <= 0) continue;
    final fillRate = tradeCounselPriorTurnOfferFillRate(state, commodityId);
    inflow += quantity * price * fillRate;
  }
  if (!inflow.isFinite) return 0;
  return inflow.round();
}
