// SPEC/game/capital-and-connectivity.md § Init town roads / Capital Setup;
// SPEC/program/game-setup-pipeline.md.
//
// Package-internal source of truth for 4-neighbor grid BFS over setup tile
// grids. Both road-geometry sites previously carried near-identical breadth
// first searches with inline `'$x|$y'` coord-key strings, bounds checks, and
// parent-map path reconstruction:
//   - init_town_roads.dart `_bfsParentsFromCapital` / `_addPathTilesToSet`
//   - capital_choice_port_road_geometry.dart `_shortestPathOnProvinceTiles`
// init_town_roads.dart even documented that its neighbor ordering was kept
// aligned with `_shortestPathOnProvinceTiles`. Centralising the skeleton here
// keeps the deterministic [kGridNeighborsCardinal4] visit order and parent-map
// shape byte-identical across both consumers.

import 'dart:collection';

import 'package:colonizethis_world/colonizethis_world.dart';

/// Canonical 2D coordinate key `'$x|$y'` used by the shared grid BFS. Single
/// source of truth for the previously inlined coord-key interpolations.
String gridCoordKey(int x, int y) => '$x|$y';

/// Whether the grid cell at ([x], [y]) may be entered during a BFS expansion.
typedef GridTilePassable = bool Function(int x, int y);

/// Breadth-first search over a 2D grid in [kGridNeighborsCardinal4] neighbor
/// order from ([startX], [startY]). The start cell is always enqueued (its
/// passability is never tested); every other cell is entered only when
/// [passable] returns `true`.
///
/// Returns a parent map keyed by [gridCoordKey] where the start maps to itself
/// (identity). Unreachable cells are absent (except the start). Reconstruct an
/// ordered path with [reconstructGridPath].
Map<String, (int, int)> bfsGridParents({
  required int startX,
  required int startY,
  required int width,
  required int height,
  required GridTilePassable passable,
}) {
  final start = (startX, startY);
  final parent = <String, (int, int)>{gridCoordKey(startX, startY): start};
  final queue = Queue<(int, int)>()..add(start);
  while (queue.isNotEmpty) {
    final (cx, cy) = queue.removeFirst();
    for (final d in kGridNeighborsCardinal4) {
      final nx = cx + d.$1;
      final ny = cy + d.$2;
      if (nx < 0 || nx >= width || ny < 0 || ny >= height) continue;
      if (!passable(nx, ny)) continue;
      final nkey = gridCoordKey(nx, ny);
      if (parent.containsKey(nkey)) continue;
      parent[nkey] = (cx, cy);
      queue.add((nx, ny));
    }
  }
  return parent;
}

/// Reconstructs the coordinate path from ([toX], [toY]) back to the BFS start
/// using [parents] (from [bfsGridParents]), returned start..end inclusive.
///
/// Returns `null` when ([toX], [toY]) was never reached (absent from
/// [parents]). The start cell terminates the walk because it maps to itself.
List<(int, int)>? reconstructGridPath({
  required Map<String, (int, int)> parents,
  required int toX,
  required int toY,
}) {
  if (!parents.containsKey(gridCoordKey(toX, toY))) return null;
  final path = <(int, int)>[];
  var cur = (toX, toY);
  while (true) {
    path.insert(0, cur);
    final pr = parents[gridCoordKey(cur.$1, cur.$2)];
    if (pr == null || (pr.$1 == cur.$1 && pr.$2 == cur.$2)) break;
    cur = pr;
  }
  return path;
}

/// 4-neighbor breadth-first **distances** (in grid steps) from ([startX],
/// [startY]) over the grid implied by [coordToKey] — a [gridCoordKey] -> canonical
/// tile-key map. A neighbor cell is entered iff [coordToKey] has an entry for its
/// [gridCoordKey]; the returned map is keyed by those tile keys (the start tile at
/// distance 0), so callers that track tile keys (not coordinates) consume it
/// directly. Returns an empty map when the start coordinate is absent from
/// [coordToKey].
///
/// Distances are 4-neighbor step counts and therefore independent of neighbor
/// visit order; routing through [kGridNeighborsCardinal4] keeps the single
/// canonical neighbor set (shared with [bfsGridParents]) without affecting
/// results. Single source of truth for the standalone distance BFS the town
/// assignment site previously inlined with raw `'$x|$y'` keys and an ad-hoc
/// cardinal-delta array.
Map<String, int> bfsGridDistances({
  required int startX,
  required int startY,
  required Map<String, String> coordToKey,
}) {
  final result = <String, int>{};
  final startTile = coordToKey[gridCoordKey(startX, startY)];
  if (startTile == null) return result;
  final queue = Queue<(int, int, int)>()..add((startX, startY, 0));
  result[startTile] = 0;
  while (queue.isNotEmpty) {
    final (cx, cy, dist) = queue.removeFirst();
    for (final d in kGridNeighborsCardinal4) {
      final nx = cx + d.$1;
      final ny = cy + d.$2;
      final tile = coordToKey[gridCoordKey(nx, ny)];
      if (tile == null || result.containsKey(tile)) continue;
      result[tile] = dist + 1;
      queue.add((nx, ny, dist + 1));
    }
  }
  return result;
}
