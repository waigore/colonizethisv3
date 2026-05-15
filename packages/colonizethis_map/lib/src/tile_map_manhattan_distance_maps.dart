/// Per-continent Manhattan distance to the nearest cell assigned to another
/// continent ([continentGrid] value >= 0 and != c). Unassigned cells (-1) are
/// not targets; distance is geometric |dx|+|dy| to the nearest target, not
/// grid-path length. Unreachable cells use [width] + [height]. Refs #2489 (P2).
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
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        var minDist = unreachable;
        for (var ny = 0; ny < height; ny++) {
          for (var nx = 0; nx < width; nx++) {
            final cell = continentGrid[ny][nx];
            if (cell < 0 || cell == c) continue;
            final d = (x - nx).abs() + (y - ny).abs();
            if (d < minDist) minDist = d;
          }
        }
        dist[y][x] = minDist;
      }
    }
  }
  return maps;
}
