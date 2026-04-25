// SPEC/program/game-setup-pipeline.md, fog-and-exploration-resolution.md.
// Initial player visibility and tile/resource indexing from generated maps.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../constants.dart';
import '../world/fog_resolution.dart';
import '../world/player_view.dart';
import '../world/province_lookup.dart';

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
  final nwSeaZoneIds =
      topologyByRegion[kRegionNewWorld]?.nodes
          .where((n) => n.type == TopologyNodeType.seaZone)
          .map((n) => n.id)
          .toSet() ??
      {};

  final ownerById = <String, String?>{
    for (final p in allProvinces(game.worldState))
      ProvinceId.full(p.regionId, ProvinceId.localIdFrom(p.id)): p.ownerId,
  };

  final playerVisibilityByTile = <String, Map<String, String>>{};
  final playerProspectedTiles = <String, Set<String>>{};

  final tileKeysByRegionAndProvince = <String, Map<String, List<String>>>{
    kRegionOldWorld: <String, List<String>>{},
    kRegionNewWorld: <String, List<String>>{},
  };
  final resourceByTileKey = <String, String>{};
  for (var y = 0; y < owMap.height; y++) {
    for (var x = 0; x < owMap.width; x++) {
      final localId = owMap.cell(x, y);
      final fullId = ProvinceId.full(kRegionOldWorld, localId);
      // Include all tiles (land and sea) in tileKeysByRegionAndProvince.
      // Land tiles: use province fullId. Sea tiles: use canonical prefixed id.
      final provinceKey = fullId;
      final tileKey = '$kRegionOldWorld|$localId|$x|$y';
      tileKeysByRegionAndProvince[kRegionOldWorld]!
          .putIfAbsent(provinceKey, () => <String>[])
          .add(tileKey);
      final res = owMap.resourceAt(x, y);
      if (res != null) resourceByTileKey[tileKey] = res.name;
    }
  }
  for (var y = 0; y < nwMap.height; y++) {
    for (var x = 0; x < nwMap.width; x++) {
      final localId = nwMap.cell(x, y);
      final fullId = ProvinceId.full(kRegionNewWorld, localId);
      final provinceKey = fullId;
      final tileKey = '$kRegionNewWorld|$localId|$x|$y';
      tileKeysByRegionAndProvince[kRegionNewWorld]!
          .putIfAbsent(provinceKey, () => <String>[])
          .add(tileKey);
      final res = nwMap.resourceAt(x, y);
      if (res != null) resourceByTileKey[tileKey] = res.name;
    }
  }

  for (final player in game.players) {
    final playerId = player.id;
    final visibility = <String, String>{};

    // Old World: land tiles are fogged (own provinces fully visible), sea tiles are fogged.
    for (var y = 0; y < owMap.height; y++) {
      for (var x = 0; x < owMap.width; x++) {
        final localId = owMap.cell(x, y);
        final fullId = ProvinceId.full(kRegionOldWorld, localId);
        final isSea = owSeaZoneIds.contains(localId);
        final ownerId = ownerById[fullId];
        final tileKey = '$kRegionOldWorld|$localId|$x|$y';
        if (isSea) {
          // Old World sea zones: fogged for all players.
          visibility[tileKey] = VisibilityLevel.fogged.name;
        } else if (ownerId != null) {
          // Land tiles: own provinces fully visible, others fogged.
          visibility[tileKey] = ownerId == playerId
              ? VisibilityLevel.fullyVisible.name
              : VisibilityLevel.fogged.name;
        }
      }
    }

    // New World: all tiles start unknown.
    for (var y = 0; y < nwMap.height; y++) {
      for (var x = 0; x < nwMap.width; x++) {
        final localId = nwMap.cell(x, y);
        final tileKey = '$kRegionNewWorld|$localId|$x|$y';
        visibility[tileKey] = VisibilityLevel.unknown.name;
      }
    }

    playerVisibilityByTile[playerId] = visibility;
    playerProspectedTiles[playerId] = <String>{};
  }

  final updatedWorldState = game.worldState.copyWith(
    playerVisibilityByTile: playerVisibilityByTile,
    playerProspectedTiles: playerProspectedTiles,
    tileKeysByRegionAndProvince: tileKeysByRegionAndProvince,
    resourceByTileKey: resourceByTileKey,
  );
  var resultGame = game.copyWith(worldState: updatedWorldState);

  // Apply coastal sea zone full visibility for Great Powers.
  // SPEC/program/fog-and-exploration-resolution.md § Coastal sea zone full visibility.
  final combinedTopology = _buildCombinedTopology(topologyByRegion);
  final visibilityAfterCoastal = applyCoastalSeaZoneFullVisibility(
    resultGame,
    playerVisibilityByTile,
    combinedTopology,
    topologyByRegion: topologyByRegion,
  );

  resultGame = resultGame.copyWith(
    worldState: resultGame.worldState.copyWith(
      playerVisibilityByTile: visibilityAfterCoastal,
    ),
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
