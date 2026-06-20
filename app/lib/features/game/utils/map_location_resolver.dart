// Tile keys for centering the map on provinces and sea zones from game UI.
// SPEC/ui/military-units-panel.md, SPEC/ui/naval-units-panel.md.

import 'package:colonizethis_app/core/utils/prefixed_id.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_map/colonizethis_map.dart' show seaZoneCentroidTileKey;
import 'package:colonizethis_models/colonizethis_models.dart';

Set<String> _seaZoneLocalIdsForRegion(MapTopology topology, String regionId) {
  return {
    for (final n in topology.nodes)
      if (n.type == TopologyNodeType.seaZone && n.regionId == regionId) n.id,
  };
}

/// Resolves the tile key to use when centering on [province] (town tile or first tile).
/// Uses `(regionId, province.id)` via [Province.regionId] and prefixed map keys.
/// Returns null if no tile can be resolved.
String? tileKeyForProvinceLocation(Game game, Province province) {
  final prefixedId = '${province.regionId}|${province.id}';
  if (province.townTileKey != null && province.townTileKey!.isNotEmpty) {
    return province.townTileKey;
  }
  final byProvince =
      game.worldState.tileKeysByRegionAndProvince[province.regionId];
  final tiles = byProvince?[prefixedId] ?? byProvince?[province.id];
  if (tiles != null && tiles.isNotEmpty) return tiles.first;
  return null;
}

/// Resolves a port tile key adjacent to the given sea zone in [regionId].
/// [seaZoneId] may be prefixed (`regionId|localId`) or local. Returns null if none.
String? tileKeyForSeaZoneLocation(
  Game game,
  String regionId,
  String seaZoneId,
) {
  final localSeaZone = prefixedIdLocalSegment(seaZoneId);
  for (final e in game.worldState.portsByProvinceSeaboard.entries) {
    final key = e.key;
    final firstPipe = key.indexOf('|');
    if (firstPipe <= 0 || firstPipe + 1 >= key.length) continue;
    final lastPipe = key.lastIndexOf('|');
    final keyRegion = key.substring(0, firstPipe);
    final keySeaZone = key.substring(lastPipe + 1);
    if (keyRegion == regionId && keySeaZone == localSeaZone) {
      return e.value;
    }
  }
  return null;
}

/// Sea fleets: centroid tile on the region tile map when [tileMap] / [regionTopology]
/// are available; otherwise falls back to [tileKeyForSeaZoneLocation] (port adjacency).
String? tileKeyForNavalFleetAtSea({
  required Game game,
  required String regionId,
  required String seaZoneId,
  TileMapResult? tileMap,
  MapTopology? regionTopology,
}) {
  final local = prefixedIdLocalSegment(seaZoneId);
  if (tileMap != null && regionTopology != null) {
    final nodeIds = _seaZoneLocalIdsForRegion(regionTopology, regionId);
    final centroid = seaZoneCentroidTileKey(
      tileMap: tileMap,
      regionId: regionId,
      localSeaZoneId: local,
      seaZoneNodeIds: nodeIds,
    );
    if (centroid != null) {
      return centroid;
    }
  }
  return tileKeyForSeaZoneLocation(game, regionId, seaZoneId);
}
