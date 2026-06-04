// Treasury planner: World Market trade orders for AI GPs. SPEC/ai/treasury-planner.md.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/ai_api.dart'
    show
        cargoHoldsForHomeFleet,
        carryForwardBidNotionalByPlayer,
        effectiveMarketPriceForCommodityId,
        oldWorldProvinceCountOwnedBy,
        pendingTreasuryCostsForTurn,
        tradeCargoCapacityForGreatPower,
        worldMarketBidTypeCap;
import 'package:colonizethis_logic/order_suggestion_api.dart'
    show TradeOrderSuggester, TradeSuggestionContext;
import 'package:colonizethis_models/colonizethis_models.dart';

import 'army_conquest_prep.dart' show regimentCountForPlayer;
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
  Orders currentOrders = const Orders(),
  ResourceRules? resourceRules,
}) {
  final ResourceRules rules = resourceRules ?? ResourceRules.defaultRules;
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

  final rawTreasury = treasury < 0 ? 0 : treasury;
  final threshold = cheapestRegimentBuildTreasuryCost();
  final brokeForLockRecovery = rawTreasury < threshold;

  // Refs #2924 F17: a below-quota zero-NW lock-recovery seller releases its
  // food surplus aggressively so its trade cargo is spent selling the
  // liquidity-food commodity into the net-positive minor/tribe auto-bid pool
  // (F15) instead of being left idle behind a 2x food safety buffer. On seed
  // 42 gp6 keeps only ~42 grain and rarely clears the 2x reserve (24), so it
  // emits offers on ~14 of 100 turns and never accumulates enough seller
  // credit to cross the regiment threshold, while gp5 — which hoards grain —
  // recovers. Dropping the safety buffer (keeping one consumption-cycle
  // reserve) lets the seller offer down to that floor each turn.
  // SPEC/ai/treasury-planner.md § Lock-recovery seller food-surplus release.
  final isLockRecoverySeller =
      _isBelowQuotaZeroNwLockRecoverySeller(game: game, playerId: playerId);

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
        ? (isLockRecoverySeller ? 0 : consumption * 2)
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

  // Refs #3122: treasury budget that bounds total bid notional this turn.
  // Mirrors the matcher-side per-buyer clamp introduced by #3115 so the
  // planner never emits a bid the matcher would have to truncate to zero.
  final pendingCosts = pendingTreasuryCostsForTurn(
    game,
    playerId,
    currentOrders,
  );
  final carryForwardBidNotional = carryForwardBidNotionalByPlayer(
    game: game,
    playerId: playerId,
    resourceRules: rules,
  );
  final treasuryBudgetForBidsRaw =
      rawTreasury - pendingCosts - carryForwardBidNotional;
  final treasuryBudgetForBids =
      treasuryBudgetForBidsRaw < 0 ? 0 : treasuryBudgetForBidsRaw;

  final treasuryForecast = treasury +
      _expectedOfferInflow(
        available: available,
        marketPrices: marketPrices,
        state: game.worldMarketState,
      );
  // Refs #2924 F13/F16: lock-recovery tier alignment keys off actual treasury,
  // not the F8 offer-inflow forecast. An optimistic forecast must not downgrade
  // offers to the moderate tier while the GP still holds less than a regiment
  // build (seed-42 gp5 stalls at treasury 1999 when forecast >= 2000).
  final lockRecoveryUrgent = brokeForLockRecovery;
  final offerPriority = lockRecoveryUrgent || treasuryForecast < threshold
      ? kTreasuryOfferPriorityUrgent
      : kTreasuryOfferPriorityModerate;

  final isLiquidityBuyer = isLockRecoveryLiquidityBuyer(
    game: game,
    playerId: playerId,
    treasuryBudgetForBids: treasuryBudgetForBids,
    treasuryForecast: treasuryForecast,
  );
  final isAffluentDesignatedBuyer = _isAffluentDesignatedLockRecoveryBuyer(
    game: game,
    playerId: playerId,
  );

  // Refs #2924 F10: affluent GPs spend treasury on inventory ahead of strict
  // deficits so the world market clears. Gated by treasury affluence so broke
  // GPs never speculate; the F3 price gate is bypassed because the GP is
  // choosing to convert treasury into stockpile regardless of unit cost.
  // Suppressed for lock-recovery liquidity buyers (their single bid slot
  // is committed to the urgent grain liquidity bid below — F12).
  if (treasury >= treasuryAffluenceThreshold() &&
      !isLiquidityBuyer &&
      !isAffluentDesignatedBuyer &&
      !isLockRecoverySeller) {
    _addSpeculativeBidNeeds(
      need: need,
      available: available,
      projected: projected,
      carryForwardBids: carryForwardBids,
      state: game.worldMarketState,
    );
  }

  // Refs #2924 F11/F12/F15: when broke GPs emit urgent offers (typically grain)
  // but bids land on other commodities or priority tiers, the matcher clears
  // zero deals. One rotating affluent GP per turn (F12) — or every GP that can
  // fund at least one liquidity-food unit when no GP is affluent (F15) — bids
  // the liquid food commodity at the same priority as urgent offers, capped by
  // treasury budget, and withholds that commodity from its offer set (mutual
  // exclusion). Other broke GPs sell only (F13).
  if (isLiquidityBuyer || isAffluentDesignatedBuyer) {
    _applyLockRecoveryLiquidityBid(
      playerId: playerId,
      game: game,
      need: need,
      available: available,
      carryForwardBids: carryForwardBids,
      treasuryBudgetForBids: treasuryBudgetForBids,
      treasuryForecast: treasuryForecast,
      addSyntheticBid: isLiquidityBuyer,
    );
    if (isLiquidityBuyer) {
      final liquidity = _lockRecoveryLiquidityCommodity(game.worldMarketState);
      // Keep only the liquidity food bid so the single bidTypeCap slot is not
      // consumed by fabric/bronze deficits that cannot match urgent grain offers.
      need.removeWhere((id, _) => id != liquidity);
    }
  } else if (lockRecoveryUrgent || isLockRecoverySeller) {
    need.clear();
  }

  // Refs #2847 § H8: a below-quota zero-NW lock-recovery seller accumulates
  // treasury by selling food, but its bid `need` is cleared every turn (it is
  // a sell-only Path-F seller), so it can never buy the cheapest regiment's
  // build-input commodity. `peasant_levies` (the universal cheapest regiment,
  // cost `cheapestRegimentBuildTreasuryCost()`) requires its `buildInputs`
  // commodities in the stockpile; with zero of them on hand
  // `suggestBuildOrders` returns no regiment candidate even when treasury is
  // affordable and a peasant is free, so the seller that has *already*
  // recovered treasury to/above the regiment threshold stays trapped at zero
  // regiments (seed-42 gp5/gp6 hold treasury >= threshold yet 0 fabric for
  // tens of turns). Inject a single build-input bid so the recovered treasury
  // converts into the army the lock-recovery sell-down existed to fund. The
  // carve-out fires only while the GP holds zero regiments and is missing a
  // build input, and clears automatically once it owns a regiment or the
  // input lands. SPEC/ai/treasury-planner.md
  // § Lock-recovery seller regiment build-input bootstrap.
  if (isLockRecoverySeller &&
      rawTreasury >= threshold &&
      regimentCountForPlayer(game, playerId) == 0) {
    for (final input in RegimentEconomyCatalog.peasantLevies.buildInputs.entries) {
      final held = projected.quantityOf(input.key) + (carryForwardBids[input.key] ?? 0);
      if (held < input.value) {
        need[input.key] = input.value - held;
      }
    }
  }

  if (available.isEmpty && need.isEmpty) {
    return const <TradeOrder>[];
  }

  // Refs #3122 + #3127: pass the treasury-budget-aware bid cap (computed above
  // — `rawTreasury - pendingCosts - carryForwardBidNotional`, floored at 0)
  // into the suggester so it never emits bids the validator rule 5 would
  // reject. Subsumes #3127's bare `max(0, treasury)` formulation.
  final suggestion = TradeOrderSuggester.suggest(
    TradeSuggestionContext(
      playerId: playerId,
      bidTypeCap: bidTypeCap,
      tradeCargoCapacity: tradeCargoCapacity,
      availableStockpileByCommodityId: available,
      commodityNeedByCommodityId: need,
      treasuryBudgetForBids: treasuryBudgetForBids,
      worldMarketState: game.worldMarketState,
      offerPriority: offerPriority,
      bidPriority: kTreasuryBidPriorityRawMaterial,
    ),
  );

  final offers = suggestion.offers;
  // Refs #2924 F11/F12: when the designated buyer is affluent its own forecast
  // is above the regiment threshold (offerPriority == moderate); the lock-
  // recovery bid still needs to clear at the urgent integer priority tier so
  // it matches broke GPs' urgent grain offers. forceBidPriority overrides the
  // tier-alignment computation so the synthetic grain bid always goes out at
  // kTreasuryOfferPriorityUrgent regardless of the buyer's own offerPriority.
  final bids = _prioritizedBids(
    rawBids: suggestion.bids,
    need: need,
    bidTypeCap: bidTypeCap,
    tradeCargoCapacity: tradeCargoCapacity,
    offerPriority: offerPriority,
    alignBidPriorityWithUrgentOffers: isLiquidityBuyer || lockRecoveryUrgent,
    forceBidPriority:
        isLiquidityBuyer ? kTreasuryOfferPriorityUrgent : null,
    preferCommodityId: isLiquidityBuyer
        ? _lockRecoveryLiquidityCommodity(game.worldMarketState)
        : null,
    treasuryBudgetForBids: treasuryBudgetForBids,
    worldMarketState: game.worldMarketState,
    resourceRules: rules,
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

int _treasuryForPlayer(Game game, String playerId) {
  for (final player in game.players) {
    if (player.id == playerId) return player.treasury;
  }
  return 0;
}

int _newWorldProvinceCountOwnedBy(Game game, String playerId) {
  var count = 0;
  for (final province in game.worldState.newWorld.provinces) {
    if (province.ownerId == playerId) count++;
  }
  return count;
}

/// Below-quota GPs with zero NW provinces and at least one OW province
/// are Path F lock-recovery **sellers** — they must accumulate seller
/// credits toward the regiment threshold, not rotate as the affluent
/// designated buyer or speculate (Refs #2924 Path F gp6 regression).
bool _isBelowQuotaZeroNwLockRecoverySeller({
  required Game game,
  required String playerId,
}) {
  final ow = oldWorldProvinceCountOwnedBy(game, playerId);
  if (ow <= 0) return false;
  if (!isBelowObserverConquestQuota(ow)) return false;
  if (_newWorldProvinceCountOwnedBy(game, playerId) != 0) return false;
  // Mid-below-quota EXPAND band (seed-42 gp3–gp6); excludes minimal
  // single-province test fixtures that are not Path F lock-recovery sellers.
  return ow >= 2;
}

/// Sorted Great Power ids for deterministic per-turn buyer rotation.
List<String> _sortedGreatPowerIds(Game game) {
  final ids = <String>[
    for (final player in game.players) player.id,
  ]..sort();
  return ids;
}

/// True iff at least one Great Power has `player.treasury <
/// cheapestRegimentBuildTreasuryCost()`. The lock-recovery liquidity bid is
/// only useful when at least one broke GP needs buy-side demand for its
/// urgent offers. Refs #2924 F12.
bool _anyBrokeGreatPower(Game game) {
  final threshold = cheapestRegimentBuildTreasuryCost();
  for (final player in game.players) {
    if (player.treasury < threshold) return true;
  }
  return false;
}

bool _isAffluentDesignatedLockRecoveryBuyer({
  required Game game,
  required String playerId,
}) {
  if (!_anyBrokeGreatPower(game)) return false;
  final gpIds = _sortedGreatPowerIds(game);
  final affluent = <String>[
    for (final id in gpIds)
      if (_treasuryForPlayer(game, id) >= treasuryAffluenceThreshold() &&
          !_isBelowQuotaZeroNwLockRecoverySeller(game: game, playerId: id))
        id,
  ];
  if (affluent.isEmpty) return false;
  final designated = lockRecoveryDesignatedBuyerId(game);
  return designated.isNotEmpty && playerId == designated;
}

/// Whether [playerId] should emit the urgent lock-recovery liquidity-food bid
/// this turn. Refs #2924 F11/F12/F13/F15.
bool isLockRecoveryLiquidityBuyer({
  required Game game,
  required String playerId,
  required int treasuryBudgetForBids,
  required int treasuryForecast,
}) {
  if (!_anyBrokeGreatPower(game)) return false;
  final liquidity = _lockRecoveryLiquidityCommodity(game.worldMarketState);
  final pricePerUnit = game.worldMarketState.prices[liquidity] ?? 0;
  if (pricePerUnit <= 0 || treasuryBudgetForBids < pricePerUnit) {
    return false;
  }
  final threshold = cheapestRegimentBuildTreasuryCost();
  final rawTreasury = _treasuryForPlayer(game, playerId);
  // F13: optimistic offer-inflow forecast keeps a broke GP on offers-only.
  if (rawTreasury < threshold && treasuryForecast >= threshold) {
    return false;
  }
  final gpIds = _sortedGreatPowerIds(game);
  final affluent = <String>[
    for (final id in gpIds)
      if (_treasuryForPlayer(game, id) >= treasuryAffluenceThreshold() &&
          !_isBelowQuotaZeroNwLockRecoverySeller(game: game, playerId: id))
        id,
  ];
  if (affluent.isNotEmpty) {
    final designated = lockRecoveryDesignatedBuyerId(game);
    return designated.isNotEmpty && playerId == designated;
  }
  // F15: when no GP is affluent, logic-phase minor auto-bids (`world_market_phase`
  // / `computeLockRecoveryMinorAutoBids`) fund liquidity-food purchases. GP buyers
  // would spend scarce treasury on grain instead of accumulating seller credits.
  return false;
}

/// Preferred liquidity buyers when no GP is affluent (6-GP observer order).
/// gp1/gp2 exit EXPAND earlier on seed 42 than gp3–gp6; keeping buys on these
/// factions prevents stuck EXPAND sellers from spending their own treasury.
const List<String> kLockRecoveryPreferredBuyerIds = ['gp1', 'gp2'];

/// Buyer when no GP meets [treasuryAffluenceThreshold]: rotate among
/// [kLockRecoveryPreferredBuyerIds] present in the game, else the two
/// richest-by-treasury GPs.
String lockRecoveryFallbackBuyerId(Game game) {
  final gpIds = _sortedGreatPowerIds(game);
  if (gpIds.isEmpty) return '';
  final preferred = <String>[
    for (final id in kLockRecoveryPreferredBuyerIds)
      if (gpIds.contains(id)) id,
  ];
  final buyerPool = preferred.length >= 2
      ? preferred
      : _twoRichestGreatPowerIdsByTreasury(game);
  if (buyerPool.isEmpty) return '';
  if (buyerPool.length == 1) return buyerPool.first;
  final turn = game.worldState.turnState.turnNumber;
  return buyerPool[turn % buyerPool.length];
}

List<String> _twoRichestGreatPowerIdsByTreasury(Game game) {
  final gpIds = _sortedGreatPowerIds(game);
  if (gpIds.isEmpty) return const [];
  final ranked = [...gpIds]
    ..sort((a, b) {
      final tA = _treasuryForPlayer(game, a);
      final tB = _treasuryForPlayer(game, b);
      if (tA != tB) return tB.compareTo(tA);
      return a.compareTo(b);
    });
  return ranked.take(2).toList();
}

/// One GP per turn acts as the market buyer for the lock-recovery food
/// commodity so other GPs' urgent offers can clear. Refs #2924 F11.
///
/// Rotates only among GPs at or above [treasuryAffluenceThreshold] so a
/// broke designated buyer does not waste the single `bidTypeCap` slot on
/// grain bids its treasury cannot fund while other GPs' urgent offers
/// starve (seed-42 gp4/gp6 `totalDealsAsSeller == 0` diagnostic). When no
/// GP meets the affluence band, [isLockRecoveryLiquidityBuyer] admits every
/// GP whose per-turn bid budget can fund at least one liquidity-food unit
/// (F15) instead of using this rotation.
///
/// Returns the empty string when no Great Power is broke — every GP is
/// already at or above the regiment threshold and the F1–F5 / F10 paths
/// handle the steady state without a synthetic grain bid. Refs #2924 F12.
String lockRecoveryDesignatedBuyerId(Game game) {
  if (!_anyBrokeGreatPower(game)) return '';
  final gpIds = _sortedGreatPowerIds(game);
  if (gpIds.isEmpty) return '';
  final threshold = treasuryAffluenceThreshold();
  final affluent = <String>[
    for (final id in gpIds)
      if (_treasuryForPlayer(game, id) >= threshold &&
          !_isBelowQuotaZeroNwLockRecoverySeller(game: game, playerId: id))
        id,
  ];
  if (affluent.isEmpty) return '';
  final turn = game.worldState.turnState.turnNumber;
  return affluent[turn % affluent.length];
}

/// Designated buyer bids [commodityId] and does not offer it this turn.
///
/// Bid quantity is the smaller of the F11 stockpile-target ceiling and
/// `max(0, treasuryBudgetForBids / pricePerUnit)` so the buyer never commits
/// more treasury than it currently holds (Refs #2924 F12 — treasury-capped)
/// **and** never overcommits against pending costs or carry-forward bid
/// notional already accounted for in [treasuryBudgetForBids] (Refs #3122).
void _applyLockRecoveryLiquidityBid({
  required String playerId,
  required Game game,
  required Map<CommodityId, int> need,
  required Map<CommodityId, int> available,
  required Map<CommodityId, int> carryForwardBids,
  required int treasuryBudgetForBids,
  required int treasuryForecast,
  required bool addSyntheticBid,
}) {
  final commodityId = _lockRecoveryLiquidityCommodity(game.worldMarketState);
  available.remove(commodityId);
  if (!addSyntheticBid) return;
  final pricePerUnit = game.worldMarketState.prices[commodityId] ?? 0;
  if (pricePerUnit <= 0) return;
  final budget =
      treasuryBudgetForBids < 0 ? 0 : treasuryBudgetForBids;
  final affordableQty = budget ~/ pricePerUnit;
  // Refs #2924 F14: lock-recovery liquidity bids use the full per-turn
  // treasury budget (after pending costs and carry-forward notional), not
  // the F10 stockpile-target ceiling of 8 units. On seed 42 the designated
  // buyer's treasury is far below the affluent band; capping at 8 kept per-
  // deal seller credits too small to approach the regiment threshold.
  final liquidityQty = affordableQty;
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
  required int treasuryBudgetForBids,
  required WorldMarketState worldMarketState,
  required ResourceRules resourceRules,
  int? forceBidPriority,
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
    // Refs #3122: clamp every bid to the running treasury budget so the
    // matcher (#3115) does not have to truncate to zero/near-zero fills.
    // When the commodity has no effective price (manufactured commodity
    // before in-game price discovery seeds a price), fall back to the
    // cargo-clamped quantity; the matcher applies its own per-tier
    // accounting if such a bid ever clears.
    final pricePerUnit = effectiveMarketPriceForCommodityId(
      commodityId: commodityId,
      worldMarket: worldMarketState,
      resourceRules: resourceRules,
    );
    int cappedQty;
    if (pricePerUnit == null) {
      cappedQty = cargoClampedQty;
    } else if (pricePerUnit <= 0) {
      cappedQty = cargoClampedQty;
    } else {
      final maxAffordable = remainingTreasuryBudget ~/ pricePerUnit;
      cappedQty = cargoClampedQty < maxAffordable
          ? cargoClampedQty
          : maxAffordable;
    }
    if (cappedQty <= 0) continue;
    result.add(
      bid.copyWith(
        quantity: cappedQty,
        priority: forceBidPriority ??
            (alignBidPriorityWithUrgentOffers
                ? offerPriority
                : _bidPriorityForCommodity(commodityId)),
      ),
    );
    remainingCargo -= cappedQty;
    if (pricePerUnit != null && pricePerUnit > 0) {
      remainingTreasuryBudget -= cappedQty * pricePerUnit;
    }
    admitted += 1;
  }
  return result;
}
