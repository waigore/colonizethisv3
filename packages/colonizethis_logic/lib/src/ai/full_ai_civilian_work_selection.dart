import 'dart:math' as math;

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../constants.dart';
import '../diplomacy/diplomacy_resolver.dart';
import '../orders/build_rail_work_rules.dart';
import '../world/player_view.dart';
import '../world/province_lookup.dart';

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
  if (provId != null &&
      ProvinceId.regionIdFrom(provId) == kNewWorldRegionId) {
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

int _pScore(
  WorkOrder w,
  Game game,
  PlayerView view,
  String playerId,
  Map<String, TileMapResult>? tileMapByRegion,
  Set<String> sHigh,
  DiplomacyFactionMembership factionMembership,
) {
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
  return base + urgent;
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
  DiplomacyFactionMembership factionMembership,
) {
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
  DiplomacyFactionMembership factionMembership,
) {
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
  );
  if (eScore > pScore) return bestE;
  if (pScore > eScore) return bestP;
  return bestE;
}

int _buildImprovementWorkScore(
  WorkOrder w,
  Game game, {
  required String playerId,
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
  return score;
}

WorkOrder? _bestBuildImprovementRow(
  List<WorkOrder> candidates,
  Game game, {
  required String playerId,
}) {
  final improvements = candidates
      .where((w) => w.target == kWorkTargetBuildImprovement)
      .toList();
  if (improvements.isEmpty) return null;
  var best = improvements.first;
  var bestScore = _buildImprovementWorkScore(best, game, playerId: playerId);
  for (var i = 1; i < improvements.length; i++) {
    final w = improvements[i];
    final s = _buildImprovementWorkScore(w, game, playerId: playerId);
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
  final purchases =
      candidates.where((w) => w.target == kWorkTargetPurchaseLand).toList();
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
}) {
  final chosen =
      _bestBuildImprovementRow(w, game, playerId: playerId) ??
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
}) {
  final W = List<WorkOrder>.from(byUnit[unitId] ?? const <WorkOrder>[]);
  _sortWorkOrdersLex(W);
  final unit = view.ownUnitsById[unitId];

  if (unit != null &&
      (unit.currentWork != null || !_civilianWorkCapableType(unit.type))) {
    return;
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
    );
  }

  workOrders.sort(_compareWorkOrderLex);
  return FullAiCivilianWorkSelectionResult(
    workOrders: workOrders,
    idleEvents: idleEvents,
  );
}
