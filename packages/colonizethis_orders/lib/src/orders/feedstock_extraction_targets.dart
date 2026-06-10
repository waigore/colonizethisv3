import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';


// Feedstock-extraction resource-id gates for the below-quota zero-NW
// lock-recovery seller / supplier roles (Refs #2847 § H8-extraction).
//
// This logic computes *which resources a player should extract* from
// deterministic game state (recipe catalogs, ownership, stockpiles) and is
// consumed by both the order-suggestion ordering path (`order_suggestion_work`)
// and the Full AI civilian work selection. It lives in the `orders` domain so
// the one-way dependency direction holds: the AI-contract layer (`src/ai/`,
// future `colonizethis_ai_contracts`) depends on `orders`, not the reverse
// (Refs #3290 § orders↔ai bidirectional-edge break;
// `.cursor/rules/colonizethis-logic-ai-decoupling.mdc`).

int regimentCountForPlayer(Game game, String playerId) {
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
  return ProvinceOwnerCache.of(
    game.worldState,
  ).countOwnedByInRegion(playerId, kRegionNewWorld);
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
  if (regimentCountForPlayer(game, playerId) != 0) return const <String>{};
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
  if (isBelowQuotaZeroNwSeller(game, playerId)) return const <String>{};
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
  final feedstock = sellerImprovementInputFeedstockResourceIds(game, playerId);
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
/// acquisition residual detection. Pure and deterministic over
/// `(game, playerId)` and the static `ProductionRecipesCatalog`.
Set<String> sellerImprovementInputFeedstockResourceIds(
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
/// supplier role must exclude.
bool isBelowQuotaZeroNwSeller(Game game, String playerId) {
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
