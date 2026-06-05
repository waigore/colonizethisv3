import 'dart:math' as math;

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../constants.dart';
import '../diplomacy/diplomacy_resolver.dart';
import '../orders/build_rail_work_rules.dart';
import '../world/player_view.dart';
import '../world/province_lookup.dart';
import '../world/unit_lookup.dart';

part 'full_ai_civilian_work_selection_feedstock.dart';

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
