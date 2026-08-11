import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import 'development_panel_map_visibility.dart';

/// Immutable map payload for the Development panel minimap (Slice E).
class DevelopmentPanelMapSnapshot {
  const DevelopmentPanelMapSnapshot({
    required this.region,
    required this.playerTerritoryTileKeys,
  });

  final RegionMapViewData region;
  final Set<String> playerTerritoryTileKeys;
}

/// Cache key for [DevelopmentPanelMapSnapshot]; excludes highlight-only inputs.
Object developmentPanelMapSnapshotCacheKey({
  required Game game,
  required String humanPlayerId,
  required String regionId,
  required PlayerView playerView,
}) {
  final visibility = <String, VisibilityLevel>{};
  for (final entry in playerView.visibilityByTile.entries) {
    if (!entry.key.startsWith('$regionId|')) continue;
    visibility[entry.key] = entry.value;
  }
  final visibilityDigest = Object.hashAll(
    visibility.entries
        .map((e) => Object.hash(e.key, e.value.index))
        .toList()
      ..sort(),
  );
  return (
    game.id,
    game.worldState.turnState.turnNumber,
    humanPlayerId,
    regionId,
    visibilityDigest,
    game.worldState.tileKeysByRegionAndProvince[regionId]?.length ?? 0,
    game.worldState.purchasedTilesByTileKey.length,
  );
}

/// Builds panel-map view data for one region (expensive; cache across highlights).
DevelopmentPanelMapSnapshot buildDevelopmentPanelMapSnapshot({
  required Game game,
  required String humanPlayerId,
  required String regionId,
  required PlayerView playerView,
  required Map<String, TileMapResult> tileMapByRegion,
  required Map<String, MapTopology> topologyByRegion,
}) {
  final visibilityByTile = developmentPanelVisibilityByTile(
    game: game,
    playerView: playerView,
    regionId: regionId,
  );
  final region = buildInitGameMapRegionViewData(
    regionId: regionId,
    game: game,
    tileMapByRegion: tileMapByRegion,
    topologyByRegion: topologyByRegion,
    cellSize: 12,
    visibilityByTile: visibilityByTile,
  );
  final playerTerritoryTileKeys = developmentPanelPlayerTerritoryTileKeys(
    game: game,
    playerId: humanPlayerId,
    regionId: regionId,
    tileMapByRegion: tileMapByRegion,
  );
  return DevelopmentPanelMapSnapshot(
    region: region,
    playerTerritoryTileKeys: playerTerritoryTileKeys,
  );
}
