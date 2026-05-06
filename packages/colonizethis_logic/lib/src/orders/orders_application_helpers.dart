import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../constants.dart';
import 'build_rail_work_rules.dart';

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
