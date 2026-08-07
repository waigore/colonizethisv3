/// Surplus / need-map analysis for trade counsel (neutral treasury path).
library;

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../industry_counsel/industry_counsel_constants.dart'
    show kIndustryCounselShortageThreshold;
import 'trade_counsel_constants.dart';
import 'trade_counsel_market_pricing.dart';

Stockpile tradeCounselProjectStockpileAfterProduction({
  required Stockpile stockpile,
  required List<AssignedRecipe> productionAssignments,
}) {
  var projected = stockpile;
  for (final assignment in productionAssignments) {
    final recipe = ProductionRecipesCatalog.byId[assignment.recipeId];
    if (recipe == null || assignment.assignedLabour <= 0) continue;
    final runs = assignment.assignedLabour ~/ recipe.labourPerOutput;
    if (runs <= 0) continue;
    for (final entry in recipe.inputQuantities.entries) {
      projected = projected.applyDelta(entry.key, -entry.value * runs);
    }
    projected = projected.applyDelta(
      recipe.outputCommodityId,
      recipe.outputQuantity * runs,
    );
  }
  return projected;
}

Set<CommodityId> tradeCounselTrackedCommodityIds({
  required Stockpile stockpile,
  required Stockpile projected,
  required Map<CommodityId, int> inputNeeds,
  required List<AssignedRecipe> productionAssignments,
}) {
  final ids = <CommodityId>{...inputNeeds.keys};
  for (final entry in stockpile.quantities.entries) {
    if (entry.value > 0) ids.add(entry.key);
  }
  for (final entry in projected.quantities.entries) {
    if (entry.value > 0) ids.add(entry.key);
  }
  for (final assignment in productionAssignments) {
    final recipe = ProductionRecipesCatalog.byId[assignment.recipeId];
    if (recipe == null) continue;
    ids.add(recipe.outputCommodityId);
    ids.addAll(recipe.inputQuantities.keys);
  }
  for (final commodity in CommodityCatalog.all) {
    if (commodity.category == CommodityCategory.food) {
      ids.add(commodity.id);
    }
  }
  return ids;
}

int tradeCounselConsumptionForecast({
  required CommodityId commodityId,
  required Commodity commodity,
  required Map<CommodityId, int> inputNeeds,
}) {
  if (inputNeeds.containsKey(commodityId)) {
    return inputNeeds[commodityId]!.clamp(1, kIndustryCounselShortageThreshold);
  }
  if (commodity.category == CommodityCategory.food) {
    return kIndustryCounselShortageThreshold;
  }
  return (kIndustryCounselShortageThreshold ~/ 2)
      .clamp(1, kIndustryCounselShortageThreshold);
}

Map<CommodityId, int> tradeCounselInputNeedsFromAssignments(
  List<AssignedRecipe> productionAssignments,
) {
  final needs = <CommodityId, int>{};
  for (final assignment in productionAssignments) {
    final recipe = ProductionRecipesCatalog.byId[assignment.recipeId];
    if (recipe == null || assignment.assignedLabour <= 0) continue;
    final runs = assignment.assignedLabour ~/ recipe.labourPerOutput;
    if (runs <= 0) continue;
    for (final entry in recipe.inputQuantities.entries) {
      needs[entry.key] = (needs[entry.key] ?? 0) + entry.value * runs;
    }
  }
  return needs;
}

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

void tradeCounselAddSpeculativeBidNeeds({
  required Map<CommodityId, int> need,
  required Map<CommodityId, int> available,
  required Stockpile projected,
  required Map<CommodityId, int> carryForwardBids,
  required WorldMarketState state,
}) {
  bool eligible(CommodityId id) {
    if (richesCommodityIds.contains(id)) return false;
    if (need.containsKey(id)) return false;
    if (available.containsKey(id)) return false;
    final projectedQty = projected.quantityOf(id);
    final carryQty = carryForwardBids[id] ?? 0;
    return kTradeCounselSpeculativeBidStockpileTarget -
            projectedQty -
            carryQty >
        0;
  }

  int gapFor(CommodityId id) {
    final projectedQty = projected.quantityOf(id);
    final carryQty = carryForwardBids[id] ?? 0;
    return kTradeCounselSpeculativeBidStockpileTarget - projectedQty - carryQty;
  }

  int offerVolumeFor(CommodityId id) =>
      state.lastTurnActivity[id]?.totalOfferQuantity ?? 0;

  final eligibleIds = CommodityCatalog.all
      .map((c) => c.id)
      .where(eligible)
      .toList(growable: false);
  if (eligibleIds.isEmpty) return;

  CommodityId pick;
  final liquid = eligibleIds.where((id) => offerVolumeFor(id) > 0).toList()
    ..sort((a, b) {
      final volCmp = offerVolumeFor(b).compareTo(offerVolumeFor(a));
      if (volCmp != 0) return volCmp;
      return a.compareTo(b);
    });
  if (liquid.isNotEmpty) {
    pick = liquid.first;
  } else {
    final foods = eligibleIds
        .where(
          (id) => CommodityCatalog.byId[id]?.category == CommodityCategory.food,
        )
        .toList()
      ..sort();
    if (foods.isNotEmpty) {
      pick = foods.first;
    } else {
      final sortedEligible = [...eligibleIds]..sort();
      pick = sortedEligible.first;
    }
  }
  need[pick] = gapFor(pick);
}
