part of 'treasury_planner.dart';

// Surplus / need-map analysis for the treasury planner (Refs #2994 F1–F5/F8 +
// #2924 F10), extracted from `treasury_planner.dart` for maintainability
// (Refs #3288 file-split). Behaviour-preserving move: same library scope (this
// is a `part of` the treasury-planner library), so imports, shared helpers, and
// visibility are unchanged.

Stockpile _projectStockpileAfterProduction({
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

Set<CommodityId> _trackedCommodityIds({
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

int _consumptionForecast({
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

Map<CommodityId, int> _inputNeedsFromAssignments(
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

void _populateTreasurySurplusAndNeedMaps({
  required Iterable<CommodityId> trackedCommodityIds,
  required Map<CommodityId, int> inputNeeds,
  required Stockpile projected,
  required Map<CommodityId, int> carryForwardOffers,
  required Map<CommodityId, int> carryForwardBids,
  required Map<CommodityId, int> marketPrices,
  required bool isLockRecoverySeller,
  required bool isRegimentBuildInputMarketSupplier,
  required Map<CommodityId, int> available,
  required Map<CommodityId, int> need,
}) {
  for (final id in trackedCommodityIds) {
    if (richesCommodityIds.contains(id)) continue;
    final commodity = CommodityCatalog.byId[id];
    if (commodity == null) continue;
    final consumption = _consumptionForecast(
      commodityId: id,
      commodity: commodity,
      inputNeeds: inputNeeds,
    );
    final inputs = inputNeeds[id] ?? 0;
    var safety = commodity.category == CommodityCategory.food
        ? (isLockRecoverySeller ? 0 : consumption * 2)
        : consumption;
    if (isRegimentBuildInputMarketSupplier &&
        _regimentBuildInputSupplyCommodityIds.contains(id)) {
      safety = 0;
    }
    final reserve = consumption + inputs + safety;
    final projectedQty = projected.quantityOf(id);
    final surplus = projectedQty - reserve - (carryForwardOffers[id] ?? 0);
    if (surplus > 0) {
      available[id] = surplus;
    }
    final deficit =
        (consumption + inputs) - projectedQty - (carryForwardBids[id] ?? 0);
    if (deficit > 0 && _marketPriceBelowProductionCost(id, marketPrices)) {
      need[id] = deficit;
    }
  }
}

/// Returns prior-turn offer-side fill rate (`0.0`–`1.0`) for [commodityId] from
/// [state.lastTurnActivity]. Returns `1.0` when no activity exists or
/// `totalOfferQuantity <= 0`, matching the "no prior data → assume fully
/// fillable" convention used elsewhere in F2/F3. Refs #2994 F8.
double _priorTurnOfferFillRate(WorldMarketState state, CommodityId commodityId) {
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
Map<CommodityId, int> _carryForwardQuantitiesByCommodity({
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
int _expectedOfferInflow({
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
    final fillRate = _priorTurnOfferFillRate(state, commodityId);
    inflow += quantity * price * fillRate;
  }
  if (!inflow.isFinite) return 0;
  return inflow.round();
}

/// Speculative-bid pass for affluent GPs (Refs #2924 F10). Mutates [need] in
/// place with synthetic stockpile-target deficits for non-riches commodities
/// the F1–F5 path did not already speak for. Adds **at most one** entry per
/// invocation so bids are concentrated on the commodity most likely to clear
/// into a real deal (treasury only redistributes when matching offers exist).
/// Selection order:
/// 1. Commodities with prior-turn `MarketActivity.totalOfferQuantity > 0`
///    (descending offer volume, then alphabetical) — proven liquidity.
/// 2. Otherwise food commodities (deterministic alphabetical) — minor/tribe
///    auto-offers reliably surface food on the next world-market phase.
/// 3. Otherwise the alphabetical first non-riches commodity that meets the
///    target gap (deterministic fallback for an empty market — pure
///    determinism for tests that do not seed `lastTurnActivity`).
/// Skips:
/// - riches commodities (excluded from world-market trade),
/// - commodities already in [need] (F1–F5 deficit path owns them),
/// - commodities already in [available] (mutual-exclusion preserved),
/// - commodities whose projected stockpile already meets
///   [kSpeculativeBidStockpileTarget] (no positive target),
/// - commodities whose remaining target is already covered by a carry-forward
///   bid residual ([carryForwardBids]).
void _addSpeculativeBidNeeds({
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
    return kSpeculativeBidStockpileTarget - projectedQty - carryQty > 0;
  }

  int gapFor(CommodityId id) {
    final projectedQty = projected.quantityOf(id);
    final carryQty = carryForwardBids[id] ?? 0;
    return kSpeculativeBidStockpileTarget - projectedQty - carryQty;
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
