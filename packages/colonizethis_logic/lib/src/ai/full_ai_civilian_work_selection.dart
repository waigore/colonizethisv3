import 'dart:math' as math;

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../constants.dart';
import '../diplomacy/diplomacy_resolver.dart';
import '../orders/build_rail_work_rules.dart';
import '../world/player_view.dart';
import '../world/province_lookup.dart';
import '../world/unit_lookup.dart';

/// Idle civilian (no new work) for Full AI observability.
class FullAiCivilianWorkIdle {
  const FullAiCivilianWorkIdle({
    required this.unitId,
    required this.unitType,
    required this.reason,
  });

  final String unitId;
  final String unitType;
  final String reason;
}

/// Deterministic Full AI civilian work selection from [suggestWorkOrders] output.
///
/// Normative rules: GitHub #2082; SPEC/program/order-suggestions.md (Full AI).
class FullAiCivilianWorkSelectionResult {
  const FullAiCivilianWorkSelectionResult({
    required this.workOrders,
    required this.idleEvents,
  });

  final List<WorkOrder> workOrders;
  final List<FullAiCivilianWorkIdle> idleEvents;
}

bool _civilianWorkCapableType(String type) =>
    isExplorerUnit(type) ||
    isCivilianWorkerUnit(type) ||
    isSpyUnit(type) ||
    isMerchantUnit(type);

int _compareWorkOrderLex(WorkOrder a, WorkOrder b) {
  final t = a.target.compareTo(b.target);
  if (t != 0) return t;
  return a.targetTileKey.compareTo(b.targetTileKey);
}

void _sortWorkOrdersLex(List<WorkOrder> list) {
  list.sort(_compareWorkOrderLex);
}

bool _observationEligible(
  PlayerView view,
  Game game,
  String playerId,
  String tileKey,
  Province province,
) {
  if (view.visibilityForTile(tileKey) == VisibilityLevel.fullyVisible) {
    return true;
  }
  if (province.ownerId == playerId) return true;
  return false;
}

bool _tileShowsMineralForExposure(
  Game game,
  String playerId,
  String tileKey,
  String mineralId,
) {
  final res = game.worldState.resourceByTileKey[tileKey];
  if (res == mineralId) return true;
  final prospected =
      game.worldState.playerProspectedTiles[playerId] ?? const <String>{};
  return prospected.contains(tileKey) && res == mineralId;
}

void _bumpExposureForTile(
  Game game,
  PlayerView view,
  String playerId,
  String tileKey,
  Province province,
  Map<String, int> counts,
) {
  if (!_observationEligible(view, game, playerId, tileKey, province)) {
    return;
  }
  for (final m in kMineralResourceIds) {
    if (!_tileShowsMineralForExposure(game, playerId, tileKey, m)) continue;
    counts[m] = (counts[m] ?? 0) + 1;
  }
}

void _bumpExposureForProvinceEntry(
  Game game,
  PlayerView view,
  String playerId,
  MapEntry<String, List<String>> entry,
  Map<String, int> counts,
) {
  final province = tryGetProvince(game.worldState, entry.key);
  if (province == null) return;
  for (final tk in entry.value) {
    _bumpExposureForTile(game, view, playerId, tk, province, counts);
  }
}

Map<String, int> _exposureCountsByMineral(
  Game game,
  PlayerView view,
  String playerId,
) {
  final counts = <String, int>{for (final m in kMineralResourceIds) m: 0};
  for (final byProvince in game.worldState.tileKeysByRegionAndProvince.values) {
    for (final entry in byProvince.entries) {
      _bumpExposureForProvinceEntry(game, view, playerId, entry, counts);
    }
  }
  return counts;
}

Set<String> _mineralsWithMinExposure(Map<String, int> exposure) {
  if (exposure.isEmpty) return {};
  var minV = 1 << 30;
  for (final v in exposure.values) {
    if (v < minV) minV = v;
  }
  return exposure.entries
      .where((e) => e.value == minV)
      .map((e) => e.key)
      .toSet();
}

int _unknownTilesInExploreProvince(PlayerView view, Game game, WorkOrder w) {
  final provId = Unit.provinceIdFromTileKey(w.targetTileKey);
  if (provId == null) return 0;
  final regionId = ProvinceId.regionIdFrom(provId);
  final tiles =
      game.worldState.tileKeysByRegionAndProvince[regionId]?[provId] ??
      const <String>[];
  var u = 0;
  for (final tk in tiles) {
    if (view.visibilityForTile(tk) == VisibilityLevel.unknown) u++;
  }
  return u;
}

int _eScore(WorkOrder w, PlayerView view, Game game) {
  final unknown = _unknownTilesInExploreProvince(view, game, w);
  // Issue #2082: E_unknown = min(24, 3 × U), not min(24, unknown) on the tile count.
  int score = 100 + math.min(24, 3 * unknown);
  final provId = Unit.provinceIdFromTileKey(w.targetTileKey);
  if (provId != null && ProvinceId.regionIdFrom(provId) == kNewWorldRegionId) {
    score += kExploreWorkScoreBonusNewWorld;
  }
  return score;
}

int _prospectTerritoryPoints(
  Game game,
  PlayerView view,
  String playerId,
  String tileKey,
  DiplomacyFactionMembership factionMembership,
) {
  final provId = Unit.provinceIdFromTileKey(tileKey);
  if (provId == null) return 0;
  final p = tryGetProvince(game.worldState, provId);
  if (p == null) return 0;
  if (p.ownerId == playerId) return 32;
  final purchased =
      game.worldState.purchasedTilesByTileKey[tileKey] == playerId;
  if (purchased) return 20;
  final owner = p.ownerId;
  if (owner != null &&
      isMinorOrTribe(game, owner, factionMembership: factionMembership)) {
    return 12;
  }
  return 0;
}

Resource? _resourceByMineralId(String mId) {
  for (final r in Resource.values) {
    if (r.name == mId) return r;
  }
  return null;
}

bool _terrainHostsMineral(
  TerrainType terrain,
  String mId,
  ResourceRules rules,
) {
  final res = _resourceByMineralId(mId);
  if (res == null) return false;
  final allowed = rules.allowedTerrains[res];
  return allowed != null && allowed.contains(terrain);
}

bool _tileCanHostAnyMineralInSet(
  Map<String, TileMapResult>? tileMapByRegion,
  String tileKey,
  Set<String> mineralIds,
) {
  if (mineralIds.isEmpty) return false;
  final terrain = terrainTypeForTileKey(tileMapByRegion, tileKey);
  if (terrain == null) return false;
  final rules = ResourceRules.defaultRules;
  for (final mId in mineralIds) {
    if (_terrainHostsMineral(terrain, mId, rules)) return true;
  }
  return false;
}

/// Planner-internal prospect score boost applied to an **unprospected** mineral
/// feedstock resource tile when the player's feedstock-extraction gate is active
/// (Refs #2847 § H8-extraction mineral feedstock prospecting). A mineral
/// feedstock tile (e.g. `iron`) must be prospected before a Builder can
/// `build_improvement` it (`work_order_target_prechecks.dart`
/// § "Mineral tile must be prospected first"), so without an Explorer
/// prospecting it the Builder feedstock-extraction boost
/// ([kRegimentBuildInputFeedstockExtractionScoreBoost]) has no valid tile to
/// improve and the multi-input `castIron` recipe stays infeasible (`iron`
/// remains `0` on seed 42 while the surface `timber` tile is improved freely).
/// Sized to mirror the Builder feedstock boost so an Explorer prospects the
/// feedstock mineral tile ahead of ordinary explore / prospect work.
/// Planner-internal — not an `ai_victory_config.dart` constant — and gated by
/// the same self-clearing feedstock set, so healthy / above-quota Great Powers
/// are never routed.
const int kFeedstockMineralProspectScoreBoost = 600;

/// True when [tileKey] hosts a **mineral** resource in [feedstockIds] that
/// [playerId] has **not** prospected — the Explorer prospect target the H8
/// feedstock-extraction gate must route a unit onto before the Builder can
/// improve it. Read-only and deterministic over `(game, playerId, tileKey)`.
bool _isUnprospectedMineralFeedstockTile(
  Game game,
  String playerId,
  String tileKey,
  Set<String> feedstockIds,
) {
  if (feedstockIds.isEmpty) return false;
  final resourceId = game.worldState.resourceByTileKey[tileKey];
  if (resourceId == null || !feedstockIds.contains(resourceId)) return false;
  if (!kMineralResourceIds.contains(resourceId)) return false;
  final prospected =
      game.worldState.playerProspectedTiles[playerId] ?? const <String>{};
  return !prospected.contains(tileKey);
}

int _pScore(
  WorkOrder w,
  Game game,
  PlayerView view,
  String playerId,
  Map<String, TileMapResult>? tileMapByRegion,
  Set<String> sHigh,
  DiplomacyFactionMembership factionMembership, {
  Set<String> feedstockExtractionResourceIds = const <String>{},
}) {
  final base =
      25 +
      _prospectTerritoryPoints(
        game,
        view,
        playerId,
        w.targetTileKey,
        factionMembership,
      );
  final urgent =
      _tileCanHostAnyMineralInSet(tileMapByRegion, w.targetTileKey, sHigh)
      ? 95
      : 0;
  final feedstock =
      w.target == kWorkTargetProspect &&
          _isUnprospectedMineralFeedstockTile(
            game,
            playerId,
            w.targetTileKey,
            feedstockExtractionResourceIds,
          )
      ? kFeedstockMineralProspectScoreBoost
      : 0;
  return base + urgent + feedstock;
}

int _exploreTieCompare(WorkOrder w, WorkOrder best) {
  final tk = w.targetTileKey.compareTo(best.targetTileKey);
  if (tk != 0) return tk;
  final pw = Unit.provinceIdFromTileKey(w.targetTileKey) ?? '';
  final pb = Unit.provinceIdFromTileKey(best.targetTileKey) ?? '';
  return pw.compareTo(pb);
}

WorkOrder? _bestExploreRow(
  List<WorkOrder> explores,
  PlayerView view,
  Game game,
) {
  if (explores.isEmpty) return null;
  var best = explores.first;
  var bestScore = _eScore(best, view, game);
  for (var i = 1; i < explores.length; i++) {
    final w = explores[i];
    final s = _eScore(w, view, game);
    if (s > bestScore) {
      bestScore = s;
      best = w;
      continue;
    }
    if (s == bestScore && _exploreTieCompare(w, best) < 0) best = w;
  }
  return best;
}

WorkOrder? _bestProspectRow(
  List<WorkOrder> prospects,
  Game game,
  PlayerView view,
  String playerId,
  Map<String, TileMapResult>? tileMapByRegion,
  Set<String> sHigh,
  DiplomacyFactionMembership factionMembership, {
  Set<String> feedstockExtractionResourceIds = const <String>{},
}) {
  if (prospects.isEmpty) return null;
  var best = prospects.first;
  var bestScore = _pScore(
    best,
    game,
    view,
    playerId,
    tileMapByRegion,
    sHigh,
    factionMembership,
    feedstockExtractionResourceIds: feedstockExtractionResourceIds,
  );
  for (var i = 1; i < prospects.length; i++) {
    final w = prospects[i];
    final s = _pScore(
      w,
      game,
      view,
      playerId,
      tileMapByRegion,
      sHigh,
      factionMembership,
      feedstockExtractionResourceIds: feedstockExtractionResourceIds,
    );
    if (s > bestScore) {
      bestScore = s;
      best = w;
      continue;
    }
    if (s == bestScore && w.targetTileKey.compareTo(best.targetTileKey) < 0) {
      best = w;
    }
  }
  return best;
}

WorkOrder? _pickExplorerCandidateSet(
  List<WorkOrder> c,
  Game game,
  PlayerView view,
  String playerId,
  Map<String, TileMapResult>? tileMapByRegion,
  DiplomacyFactionMembership factionMembership, {
  Set<String> feedstockExtractionResourceIds = const <String>{},
}) {
  final explores = c.where((w) => w.target == kWorkTargetExplore).toList();
  final prospects = c.where((w) => w.target == kWorkTargetProspect).toList();
  final exposure = _exposureCountsByMineral(game, view, playerId);
  final sHigh = _mineralsWithMinExposure(exposure);
  final bestE = _bestExploreRow(explores, view, game);
  final bestP = _bestProspectRow(
    prospects,
    game,
    view,
    playerId,
    tileMapByRegion,
    sHigh,
    factionMembership,
    feedstockExtractionResourceIds: feedstockExtractionResourceIds,
  );
  if (bestE == null && bestP == null) return null;
  if (bestE == null) return bestP;
  if (bestP == null) return bestE;
  final eScore = _eScore(bestE, view, game);
  final pScore = _pScore(
    bestP,
    game,
    view,
    playerId,
    tileMapByRegion,
    sHigh,
    factionMembership,
    feedstockExtractionResourceIds: feedstockExtractionResourceIds,
  );
  if (eScore > pScore) return bestE;
  if (pScore > eScore) return bestP;
  return bestE;
}

/// Planner-internal score boost applied to an unimproved feedstock resource
/// tile when the [regimentBuildInputFeedstockExtractionResourceIds] gate is
/// active (Refs #2847 § H8-extraction). Sized above
/// [kBuildImprovementExtractableResourceScore] plus the New World resource
/// bonuses so a lock-recovery seller routes its Builder onto the feedstock
/// tile ahead of any other extractable improvement. Planner-internal — not an
/// `ai_victory_config.dart` constant — mirroring the economy-planner H8
/// production boost and the #2847 "no new config constants" scope constraint.
const int kRegimentBuildInputFeedstockExtractionScoreBoost = 600;

int _buildImprovementWorkScore(
  WorkOrder w,
  Game game, {
  required String playerId,
  Set<String> feedstockExtractionResourceIds = const <String>{},
}) {
  if (w.target != kWorkTargetBuildImprovement) return 0;
  final level = game.worldState.tileState.improvementLevel(w.targetTileKey);
  if (level >= 1) return 1;
  final resourceId = game.worldState.resourceByTileKey[w.targetTileKey];
  if (resourceId == null || resourceId.isEmpty) return 2;
  var score = kBuildImprovementExtractableResourceScore;
  if (Unit.regionIdFromTileKey(w.targetTileKey) == kNewWorldRegionId) {
    score += kBuildImprovementNewWorldResourceBonus;
    final provId = Unit.provinceIdFromTileKey(w.targetTileKey);
    if (provId != null &&
        tryGetProvince(game.worldState, provId)?.ownerId == playerId) {
      score += kBuildImprovementOwnedNewWorldResourceBonus;
    }
  }
  if (feedstockExtractionResourceIds.contains(resourceId)) {
    score += kRegimentBuildInputFeedstockExtractionScoreBoost;
  }
  return score;
}

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

/// The (at most) one idle Builder and one idle Explorer the active player must
/// keep in the Old World for H8 feedstock prospecting + extraction, instead of
/// letting them migrate to New World colonial work (Refs #2847 § H8-extraction
/// supplier Old World feedstock unit reservation).
///
/// The seed-42 affluent suppliers own an unimproved Old World `iron` / `timber`
/// feedstock tile on every gate-active turn, yet every idle Builder / Explorer
/// is routed to higher-scoring **New World** owned-resource work (the New World
/// bonuses in [_buildImprovementWorkScore] / [_eScore]), so the now-correct
/// prospecting / co-availability ordering chain never gets a unit positioned on
/// the Old World feedstock tile. Holding one idle Builder and one idle Explorer
/// out of New World work keeps them available for the Old World feedstock
/// `prospect` + `build_improvement` the existing
/// [kFeedstockMineralProspectScoreBoost] /
/// [kRegimentBuildInputFeedstockExtractionScoreBoost] boosts then select.
class _OwFeedstockReservation {
  const _OwFeedstockReservation({this.builderUnitId, this.explorerUnitId});

  final String? builderUnitId;
  final String? explorerUnitId;

  static const none = _OwFeedstockReservation();

  bool reserves(String unitId) =>
      unitId == builderUnitId || unitId == explorerUnitId;
}

/// Resolves the [_OwFeedstockReservation] for the active player.
///
/// Returns [_OwFeedstockReservation.none] unless the feedstock-extraction gate
/// is active ([feedstockExtractionResourceIds] non-empty). When active, reserves
/// the lexicographically-smallest idle (`currentWork == null`) Builder iff the
/// player owns an unimproved Old World feedstock tile, and the
/// lexicographically-smallest idle Explorer iff the player owns an unprospected
/// Old World mineral feedstock tile. Deterministic over
/// `(view.ownUnits, game, feedstockExtractionResourceIds)`.
_OwFeedstockReservation _resolveOwFeedstockReservation(
  PlayerView view,
  Game game,
  Set<String> feedstockExtractionResourceIds,
) {
  if (feedstockExtractionResourceIds.isEmpty) {
    return _OwFeedstockReservation.none;
  }
  final playerId = view.playerId;
  final reserveBuilder = _ownsUnimprovedOldWorldFeedstockTile(
    game,
    playerId,
    feedstockExtractionResourceIds,
  );
  final reserveExplorer = _ownsUnprospectedOldWorldMineralFeedstockTile(
    game,
    playerId,
    feedstockExtractionResourceIds,
  );
  if (!reserveBuilder && !reserveExplorer) return _OwFeedstockReservation.none;
  final idleBuilders = <String>[];
  final idleExplorers = <String>[];
  for (final unit in view.ownUnits) {
    if (unit.currentWork != null) continue;
    if (reserveBuilder && unit.type == kUnitTypeBuilder) {
      idleBuilders.add(unit.id);
    }
    if (reserveExplorer && isExplorerUnit(unit.type)) {
      idleExplorers.add(unit.id);
    }
  }
  idleBuilders.sort();
  idleExplorers.sort();
  return _OwFeedstockReservation(
    builderUnitId: idleBuilders.isEmpty ? null : idleBuilders.first,
    explorerUnitId: idleExplorers.isEmpty ? null : idleExplorers.first,
  );
}

/// Drops every New World `targetTileKey` work order from [orders] so a reserved
/// Old World feedstock unit is not routed to New World colonial work. Leaves the
/// unit with only its Old World candidates (or none, in which case it stays idle
/// in the Old World). Refs #2847 § H8-extraction supplier Old World feedstock
/// unit reservation.
void _dropNewWorldWorkOrders(List<WorkOrder> orders) {
  orders.removeWhere(
    (w) => Unit.regionIdFromTileKey(w.targetTileKey) == kNewWorldRegionId,
  );
}

WorkOrder? _bestBuildImprovementRow(
  List<WorkOrder> candidates,
  Game game, {
  required String playerId,
  Set<String> feedstockExtractionResourceIds = const <String>{},
}) {
  final improvements = candidates
      .where((w) => w.target == kWorkTargetBuildImprovement)
      .toList();
  if (improvements.isEmpty) return null;
  var best = improvements.first;
  var bestScore = _buildImprovementWorkScore(
    best,
    game,
    playerId: playerId,
    feedstockExtractionResourceIds: feedstockExtractionResourceIds,
  );
  for (var i = 1; i < improvements.length; i++) {
    final w = improvements[i];
    final s = _buildImprovementWorkScore(
      w,
      game,
      playerId: playerId,
      feedstockExtractionResourceIds: feedstockExtractionResourceIds,
    );
    if (s > bestScore) {
      bestScore = s;
      best = w;
      continue;
    }
    if (s == bestScore && _compareWorkOrderLex(w, best) < 0) {
      best = w;
    }
  }
  return best;
}

int _purchaseLandWorkScore(
  WorkOrder w,
  Game game,
  DiplomacyFactionMembership factionMembership,
) {
  if (w.target != kWorkTargetPurchaseLand) return 0;
  final provId = Unit.provinceIdFromTileKey(w.targetTileKey);
  if (provId == null || provId.isEmpty) return 1;
  if (ProvinceId.regionIdFrom(provId) == kNewWorldRegionId) {
    final ownerId = tryGetProvince(game.worldState, provId)?.ownerId;
    if (ownerId != null &&
        isMinorOrTribe(game, ownerId, factionMembership: factionMembership)) {
      return kPurchaseLandNewWorldTribeWorkScore;
    }
    return kPurchaseLandNewWorldOtherWorkScore;
  }
  return 60;
}

WorkOrder? _bestPurchaseLandRow(
  List<WorkOrder> candidates,
  Game game,
  DiplomacyFactionMembership factionMembership,
) {
  final purchases = candidates
      .where((w) => w.target == kWorkTargetPurchaseLand)
      .toList();
  if (purchases.isEmpty) return null;
  var best = purchases.first;
  var bestScore = _purchaseLandWorkScore(best, game, factionMembership);
  for (var i = 1; i < purchases.length; i++) {
    final w = purchases[i];
    final s = _purchaseLandWorkScore(w, game, factionMembership);
    if (s > bestScore) {
      bestScore = s;
      best = w;
      continue;
    }
    if (s == bestScore && _compareWorkOrderLex(w, best) < 0) {
      best = w;
    }
  }
  return best;
}

void _appendBuilderPathResult({
  required Unit? unit,
  required List<WorkOrder> w,
  required Game game,
  required String playerId,
  required List<WorkOrder> workOrders,
  required List<FullAiCivilianWorkIdle> idleEvents,
  Set<String> feedstockExtractionResourceIds = const <String>{},
}) {
  final chosen =
      _bestBuildImprovementRow(
        w,
        game,
        playerId: playerId,
        feedstockExtractionResourceIds: feedstockExtractionResourceIds,
      ) ??
      _pickLexicographic(w);
  if (chosen != null) {
    workOrders.add(chosen);
    return;
  }
  if (unit == null) return;
  idleEvents.add(
    FullAiCivilianWorkIdle(
      unitId: unit.id,
      unitType: unit.type,
      reason: 'no_suggestions',
    ),
  );
}

void _appendMerchantPathResult({
  required Unit? unit,
  required List<WorkOrder> w,
  required Game game,
  required DiplomacyFactionMembership factionMembership,
  required List<WorkOrder> workOrders,
  required List<FullAiCivilianWorkIdle> idleEvents,
}) {
  final chosen =
      _bestPurchaseLandRow(w, game, factionMembership) ?? _pickLexicographic(w);
  if (chosen != null) {
    workOrders.add(chosen);
    return;
  }
  if (unit == null) return;
  idleEvents.add(
    FullAiCivilianWorkIdle(
      unitId: unit.id,
      unitType: unit.type,
      reason: 'no_suggestions',
    ),
  );
}

WorkOrder? _pickLexicographic(List<WorkOrder> w) {
  if (w.isEmpty) return null;
  final copy = List<WorkOrder>.from(w)..sort(_compareWorkOrderLex);
  return copy.first;
}

bool _explorerOnlySuggestions(List<WorkOrder> w) {
  if (w.isEmpty) return false;
  return w.every(
    (o) => o.target == kWorkTargetExplore || o.target == kWorkTargetProspect,
  );
}

void _appendExplorerPathResult({
  required Unit? unit,
  required List<WorkOrder> w,
  required Game game,
  required PlayerView view,
  required String playerId,
  Map<String, TileMapResult>? tileMapByRegion,
  required DiplomacyFactionMembership factionMembership,
  required List<WorkOrder> workOrders,
  required List<FullAiCivilianWorkIdle> idleEvents,
  Set<String> feedstockExtractionResourceIds = const <String>{},
}) {
  final c = w
      .where(
        (o) =>
            o.target == kWorkTargetExplore || o.target == kWorkTargetProspect,
      )
      .toList();
  if (c.isEmpty) {
    if (unit == null) return;
    idleEvents.add(
      FullAiCivilianWorkIdle(
        unitId: unit.id,
        unitType: unit.type,
        reason: 'no_suggestions',
      ),
    );
    return;
  }
  final chosen = _pickExplorerCandidateSet(
    c,
    game,
    view,
    playerId,
    tileMapByRegion,
    factionMembership,
    feedstockExtractionResourceIds: feedstockExtractionResourceIds,
  );
  if (chosen != null) {
    workOrders.add(chosen);
    return;
  }
  if (unit == null) return;
  idleEvents.add(
    FullAiCivilianWorkIdle(
      unitId: unit.id,
      unitType: unit.type,
      reason: 'no_suggestions',
    ),
  );
}

void _appendLexicographicPathResult({
  required Unit? unit,
  required List<WorkOrder> w,
  required List<WorkOrder> workOrders,
  required List<FullAiCivilianWorkIdle> idleEvents,
}) {
  if (w.isEmpty) {
    if (unit == null) return;
    idleEvents.add(
      FullAiCivilianWorkIdle(
        unitId: unit.id,
        unitType: unit.type,
        reason: 'no_suggestions',
      ),
    );
    return;
  }
  final chosen = _pickLexicographic(w);
  if (chosen == null) return;
  workOrders.add(chosen);
}

void _appendSelectionForUnitId({
  required String unitId,
  required Map<String, List<WorkOrder>> byUnit,
  required PlayerView view,
  required Game game,
  Map<String, TileMapResult>? tileMapByRegion,
  required DiplomacyFactionMembership factionMembership,
  required List<WorkOrder> workOrders,
  required List<FullAiCivilianWorkIdle> idleEvents,
  Set<String> feedstockExtractionResourceIds = const <String>{},
  _OwFeedstockReservation reservation = _OwFeedstockReservation.none,
}) {
  final W = List<WorkOrder>.from(byUnit[unitId] ?? const <WorkOrder>[]);
  _sortWorkOrdersLex(W);
  final unit = view.ownUnitsById[unitId];

  if (unit != null &&
      (unit.currentWork != null || !_civilianWorkCapableType(unit.type))) {
    return;
  }

  // Refs #2847 § H8-extraction: a reserved Old World feedstock unit keeps only
  // its Old World candidates so it is not routed to higher-scoring New World
  // colonial work, staying available for the Old World feedstock prospect /
  // build_improvement the feedstock score boosts then select.
  if (reservation.reserves(unitId)) {
    _dropNewWorldWorkOrders(W);
  }

  final isExplorerCase = unit != null && isExplorerUnit(unit.type);
  final orphanExplorerScoring =
      unit == null && W.isNotEmpty && _explorerOnlySuggestions(W);

  if (isExplorerCase || orphanExplorerScoring) {
    _appendExplorerPathResult(
      unit: unit,
      w: W,
      game: game,
      view: view,
      playerId: view.playerId,
      tileMapByRegion: tileMapByRegion,
      factionMembership: factionMembership,
      workOrders: workOrders,
      idleEvents: idleEvents,
      feedstockExtractionResourceIds: feedstockExtractionResourceIds,
    );
    return;
  }

  if (unit != null && unit.type == kUnitTypeBuilder) {
    _appendBuilderPathResult(
      unit: unit,
      w: W,
      game: game,
      playerId: view.playerId,
      workOrders: workOrders,
      idleEvents: idleEvents,
      feedstockExtractionResourceIds: feedstockExtractionResourceIds,
    );
    return;
  }

  if (unit != null && isMerchantUnit(unit.type)) {
    _appendMerchantPathResult(
      unit: unit,
      w: W,
      game: game,
      factionMembership: factionMembership,
      workOrders: workOrders,
      idleEvents: idleEvents,
    );
    return;
  }

  _appendLexicographicPathResult(
    unit: unit,
    w: W,
    workOrders: workOrders,
    idleEvents: idleEvents,
  );
}

/// Selects per-unit civilian work for Full AI from [workSuggestions].
FullAiCivilianWorkSelectionResult selectFullAiCivilianWorkOrders({
  required List<WorkOrder> workSuggestions,
  required PlayerView view,
  required Game game,
  Map<String, TileMapResult>? tileMapByRegion,
}) {
  final byUnit = <String, List<WorkOrder>>{};
  for (final w in workSuggestions) {
    byUnit.putIfAbsent(w.unitId, () => <WorkOrder>[]).add(w);
  }
  for (final list in byUnit.values) {
    _sortWorkOrdersLex(list);
  }

  final suggestionUnitIds = byUnit.keys.toList()..sort();
  final idleCivilianIds = view.ownUnits
      .where((u) => u.currentWork == null && _civilianWorkCapableType(u.type))
      .map((u) => u.id)
      .toList();
  final allUnitIds = {...suggestionUnitIds, ...idleCivilianIds}.toList()
    ..sort();

  final workOrders = <WorkOrder>[];
  final idleEvents = <FullAiCivilianWorkIdle>[];
  final factionMembership = DiplomacyFactionMembership.from(game);
  final feedstockExtractionResourceIds =
      feedstockExtractionResourceIdsForPlayer(game, view.playerId);
  final reservation = _resolveOwFeedstockReservation(
    view,
    game,
    feedstockExtractionResourceIds,
  );

  for (final unitId in allUnitIds) {
    _appendSelectionForUnitId(
      unitId: unitId,
      byUnit: byUnit,
      view: view,
      game: game,
      tileMapByRegion: tileMapByRegion,
      factionMembership: factionMembership,
      workOrders: workOrders,
      idleEvents: idleEvents,
      feedstockExtractionResourceIds: feedstockExtractionResourceIds,
      reservation: reservation,
    );
  }

  workOrders.sort(_compareWorkOrderLex);
  return FullAiCivilianWorkSelectionResult(
    workOrders: workOrders,
    idleEvents: idleEvents,
  );
}
