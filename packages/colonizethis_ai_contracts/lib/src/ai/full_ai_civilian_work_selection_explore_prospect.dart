import 'dart:math' as math;

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_orders/colonizethis_orders.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import '../constants.dart';
import 'full_ai_civilian_work_selection_explore_prospect_exposure.dart';
import 'full_ai_civilian_work_selection_feedstock_predicates.dart';
import 'full_ai_civilian_work_selection_shared.dart';

// Explorer / prospect candidate scoring and per-row selection for Full AI
// civilian work (mineral exposure balancing, explore/prospect scoring, and the
// best-explore / best-prospect / combined explorer-candidate pickers). Split
// out of full_ai_civilian_work_selection.dart by concern to keep each library
// file small.

int unknownTilesInExploreProvince(PlayerView view, Game game, WorkOrder w) {
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

int exploreWorkScore(WorkOrder w, PlayerView view, Game game) {
  final unknown = unknownTilesInExploreProvince(view, game, w);
  // Issue #2082: E_unknown = min(24, 3 × U), not min(24, unknown) on the tile count.
  int score = 100 + math.min(24, 3 * unknown);
  final provId = Unit.provinceIdFromTileKey(w.targetTileKey);
  if (provId != null && ProvinceId.regionIdFrom(provId) == kNewWorldRegionId) {
    score += kExploreWorkScoreBonusNewWorld;
  }
  return score;
}

int prospectTerritoryPoints(
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

Resource? resourceByMineralId(String mId) {
  for (final r in Resource.values) {
    if (r.name == mId) return r;
  }
  return null;
}

bool terrainHostsMineral(
  TerrainType terrain,
  String mId,
  ResourceRules rules,
) {
  final res = resourceByMineralId(mId);
  if (res == null) return false;
  final allowed = rules.allowedTerrains[res];
  return allowed != null && allowed.contains(terrain);
}

bool tileCanHostAnyMineralInSet(
  Map<String, TileMapResult>? tileMapByRegion,
  String tileKey,
  Set<String> mineralIds,
) {
  if (mineralIds.isEmpty) return false;
  final terrain = terrainTypeForTileKey(tileMapByRegion, tileKey);
  if (terrain == null) return false;
  final rules = ResourceRules.defaultRules;
  for (final mId in mineralIds) {
    if (terrainHostsMineral(terrain, mId, rules)) return true;
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

int prospectWorkScore(
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
      prospectTerritoryPoints(
        game,
        view,
        playerId,
        w.targetTileKey,
        factionMembership,
      );
  final urgent =
      tileCanHostAnyMineralInSet(tileMapByRegion, w.targetTileKey, sHigh)
      ? 95
      : 0;
  final feedstock =
      w.target == kWorkTargetProspect &&
          isUnprospectedMineralFeedstockTile(
            game,
            playerId,
            w.targetTileKey,
            feedstockExtractionResourceIds,
          )
      ? kFeedstockMineralProspectScoreBoost
      : 0;
  return base + urgent + feedstock;
}

int exploreTieCompare(WorkOrder w, WorkOrder best) {
  final tk = w.targetTileKey.compareTo(best.targetTileKey);
  if (tk != 0) return tk;
  final pw = Unit.provinceIdFromTileKey(w.targetTileKey) ?? '';
  final pb = Unit.provinceIdFromTileKey(best.targetTileKey) ?? '';
  return pw.compareTo(pb);
}

WorkOrder? bestExploreRow(
  List<WorkOrder> explores,
  PlayerView view,
  Game game,
) {
  return bestScoredWorkRow(
    explores,
    scoreOf: (w) => exploreWorkScore(w, view, game),
    compareTieBreak: exploreTieCompare,
  );
}

WorkOrder? bestProspectRow(
  List<WorkOrder> prospects,
  Game game,
  PlayerView view,
  String playerId,
  Map<String, TileMapResult>? tileMapByRegion,
  Set<String> sHigh,
  DiplomacyFactionMembership factionMembership, {
  Set<String> feedstockExtractionResourceIds = const <String>{},
}) {
  return bestScoredWorkRow(
    prospects,
    scoreOf: (w) => prospectWorkScore(
      w,
      game,
      view,
      playerId,
      tileMapByRegion,
      sHigh,
      factionMembership,
      feedstockExtractionResourceIds: feedstockExtractionResourceIds,
    ),
    compareTieBreak: (a, b) => a.targetTileKey.compareTo(b.targetTileKey),
  );
}

WorkOrder? pickExplorerCandidateSet(
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
  final exposure = exposureCountsByMineral(game, view, playerId);
  final sHigh = mineralsWithMinExposure(exposure);
  final bestE = bestExploreRow(explores, view, game);
  final bestP = bestProspectRow(
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
  final eScore = exploreWorkScore(bestE, view, game);
  final pScore = prospectWorkScore(
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
