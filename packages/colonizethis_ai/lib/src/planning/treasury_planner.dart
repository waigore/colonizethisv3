// Treasury planner: World Market trade orders for AI GPs. SPEC/ai/treasury-planner.md.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/ai_api.dart'
    show cargoHoldsForHomeFleet, worldMarketBidTypeCap;
import 'package:colonizethis_logic/order_suggestion_api.dart'
    show TradeOrderSuggester, TradeSuggestionContext;
import 'package:colonizethis_models/colonizethis_models.dart';

import 'expand_phase_planner.dart' show cheapestRegimentBuildTreasuryCost;
import 'recipe_scoring.dart' show kShortageThreshold;

/// Bid priority tiers (1 = highest). Refs #2994 F4.
const int kTreasuryBidPriorityEssentialInput = 1;
const int kTreasuryBidPriorityLuxury = 2;
const int kTreasuryBidPriorityRawMaterial = 3;
const int kTreasuryBidPriorityFood = 4;

/// Default offer priority when treasury is comfortable.
const int kTreasuryOfferPriorityModerate = 5;

/// Aggressive sell priority when treasury is below the regiment threshold.
const int kTreasuryOfferPriorityUrgent = 2;

/// Returns trade orders for one AI-controlled GP after production planning.
///
/// Runs after [productionAssignments] are chosen in [runEconomyPlanner]. Uses
/// [TradeOrderSuggester] with treasury-aware surplus/need maps and per-commodity
/// bid priorities. Refs #2994 F1–F5, F8 (carry-forward de-duplication and
/// prior-fill-rate-aware offer urgency, see SPEC/ai/treasury-planner.md
/// § Partial-fill-aware forecasting).
List<TradeOrder> runTreasuryPlanner({
  required Game game,
  required String playerId,
  required Stockpile stockpile,
  required List<AssignedRecipe> productionAssignments,
  required int treasury,
}) {
  final bidTypeCap = worldMarketBidTypeCap(game, playerId);
  final homeFleetHolds = cargoHoldsForHomeFleet(game, playerId);
  // Overseas extraction tonnage reservation lands when extraction publishes
  // per-player planned tonnage on the pipeline; until then treat as zero
  // (same deferral as world-market phase handler Refs #2990 B3).
  final tradeCargoCapacity = homeFleetHolds < 0 ? 0 : homeFleetHolds;

  final projected = _projectStockpileAfterProduction(
    stockpile: stockpile,
    productionAssignments: productionAssignments,
  );
  final inputNeeds = _inputNeedsFromAssignments(productionAssignments);
  final trackedCommodityIds = _trackedCommodityIds(
    stockpile: stockpile,
    projected: projected,
    inputNeeds: inputNeeds,
    productionAssignments: productionAssignments,
  );
  final available = <CommodityId, int>{};
  final need = <CommodityId, int>{};
  final marketPrices = game.worldMarketState.prices;
  // Refs #2994 F8: carry-forward residuals already represented in Issue A's
  // queues are subtracted from the planner's new-emission gap so the engine
  // never sees duplicate quantities.
  final carryForwardOffers = _carryForwardQuantitiesByCommodity(
    state: game.worldMarketState,
    playerId: playerId,
    side: TradeOrderType.offer,
  );
  final carryForwardBids = _carryForwardQuantitiesByCommodity(
    state: game.worldMarketState,
    playerId: playerId,
    side: TradeOrderType.bid,
  );

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
    final safety = commodity.category == CommodityCategory.food
        ? consumption * 2
        : consumption;
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

  if (available.isEmpty && need.isEmpty) {
    return const <TradeOrder>[];
  }

  final threshold = cheapestRegimentBuildTreasuryCost();
  final treasuryForecast = treasury +
      _expectedOfferInflow(
        available: available,
        marketPrices: marketPrices,
        state: game.worldMarketState,
      );
  final offerPriority = treasuryForecast < threshold
      ? kTreasuryOfferPriorityUrgent
      : kTreasuryOfferPriorityModerate;

  final suggestion = TradeOrderSuggester.suggest(
    TradeSuggestionContext(
      playerId: playerId,
      bidTypeCap: bidTypeCap,
      tradeCargoCapacity: tradeCargoCapacity,
      availableStockpileByCommodityId: available,
      commodityNeedByCommodityId: need,
      offerPriority: offerPriority,
      bidPriority: kTreasuryBidPriorityRawMaterial,
    ),
  );

  final offers = suggestion.offers;
  final bids = _prioritizedBids(
    rawBids: suggestion.bids,
    need: need,
    bidTypeCap: bidTypeCap,
    tradeCargoCapacity: tradeCargoCapacity,
  );

  return [...offers, ...bids];
}

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

bool _marketPriceBelowProductionCost(
  CommodityId commodityId,
  Map<CommodityId, double> marketPrices,
) {
  final marketPrice = marketPrices[commodityId];
  if (marketPrice == null) return true;
  var bestCost = double.infinity;
  for (final recipe in ProductionRecipesCatalog.all) {
    if (recipe.outputCommodityId != commodityId) continue;
    var inputCost = 0.0;
    for (final entry in recipe.inputQuantities.entries) {
      final inputPrice = marketPrices[entry.key] ?? 0.0;
      inputCost += inputPrice * entry.value;
    }
    final perUnit = inputCost / recipe.outputQuantity;
    if (perUnit < bestCost) bestCost = perUnit;
  }
  if (bestCost == double.infinity) return true;
  return marketPrice < bestCost;
}

int _bidPriorityForCommodity(CommodityId commodityId) {
  final commodity = CommodityCatalog.byId[commodityId];
  if (commodity == null) return kTreasuryBidPriorityRawMaterial;
  return switch (commodity.category) {
    CommodityCategory.manufactured ||
    CommodityCategory.advanced =>
      kTreasuryBidPriorityEssentialInput,
    CommodityCategory.food => kTreasuryBidPriorityFood,
    CommodityCategory.rawMaterial => kTreasuryBidPriorityRawMaterial,
    CommodityCategory.luxury => kTreasuryBidPriorityLuxury,
    CommodityCategory.riches => kTreasuryBidPriorityRawMaterial,
  };
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
  required Map<CommodityId, double> marketPrices,
  required WorldMarketState state,
}) {
  if (available.isEmpty) return 0;
  var inflow = 0.0;
  for (final entry in available.entries) {
    final commodityId = entry.key;
    final quantity = entry.value;
    if (quantity <= 0) continue;
    final price = marketPrices[commodityId] ?? 0.0;
    if (price <= 0.0) continue;
    final fillRate = _priorTurnOfferFillRate(state, commodityId);
    inflow += quantity * price * fillRate;
  }
  if (!inflow.isFinite) return 0;
  return inflow.round();
}

List<TradeOrder> _prioritizedBids({
  required List<TradeOrder> rawBids,
  required Map<CommodityId, int> need,
  required int bidTypeCap,
  required int tradeCargoCapacity,
}) {
  if (rawBids.isEmpty || bidTypeCap <= 0 || tradeCargoCapacity <= 0) {
    return const <TradeOrder>[];
  }
  final byCommodity = <CommodityId, TradeOrder>{
    for (final bid in rawBids) bid.commodityId: bid,
  };
  final orderedIds = need.keys.toList(growable: false)
    ..sort((a, b) {
      final priorityCmp =
          _bidPriorityForCommodity(a).compareTo(_bidPriorityForCommodity(b));
      if (priorityCmp != 0) return priorityCmp;
      return a.compareTo(b);
    });

  final result = <TradeOrder>[];
  var remainingCargo = tradeCargoCapacity;
  var admitted = 0;
  for (final commodityId in orderedIds) {
    if (admitted >= bidTypeCap) break;
    if (remainingCargo <= 0) break;
    final bid = byCommodity[commodityId];
    if (bid == null) continue;
    final cappedQty = bid.quantity < remainingCargo
        ? bid.quantity
        : remainingCargo;
    if (cappedQty <= 0) continue;
    result.add(
      bid.copyWith(
        quantity: cappedQty,
        priority: _bidPriorityForCommodity(commodityId),
      ),
    );
    remainingCargo -= cappedQty;
    admitted += 1;
  }
  return result;
}
