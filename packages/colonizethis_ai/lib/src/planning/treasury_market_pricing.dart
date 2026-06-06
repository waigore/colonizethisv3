part of 'treasury_planner.dart';

// Market-pricing, per-commodity bid-priority, and supplier offer-tier helpers
// for the treasury planner (Refs #2994 F3/F4 + #2847 H8-supply), extracted from
// `treasury_planner.dart` for maintainability (Refs #3288 file-split).
// Behaviour-preserving move: same library scope (this is a `part of` the
// treasury-planner library), so imports, shared helpers, and visibility are
// unchanged.

bool _marketPriceBelowProductionCost(
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

/// True when some faction other than [excludePlayerId] holds a standing
/// (carry-forward) offer for [commodityId] in the world market — i.e. real
/// supply the buyer can bid against. Refs #2847 H8-supply castIron source:
/// once an affluent supplier's over-produced `castIron` surplus stands in the
/// market, a locked seller bids `castIron` **directly** instead of routing to
/// domestic production from feedstock it cannot extract. Pure read of
/// [WorldMarketState.carryForwardOffersByFactionId]; deterministic.
bool _marketHasStandingOfferSupplyFromOthers({
  required WorldMarketState state,
  required CommodityId commodityId,
  required String excludePlayerId,
}) {
  for (final entry in state.carryForwardOffersByFactionId.entries) {
    if (entry.key == excludePlayerId) continue;
    for (final order in entry.value) {
      if (order.commodityId == commodityId && order.quantity > 0) {
        return true;
      }
    }
  }
  return false;
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

/// Commodity ids affluent GPs release when any lock-recovery seller needs the
/// H8 bootstrap path (Refs #2847 H8-supply market).
const Set<CommodityId> _regimentBuildInputSupplyCommodityIds = {
  'wool',
  'cotton',
  'fabric',
  // Refs #2847 H8-extraction: the level-0 build_improvement inputs the locked
  // seller bids for to unblock domestic feedstock extraction.
  'lumber',
  'castIron',
};

/// Re-tags a lock-recovery supplier's build-input supply offers so each lands
/// in the **same** integer priority tier the locked buyer bids that commodity
/// at (`_bidPriorityForCommodity`), enabling the per-commodity offer/bid cross
/// the DealMatcher otherwise blocks across mismatched tiers
/// (SPEC/program/world-market-resolution.md § Step C; Refs #2847 H8-supply
/// market order matching). Only offers whose commodity is in
/// [_regimentBuildInputSupplyCommodityIds] are retuned; all other offers (for
/// example the urgent liquidity-food offer) keep their computed priority. The
/// original list is returned unchanged when no tier actually moves so equal
/// inputs keep their identity (determinism).
List<TradeOrder> _alignBuildInputSupplyOfferTiers(List<TradeOrder> offers) {
  if (offers.isEmpty) return offers;
  var changed = false;
  final result = <TradeOrder>[];
  for (final offer in offers) {
    if (!_regimentBuildInputSupplyCommodityIds.contains(offer.commodityId)) {
      result.add(offer);
      continue;
    }
    final alignedPriority = _bidPriorityForCommodity(offer.commodityId);
    if (alignedPriority == offer.priority) {
      result.add(offer);
      continue;
    }
    result.add(offer.copyWith(priority: alignedPriority));
    changed = true;
  }
  return changed ? result : offers;
}
