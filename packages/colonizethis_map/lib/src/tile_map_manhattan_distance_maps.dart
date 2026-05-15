import 'tile_map_directions.dart';

/// Per-continent Manhattan distance to the nearest cell assigned to another
/// continent ([continentGrid] value >= 0 and != c). Unreachable cells use
/// [width] + [height]. Refs #2489 (P2).
List<List<List<int>>> manhattanDistToOtherContinentsMaps({
  required List<List<int>> continentGrid,
  required int width,
  required int height,
  required int numContinents,
}) {
  if (numContinents <= 0) return const [];
  final unreachable = width + height;
  final maps = List.generate(
    numContinents,
    (_) => List.generate(height, (_) => List.filled(width, unreachable)),
  );
  for (var c = 0; c < numContinents; c++) {
    final dist = maps[c];
    final queue = <(int x, int y)>[];
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final cell = continentGrid[y][x];
        if (cell < 0 || cell == c) continue;
        dist[y][x] = 0;
        queue.add((x, y));
      }
    }
    var qi = 0;
    while (qi < queue.length) {
      final (x, y) = queue[qi++];
      final d = dist[y][x];
      for (final (dx, dy) in kTileMapDirections4NorthSouthWestEast) {
        final nx = x + dx;
        final ny = y + dy;
        if (nx < 0 || nx >= width || ny < 0 || ny >= height) continue;
        final next = d + 1;
        if (dist[ny][nx] <= next) continue;
        dist[ny][nx] = next;
        queue.add((nx, ny));
      }
    }
  }
  return maps;
}
