// Treasury planner: World Market trade orders for AI GPs. SPEC/ai/treasury-planner.md.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/ai_api.dart'
    show cargoHoldsForHomeFleet, tradeCargoCapacityForGreatPower, worldMarketBidTypeCap;
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

/// Multiplier on `cheapestRegimentBuildTreasuryCost()` that defines the
/// "affluent" treasury band where speculative bidding activates. The default
/// `1` means a GP that can afford at least the cheapest regiment build is
/// also allowed to spend a small marginal amount on inventory inputs so the
/// world market clears (Refs #2924 F10). A GP whose treasury is below the
/// regiment threshold cannot afford regiments **or** speculation; the
/// affluence gate keeps speculation off for those broke GPs.
/// SPEC/ai/treasury-planner.md § Affluent-GP speculative bidding.
const int kTreasuryAffluenceThresholdMultiplier = 1;

/// Target stockpile quantity per non-riches commodity the affluent
/// speculative-bid pass tries to lift the GP toward when no F1–F5 deficit
/// already covers that commodity. Aligned with [kShortageThreshold] so a
/// successful buy completes one full consumption cycle. Refs #2924 F10.
const int kSpeculativeBidStockpileTarget = kShortageThreshold;

/// Treasury band at which speculative bidding activates. Refs #2924 F10.
int treasuryAffluenceThreshold() =>
    kTreasuryAffluenceThresholdMultiplier *
        cheapestRegimentBuildTreasuryCost();

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
  Map<String, TileMapResult>? tileMapByRegion,
  MapTopology? topology,
}) {
  final bidTypeCap = worldMarketBidTypeCap(game, playerId);
  final tradeCargoCapacity = tileMapByRegion != null &&
          tileMapByRegion.isNotEmpty &&
          topology != null
      ? tradeCargoCapacityForGreatPower(
          game: game,
          playerId: playerId,
          tileMapByRegion: tileMapByRegion,
          topology: topology,
        )
      : () {
          final homeFleetHolds = cargoHoldsForHomeFleet(game, playerId);
          return homeFleetHolds < 0 ? 0 : homeFleetHolds;
        }();

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
  final lockRecoveryUrgent = treasuryForecast < threshold;

  // Refs #2924 F10: affluent GPs spend treasury on inventory ahead of strict
  // deficits so the world market clears. Gated by treasury affluence so broke
  // GPs never speculate; the F3 price gate is bypassed because the GP is
  // choosing to convert treasury into stockpile regardless of unit cost.
  if (treasury >= treasuryAffluenceThreshold()) {
    _addSpeculativeBidNeeds(
      need: need,
      available: available,
      projected: projected,
      carryForwardBids: carryForwardBids,
      state: game.worldMarketState,
    );
  }

  // Refs #2924 F11: when every GP is below the regiment threshold they all
  // emit urgent offers (typically grain) but bids land on other commodities
  // and priority tiers, so the matcher clears zero deals. One rotating GP per
  // turn bids the liquid food commodity at the same priority as urgent offers
  // and withholds that commodity from its offer set (mutual exclusion).
  if (lockRecoveryUrgent) {
    _applyLockRecoveryLiquidityBid(
      playerId: playerId,
      game: game,
      need: need,
      available: available,
      carryForwardBids: carryForwardBids,
    );
    final liquidity = _lockRecoveryLiquidityCommodity(game.worldMarketState);
    if (playerId == lockRecoveryDesignatedBuyerId(game)) {
      // Keep only the liquidity food bid so the single bidTypeCap slot is not
      // consumed by fabric/bronze deficits that cannot match urgent grain offers.
      need.removeWhere((id, _) => id != liquidity);
    } else {
      // Non-designated GPs only sell during lock recovery.
      need.clear();
    }
  }

  if (available.isEmpty && need.isEmpty) {
    return const <TradeOrder>[];
  }

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
    offerPriority: offerPriority,
    alignBidPriorityWithUrgentOffers: lockRecoveryUrgent,
    preferCommodityId: lockRecoveryUrgent
        ? _lockRecoveryLiquidityCommodity(game.worldMarketState)
        : null,
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
  Map<CommodityId, int> marketPrices,
) {
  final marketPrice = marketPrices[commodityId];
  if (marketPrice == null) return true;
  var bestCost = double.infinity;
  for (final recipe in ProductionRecipesCatalog.all) {
    if (recipe.outputCommodityId != commodityId) continue;
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

/// Food commodity with the highest prior-turn offer volume on the world
/// market; used as the lock-recovery bid target when every GP is selling
/// surplus food under urgent offers. Refs #2924 F11.
CommodityId _lockRecoveryLiquidityCommodity(WorldMarketState state) {
  CommodityId? bestId;
  var bestVolume = 0;
  for (final entry in state.lastTurnActivity.entries) {
    final commodityId = entry.key;
    final commodity = CommodityCatalog.byId[commodityId];
    if (commodity == null || commodity.category != CommodityCategory.food) {
      continue;
    }
    final volume = entry.value.totalOfferQuantity;
    if (volume > bestVolume) {
      bestVolume = volume;
      bestId = commodityId;
      continue;
    }
    if (volume == bestVolume &&
        bestId != null &&
        commodityId.compareTo(bestId) < 0) {
      bestId = commodityId;
    }
  }
  if (bestId != null) return bestId;
  final foods = CommodityCatalog.all
      .where((c) => c.category == CommodityCategory.food)
      .map((c) => c.id)
      .toList(growable: false)
    ..sort();
  return foods.isNotEmpty ? foods.first : 'grain';
}

/// Sorted Great Power ids for deterministic per-turn buyer rotation.
List<String> _sortedGreatPowerIds(Game game) {
  final ids = <String>[
    for (final player in game.players) player.id,
  ]..sort();
  return ids;
}

/// One GP per turn acts as the market buyer for the lock-recovery food
/// commodity so other GPs' urgent offers can clear. Refs #2924 F11.
String lockRecoveryDesignatedBuyerId(Game game) {
  final gpIds = _sortedGreatPowerIds(game);
  if (gpIds.isEmpty) return '';
  final turn = game.worldState.turnState.turnNumber;
  return gpIds[turn % gpIds.length];
}

/// Designated buyer bids [commodityId] and does not offer it this turn.
void _applyLockRecoveryLiquidityBid({
  required String playerId,
  required Game game,
  required Map<CommodityId, int> need,
  required Map<CommodityId, int> available,
  required Map<CommodityId, int> carryForwardBids,
}) {
  if (playerId != lockRecoveryDesignatedBuyerId(game)) return;
  final commodityId = _lockRecoveryLiquidityCommodity(game.worldMarketState);
  available.remove(commodityId);
  // Liquidity bid: buy-side demand for other GPs' urgent food offers, not a
  // stockpile deficit. Use a fixed target quantity independent of projected
  // surplus so a designated buyer with large food stockpiles still clears deals.
  final carryQty = carryForwardBids[commodityId] ?? 0;
  final liquidityQty = kSpeculativeBidStockpileTarget - carryQty;
  if (liquidityQty <= 0) return;
  final existing = need[commodityId] ?? 0;
  if (liquidityQty > existing) {
    need[commodityId] = liquidityQty;
  }
}

List<TradeOrder> _prioritizedBids({
  required List<TradeOrder> rawBids,
  required Map<CommodityId, int> need,
  required int bidTypeCap,
  required int tradeCargoCapacity,
  required int offerPriority,
  required bool alignBidPriorityWithUrgentOffers,
  CommodityId? preferCommodityId,
}) {
  if (rawBids.isEmpty || bidTypeCap <= 0 || tradeCargoCapacity <= 0) {
    return const <TradeOrder>[];
  }
  final byCommodity = <CommodityId, TradeOrder>{
    for (final bid in rawBids) bid.commodityId: bid,
  };
  final orderedIds = need.keys.toList(growable: false)
    ..sort((a, b) {
      if (preferCommodityId != null) {
        if (a == preferCommodityId) return -1;
        if (b == preferCommodityId) return 1;
      }
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
        priority: alignBidPriorityWithUrgentOffers
            ? offerPriority
            : _bidPriorityForCommodity(commodityId),
      ),
    );
    remainingCargo -= cappedQty;
    admitted += 1;
  }
  return result;
}
