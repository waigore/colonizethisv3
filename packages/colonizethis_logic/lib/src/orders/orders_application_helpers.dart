import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

/// Helpers for order application. SPEC/program/orders.md, development-resolution.
/// Used by orders_application for work and build phases.

/// Whether the tile is eligible for mineral-related work (prospect, build_improvement).
/// Uses terrain from [tileMapByRegion] when available; otherwise resource id from [game].
bool isMineralEligibleTile(
  Game game,
  Map<String, TileMapResult>? tileMapByRegion,
  String tileKey,
) {
  const mineralTerrains = {
    TerrainType.swamp,
    TerrainType.hills,
    TerrainType.mountain,
    TerrainType.desert,
  };

  if (tileMapByRegion != null && tileMapByRegion.isNotEmpty) {
    final parts = tileKey.split('|');
    if (parts.length == 4) {
      final regionId = parts[0];
      final x = int.tryParse(parts[2]);
      final y = int.tryParse(parts[3]);
      final tileMap = tileMapByRegion[regionId];
      if (tileMap != null && x != null && y != null) {
        final terrain = tileMap.terrainAt(x, y);
        if (terrain != null) {
          return mineralTerrains.contains(terrain);
        }
      }
    }
  }

  final resourceId = game.worldState.resourceByTileKey[tileKey];
  if (resourceId == null || resourceId.isEmpty) {
    return false;
  }
  const mineralIds = {
    'iron',
    'copper',
    'tin',
    'coal',
    'silver',
    'gold',
    'gems',
    'diamonds',
  };
  return mineralIds.contains(resourceId);
}
