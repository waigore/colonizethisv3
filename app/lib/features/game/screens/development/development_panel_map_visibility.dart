import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

/// Builds per-tile visibility for Development panel map (player-constrained).
///
/// When [regionId] is set, only tiles in that region are included (Slice E).
Map<String, TileVisibility> developmentPanelVisibilityByTile({
  required Game game,
  required PlayerView playerView,
  String? regionId,
}) {
  final visibilityByTile = <String, TileVisibility>{};
  for (final entry in game.worldState.tileKeysByRegionAndProvince.entries) {
    if (regionId != null && entry.key != regionId) continue;
    for (final tileKeys in entry.value.values) {
      for (final tileKey in tileKeys) {
        visibilityByTile[tileKey] = switch (playerView.visibilityForTile(tileKey)) {
          VisibilityLevel.fullyVisible => TileVisibility.visible,
          VisibilityLevel.fogged => TileVisibility.fogged,
          VisibilityLevel.unknown => TileVisibility.unrevealed,
        };
      }
    }
  }
  return visibilityByTile;
}

/// Land tile keys owned by [playerId] in [regionId] (provinces + purchased).
Set<String> developmentPanelPlayerTerritoryTileKeys({
  required Game game,
  required String playerId,
  required String regionId,
  required Map<String, TileMapResult> tileMapByRegion,
}) {
  final keys = <String>{};
  final ownerCache = ProvinceOwnerCache.of(game.worldState);
  for (final province in ownerCache.provincesOwnedByInRegion(playerId, regionId)) {
    final tileKeys =
        game.worldState.tileKeysByRegionAndProvince[regionId]?[province.id] ??
            const <String>[];
    for (final tileKey in tileKeys) {
      if (_isLandTile(tileKey, tileMapByRegion)) {
        keys.add(tileKey);
      }
    }
  }
  for (final entry in game.worldState.purchasedTilesByTileKey.entries) {
    if (entry.value != playerId) continue;
    if (!entry.key.startsWith('$regionId|')) continue;
    if (_isLandTile(entry.key, tileMapByRegion)) {
      keys.add(entry.key);
    }
  }
  return keys;
}

bool _isLandTile(
  String tileKey,
  Map<String, TileMapResult> tileMapByRegion,
) {
  final parts = tileKey.split('|');
  if (parts.length < 4) return false;
  final regionId = parts[0];
  final localProvinceId = parts[1];
  final x = int.tryParse(parts[2]);
  final y = int.tryParse(parts[3]);
  if (x == null || y == null) return false;
  final map = tileMapByRegion[regionId];
  if (map == null) return false;
  if (x < 0 || y < 0 || x >= map.width || y >= map.height) return false;
  return map.grid[y][x] == localProvinceId;
}
