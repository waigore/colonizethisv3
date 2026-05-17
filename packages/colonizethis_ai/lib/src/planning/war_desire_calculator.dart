import 'dart:math' as math;

import 'package:colonizethis_logic/ai_api.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

int computeWarDesireScore({
  required Game game,
  required String nationId,
  required String targetFactionId,
  required int relationScore,
}) {
  final attackerPower = greatPowerPowerScore(game, nationId);
  final targetPower = greatPowerPowerScore(game, targetFactionId);
  final targetPowerSafe = targetPower <= 0 ? 1 : targetPower;
  final strengthRatio = attackerPower / targetPowerSafe;
  var score = 50;

  if (strengthRatio >= 1.35) {
    score += 30;
  } else if (strengthRatio >= 0.85) {
    score += 5;
  } else {
    score -= 25;
  }

  if (relationScore >= 70) {
    score -= 40;
  } else if (relationScore >= 50) {
    score -= 20;
  } else if (relationScore <= 25) {
    score += 10;
  }

  final targetIsMinorOrTribe =
      game.minorNations.any((m) => m.id == targetFactionId) ||
      game.tribes.any((t) => t.id == targetFactionId);
  if (targetIsMinorOrTribe) {
    score += _resourceNeedBonus(game, nationId, targetFactionId);
    score += _interventionRiskPenalty(game, nationId, targetFactionId);
    score += _invasionCapacityAdjustment(game, nationId, targetFactionId);
  }

  return score.clamp(0, 100);
}

int _resourceNeedBonus(Game game, String nationId, String targetFactionId) {
  final ownedResourceIds = <String>{};
  final player = game.playerById(nationId);
  if (player != null) {
    for (final entry in player.stockpile.quantities.entries) {
      if (entry.value > 0) ownedResourceIds.add(entry.key);
    }
  }
  final targetResourceIds = <String>{};
  final byRegion = game.worldState.tileKeysByRegionAndProvince;
  for (final p in allProvinces(game.worldState)) {
    if (p.ownerId != targetFactionId) continue;
    final tiles = byRegion[p.regionId]?[p.id] ?? const <String>[];
    for (final tileKey in tiles) {
      final resource = game.worldState.resourceByTileKey[tileKey];
      if (resource != null && resource.isNotEmpty) {
        targetResourceIds.add(resource);
      }
    }
  }
  final missing = targetResourceIds
      .where((id) => !ownedResourceIds.contains(id))
      .length;
  return (missing * 5).clamp(0, 15);
}

int _interventionRiskPenalty(
  Game game,
  String nationId,
  String targetFactionId,
) {
  var count = 0;
  for (final overture in game.overtureStates) {
    if (overture.targetId != targetFactionId) continue;
    if (overture.gpId == nationId) continue;
    if (!overture.hasEmbassy) continue;
    if (game.players.any((p) => p.id == overture.gpId)) count++;
  }
  return -(count * 8).clamp(0, 24);
}

int _invasionCapacityAdjustment(
  Game game,
  String nationId,
  String targetFactionId,
) {
  final ownRegiments = allUnitsFromWorld(
    game.worldState,
  ).where((u) => u.ownerId == nationId).length;
  final targetRegiments = allUnitsFromWorld(
    game.worldState,
  ).where((u) => u.ownerId == targetFactionId).length;
  var score = 0;
  if (ownRegiments < math.max(2, targetRegiments ~/ 2)) {
    score -= 20;
  } else if (ownRegiments > targetRegiments) {
    score += 10;
  }

  final ownRegionIds = allProvinces(
    game.worldState,
  ).where((p) => p.ownerId == nationId).map((p) => p.regionId).toSet();
  final targetRegionIds = allProvinces(
    game.worldState,
  ).where((p) => p.ownerId == targetFactionId).map((p) => p.regionId).toSet();
  final requiresOverseas = targetRegionIds.any(
    (id) => !ownRegionIds.contains(id),
  );
  if (requiresOverseas && shipCountForFaction(game, nationId) <= 0) {
    score -= 25;
  }

  final activeWars = game.diplomacyRelations
      .where((r) => r.involvesNation(nationId) && r.atWar)
      .length;
  if (activeWars >= 2) score -= 15;
  return score;
}
