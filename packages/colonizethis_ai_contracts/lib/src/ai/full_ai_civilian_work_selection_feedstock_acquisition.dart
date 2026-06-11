part of 'full_ai_civilian_work_selection.dart';

// Seller feedstock-tile acquisition target selection plus the
// lock-recovery producible improvement-input staging and Old World
// feedstock-reservation predicates for the below-quota zero-NW
// lock-recovery seller / supplier roles (Refs #2847 H8-extraction). The
// feedstock-extraction resource-id gates these build on now live in the
// `orders` domain (`orders/feedstock_extraction_targets.dart`) so the one-way
// orders↔ai dependency direction holds (Refs #3290). Split out of
// full_ai_civilian_work_selection_feedstock.dart by concern to keep each
// library file at or below the repo source-file line limit; shares the parent
// library's private scope via `part`.

/// The deterministic ascending-sorted list of **Old World** province ids the
/// flagged seller [playerId] could acquire (by conquest or purchasable land) to
/// gain an improvement-input feedstock tile it does not currently own (Refs
/// #2847 § H8-extraction seller feedstock-tile acquisition target selection).
///
/// Selection contract that builds directly on the acquisition-residual detector
/// [sellerNeedsImprovementInputFeedstockTileAcquisition]: where the detector
/// answers *whether* a seller must acquire a feedstock tile, this answers
/// *which Old World provinces host the feedstock demand it could acquire*.
/// Returns the empty list unless the acquisition residual is active for
/// [playerId] (so it is empty for every healthy / above-quota / regiment-holding
/// / NW-owning GP, and the +6 Old World conquest baseline GPs are never
/// flagged). When active, it returns every Old World province **not** owned by
/// [playerId] that hosts at least one tile whose resource is in the seller's
/// improvement-input feedstock demand set
/// (`sellerImprovementInputFeedstockResourceIds`), sorted ascending by province
/// id for a deterministic candidate ordering.
///
/// **Topology-free by construction.** Province adjacency, reachability, and
/// war-cost ranking are the province of the later acquisition-wiring slice,
/// which intersects this candidate list with the conquest / purchasable-land
/// target sets it derives from the combined topology. New World provinces are
/// excluded: the failing sellers hold zero New World land and the turn-100 gate
/// is Old World conquest, so a New World feedstock tile cannot close it.
///
/// Province ownership and region are derived from the tile key
/// (`Unit.provinceIdFromTileKey` / `Unit.regionIdFromTileKey`) and
/// `tryGetProvince`, so the scan works from `WorldState.resourceByTileKey`
/// alone. Pure and deterministic over `(game, playerId)` and the static
/// `ProductionRecipesCatalog`; changes no behaviour on its own, performs no I/O
/// and no logging, and adds no `ai_victory_config.dart` constant.
List<String> sellerFeedstockTileAcquisitionTargetProvinceIdsSorted(
  Game game,
  String playerId,
) {
  if (!sellerNeedsImprovementInputFeedstockTileAcquisition(game, playerId)) {
    return const <String>[];
  }
  final feedstock = sellerImprovementInputFeedstockResourceIds(game, playerId);
  final ws = game.worldState;
  final provinceIds = <String>{};
  for (final entry in ws.resourceByTileKey.entries) {
    if (!feedstock.contains(entry.value)) continue;
    if (Unit.regionIdFromTileKey(entry.key) == kNewWorldRegionId) continue;
    final provinceId = Unit.provinceIdFromTileKey(entry.key);
    if (provinceId == null) continue;
    final province = ws.tryGetProvince(provinceId);
    if (province == null || province.ownerId == playerId) continue;
    provinceIds.add(provinceId);
  }
  final sorted = provinceIds.toList()..sort();
  return List<String>.unmodifiable(sorted);
}

/// The deterministic ascending-sorted subset of the flagged seller's
/// feedstock-tile acquisition candidate provinces
/// ([sellerFeedstockTileAcquisitionTargetProvinceIdsSorted]) that are also
/// **acquirable** this turn per the caller-supplied [acquirableProvinceIds]
/// (Refs #2847 § H8-extraction seller feedstock-tile acquisition target
/// intersection).
///
/// [acquirableProvinceIds] is the caller's topology-derived target set — the
/// union of the conquest (declare-war / army-reachable) and purchasable-land
/// target province ids the AI planner computes from the combined topology — so
/// this function stays **topology-free** by construction: it derives no
/// adjacency or reachability itself, it only intersects the already-deterministic
/// feedstock candidate list with the planner's reported acquirable set.
///
/// Returns the empty list when the acquisition residual is inactive for
/// [playerId], when [acquirableProvinceIds] is empty, or when no feedstock
/// candidate is acquirable this turn. Preserves the ascending province-id order
/// of the candidate list. Pure and deterministic over
/// `(game, playerId, acquirableProvinceIds)` and the static
/// `ProductionRecipesCatalog`; changes no behaviour on its own, performs no I/O
/// and no logging, and adds no `ai_victory_config.dart` constant.
List<String> sellerFeedstockTileAcquisitionTargetsAmongAcquirable(
  Game game,
  String playerId,
  Set<String> acquirableProvinceIds,
) {
  if (acquirableProvinceIds.isEmpty) return const <String>[];
  final candidates = sellerFeedstockTileAcquisitionTargetProvinceIdsSorted(
    game,
    playerId,
  );
  if (candidates.isEmpty) return const <String>[];
  final intersection = <String>[
    for (final id in candidates)
      if (acquirableProvinceIds.contains(id)) id,
  ];
  return List<String>.unmodifiable(intersection);
}

/// The single deterministic **primary** Old World feedstock-tile acquisition
/// target province id for the flagged seller [playerId] this turn, or `null`
/// when there is none (Refs #2847 § H8-extraction seller feedstock-tile
/// acquisition target pick).
///
/// Final pick contract that builds on the intersection
/// ([sellerFeedstockTileAcquisitionTargetsAmongAcquirable]): it collapses that
/// list to the **one** province the acquisition-wiring slice should pursue, so
/// the slice emits exactly one deterministic acquisition order per turn rather
/// than re-deriving the choice itself. The pick is the lowest province id in the
/// acquirable subset — the subset is already ascending-sorted, so the first
/// element is the deterministic primary target independent of
/// [acquirableProvinceIds] iteration order.
///
/// Returns `null` when the acquisition residual is inactive for [playerId], when
/// [acquirableProvinceIds] is empty, or when no feedstock candidate is
/// acquirable this turn. **Topology-free** by construction. Pure and
/// deterministic over `(game, playerId, acquirableProvinceIds)` and the static
/// `ProductionRecipesCatalog`; changes no behaviour on its own, performs no I/O
/// and no logging, and adds no `ai_victory_config.dart` constant.
String? sellerFeedstockTileAcquisitionTarget(
  Game game,
  String playerId,
  Set<String> acquirableProvinceIds,
) {
  final acquirable = sellerFeedstockTileAcquisitionTargetsAmongAcquirable(
    game,
    playerId,
    acquirableProvinceIds,
  );
  if (acquirable.isEmpty) return null;
  return acquirable.first;
}

/// Producible **multi-input** level-0 `build_improvement` input commodities
/// (`castIron`) a below-quota zero-NW lock-recovery seller should stage
/// domestically on feasible turns **even after its fabric-feedstock
/// improvement-cost gate goes inactive**, provided it still owns the `castIron`
/// feedstock tiles (`timber` / `iron`) it extracts from (Refs #2847 § H8
/// production allocation; S7-D castIron production-assignment localization,
/// PR #3289).
///
/// This returns `{castIron}` (and any other producible multi-input level-0
/// improvement input) the seller is **short** of, gated on the seller being a
/// below-quota zero-NW lock-recovery seller (`oldWorld ∈ [2, quota)`, zero New
/// World provinces) with **zero regiments** that still **owns at least one tile
/// hosting that recipe's feedstock** (`timber` / `iron`) at any improvement
/// level. The single-input `lumber` path is intentionally excluded (already
/// covered by the improvement-cost-gated set, and a single-input recipe has no
/// co-availability problem). Self-clears once the seller holds the input or owns
/// a regiment, so the +6 Old World conquest baseline GPs (gp1 / gp2, holding
/// regiments) are never routed. Pure and deterministic over `(game, playerId)`
/// and the static `ProductionRecipesCatalog` / work-order cost table.
Set<String> selfLockRecoverySellerStageableImprovementInputs(
  Game game,
  String playerId,
) {
  if (regimentCountForPlayer(game, playerId) != 0) return const <String>{};
  if (!isBelowQuotaZeroNwSeller(game, playerId)) return const <String>{};
  Player? seller;
  for (final player in game.players) {
    if (player.id == playerId) {
      seller = player;
      break;
    }
  }
  if (seller == null) return const <String>{};
  final baseCost = workOrderCostBuildImprovement(0);
  if (baseCost.isEmpty) return const <String>{};
  final result = <String>{};
  for (final entry in baseCost.entries) {
    if (seller.stockpile.quantityOf(entry.key) >= entry.value) continue;
    final recipe = _lowestIdMultiInputRecipeProducingOutput(entry.key);
    if (recipe == null) continue;
    if (!_ownsFeedstockResourceTile(
      game,
      playerId,
      recipe.inputQuantities.keys.toSet(),
    )) {
      continue;
    }
    result.add(entry.key);
  }
  return result;
}

/// The production recipe with the lowest `id` whose output is [outputId] and
/// which consumes more than one distinct input commodity (e.g.
/// `castIron_from_timber_iron_coal`), or `null` when none exists. Single-input
/// recipes (e.g. `lumber_from_timber`) are excluded — they have no
/// feedstock-co-availability problem. Deterministic over the static
/// `ProductionRecipesCatalog`.
ProductionRecipe? _lowestIdMultiInputRecipeProducingOutput(String outputId) {
  ProductionRecipe? best;
  for (final recipe in ProductionRecipesCatalog.all) {
    if (recipe.outputCommodityId != outputId) continue;
    if (recipe.inputQuantities.length <= 1) continue;
    if (best == null || recipe.id.compareTo(best.id) < 0) best = recipe;
  }
  return best;
}

/// True iff [playerId] owns at least one **Old World** province tile hosting a
/// resource in [feedstockIds] that is still unimproved (`improvementLevel < 1`)
/// — the `build_improvement` target a supplier (or seller) must keep an idle
/// Builder in the Old World to extract (Refs #2847 § H8-extraction supplier
/// Old World feedstock unit reservation). Old World is every region that is not
/// [kNewWorldRegionId], derived from the tile key alone so the scan works from
/// `WorldState.resourceByTileKey`. Read-only and deterministic.
bool _ownsUnimprovedOldWorldFeedstockTile(
  Game game,
  String playerId,
  Set<String> feedstockIds,
) {
  if (feedstockIds.isEmpty) return false;
  final ws = game.worldState;
  for (final entry in ws.resourceByTileKey.entries) {
    if (!feedstockIds.contains(entry.value)) continue;
    if (Unit.regionIdFromTileKey(entry.key) == kNewWorldRegionId) continue;
    final provinceId = Unit.provinceIdFromTileKey(entry.key);
    if (provinceId == null) continue;
    final province = ws.tryGetProvince(provinceId);
    if (province == null || province.ownerId != playerId) continue;
    if (ws.tileState.improvementLevel(entry.key) < 1) return true;
  }
  return false;
}

/// True iff [playerId] owns at least one **Old World** province tile hosting an
/// **unprospected mineral** feedstock resource in [feedstockIds] — the
/// `prospect` target a supplier (or seller) must keep an idle Explorer in the
/// Old World to expose before the Builder can improve it (Refs #2847
/// § H8-extraction supplier Old World feedstock unit reservation). Read-only
/// and deterministic.
bool _ownsUnprospectedOldWorldMineralFeedstockTile(
  Game game,
  String playerId,
  Set<String> feedstockIds,
) {
  if (feedstockIds.isEmpty) return false;
  final ws = game.worldState;
  for (final entry in ws.resourceByTileKey.entries) {
    if (!feedstockIds.contains(entry.value)) continue;
    if (Unit.regionIdFromTileKey(entry.key) == kNewWorldRegionId) continue;
    final provinceId = Unit.provinceIdFromTileKey(entry.key);
    if (provinceId == null) continue;
    final province = ws.tryGetProvince(provinceId);
    if (province == null || province.ownerId != playerId) continue;
    if (_isUnprospectedMineralFeedstockTile(
      game,
      playerId,
      entry.key,
      feedstockIds,
    )) {
      return true;
    }
  }
  return false;
}
