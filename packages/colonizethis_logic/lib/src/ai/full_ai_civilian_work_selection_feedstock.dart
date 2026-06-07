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
