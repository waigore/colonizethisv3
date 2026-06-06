part of 'treasury_planner.dart';

// Lock-recovery seller regiment build-input bootstrap: feedstock reservation,
// improvement-input bids, and domestic-production feedstock staging for the
// treasury planner (Refs #2847 § H8 / H8-extraction), extracted from
// `treasury_planner.dart` for maintainability (Refs #3288 file-split).
// Behaviour-preserving move: same library scope (this is a `part of` the
// treasury-planner library), so imports, shared helpers, and visibility are
// unchanged.

/// Feedstock commodity ids consumed by production recipes whose output is a
/// currently-missing cheapest-regiment (`peasant_levies`) build input.
///
/// Refs #2847 § H8-supply. The cheapest regiment needs `fabric`, which is
/// produced from `wool` (`fabricFromWool`) or `cotton` (`fabricFromCotton`).
/// When the projected stockpile is short of a build input, this returns the
/// input commodities of every recipe that outputs that build input so a
/// lock-recovery seller can retain the feedstock instead of selling it as
/// surplus. Pure function of the projected [Stockpile] and the static
/// `RegimentEconomyCatalog` / `ProductionRecipesCatalog`; returns the empty
/// set once every build input is on hand (the reservation self-clears).
Set<CommodityId> _regimentBuildInputFeedstockIds(Stockpile projected) {
  final missingInputs = <CommodityId>{
    for (final entry
        in RegimentEconomyCatalog.peasantLevies.buildInputs.entries)
      if (projected.quantityOf(entry.key) < entry.value) entry.key,
  };
  if (missingInputs.isEmpty) return const <CommodityId>{};
  final feedstock = <CommodityId>{};
  for (final buildInputId in missingInputs) {
    for (final recipe in ProductionRecipesCatalog.producing(buildInputId)) {
      feedstock.addAll(recipe.inputQuantities.keys);
    }
  }
  return feedstock;
}

/// Build-input feedstock ids ordered so Old World lock-recovery sellers extract
/// wool before cotton (seed-42), then alphabetically for determinism.
List<CommodityId> _sortedRegimentBuildInputFeedstockIds(Stockpile projected) {
  return _regimentBuildInputFeedstockIds(projected).toList()
    ..sort((a, b) {
      if (a == CommodityCatalog.wool.id) return -1;
      if (b == CommodityCatalog.wool.id) return 1;
      return a.compareTo(b);
    });
}

/// Adds the feedstock bid for the first viable [feedstockCandidates] entry so a
/// lock-recovery seller can domestically produce a missing regiment build input.
/// Returns true when a feedstock bid was queued (still accumulating feedstock).
bool _addRegimentBuildInputFeedstockBootstrapNeed({
  required List<CommodityId> feedstockCandidates,
  required Stockpile projected,
  required Map<CommodityId, int> carryForwardBids,
  required Map<CommodityId, int> need,
}) {
  for (final feedstockId in feedstockCandidates) {
    final qtyNeeded =
        _feedstockQuantityForOneMissingBuildInputRun(feedstockId, projected);
    if (qtyNeeded <= 0) continue;
    final held =
        projected.quantityOf(feedstockId) + (carryForwardBids[feedstockId] ?? 0);
    if (held >= qtyNeeded) return false;
    need[feedstockId] = qtyNeeded - held;
    return true;
  }
  return false;
}

/// Adds bids for the level-0 `build_improvement` inputs (lumber + cast iron) a
/// lock-recovery seller must hold to extract its owned fabric feedstock tile,
/// but does not, when the regiment build-input feedstock-extraction gate is
/// active and a feedstock tile is owned (Refs #2847 § H8-extraction).
///
/// Returns true when at least one improvement-input bid was queued (a deficit
/// remains). The caller suppresses the downstream feedstock / fabric bootstrap
/// bids on that turn so the single `bidTypeCap` slot targets the prerequisite
/// supply. Self-clearing: the
/// [regimentBuildInputFeedstockImprovementInputCost] contract returns the empty
/// map once the GP owns a regiment, holds the build input, or has improved the
/// feedstock tile.
bool _addRegimentFeedstockImprovementInputNeed({
  required Game game,
  required String playerId,
  required Stockpile projected,
  required Map<CommodityId, int> carryForwardBids,
  required Map<CommodityId, int> need,
}) {
  final cost = regimentBuildInputFeedstockImprovementInputCost(game, playerId);
  if (cost.isEmpty) return false;
  // Deterministic iteration over the cost map (insertion order is fixed by the
  // contract, but sorting guards against future reordering).
  final inputIds = cost.keys.toList()..sort();

  // Pass 1 — directly-buyable improvement-inputs (e.g. `lumber`, which suppliers
  // release as surplus). These are acquired first so the single `bidTypeCap`
  // slot targets an essential input the world market can actually supply (the
  // suggester admits bids in alphabetical, cap-bounded order, so a raw-material
  // feedstock bid would otherwise crowd out the essential `lumber` bid).
  var queued = false;
  for (final inputId in inputIds) {
    // Refs #2847 H8-supply castIron source: a domestic-production improvement
    // input (e.g. `castIron`) is normally produced from feedstock (Pass 2)
    // because the world market structurally lacks supply. Once an affluent
    // supplier over-produces and offers it (a standing carry-forward offer
    // exists), bid it **directly** here so the deal can cross — breaking the
    // extraction deadlock without waiting on feedstock the seller cannot mine.
    if (kDomesticProductionImprovementInputIds.contains(inputId) &&
        !_marketHasStandingOfferSupplyFromOthers(
          state: game.worldMarketState,
          commodityId: inputId,
          excludePlayerId: playerId,
        )) {
      continue;
    }
    final held =
        projected.quantityOf(inputId) + (carryForwardBids[inputId] ?? 0);
    final missing = cost[inputId]! - held;
    if (missing > 0) {
      need[inputId] = missing;
      queued = true;
    }
  }
  if (queued) return true;

  // Pass 2 — domestically-produced improvement-inputs (Refs #2847 H8-extraction
  // castIron residual). `castIron` has no world-market supply on seed 42 (it is
  // consumed by Old World military builds, so no Great Power offers a surplus),
  // so the seller bids `castIron`'s production feedstock (`timber` + `iron`) and
  // the economy planner produces it (SPEC/ai/treasury-planner.md § Lock-recovery
  // seller improvement-input domestic production). A still-missing
  // domestic-production input keeps the fabric/feedstock bootstrap suppressed
  // even when its feedstock is already on hand (production is pending).
  for (final inputId in inputIds) {
    if (!kDomesticProductionImprovementInputIds.contains(inputId)) continue;
    final held =
        projected.quantityOf(inputId) + (carryForwardBids[inputId] ?? 0);
    if (cost[inputId]! - held <= 0) continue;
    _addImprovementInputProductionFeedstockNeed(
      improvementInputId: inputId,
      projected: projected,
      carryForwardBids: carryForwardBids,
      need: need,
    );
    queued = true;
  }
  return queued;
}

/// Bids the production feedstock for one run of [improvementInputId] when a
/// lock-recovery seller is short of the feedstock to produce it domestically.
/// Adds nothing when the feedstock for one full run is already on hand (the
/// economy planner will run the recipe next; the caller still suppresses the
/// direct improvement-input bid because the world market structurally lacks
/// supply for it). Deterministic: selects the lowest-`id` recipe producing the
/// input. Refs #2847 § H8-extraction castIron residual.
void _addImprovementInputProductionFeedstockNeed({
  required CommodityId improvementInputId,
  required Stockpile projected,
  required Map<CommodityId, int> carryForwardBids,
  required Map<CommodityId, int> need,
}) {
  final recipe = _lowestIdRecipeProducing(improvementInputId);
  if (recipe == null) return;
  for (final entry in recipe.inputQuantities.entries) {
    final held =
        projected.quantityOf(entry.key) + (carryForwardBids[entry.key] ?? 0);
    final missing = entry.value - held;
    if (missing > 0) {
      need[entry.key] = (need[entry.key] ?? 0) + missing;
    }
  }
}

/// The production recipe with the lowest `id` whose output is [commodityId], or
/// `null` when no recipe produces it. Deterministic over the static
/// `ProductionRecipesCatalog`.
ProductionRecipe? _lowestIdRecipeProducing(CommodityId commodityId) {
  ProductionRecipe? best;
  for (final recipe in ProductionRecipesCatalog.producing(commodityId)) {
    if (best == null || recipe.id.compareTo(best.id) < 0) {
      best = recipe;
    }
  }
  return best;
}

/// Adds direct bids for any missing `peasant_levies` build input when no
/// feedstock bootstrap bid is pending.
void _addRegimentBuildInputDirectNeed({
  required Stockpile projected,
  required Map<CommodityId, int> carryForwardBids,
  required Map<CommodityId, int> need,
}) {
  for (final input in RegimentEconomyCatalog.peasantLevies.buildInputs.entries) {
    final held =
        projected.quantityOf(input.key) + (carryForwardBids[input.key] ?? 0);
    if (held < input.value) {
      need[input.key] = input.value - held;
    }
  }
}

/// Per-run feedstock input quantity required to produce one unit of a missing
/// `peasant_levies` build input via a production recipe consuming [feedstockId].
int _feedstockQuantityForOneMissingBuildInputRun(
  CommodityId feedstockId,
  Stockpile projected,
) {
  var needed = 0;
  for (final entry in RegimentEconomyCatalog.peasantLevies.buildInputs.entries) {
    if (projected.quantityOf(entry.key) >= entry.value) continue;
    for (final recipe in ProductionRecipesCatalog.producing(entry.key)) {
      final perRun = recipe.inputQuantities[feedstockId];
      if (perRun != null && perRun > needed) {
        needed = perRun;
      }
    }
  }
  return needed;
}

/// Level-0 `build_improvement` improvement-input commodities a lock-recovery
/// seller must produce domestically because the world market structurally lacks
/// supply for them on seed 42. `castIron` is consumed by Old World military
/// builds, so no Great Power offers a surplus for the seller's bid to cross
/// (SPEC/ai/treasury-planner.md § Lock-recovery seller improvement-input
/// domestic production; Refs #2847 § H8-extraction castIron residual). For these
/// inputs the seller bids the production feedstock (e.g. `timber` + `iron` for
/// `castIron`) and the economy planner produces the input
/// (economy-planner.md § Regiment build-input production priority).
const Set<CommodityId> kDomesticProductionImprovementInputIds = {'castIron'};
