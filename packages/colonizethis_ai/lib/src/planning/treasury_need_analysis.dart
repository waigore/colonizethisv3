
import 'planning_imports.dart';
import 'recipe_scoring.dart' show kShortageThreshold;
import 'treasury_market_pricing.dart';

export 'treasury_need_analysis_speculative.dart';

// Surplus / need-map analysis for the treasury planner (Refs #2994 F1–F5/F8 +
// #2924 F10), extracted from `treasury_planner.dart` for maintainability
// (Refs #3288 file-split). Behaviour-preserving move: same library scope (this
// is a `part of` the treasury-planner library), so imports, shared helpers, and
// visibility are unchanged.

Stockpile projectStockpileAfterProduction({
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

Set<CommodityId> trackedCommodityIds({
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

int consumptionForecast({
  required CommodityId commodityId,
  required Commodity commodity,
  required Map<CommodityId, int> inputNeeds,
}) {
  if (inputNeeds.containsKey(commodityId)) {
    return inputNeeds[commodityId]!.clamp(1, kShortageThreshold);
  }
  if (commodity.category == CommodityCategory.food) {
    return kShortageThreshold;
  }
  return (kShortageThreshold ~/ 2).clamp(1, kShortageThreshold);
}

Map<CommodityId, int> inputNeedsFromAssignments(
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

/// Parameter bag for [populateTreasurySurplusAndNeedMaps] (Refs #3997).
final class TreasurySurplusNeedMapsInput {
  const TreasurySurplusNeedMapsInput({
    required this.trackedCommodityIds,
    required this.inputNeeds,
    required this.projected,
    required this.carryForwardOffers,
    required this.carryForwardBids,
    required this.marketPrices,
    required this.isLockRecoverySeller,
    required this.isRegimentBuildInputMarketSupplier,
    required this.available,
    required this.need,
  });

  final Iterable<CommodityId> trackedCommodityIds;
  final Map<CommodityId, int> inputNeeds;
  final Stockpile projected;
  final Map<CommodityId, int> carryForwardOffers;
  final Map<CommodityId, int> carryForwardBids;
  final Map<CommodityId, int> marketPrices;
  final bool isLockRecoverySeller;
  final bool isRegimentBuildInputMarketSupplier;
  final Map<CommodityId, int> available;
  final Map<CommodityId, int> need;
}

void populateTreasurySurplusAndNeedMaps(TreasurySurplusNeedMapsInput input) {
  for (final id in input.trackedCommodityIds) {
    if (richesCommodityIds.contains(id)) continue;
    final commodity = CommodityCatalog.byId[id];
    if (commodity == null) continue;
    final consumption = consumptionForecast(
      commodityId: id,
      commodity: commodity,
      inputNeeds: input.inputNeeds,
    );
    final inputs = input.inputNeeds[id] ?? 0;
    var safety = commodity.category == CommodityCategory.food
        ? (input.isLockRecoverySeller ? 0 : consumption * 2)
        : consumption;
    if (input.isRegimentBuildInputMarketSupplier &&
        regimentBuildInputSupplyCommodityIds.contains(id)) {
      safety = 0;
    }
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
        marketPriceBelowProductionCost(id, input.marketPrices)) {
      input.need[id] = deficit;
    }
  }
}

/// Returns prior-turn offer-side fill rate (`0.0`–`1.0`) for [commodityId] from
/// [state.lastTurnActivity]. Returns `1.0` when no activity exists or
/// `totalOfferQuantity <= 0`, matching the "no prior data → assume fully
/// fillable" convention used elsewhere in F2/F3. Refs #2994 F8.
double priorTurnOfferFillRate(WorldMarketState state, CommodityId commodityId) {
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

/// Carry-forward residual quantity per commodity for [playerId] on the given
/// [side], summed across all carry-forward entries. Returns an empty map when
/// the player has no carry-forward state. Refs #2994 F8.
Map<CommodityId, int> carryForwardQuantitiesByCommodity({
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

/// Discounts forecasted treasury inflow from this turn's offers by the
/// prior-turn offer-side fill rate per commodity, rounded to an integer
/// treasury unit. A first-ever market turn (no prior activity) returns the
/// nominal sum (full-fill credit) per the F2/F3 default. Refs #2994 F8.
int expectedOfferInflow({
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
    final fillRate = priorTurnOfferFillRate(state, commodityId);
    inflow += quantity * price * fillRate;
  }
  if (!inflow.isFinite) return 0;
  return inflow.round();
}
