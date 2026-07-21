import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../build_rail_work_rules.dart';
import '../order_validation_result.dart';
import '../unit_type_helpers.dart';
import 'work_order_target_prechecks_shared.dart';

OrderValidationResult? precheckBuildImprovement(
  WorkOrderTargetPrecheckContext ctx,
  WorkOrder o,
  String? targetProvinceId,
  String? ownerId,
  String unitType,
) {
  final accessRejection = rejectIfUncontrolledWithoutEmbassyWork(
    ctx,
    o.targetTileKey,
    unitType: unitType,
    provinceOwnerId: ownerId,
    message: 'Cannot build improvement in foreign or uncontrolled province',
  );
  if (accessRejection != null) return accessRejection;
  final resourceGate = resourceOrMineralRejection(
    ctx,
    o.targetTileKey,
    emptyResourceMessage:
        'Tile has no resource; build_improvement requires a resource on the tile',
  );
  if (resourceGate.rejection != null) return resourceGate.rejection;
  final resourceId = resourceGate.resourceId;
  if (resourceId == null) {
    return OrderValidationResult.rejected(
      'Tile has no resource; build_improvement requires a resource on the tile',
    );
  }
  final currentLevel = ctx.game.worldState.improvementLevelAtTile(
    o.targetTileKey,
  );
  if (currentLevel >= 4) {
    return OrderValidationResult.rejected(
      'Improvement level already at maximum (4)',
    );
  }
  final techCap = extractionCapForResourceForUnlocked(
    ctx.player.techUnlocked,
    resourceId,
  );
  final terrain = terrainTypeForTileKey(
    ctx.tileMapByRegion,
    o.targetTileKey,
  );
  final effectiveCap = terrain == null
      ? techCap
      : clampExtractionCapForTerrain(techCap, resourceId, terrain);
  if (terrain != null && effectiveCap < techCap && currentLevel + 1 > effectiveCap) {
    return OrderValidationResult.rejected(
      'Terrain caps $resourceId extraction at level $effectiveCap on this '
      'terrain (scrub forest timber is hard-capped at level 1)',
    );
  }
  if (currentLevel + 1 > effectiveCap) {
    return OrderValidationResult.rejected(
      'Insufficient tech for next improvement level on $resourceId '
      '(extraction cap $effectiveCap; unlock gathering tech to raise the cap)',
    );
  }
  return null;
}

OrderValidationResult? precheckDevExclusiveTileConflict(
  WorkOrderTargetPrecheckContext ctx,
  WorkOrder order,
  String? targetProvinceId,
  String? provinceOwnerId,
  String unitType,
) {
  if (!isDevExclusiveUnitType(unitType) ||
      !isDevExclusiveWorkTarget(order.target)) {
    return null;
  }
  if (!ctx.devExclusiveTiles.contains(order.targetTileKey)) {
    return null;
  }
  return OrderValidationResult.rejected(
    'Tile already has development or purchase work for this player',
  );
}
