import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../constants.dart';
import 'package:colonizethis_world/src/world/tile_key_coordinates.dart' as tile_key_coordinates;
import 'build_rail_work_rules.dart';

/// Canonical tile-key coordinate parser for `regionId|provinceId|x|y`.
({String regionId, String provinceLocalId, int x, int y})?
parseTileKeyCoordinates(String tileKey) {
  return tile_key_coordinates.parseTileKeyCoordinates(tileKey);
}

/// Clears active work state for a unit and restores its pre-assignment tile.
Unit cancelUnitWork(Unit unit, {String? restoredTile}) {
  final restored = restoredTile ?? unit.originTileKey ?? unit.tileKey;
  return unit.copyWith(
    status: UnitStatus.idle,
    tileKey: restored,
    clearCurrentWork: true,
    clearOriginTileKey: true,
    clearAssignedTileKey: true,
  );
}

/// Helpers for order application. SPEC/program/orders.md, development-resolution.
/// Used by orders_application for work and build phases.

/// Whether the tile is eligible for mineral-related work (prospect, build_improvement).
///
/// When [game.worldState.resourceByTileKey] has a known resource that is not a
/// prospect-required mineral, returns false even if [tileMapByRegion] shows
/// prospectable terrain (e.g. wool on hills). Missing/unknown resource uses
/// prospectable terrain from [tileMapByRegion] when available; otherwise falls
/// back to mineral ids on the tile only.
bool isMineralEligibleTile(
  Game game,
  Map<String, TileMapResult>? tileMapByRegion,
  String tileKey,
) {
  final terrain = terrainTypeForTileKey(tileMapByRegion, tileKey);
  final resourceId = game.worldState.resourceByTileKey[tileKey];
  final hasResource = resourceId != null && resourceId.isNotEmpty;

  if (hasResource) {
    if (!kMineralResourceIds.contains(resourceId)) {
      return false;
    }
    if (terrain != null) {
      return isProspectableTerrain(terrain);
    }
    return true;
  }

  if (terrain != null) {
    return isProspectableTerrain(terrain);
  }
  return false;
}
