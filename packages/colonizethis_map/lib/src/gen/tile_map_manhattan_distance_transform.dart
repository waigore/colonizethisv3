import 'dart:math' show min;

import '../tile_map_grid.dart';

/// Exact grid Manhattan (L1) distance from each cell to the nearest coordinate
/// in [sources].
///
/// Duplicate coordinates in [sources] are ignored. When [sources] is empty,
/// every cell receives [distanceWhenNoSources] (same contract as
/// [manhattanDistToNearestSourceXY] when no cell satisfies [isSource]).
///
/// Refs #2489 (organic land-seed close-sea scoring: one transform per placement
/// instead of per-cell scans over growing seed lists).
List<List<int>> manhattanDistToNearestPoints(
  int width,
  int height,
  Iterable<(int x, int y)> sources, {
  required int distanceWhenNoSources,
}) {
  final sourceCells = <(int, int)>{};
  for (final p in sources) {
    sourceCells.add((p.$1, p.$2));
  }
  if (sourceCells.isEmpty) {
    if (width <= 0 || height <= 0) {
      return [];
    }
    return TileMapGrid.filled(height, width, distanceWhenNoSources);
  }
  return manhattanDistToNearestSourceXY(
    width,
    height,
    (x, y) => sourceCells.contains((x, y)),
    distanceWhenNoSources: distanceWhenNoSources,
  );
}

/// Exact grid Manhattan (L1) distance from each cell to the nearest cell where
/// [isSource] is true.
///
/// When no cell satisfies [isSource], every cell is set to [distanceWhenNoSources]
/// so callers can preserve legacy sentinel semantics.
List<List<int>> manhattanDistToNearestSourceXY(
  int width,
  int height,
  bool Function(int x, int y) isSource, {
  required int distanceWhenNoSources,
}) {
  if (width <= 0 || height <= 0) {
    return [];
  }
  const inf = 1 << 30;
  final dist = TileMapGrid.generate(
    height,
    width,
    (y, x) => isSource(x, y) ? 0 : inf,
  );
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      var d = dist[y][x];
      if (y > 0) {
        d = min(d, dist[y - 1][x] + 1);
      }
      if (x > 0) {
        d = min(d, dist[y][x - 1] + 1);
      }
      dist[y][x] = d;
    }
  }
  for (var y = height - 1; y >= 0; y--) {
    for (var x = width - 1; x >= 0; x--) {
      var d = dist[y][x];
      if (y + 1 < height) {
        d = min(d, dist[y + 1][x] + 1);
      }
      if (x + 1 < width) {
        d = min(d, dist[y][x + 1] + 1);
      }
      dist[y][x] = d;
    }
  }
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      if (dist[y][x] >= inf) {
        dist[y][x] = distanceWhenNoSources;
      }
    }
  }
  return dist;
}
