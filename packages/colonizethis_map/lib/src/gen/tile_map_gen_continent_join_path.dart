/// Sea-path BFS and adjacent-province resolution for continent joining.
/// SPEC/program/tile-map-gen-algorithm.md.
library;

import '../tile_map_directions.dart';
import '../tile_map_grid.dart';

/// Shortest BFS path of [seaZoneId] cells between two land components.
List<(int x, int y)> shortestSeaPathBetweenLandComponents({
  required List<List<String>> grid,
  required String seaZoneId,
  required Set<(int x, int y)> compA,
  required Set<(int x, int y)> compB,
  required int width,
  required int height,
}) {
  final seaAdjacentToA = <(int x, int y)>{};
  for (final (x, y) in compA) {
    for (final (dx, dy) in kTileMapDirections4NorthSouthWestEast) {
      final nx = x + dx;
      final ny = y + dy;
      if (nx >= 0 &&
          nx < width &&
          ny >= 0 &&
          ny < height &&
          grid[ny][nx] == seaZoneId) {
        seaAdjacentToA.add((nx, ny));
      }
    }
  }
  final seaAdjacentToB = <(int x, int y)>{};
  for (final (x, y) in compB) {
    for (final (dx, dy) in kTileMapDirections4NorthSouthWestEast) {
      final nx = x + dx;
      final ny = y + dy;
      if (nx >= 0 &&
          nx < width &&
          ny >= 0 &&
          ny < height &&
          grid[ny][nx] == seaZoneId) {
        seaAdjacentToB.add((nx, ny));
      }
    }
  }
  if (seaAdjacentToA.isEmpty || seaAdjacentToB.isEmpty) return [];
  final prev = <(int x, int y), (int x, int y)?>{};
  final queue = <(int x, int y)>[];
  for (final p in seaAdjacentToA) {
    prev[p] = null;
    queue.add(p);
  }
  (int x, int y)? goal;
  while (queue.isNotEmpty && goal == null) {
    final (x, y) = queue.removeAt(0);
    if (seaAdjacentToB.contains((x, y))) {
      goal = (x, y);
      break;
    }
    for (final (dx, dy) in kTileMapDirections4NorthSouthWestEast) {
      final nx = x + dx;
      final ny = y + dy;
      if (nx < 0 || nx >= width || ny < 0 || ny >= height) {
        continue;
      }
      if (grid[ny][nx] != seaZoneId) continue;
      final next = (nx, ny);
      if (prev.containsKey(next)) continue;
      prev[next] = (x, y);
      queue.add(next);
    }
  }
  if (goal == null) return [];
  final path = <(int x, int y)>[];
  (int x, int y)? cur = goal;
  while (cur != null) {
    path.add(cur);
    cur = prev[cur];
  }
  return path.reversed.toList();
}

/// Province id on [compA] adjacent to the first cell of [path].
String provinceIdAdjacentToSeaPath({
  required List<List<String>> grid,
  required Set<(int x, int y)> compA,
  required List<(int x, int y)> path,
  required int width,
  required int height,
}) {
  for (final (px, py) in path) {
    for (final (dx, dy) in kTileMapDirections4NorthSouthWestEast) {
      final nx = px + dx;
      final ny = py + dy;
      if (nx >= 0 &&
          nx < width &&
          ny >= 0 &&
          ny < height &&
          compA.contains((nx, ny))) {
        return grid[ny][nx];
      }
    }
  }
  final anyInA = compA.first;
  return grid[anyInA.$2][anyInA.$1];
}

/// One O(W×H) scan; [joinContinents] reuses and incrementally updates these sets.
List<Set<(int x, int y)>> buildLandCellsByContinentIndex({
  required List<List<String>> grid,
  required Map<String, int> membership,
  required String seaZoneId,
  required int numContinents,
}) {
  final out = List<Set<(int x, int y)>>.generate(
    numContinents,
    (_) => <(int x, int y)>{},
  );
  TileMapGrid.forEachCell(grid, (y, x, id) {
    if (id == seaZoneId) return;
    final continentIndex = membership[id];
    if (continentIndex == null ||
        continentIndex < 0 ||
        continentIndex >= numContinents) {
      return;
    }
    out[continentIndex].add((x, y));
  });
  return out;
}

/// Drops every cell in [cells] from each continent's land-cell set.
void removeCellsFromAllContinents(
  List<Set<(int x, int y)>> landCellsByContinent,
  List<(int x, int y)> cells,
  int numContinents,
) {
  for (final (x, y) in cells) {
    for (var ci = 0; ci < numContinents; ci++) {
      landCellsByContinent[ci].remove((x, y));
    }
  }
}
