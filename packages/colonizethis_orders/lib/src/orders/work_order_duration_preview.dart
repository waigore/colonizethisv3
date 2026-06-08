import 'dart:math';

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'order_work_constants.dart';
import 'package:colonizethis_world/src/world/province_lookup.dart';

/// Returns deterministic assign-time total turns for a pending civilian work
/// order preview shown before turn resolution.
///
/// The return value is always at least `1` for UI display consistency.
int previewTotalTurnsForPendingWorkOrder({
  required Game game,
  required Unit unit,
  required WorkOrder order,
}) {
  if (order.target == kWorkTargetCounterSpy) {
    return 1;
  }
  if (order.target == kWorkTargetExplore) {
    return _previewExploreTurns(game: game, unit: unit, order: order);
  }
  if (order.target == kWorkTargetBuildFort) {
    final provinceId =
        Unit.provinceIdFromTileKey(order.targetTileKey) ??
        unit.locationProvinceId;
    final fortLevel =
        tryGetProvince(game.worldState, provinceId)?.fortLevel ?? 0;
    return max(1, totalTurnsForWork(order.target, fortLevel: fortLevel));
  }
  if (order.target == kWorkTargetBuildImprovement) {
    final level = game.worldState.tileState.improvementLevel(
      order.targetTileKey,
    );
    return max(1, totalTurnsForWork(order.target, improvementLevel: level));
  }
  return max(1, totalTurnsForWork(order.target));
}

int _previewExploreTurns({
  required Game game,
  required Unit unit,
  required WorkOrder order,
}) {
  final targetRegionId =
      Unit.regionIdFromTileKey(order.targetTileKey) ??
      Unit.regionIdFromTileKey(unit.tileKey) ??
      ProvinceId.regionIdFrom(unit.locationProvinceId);
  final targetProvinceId =
      Unit.provinceIdFromTileKey(order.targetTileKey) ??
      unit.locationProvinceId;
  final byProvince =
      game.worldState.tileKeysByRegionAndProvince[targetRegionId];
  if (byProvince == null || byProvince.isEmpty) return 1;

  final tilesInProvince = byProvince[targetProvinceId]?.length ?? 0;
  if (tilesInProvince <= 0) return 1;

  var maxTiles = 1;
  for (final tileKeys in byProvince.values) {
    if (tileKeys.length > maxTiles) {
      maxTiles = tileKeys.length;
    }
  }
  return (3 * tilesInProvince / maxTiles).ceil().clamp(1, 999);
}
