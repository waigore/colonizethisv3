import 'tile_map_manhattan_distance_transform.dart';

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
  return List.generate(
    numContinents,
    (c) => manhattanDistToNearestSourceXY(width, height, (x, y) {
      final cell = continentGrid[y][x];
      return cell >= 0 && cell != c;
    }, distanceWhenNoSources: unreachable),
  );
}
