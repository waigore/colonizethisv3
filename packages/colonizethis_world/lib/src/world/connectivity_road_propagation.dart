/// Road-rule tile BFS for capital connectivity (first and port-expansion passes).
/// Standalone library (wave 5 slice B, Refs #4125) so propagation can be tested
/// without port-expansion / town-closure wiring.
library;

import 'dart:collection';

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'connectivity_metrics.dart';
import 'connectivity_tile_helpers.dart';
import 'package:colonizethis_world/src/utils/graph_traversal.dart';

/// Tile-grid BFS with per-tile transport caps. Shared by the capital-seed pass
/// and the sea-connected port expansion pass.
void runConnectivityRoadPropagation({
  required Queue<String> queue,
  required Set<String> connected,
  required Map<String, int> pathCap,
  required WorldState worldState,
  required Map<String, (String, String)> portTileToProvinceSeaZone,
  required Map<String, TileMapResult> tileMapByRegion,
  required Set<String> provinceIdsByType,
  required Set<String> ownedProvinceIds,
  required bool Function(String tileKey) canExpandFrom,
  ConnectivityHotPathMetrics? metrics,
}) {
  propagateConnectivityBottleneckQueue(
    queue: queue,
    connected: connected,
    pathCap: pathCap,
    onDequeue: metrics?.recordConnectivityBottleneckDequeue,
    shouldExpandEdgesFrom: (key) {
      final coords = parseTileKeyCoordinates(key);
      if (coords == null) return false;
      final fullProvinceId = '${coords.regionId}|${coords.provinceLocalId}';
      if (coords.x < 0 || coords.y < 0) return false;
      if (!ownedProvinceIds.contains(fullProvinceId)) return false;
      final map = tileMapByRegion[coords.regionId];
      if (map == null) return false;
      return canExpandFrom(key);
    },
    neighborsOf: (key) {
      final coords = parseTileKeyCoordinates(key);
      if (coords == null) return const <String>[];
      if (coords.x < 0 || coords.y < 0) return const <String>[];
      final map = tileMapByRegion[coords.regionId];
      if (map == null) return const <String>[];
      return adjacentTileKeys(
        coords.regionId,
        coords.provinceLocalId,
        coords.x,
        coords.y,
        map,
        provinceIdsByType,
      );
    },
    transportLevelAt: (neighbor) =>
        transportLevelAtTile(worldState, neighbor, portTileToProvinceSeaZone),
  );
}
