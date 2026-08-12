/// Shared Engineer work-order scoring (road / port / fort).
/// SPEC/ai/civilian-work-planner.md + SPEC/program/development-counsel-ranking.md.
library;

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import 'connectivity_dev_snapshot.dart';
import 'order_work_constants.dart';

bool isEngineerWorkTarget(String target) =>
    target == kWorkTargetBuildRoad ||
    target == kWorkTargetBuildPort ||
    target == kWorkTargetBuildFort;

/// Deterministic score for an Engineer `build_road` / `build_port` / `build_fort`
/// candidate. Returns `0` for non-Engineer targets.
int engineerWorkScore(
  WorkOrder w,
  Game game, {
  required String playerId,
  ConnectivityDevSnapshot? connectivityDev,
}) {
  final resourceId = game.worldState.resourceByTileKey[w.targetTileKey];
  final hasResource = resourceId != null && resourceId.isNotEmpty;
  final capitalProvinceId = game.playerById(playerId)?.capitalProvinceId;
  final provinceId = Unit.provinceIdFromTileKey(w.targetTileKey);
  final inCapital =
      capitalProvinceId != null &&
      provinceId != null &&
      provinceId == capitalProvinceId;
  final inNewWorld =
      Unit.regionIdFromTileKey(w.targetTileKey) == kNewWorldRegionId;
  switch (w.target) {
    case kWorkTargetBuildRoad:
      var score = kEngineerBuildRoadBaseWorkScore;
      if (hasResource) score += kEngineerRoadResourceConnectivityBonus;
      if (inCapital) score += kEngineerRoadCapitalLogisticsBonus;
      if (connectivityDev != null &&
          connectivityDev.hasUnconnectedDevTargets &&
          connectivityDev.frontierExtensionTiles.contains(w.targetTileKey)) {
        score += kEngineerFrontierRoadExtensionBonus;
      }
      return score;
    case kWorkTargetBuildPort:
      var score = kEngineerBuildPortBaseWorkScore;
      if (hasResource) score += kEngineerPortResourceExtractionBonus;
      if (inNewWorld) score += kEngineerPortNewWorldCoastalBonus;
      if (connectivityDev != null &&
          connectivityDev.hasUnconnectedDevTargets &&
          provinceId != null &&
          connectivityDev.provincesWithUnconnectedDevTargets.contains(
            provinceId,
          )) {
        score += kEngineerPortOverseasLinkageBonus;
      }
      return score;
    case kWorkTargetBuildFort:
      var score = kEngineerBuildFortBaseWorkScore;
      if (inCapital) score += kEngineerFortCapitalDefenseBonus;
      if (inNewWorld) score += kEngineerFortNewWorldBorderBonus;
      return score;
  }
  return 0;
}

/// Stable secondary ordering for equally scored Engineer candidates.
int compareEngineerWorkCandidates(WorkOrder a, WorkOrder b) {
  final pa = Unit.provinceIdFromTileKey(a.targetTileKey) ?? '';
  final pb = Unit.provinceIdFromTileKey(b.targetTileKey) ?? '';
  final p = pa.compareTo(pb);
  if (p != 0) return p;
  final t = a.targetTileKey.compareTo(b.targetTileKey);
  if (t != 0) return t;
  return a.target.compareTo(b.target);
}

/// Highest-scoring Engineer candidate, or null when none.
WorkOrder? bestEngineerWorkOrder(
  List<WorkOrder> candidates,
  Game game, {
  required String playerId,
  ConnectivityDevSnapshot? connectivityDev,
}) {
  final engineerCandidates = candidates
      .where((w) => isEngineerWorkTarget(w.target))
      .toList();
  if (engineerCandidates.isEmpty) return null;
  var best = engineerCandidates.first;
  var bestScore = engineerWorkScore(
    best,
    game,
    playerId: playerId,
    connectivityDev: connectivityDev,
  );
  for (var i = 1; i < engineerCandidates.length; i++) {
    final w = engineerCandidates[i];
    final s = engineerWorkScore(
      w,
      game,
      playerId: playerId,
      connectivityDev: connectivityDev,
    );
    if (s > bestScore) {
      bestScore = s;
      best = w;
      continue;
    }
    if (s == bestScore && compareEngineerWorkCandidates(w, best) < 0) {
      best = w;
    }
  }
  return best;
}
