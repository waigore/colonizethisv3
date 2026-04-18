part of 'tile_map_generator.dart';

/// Grid and connectivity helpers shared by tile map generation passes.
/// SPEC/program/tile-map-gen-algorithm.md
class TileMapGridGraph {
  TileMapGridGraph(this.params);

  final TileMapParams params;

  List<Set<(int x, int y)>> connectedComponentsOfLand(
    Set<(int x, int y)> landCells,
  ) {
    if (landCells.isEmpty) return [];
    final result = <Set<(int x, int y)>>[];
    final remaining = Set<(int x, int y)>.from(landCells);
    while (remaining.isNotEmpty) {
      final start = remaining.first;
      remaining.remove(start);
      final component = <(int x, int y)>{start};
      final queue = <(int x, int y)>[start];
      while (queue.isNotEmpty) {
        final (x, y) = queue.removeLast();
        for (final (dx, dy) in [(0, -1), (0, 1), (-1, 0), (1, 0)]) {
          final n = (x + dx, y + dy);
          if (remaining.remove(n)) {
            component.add(n);
            queue.add(n);
          }
        }
      }
      result.add(component);
    }
    return result;
  }

  /// Pass 11: 4-connected components of sea cells (grid cells with seaZoneId).
  List<Set<(int x, int y)>> connectedComponentsOfSea(
    List<List<String>> grid,
    String seaZoneId,
  ) {
    final seaCells = <(int x, int y)>{};
    for (var y = 0; y < params.height; y++) {
      for (var x = 0; x < params.width; x++) {
        if (grid[y][x] == seaZoneId) seaCells.add((x, y));
      }
    }
    return connectedComponentsOfLand(seaCells);
  }

  (int, int) minYx(Set<(int x, int y)> cells) {
    var minY = params.height;
    var minX = params.width;
    for (final (x, y) in cells) {
      if (y < minY || (y == minY && x < minX)) {
        minY = y;
        minX = x;
      }
    }
    return (minY, minX);
  }

  int countSeaCells(List<List<String>> grid, String seaZoneId) {
    var n = 0;
    for (var y = 0; y < params.height; y++) {
      for (var x = 0; x < params.width; x++) {
        if (grid[y][x] == seaZoneId) n++;
      }
    }
    return n;
  }

  /// Ocean = sea cells reachable from grid boundary. Lake = sea not in ocean.
  Set<(int x, int y)> oceanCells(List<List<String>> grid, String seaZoneId) {
    final ocean = <(int x, int y)>{};
    final queue = <(int x, int y)>[];
    for (var x = 0; x < params.width; x++) {
      if (grid[0][x] == seaZoneId) {
        ocean.add((x, 0));
        queue.add((x, 0));
      }
      if (params.height > 1 && grid[params.height - 1][x] == seaZoneId) {
        ocean.add((x, params.height - 1));
        queue.add((x, params.height - 1));
      }
    }
    for (var y = 0; y < params.height; y++) {
      if (grid[y][0] == seaZoneId && !ocean.contains((0, y))) {
        ocean.add((0, y));
        queue.add((0, y));
      }
      if (params.width > 1 &&
          grid[y][params.width - 1] == seaZoneId &&
          !ocean.contains((params.width - 1, y))) {
        ocean.add((params.width - 1, y));
        queue.add((params.width - 1, y));
      }
    }
    while (queue.isNotEmpty) {
      final (x, y) = queue.removeLast();
      for (final (nx, ny) in [(x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)]) {
        if (nx >= 0 &&
            nx < params.width &&
            ny >= 0 &&
            ny < params.height &&
            grid[ny][nx] == seaZoneId &&
            !ocean.contains((nx, ny))) {
          ocean.add((nx, ny));
          queue.add((nx, ny));
        }
      }
    }
    return ocean;
  }

  /// Continent index for a land cell from nearest land seed. Returns 0 when seeds empty.
  int continentForLandCell(
    int x,
    int y,
    List<(int x, int y)> landSeeds,
    List<int> continentBySeedIndex,
  ) {
    if (landSeeds.isEmpty) return 0;
    var bestSeedIndex = 0;
    var bestD2 = kUnsetSquaredDistanceInt31;
    for (var i = 0; i < landSeeds.length; i++) {
      final (sx, sy) = landSeeds[i];
      final d2 = (x - sx) * (x - sx) + (y - sy) * (y - sy);
      if (d2 < bestD2) {
        bestD2 = d2;
        bestSeedIndex = i;
      }
    }
    return continentBySeedIndex[bestSeedIndex];
  }

  int oceanNeighbourCount(
    List<List<String>> grid,
    int x,
    int y,
    String seaZoneId,
    Set<(int x, int y)> ocean,
  ) {
    var n = 0;
    for (final (dx, dy) in [(0, -1), (0, 1), (-1, 0), (1, 0)]) {
      final nx = x + dx;
      final ny = y + dy;
      if (nx >= 0 &&
          nx < params.width &&
          ny >= 0 &&
          ny < params.height &&
          grid[ny][nx] == seaZoneId &&
          ocean.contains((nx, ny))) {
        n++;
      }
    }
    return n;
  }
}
