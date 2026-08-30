/// DEVELOP-phase planner (Refs #2509 S4 / S10).
///
/// Improve owned land only. Dispatch: `SPEC/ai/phase-planner-dispatch.md`.
/// NW suppression AC: `SPEC/ai/phase-planner-architecture.md`.
library;

import '../perception/perception_snapshot.dart';
import 'planning_imports.dart';
import 'planning_helpers.dart';

/// Every at-war Great Power, sorted ascending. No exceptions.
List<String> planDevelopPeace({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
  return gpFactionIdsAtWarWith(game, snapshot);
}

/// `build_improvement` orders for idle Builders on owned extractable tiles.
///
/// Same-region Manhattan pairing (no naval Builder transport). Scoring
/// matches logic-side civilian constants. `SPEC/ai/phase-planner-architecture.md`.
List<WorkOrder> planDevelopCivilian({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
  final playerId = snapshot.playerId;
  final world = game.worldState;

  final ownedProvinceIds = <String>{};
  final townTileKeys = <String>{};
  for (final province in ProvinceOwnerCache.of(
    world,
  ).provincesOwnedBy(playerId)) {
    ownedProvinceIds.add(province.id);
    final townTileKey = province.townTileKey;
    if (townTileKey != null && townTileKey.isNotEmpty) {
      townTileKeys.add(townTileKey);
    }
  }
  if (ownedProvinceIds.isEmpty) {
    return const [];
  }

  final builders = <Unit>[
    for (final unit in allUnitsFromWorld(world))
      if (unit.ownerId == playerId &&
          unit.type == kUnitTypeBuilder &&
          unit.status == UnitStatus.idle)
        unit,
  ]..sort((a, b) => a.id.compareTo(b.id));
  if (builders.isEmpty) {
    return const [];
  }

  final tileState = world.tileState;
  final eligibleTileKeys = <String>[];
  for (final entry in world.resourceByTileKey.entries) {
    final tileKey = entry.key;
    final resourceId = entry.value;
    if (resourceId.isEmpty) continue;
    final provinceId = Unit.provinceIdFromTileKey(tileKey);
    if (provinceId == null || !ownedProvinceIds.contains(provinceId)) {
      continue;
    }
    if (townTileKeys.contains(tileKey)) continue;
    if (tileState.improvementLevel(tileKey) >= 1) continue;
    eligibleTileKeys.add(tileKey);
  }
  if (eligibleTileKeys.isEmpty) {
    return const [];
  }

  eligibleTileKeys.sort((a, b) {
    final scoreCmp = _developCivilianTileScore(
      b,
    ).compareTo(_developCivilianTileScore(a));
    if (scoreCmp != 0) return scoreCmp;
    return a.compareTo(b);
  });

  final assignedBuilderIds = <String>{};
  final orders = <WorkOrder>[];
  for (final tileKey in eligibleTileKeys) {
    if (assignedBuilderIds.length == builders.length) break;
    final tileRegionId = Unit.regionIdFromTileKey(tileKey);
    if (tileRegionId == null || tileRegionId.isEmpty) continue;
    final tileXy = _xyFromTileKey(tileKey);
    if (tileXy == null) continue;

    Unit? best;
    int? bestDistance;
    for (final builder in builders) {
      if (assignedBuilderIds.contains(builder.id)) continue;
      final builderTileKey = builder.tileKey;
      if (builderTileKey == null || builderTileKey.isEmpty) continue;
      if (Unit.regionIdFromTileKey(builderTileKey) != tileRegionId) continue;
      final builderXy = _xyFromTileKey(builderTileKey);
      if (builderXy == null) continue;
      final distance =
          (builderXy.x - tileXy.x).abs() + (builderXy.y - tileXy.y).abs();
      if (best == null || distance < bestDistance!) {
        best = builder;
        bestDistance = distance;
      }
    }
    if (best == null) continue;
    orders.add(
      WorkOrder(
        unitId: best.id,
        target: kWorkTargetBuildImprovement,
        targetTileKey: tileKey,
      ),
    );
    assignedBuilderIds.add(best.id);
  }
  return orders;
}

/// `(x, y)` from `regionId|localId|x|y` without importing colonizethis_logic.
({int x, int y})? _xyFromTileKey(String tileKey) {
  final parts = tileKey.split('|');
  if (parts.length < 4) return null;
  final x = int.tryParse(parts[2]);
  final y = int.tryParse(parts[3]);
  if (x == null || y == null) return null;
  return (x: x, y: y);
}

/// Tile score for [planDevelopCivilian] (logic-side civilian constants).
int _developCivilianTileScore(String tileKey) {
  var score = kBuildImprovementExtractableResourceScore;
  if (Unit.regionIdFromTileKey(tileKey) == kNewWorldRegionId) {
    score += kBuildImprovementNewWorldResourceBonus;
    score += kBuildImprovementOwnedNewWorldResourceBonus;
  }
  return score;
}
