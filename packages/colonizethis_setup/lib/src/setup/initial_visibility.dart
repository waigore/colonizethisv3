// SPEC/program/game-setup-pipeline.md, fog-and-exploration-resolution.md.
// Initial player visibility and tile/resource indexing from generated maps.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_world/colonizethis_world.dart';

import 'tile_cell_scan.dart';

void _indexTileMapIntoProvinceBuckets({
  required TileMapResult map,
  required String regionId,
  required Map<String, List<String>> bucket,
  required Map<String, String> resourceByTileKey,
}) {
  forEachTileCell(map, regionId, (x, y, localId, tileKey) {
    final provinceKey = ProvinceId.full(regionId, localId);
    bucket.putIfAbsent(provinceKey, () => <String>[]).add(tileKey);
    final res = map.resourceAt(x, y);
    if (res != null) resourceByTileKey[tileKey] = res.name;
  });
}

Map<String, String> _buildOldWorldVisibilityForPlayer({
  required TileMapResult owMap,
  required Set<String> owSeaZoneIds,
  required Map<String, String?> ownerById,
  required String playerId,
}) {
  final visibility = <String, String>{};
  forEachTileCell(owMap, kRegionOldWorld, (x, y, localId, tileKey) {
    final isSea = owSeaZoneIds.contains(localId);
    if (isSea) {
      visibility[tileKey] = VisibilityLevel.fogged.name;
      return;
    }
    final fullId = ProvinceId.full(kRegionOldWorld, localId);
    final ownerId = ownerById[fullId];
    if (ownerId != null) {
      visibility[tileKey] = ownerId == playerId
          ? VisibilityLevel.fullyVisible.name
          : VisibilityLevel.fogged.name;
    }
  });
  return visibility;
}

void _fillNewWorldUnknownVisibility({
  required TileMapResult nwMap,
  required Map<String, String> visibility,
}) {
  forEachTileCell(nwMap, kRegionNewWorld, (x, y, localId, tileKey) {
    visibility[tileKey] = VisibilityLevel.unknown.name;
  });
}

/// Applies initial visibility and tile metadata to [game] using [tileMapByRegion].
/// Own provinces: fullyVisible (OW) or unknown (NW). Others: fogged (OW).
/// Sea zones: fogged (OW), unknown (NW).
/// Then applies coastal sea zone full visibility for Great Powers.
/// Builds tileKeysByRegionAndProvince and resourceByTileKey for resolution.
Game applyInitialVisibility({
  required Game game,
  required Map<String, TileMapResult> tileMapByRegion,
  required Map<String, MapTopology> topologyByRegion,
}) {
  final owMap = tileMapByRegion[kRegionOldWorld];
  final nwMap = tileMapByRegion[kRegionNewWorld];
  if (owMap == null || nwMap == null) return game;

  // Collect sea zone IDs from topology for each region.
  final owSeaZoneIds =
      topologyByRegion[kRegionOldWorld]?.nodes
          .where((n) => n.type == TopologyNodeType.seaZone)
          .map((n) => n.id)
          .toSet() ??
      {};

  final ownerById = <String, String?>{
    for (final p in allProvinces(game.worldState))
      (ProvinceId.isPrefixed(p.id) ? p.id : ProvinceId.full(p.regionId, p.id)):
          p.ownerId,
  };

  final playerVisibilityByTile = <String, Map<String, String>>{};
  final playerProspectedTiles = <String, Set<String>>{};

  final tileKeysByRegionAndProvince = <String, Map<String, List<String>>>{
    kRegionOldWorld: <String, List<String>>{},
    kRegionNewWorld: <String, List<String>>{},
  };
  final resourceByTileKey = <String, String>{};
  _indexTileMapIntoProvinceBuckets(
    map: owMap,
    regionId: kRegionOldWorld,
    bucket: tileKeysByRegionAndProvince[kRegionOldWorld]!,
    resourceByTileKey: resourceByTileKey,
  );
  _indexTileMapIntoProvinceBuckets(
    map: nwMap,
    regionId: kRegionNewWorld,
    bucket: tileKeysByRegionAndProvince[kRegionNewWorld]!,
    resourceByTileKey: resourceByTileKey,
  );

  for (final player in game.players) {
    final playerId = player.id;
    final visibility = _buildOldWorldVisibilityForPlayer(
      owMap: owMap,
      owSeaZoneIds: owSeaZoneIds,
      ownerById: ownerById,
      playerId: playerId,
    );
    _fillNewWorldUnknownVisibility(nwMap: nwMap, visibility: visibility);

    playerVisibilityByTile[playerId] = visibility;
    playerProspectedTiles[playerId] = <String>{};
  }

  final updatedWorldState = game.worldState.copyWith(
    playerVisibilityByTile: playerVisibilityByTile,
    playerProspectedTiles: playerProspectedTiles,
    tileKeysByRegionAndProvince: tileKeysByRegionAndProvince,
    resourceByTileKey: resourceByTileKey,
  );
  var resultGame = game.withWorldState(updatedWorldState);

  // Apply coastal sea zone full visibility for Great Powers.
  // SPEC/program/fog-and-exploration-resolution.md § Coastal sea zone full visibility.
  final combinedTopology = _buildCombinedTopology(topologyByRegion);
  final visibilityAfterCoastal = applyCoastalSeaZoneFullVisibility(
    resultGame,
    playerVisibilityByTile,
    combinedTopology,
    topologyByRegion: topologyByRegion,
  );

  resultGame = resultGame.updateWorldState(
    (ws) => ws.copyWith(playerVisibilityByTile: visibilityAfterCoastal),
  );

  return resultGame;
}

/// Builds a combined topology from per-region topologies for use in
/// coastal sea zone visibility resolution.
MapTopology _buildCombinedTopology(Map<String, MapTopology> topologyByRegion) {
  final allNodes = <TopologyNode>[];
  final allEdges = <TopologyEdge>[];
  for (final topology in topologyByRegion.values) {
    allNodes.addAll(topology.nodes);
    allEdges.addAll(topology.edges);
  }
  return MapTopology(nodes: allNodes, edges: allEdges);
}
