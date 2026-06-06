part of 'full_ai_civilian_work_selection.dart';

// Feedstock-extraction resource-id gates and Old World feedstock-tile
// ownership predicates for the below-quota zero-NW lock-recovery seller /
// supplier roles (Refs #2847 § H8-extraction). Split out of
// full_ai_civilian_work_selection.dart by concern to keep each library file
// at or below the repo non-comment line limit; shares the parent library's
// private scope via `part`.

int _regimentCountForPlayer(Game game, String playerId) {
  var count = 0;
  for (final unit in allUnitsFromWorld(game.worldState)) {
    if (unit.ownerId != playerId) continue;
    if (RegimentEconomyCatalog.byId.containsKey(unit.type)) {
      count++;
    }
  }
  return count;
}

int _newWorldProvinceCountOwnedBy(Game game, String playerId) {
  return game.worldState
      .provincesForRegion(kRegionNewWorld)
      .where((p) => p.ownerId == playerId)
      .length;
}

/// Resource ids a below-quota zero-NW lock-recovery seller should extract to
/// domestically produce the cheapest regiment's missing build input
/// (Refs #2847 § H8-extraction; companion to
/// `treasury-planner.md` § Lock-recovery seller regiment build-input
/// bootstrap).
///
/// Returns the empty set unless the lock-recovery rebuild gate holds for
/// [playerId]:
///
/// - below-quota zero-NW lock-recovery seller — `oldWorldProvinceCountOwnedBy`
///   in `[2, kObserverConquestMinOwProvincesPerGp)` and zero New World
///   provinces, and
/// - `regimentCountForPlayer == 0` (zero-regiment rebuild gap).
///
/// **Treasury-independent (Refs #2847 H8-extraction).** The gate is
/// deliberately **not** conditioned on
/// `player.treasury >= cheapestRegimentBuildTreasuryCost()`. Routing a Builder
/// onto an owned feedstock tile only spends labour — it spends no treasury —
/// and the phase planner already sets `forceCheapestRegimentBuild` (arm A:
/// `regimentCount == 0` + invadable Old World frontier) regardless of treasury
/// so the rebuild trap cannot stick. A treasury gate on extraction re-imposed
/// that trap on the *input*: the failing seed-42 Great Powers sit below the
/// regiment cost ~97 of 100 turns, so the Builder was only routed onto the
/// feedstock tile on the rare recovered turn and the multi-turn
/// `extract → produce → build` chain could never finish inside the brief
/// recovery window. This mirrors the treasury-independent regiment build-input
/// *production* boost (economy-planner.md § Treasury-independent staging); the
/// actual market **bids** and build order remain treasury-gated at their call
/// sites (treasury-planner.md § Lock-recovery seller regiment build-input
/// bootstrap). The `regimentCount == 0` guard still excludes every healthy
/// regiment-holding Great Power, so the +6 Old World conquest baseline GPs are
/// never routed.
///
/// The returned ids are the production-recipe feedstock commodities (e.g.
/// `wool` / `cotton` for `fabric`) of every recipe whose output is a missing
/// `peasant_levies` build input. Tile resource ids equal commodity ids for
/// these agricultural resources (`resource_extractor.dart`
/// § `_resourceToCommodityId`), so the set can be matched directly against
/// `WorldState.resourceByTileKey`. Self-clears once the build input is on hand
/// or the GP owns a regiment. Pure and deterministic over `(game, playerId)`
/// and the static `RegimentEconomyCatalog` / `ProductionRecipesCatalog`.
Set<String> regimentBuildInputFeedstockExtractionResourceIds(
  Game game,
  String playerId,
) {
  final player = game.playerById(playerId);
  if (player == null) return const <String>{};
  if (_regimentCountForPlayer(game, playerId) != 0) return const <String>{};
  final ow = oldWorldProvinceCountOwnedBy(game, playerId);
  if (ow < 2 || !isBelowObserverConquestQuota(ow)) return const <String>{};
  if (_newWorldProvinceCountOwnedBy(game, playerId) != 0) {
    return const <String>{};
  }
  final missingInputs = <CommodityId>{
    for (final entry
        in RegimentEconomyCatalog.peasantLevies.buildInputs.entries)
      if (player.stockpile.quantityOf(entry.key) < entry.value) entry.key,
  };
  if (missingInputs.isEmpty) return const <String>{};
  final feedstock = <String>{};
  for (final recipe in ProductionRecipesCatalog.all) {
    if (missingInputs.contains(recipe.outputCommodityId)) {
      feedstock.addAll(recipe.inputQuantities.keys);
    }
  }
  return feedstock;
}

/// True iff [playerId] owns at least one province tile hosting a resource in
/// [feedstockIds] that is still unimproved (`improvementLevel < 1`) — a Builder
/// target whose `build_improvement` would extract the feedstock the
/// `fabricFrom*` recipes consume. Province ownership is derived from the tile
/// key (`Unit.provinceIdFromTileKey`) so the scan works from
/// `WorldState.resourceByTileKey` alone. Read-only; Refs #2847 H8-extraction.
bool _ownsUnimprovedFeedstockResourceTile(
  Game game,
  String playerId,
  Set<String> feedstockIds,
) {
  if (feedstockIds.isEmpty) return false;
  final ws = game.worldState;
  for (final entry in ws.resourceByTileKey.entries) {
    if (!feedstockIds.contains(entry.value)) continue;
    final provinceId = Unit.provinceIdFromTileKey(entry.key);
    if (provinceId == null) continue;
    final province = tryGetProvince(ws, provinceId);
    if (province == null || province.ownerId != playerId) continue;
    if (ws.tileState.improvementLevel(entry.key) < 1) return true;
  }
  return false;
}

/// True iff [playerId] owns at least one province tile hosting a resource in
/// [feedstockIds] at **any** improvement level — the inverse precondition of
/// the feedstock-tile acquisition residual
/// ([sellerNeedsImprovementInputFeedstockTileAcquisition]). Unlike
/// [_ownsUnimprovedFeedstockResourceTile] this ignores `improvementLevel`, so an
/// already-improved feedstock tile still counts as owned (the seller has the
/// tile; it needs no acquisition). Province ownership is derived from the tile
/// key (`Unit.provinceIdFromTileKey`) so the scan works from
/// `WorldState.resourceByTileKey` alone. Read-only and deterministic; Refs #2847
/// § H8-extraction seller feedstock-tile acquisition residual.
bool _ownsFeedstockResourceTile(
  Game game,
  String playerId,
  Set<String> feedstockIds,
) {
  if (feedstockIds.isEmpty) return false;
  final ws = game.worldState;
  for (final entry in ws.resourceByTileKey.entries) {
    if (!feedstockIds.contains(entry.value)) continue;
    final provinceId = Unit.provinceIdFromTileKey(entry.key);
    if (provinceId == null) continue;
    final province = tryGetProvince(ws, provinceId);
    if (province == null || province.ownerId != playerId) continue;
    return true;
  }
  return false;
}

/// Level-0 `build_improvement` material cost (`{lumber: 1, castIron: 1}`,
/// `work_order_costs.dart` § `workOrderCostBuildImprovement`) a below-quota
/// zero-NW lock-recovery seller must hold to extract its own fabric feedstock
/// tile (Refs #2847 § H8-extraction; companion to `treasury-planner.md`
/// § Lock-recovery seller feedstock-improvement input bootstrap).
///
/// Returns the cost map **only** when the regiment build-input
/// feedstock-extraction gate is active for [playerId]
/// ([regimentBuildInputFeedstockExtractionResourceIds] non-empty) **and** the
/// seller owns an unimproved tile hosting one of those feedstock resources —
/// the case where the routed Builder is blocked by the lumber / cast-iron
/// improvement cost it cannot afford. Returns the empty map otherwise, so it
/// self-clears once the GP owns a regiment, holds the build input, or has
/// improved the feedstock tile. The returned quantities are the **full** level-0
/// cost; the caller nets on-hand stock and carry-forward bids to size the actual
/// bid. Pure and deterministic over `(game, playerId)` and the static
/// `RegimentEconomyCatalog` / `ProductionRecipesCatalog` / work-order cost table.
Map<String, int> regimentBuildInputFeedstockImprovementInputCost(
  Game game,
  String playerId,
) {
  final feedstockIds = regimentBuildInputFeedstockExtractionResourceIds(
    game,
    playerId,
  );
  if (feedstockIds.isEmpty) return const <String, int>{};
  if (!_ownsUnimprovedFeedstockResourceTile(game, playerId, feedstockIds)) {
    return const <String, int>{};
  }
  return Map<String, int>.unmodifiable(workOrderCostBuildImprovement(0));
}

/// Resource ids an affluent **supplier** should extract so it can over-produce
/// the domestically-produced level-0 `build_improvement` input (e.g.
/// `castIron`) a *peer* below-quota zero-NW lock-recovery seller needs but can
/// neither mine nor buy (Refs #2847 § H8-extraction supplier feedstock).
///
/// Closes the upstream link the post-#3244 S7-D diagnostic pinned: the supplier
/// `castIron` over-production (`economy_planner.dart` § Supplier improvement-
/// input over-production) + surplus release (`treasury_planner.dart`) loop is
/// **infeasible** while no affluent supplier holds or extracts the `timber` /
/// `iron` the `castIron` recipe consumes. This routes the supplier's idle
/// Builder onto its own unimproved `timber` / `iron` tile via the shared
/// feedstock score boost in [_buildImprovementWorkScore], giving the over-
/// production feedstock to run.
///
/// Returns the production-recipe feedstock commodities (e.g. `timber`, `iron`)
/// of every recipe whose output is a producible improvement input a peer locked
/// seller still needs, only when ALL hold:
/// - [playerId] is NOT itself a below-quota zero-NW lock-recovery seller (its
///   own [regimentBuildInputFeedstockExtractionResourceIds] gate already routes
///   its Builder); this scopes the supplier role to healthy / above-quota Great
///   Powers so the +6 Old World conquest baseline GPs are never starved,
/// - some OTHER player IS a below-quota zero-NW lock-recovery seller whose
///   level-0 improvement-input gate is active and is missing a producible
///   improvement input (peer demand exists), and
/// - [playerId] owns an unimproved tile hosting one of those feedstock
///   resources to extract.
/// Self-clears once no locked seller needs the improvement input or the
/// supplier owns no unimproved feedstock tile. Pure and deterministic over
/// `(game, playerId)` and the static `ProductionRecipesCatalog` / work-order
/// cost table.
Set<String> supplierImprovementInputFeedstockExtractionResourceIds(
  Game game,
  String playerId,
) {
  // The supplier role excludes a GP that is itself a locked seller — its own
  // feedstock-extraction gate already routes its Builder. Restricting the role
  // this way keeps it on healthy / above-quota GPs only.
  if (_isBelowQuotaZeroNwSeller(game, playerId)) return const <String>{};
  final neededInputs = peerLockRecoverySellerNeededProducibleImprovementInputs(
    game,
    excludePlayerId: playerId,
  );
  if (neededInputs.isEmpty) return const <String>{};
  final feedstock = <String>{};
  for (final recipe in ProductionRecipesCatalog.all) {
    if (neededInputs.contains(recipe.outputCommodityId)) {
      feedstock.addAll(recipe.inputQuantities.keys);
    }
  }
  if (feedstock.isEmpty) return const <String>{};
  if (!_ownsUnimprovedFeedstockResourceTile(game, playerId, feedstock)) {
    return const <String>{};
  }
  return feedstock;
}

/// Resource ids a below-quota zero-NW lock-recovery **seller** should extract so
/// it can domestically produce the level-0 `build_improvement` inputs (`lumber`
/// and/or `castIron`) it is **itself** short of and cannot reliably buy on
/// seed 42 (Refs #2847 § H8-extraction seller improvement-input feedstock).
///
/// Seller-side companion to
/// [supplierImprovementInputFeedstockExtractionResourceIds]: where the supplier
/// variant routes an *affluent peer's* idle Builder onto `timber` / `iron` so it
/// can over-produce the improvement input a locked seller needs, this routes the
/// **seller's own** idle Builder onto its own unimproved `timber` / `iron` tile
/// so the seller's domestic improvement-input production (`economy_planner.dart`
/// § Domestic improvement-input production) has feedstock to run. Without it the
/// seller's `lumber_from_timber` production draws on a `timber` stockpile that
/// stays `0`, because every idle Builder is routed to higher-scoring New World
/// colonial work and never extracts the `timber` the recipe consumes — the
/// mirror of the supplier residual the supplier-side gate closes.
///
/// Returns the production-recipe feedstock commodities (`timber` for `lumber`;
/// `timber` + `iron` for `castIron`) of every recipe whose output is a producible
/// improvement input the seller still needs
/// ([selfLockRecoverySellerNeededProducibleImprovementInputs]), only when the
/// seller owns at least one **unimproved** (`improvementLevel < 1`) tile hosting
/// one of those feedstock resources. Returns the empty set for any player whose
/// seller improvement-input gate is inactive — including every healthy /
/// above-quota Great Power and every regiment-holding GP — so the +6 Old World
/// conquest baseline GPs are never routed. Self-clears once the seller holds the
/// improvement input, improves the feedstock tile, or owns a regiment. Pure and
/// deterministic over `(game, playerId)` and the static
/// `ProductionRecipesCatalog`.
Set<String> sellerImprovementInputFeedstockExtractionResourceIds(
  Game game,
  String playerId,
) {
  final feedstock = _sellerImprovementInputFeedstockResourceIds(game, playerId);
  if (feedstock.isEmpty) return const <String>{};
  if (!_ownsUnimprovedFeedstockResourceTile(game, playerId, feedstock)) {
    return const <String>{};
  }
  return feedstock;
}

/// The production-recipe feedstock commodities (`timber` for `lumber`;
/// `timber` + `iron` for `castIron`) of every recipe whose output is a
/// producible level-0 `build_improvement` input the below-quota zero-NW
/// lock-recovery seller [playerId] still needs
/// ([selfLockRecoverySellerNeededProducibleImprovementInputs]).
///
/// Unlike [sellerImprovementInputFeedstockExtractionResourceIds] this is the
/// **un-gated** feedstock set: it is the seller's improvement-input feedstock
/// *demand* before the owned-unimproved-tile carve-out is applied. Returns the
/// empty set whenever the seller needs no producible improvement input (gate
/// inactive — at quota, owns a regiment, owns a New World province, or already
/// holds the inputs). Shared core for the routing gate and the feedstock-tile
/// acquisition residual detection
/// ([sellerNeedsImprovementInputFeedstockTileAcquisition]). Pure and
/// deterministic over `(game, playerId)` and the static
/// `ProductionRecipesCatalog`.
Set<String> _sellerImprovementInputFeedstockResourceIds(
  Game game,
  String playerId,
) {
  final neededInputs = selfLockRecoverySellerNeededProducibleImprovementInputs(
    game,
    playerId,
  );
  if (neededInputs.isEmpty) return const <String>{};
  final feedstock = <String>{};
  for (final recipe in ProductionRecipesCatalog.all) {
    if (neededInputs.contains(recipe.outputCommodityId)) {
      feedstock.addAll(recipe.inputQuantities.keys);
    }
  }
  return feedstock;
}

/// True iff the below-quota zero-NW lock-recovery seller [playerId] needs a
/// producible level-0 `build_improvement` input (`lumber` / `castIron`) it must
/// produce domestically, but owns **no** province tile hosting **any** of that
/// input's feedstock resource — at **any** improvement level — so it cannot be
/// routed to extract the feedstock and must instead **acquire** a feedstock tile
/// (Refs #2847 § H8-extraction seller feedstock-tile acquisition residual).
///
/// Detection contract for the residual disclosed in [economy-planner.md]
/// (`SPEC/ai/economy-planner.md` § Residual feedstock-tile dependency and
/// § Seller improvement-input feedstock extraction): the seller-side routing
/// gate [sellerImprovementInputFeedstockExtractionResourceIds] only re-prioritises
/// an **existing** owned unimproved feedstock tile — it acquires no tile, so a
/// failing GP whose Old World territory contains no `timber` tile still cannot
/// source `lumber` domestically and the turn-100 conquest gate stays open on that
/// axis. This predicate isolates exactly that class so an acquisition slice can
/// gate on it deterministically.
///
/// Returns `true` only when both hold:
///   * the seller's improvement-input feedstock **demand**
///     ([_sellerImprovementInputFeedstockResourceIds]) is non-empty — i.e. the
///     improvement-cost gate is active and the seller is short of a producible
///     input; **and**
///   * the seller owns **no** tile hosting any feedstock resource in that demand
///     set ([_ownsFeedstockResourceTile] is `false`).
///
/// Returns `false` for:
///   * every player whose improvement-input gate is inactive (at or above the
///     conquest quota, owns a regiment, owns a New World province, or already
///     holds the inputs) — so the +6 Old World conquest baseline GPs are never
///     flagged; and
///   * a seller that already owns a feedstock tile, whether **unimproved** (the
///     routing gate handles it) or **improved** (a distinct improved-tile
///     residual, not feedstock-tile acquisition) — owning the tile means no
///     acquisition is required.
///
/// Pure and deterministic over `(game, playerId)` and the static
/// `ProductionRecipesCatalog`; performs no I/O and no logging.
bool sellerNeedsImprovementInputFeedstockTileAcquisition(
  Game game,
  String playerId,
) {
  final feedstock = _sellerImprovementInputFeedstockResourceIds(game, playerId);
  if (feedstock.isEmpty) return false;
  return !_ownsFeedstockResourceTile(game, playerId, feedstock);
}

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
/// ([_sellerImprovementInputFeedstockResourceIds]), sorted ascending by province
/// id for a deterministic candidate ordering.
///
/// **Topology-free by construction.** Province adjacency, reachability, and
/// war-cost ranking are the province of the later acquisition-wiring slice,
/// which intersects this candidate list with the conquest / purchasable-land
/// target sets it derives from the combined topology. This contract isolates the
/// *which feedstock-bearing Old World provinces exist to acquire* question
/// deterministically, so the wiring slice gates on it without re-deriving
/// feedstock demand. New World provinces are excluded: the failing sellers hold
/// zero New World land and the turn-100 gate is Old World conquest, so a New
/// World feedstock tile cannot close it.
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
  final feedstock = _sellerImprovementInputFeedstockResourceIds(game, playerId);
  final ws = game.worldState;
  final provinceIds = <String>{};
  for (final entry in ws.resourceByTileKey.entries) {
    if (!feedstock.contains(entry.value)) continue;
    if (Unit.regionIdFromTileKey(entry.key) == kNewWorldRegionId) continue;
    final provinceId = Unit.provinceIdFromTileKey(entry.key);
    if (provinceId == null) continue;
    final province = tryGetProvince(ws, provinceId);
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
/// The selection contract above enumerates *which* Old World provinces host the
/// feedstock the seller could acquire without consulting topology; this
/// intersection narrows that candidate list to the provinces the AI-side
/// acquisition path can actually reach this turn. [acquirableProvinceIds] is the
/// caller's topology-derived target set — the union of the conquest
/// (declare-war / army-reachable) and purchasable-land target province ids the
/// AI planner computes from the combined topology — so this function stays
/// **topology-free** by construction: it derives no adjacency or reachability
/// itself, it only intersects the already-deterministic feedstock candidate list
/// with the planner's reported acquirable set, completing the "intersect this
/// candidate list with the conquest / purchasable-land target sets" step the
/// acquisition-wiring slice needs.
///
/// Returns the empty list when the acquisition residual is inactive for
/// [playerId] (so it is empty for every healthy / above-quota / regiment-holding
/// / NW-owning GP, and the +6 Old World conquest baseline GPs are never
/// flagged), when [acquirableProvinceIds] is empty, or when no feedstock
/// candidate is acquirable this turn. Preserves the ascending province-id order
/// of the candidate list (the source list is already sorted, so iteration order
/// is independent of [acquirableProvinceIds] iteration order). Pure and
/// deterministic over `(game, playerId, acquirableProvinceIds)` and the static
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
/// ([sellerFeedstockTileAcquisitionTargetsAmongAcquirable]): where the
/// intersection narrows the topology-free feedstock candidate list to every
/// province the planner reports as acquirable this turn, this collapses that
/// list to the **one** province the acquisition-wiring slice should pursue, so
/// the slice emits exactly one deterministic acquisition order per turn rather
/// than re-deriving the choice itself. The pick is the lowest province id in the
/// acquirable subset — the subset is already ascending-sorted, so the first
/// element is the deterministic primary target independent of
/// [acquirableProvinceIds] iteration order.
///
/// Returns `null` when the acquisition residual is inactive for [playerId] (so
/// it is `null` for every healthy / above-quota / regiment-holding / NW-owning
/// GP, and the +6 Old World conquest baseline GPs are never picked), when
/// [acquirableProvinceIds] is empty, or when no feedstock candidate is
/// acquirable this turn. **Topology-free** by construction — it derives no
/// adjacency or reachability itself, only selecting from the planner's reported
/// acquirable set. Pure and deterministic over
/// `(game, playerId, acquirableProvinceIds)` and the static
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

/// Union of the seller-side feedstock gates and the supplier-side gate for
/// [playerId] (Refs #2847 § H8-extraction):
///
/// - [regimentBuildInputFeedstockExtractionResourceIds] — routes a locked
///   seller's Builder onto its `peasant_levies` regiment-build-input feedstock
///   (`wool` / `cotton` for `fabric`).
/// - [sellerImprovementInputFeedstockExtractionResourceIds] — routes the same
///   locked seller's Builder onto the `timber` / `iron` its own level-0
///   `build_improvement` inputs (`lumber` / `castIron`) are produced from.
/// - [supplierImprovementInputFeedstockExtractionResourceIds] — routes an
///   affluent supplier's Builder onto the `timber` / `iron` it over-produces a
///   peer locked seller's improvement input from.
///
/// A locked seller may match **both** seller-side gates (regiment-build-input
/// and improvement-input feedstock are distinct resource sets it legitimately
/// needs), while the supplier gate is mutually exclusive with the seller role,
/// so the union is over `Set` semantics and never double-counts a resource.
/// Non-empty **only** under those deterministic lock-recovery conditions; the
/// empty set for every ordinary player so callers (civilian-work selection
/// scoring and `build_improvement` suggestion ordering) leave off-gate behaviour
/// unchanged. Pure and deterministic over `(game, playerId)` and the static
/// catalogs.
Set<String> feedstockExtractionResourceIdsForPlayer(
  Game game,
  String playerId,
) {
  return <String>{
    ...regimentBuildInputFeedstockExtractionResourceIds(game, playerId),
    ...sellerImprovementInputFeedstockExtractionResourceIds(game, playerId),
    ...supplierImprovementInputFeedstockExtractionResourceIds(game, playerId),
  };
}

/// True iff [playerId] holds Old World land below the observer conquest quota
/// (`oldWorldProvinceCountOwnedBy` in `[2, kObserverConquestMinOwProvincesPerGp)`)
/// and owns zero New World provinces — the Path F lock-recovery seller band the
/// supplier role must exclude. Logic-local mirror of the AI-side predicate so
/// the supplier gate stays computable inside the logic package.
bool _isBelowQuotaZeroNwSeller(Game game, String playerId) {
  final ow = oldWorldProvinceCountOwnedBy(game, playerId);
  if (ow < 2) return false;
  if (!isBelowObserverConquestQuota(ow)) return false;
  return _newWorldProvinceCountOwnedBy(game, playerId) == 0;
}

/// Producible level-0 `build_improvement` input commodities still missing from
/// at least one *other* below-quota zero-NW lock-recovery seller blocked at the
/// improvement-cost gate (`regimentBuildInputFeedstockImprovementInputCost`
/// non-empty). "Producible" means some `ProductionRecipesCatalog` recipe outputs
/// the commodity, so an affluent supplier can over-produce it for release.
///
/// Both level-0 inputs are producible (`lumber` from `timber`; `castIron` from
/// `timber` + `iron`), so each enters the set whenever a peer locked seller is
/// **short** of it. On seed 42 `castIron` has no world-market supply and `lumber`
/// market supply is structurally thin (the S7-D lumber re-localization, Refs
/// #2847): the locked seller holds neither, so **both** join the set and an
/// affluent supplier over-produces and releases them. An input the seller
/// already holds is excluded by the missing-stock check. Pure and deterministic
/// over `(game)` and the static catalogs / cost table.
Set<String> peerLockRecoverySellerNeededProducibleImprovementInputs(
  Game game, {
  required String excludePlayerId,
}) {
  final result = <String>{};
  for (final player in game.players) {
    if (player.id == excludePlayerId) continue;
    result.addAll(_producibleImprovementInputsShortForPlayer(game, player));
  }
  return result;
}

/// Producible level-0 `build_improvement` input commodities [playerId] — a
/// below-quota zero-NW lock-recovery seller blocked at the improvement-cost
/// gate — is **itself** short of and can produce domestically (Refs #2847
/// § H8-extraction seller domestic improvement-input production; S7-D lumber
/// re-localization).
///
/// The seller-side companion to
/// [peerLockRecoverySellerNeededProducibleImprovementInputs]: where the peer
/// variant returns the producible inputs *other* lock-recovery sellers need (so
/// an affluent supplier over-produces them for release), this returns the
/// producible inputs the seller must produce **from its own owned feedstock**
/// because the world market cannot reliably supply them on seed 42 — `castIron`
/// has no market supply at all, and `lumber` market supply is structurally thin
/// (one offerer). Both level-0 inputs are producible (`lumber` from `timber`;
/// `castIron` from `timber` + `iron`), so each enters the set whenever the
/// seller is **short** of it under an active improvement-cost gate.
///
/// Returns the empty set for any player whose improvement-cost gate is inactive
/// (`regimentBuildInputFeedstockImprovementInputCost` empty) — including every
/// healthy / above-quota Great Power and every regiment-holding GP — so the +6
/// Old World conquest baseline GPs are never routed. Pure and deterministic over
/// `(game, playerId)` and the static catalogs / cost table.
Set<String> selfLockRecoverySellerNeededProducibleImprovementInputs(
  Game game,
  String playerId,
) {
  for (final player in game.players) {
    if (player.id != playerId) continue;
    return _producibleImprovementInputsShortForPlayer(game, player);
  }
  return const <String>{};
}

/// Producible **multi-input** level-0 `build_improvement` input commodities
/// (`castIron`) a below-quota zero-NW lock-recovery seller should stage
/// domestically on feasible turns **even after its fabric-feedstock
/// improvement-cost gate goes inactive**, provided it still owns the `castIron`
/// feedstock tiles (`timber` / `iron`) it extracts from (Refs #2847 § H8
/// production allocation; S7-D castIron production-assignment localization,
/// PR #3289).
///
/// [selfLockRecoverySellerNeededProducibleImprovementInputs] only reports the
/// inputs while `regimentBuildInputFeedstockImprovementInputCost` is active,
/// which is gated on the seller owning an **unimproved** `wool` / `cotton`
/// (fabric-recipe) feedstock tile. The S7-D castIron localization pinned a
/// residual where a recovered seller (seed-42 gp5) co-holds the `castIron`
/// feedstock (`timber` + `iron`) and the only `castIron` recipe is materially
/// feasible for ~53 turns, yet `castIron` production is never assigned because
/// that fabric-tile gate has gone inactive once the fabric tile is improved —
/// a production-allocation gap, not a feedstock-supply gap.
///
/// This returns `{castIron}` (and any other producible multi-input level-0
/// improvement input) the seller is **short** of, gated on the seller being a
/// below-quota zero-NW lock-recovery seller (`oldWorld ∈ [2, quota)`, zero New
/// World provinces) with **zero regiments** that still **owns at least one tile
/// hosting that recipe's feedstock** (`timber` / `iron`) at any improvement
/// level. The tile-ownership precondition keeps the staging purposeful and
/// scopes it to sellers that genuinely run the `extract → produce → improve`
/// chain (so a seller owning no feedstock tile, like the gate-inactive negative
/// controls, never stages it). The economy planner's own `feasibleRuns` check
/// still only assigns the recipe on turns the seller actually holds enough
/// feedstock, and the multi-input feedstock reserve preserves `timber` / `iron`
/// co-availability. The single-input `lumber` path is intentionally excluded
/// (already covered by the improvement-cost-gated set, and a single-input
/// recipe has no co-availability problem). Self-clears once the seller holds
/// the input or owns a regiment, so the +6 Old World conquest baseline GPs
/// (gp1 / gp2, holding regiments) are never routed. Pure and deterministic over
/// `(game, playerId)` and the static `ProductionRecipesCatalog` / work-order
/// cost table.
Set<String> selfLockRecoverySellerStageableImprovementInputs(
  Game game,
  String playerId,
) {
  if (_regimentCountForPlayer(game, playerId) != 0) return const <String>{};
  if (!_isBelowQuotaZeroNwSeller(game, playerId)) return const <String>{};
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

/// The producible level-0 `build_improvement` input commodities [player] is
/// short of at its active improvement-cost gate. "Producible" means some
/// `ProductionRecipesCatalog` recipe outputs the commodity. Returns the empty
/// set when the gate is inactive (cost map empty). Shared core for the peer and
/// self lock-recovery seller producible-input contracts.
Set<String> _producibleImprovementInputsShortForPlayer(
  Game game,
  Player player,
) {
  final cost = regimentBuildInputFeedstockImprovementInputCost(game, player.id);
  if (cost.isEmpty) return const <String>{};
  final result = <String>{};
  for (final entry in cost.entries) {
    final producible = ProductionRecipesCatalog.all.any(
      (r) => r.outputCommodityId == entry.key,
    );
    if (!producible) continue;
    if (player.stockpile.quantityOf(entry.key) < entry.value) {
      result.add(entry.key);
    }
  }
  return result;
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
    final province = tryGetProvince(ws, provinceId);
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
    final province = tryGetProvince(ws, provinceId);
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
