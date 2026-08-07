/// Market-pricing helpers for trade counsel (neutral treasury path).
library;

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'trade_counsel_constants.dart';

bool tradeCounselMarketPriceBelowProductionCost(
  CommodityId commodityId,
  Map<CommodityId, int> marketPrices,
) {
  final marketPrice = marketPrices[commodityId];
  if (marketPrice == null) return true;
  var bestCost = double.infinity;
  for (final recipe in ProductionRecipesCatalog.producing(commodityId)) {
    var inputCost = 0.0;
    for (final entry in recipe.inputQuantities.entries) {
      final inputPrice = marketPrices[entry.key] ?? 0;
      inputCost += inputPrice * entry.value;
    }
    final perUnit = inputCost / recipe.outputQuantity;
    if (perUnit < bestCost) bestCost = perUnit;
  }
  if (bestCost == double.infinity) return true;
  return marketPrice < bestCost;
}

int tradeCounselBidPriorityForCommodity(CommodityId commodityId) {
  final commodity = CommodityCatalog.byId[commodityId];
  if (commodity == null) return kTradeCounselBidPriorityRawMaterial;
  return switch (commodity.category) {
    CommodityCategory.manufactured ||
    CommodityCategory.advanced =>
      kTradeCounselBidPriorityEssentialInput,
    CommodityCategory.food => kTradeCounselBidPriorityFood,
    CommodityCategory.rawMaterial => kTradeCounselBidPriorityRawMaterial,
    CommodityCategory.luxury => kTradeCounselBidPriorityLuxury,
    CommodityCategory.riches => kTradeCounselBidPriorityRawMaterial,
  };
}
