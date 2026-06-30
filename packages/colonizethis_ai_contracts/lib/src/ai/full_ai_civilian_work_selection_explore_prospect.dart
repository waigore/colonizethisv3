part of 'full_ai_civilian_work_selection.dart';

// Explorer / prospect candidate scoring and per-row selection for Full AI
// civilian work (mineral exposure balancing, explore/prospect scoring, and the
// best-explore / best-prospect / combined explorer-candidate pickers). Split
// out of full_ai_civilian_work_selection.dart by concern to keep each library
// file small; shares the parent library's private scope via `part`.

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
  final province = game.worldState.tryGetProvince(entry.key);
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
  final p = game.worldState.tryGetProvince(provId);
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

// The Explorer mineral-feedstock prospect score boost
// ([kFeedstockMineralProspectScoreBoost]) is a GA-tunable constant in
// `ai_victory_config.dart` / `ai_parameter_registry.dart` (Refs #3794). A
// mineral feedstock tile (e.g. `iron`) must be prospected before a Builder can
// `build_improvement` it, so an Explorer prospects the feedstock mineral tile
// ahead of ordinary explore / prospect work; behaviour is normative in
// SPEC/ai/civilian-work-planner.md.

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
