/// 4-connected BFS component partitioning for tile map generation.
/// SPEC/program/tile-map-gen-algorithm.md

import '../tile_map_directions.dart';
import 'tile_map_land_seed_contract.dart';

class TileMapGridGraphConnectivity {
  TileMapGridGraphConnectivity(this.params);

  final TileMapLandSeedParams params;

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
        _expandLandComponentNeighbors(x, y, remaining, component, queue);
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

  void _expandLandComponentNeighbors(
    int x,
    int y,
    Set<(int x, int y)> remaining,
    Set<(int x, int y)> component,
    List<(int x, int y)> queue,
  ) {
    for (final (dx, dy) in kTileMapDirections4NorthSouthWestEast) {
      final n = (x + dx, y + dy);
      if (!remaining.remove(n)) continue;
      component.add(n);
      queue.add(n);
    }
  }
}
