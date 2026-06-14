part of 'tile_map_generator.dart';

extension _TileMapGenJoinSeaSubdividePart on _TileMapGenJoinSea {
  /// Pass 11: Subdivide sea so each zone has at most maxSeaZoneFraction * totalSea tiles.
  /// Returns (newGrid, total sea zone count).
  (List<List<String>>, int) subdivideSeaZonesWithCap(
    List<List<String>> grid,
    String seaZoneId,
    int totalSea,
  ) {
    final components = _graph.connectedComponentsOfSea(grid, seaZoneId);
    if (components.isEmpty) return (grid, 0);
    final sorted = List<Set<(int x, int y)>>.from(components)
      ..sort((a, b) {
        final (minYa, minXa) = _graph.minYx(a);
        final (minYb, minXb) = _graph.minYx(b);
        if (minYa != minYb) return minYa.compareTo(minYb);
        return minXa.compareTo(minXb);
      });
    final g = TileMapGrid.copy(grid);
    final maxPerZone = (params.maxSeaZoneFraction * totalSea).floor();
    var nextSeaZoneIndex = 1;
    for (final component in sorted) {
      final size = component.length;
      if (maxPerZone <= 0 || size <= maxPerZone) {
        final id = 's$nextSeaZoneIndex';
        nextSeaZoneIndex++;
        for (final (x, y) in component) {
          g[y][x] = id;
        }
        continue;
      }
      final K = (size / maxPerZone).ceil().clamp(1, size);
      final seeds = _placeSeaSeedsFarthestPoint(component, K);
      final seedMap = <String, (int x, int y)>{
        for (var i = 0; i < seeds.length; i++)
          's${nextSeaZoneIndex + i}': seeds[i],
      };
      final assignment = assignCellsToNearestSeed(
        component,
        seedMap,
        noiseScale: params.voronoiNoiseScale,
        noiseSeed: params.seed,
      );
      for (final entry in assignment.entries) {
        final (x, y) = entry.key;
        g[y][x] = entry.value;
      }
      nextSeaZoneIndex += K;
    }
    return (g, nextSeaZoneIndex - 1);
  }

  /// Place K well-spread seeds in [cells] using farthest-point sampling.
  List<(int x, int y)> _placeSeaSeedsFarthestPoint(
    Set<(int x, int y)> cells,
    int K,
  ) {
    if (cells.isEmpty || K <= 0) return [];
    final list = cells.toList();
    if (K >= list.length) return list;
    list.sort((a, b) {
      if (a.$2 != b.$2) return a.$2.compareTo(b.$2);
      return a.$1.compareTo(b.$1);
    });
    final chosen = <(int x, int y)>[list.first];
    for (var i = 1; i < K; i++) {
      chosen.add(_bestFarthestPointCellFromList(list, chosen));
    }
    return chosen;
  }

  (int x, int y) _bestFarthestPointCellFromList(
    List<(int x, int y)> list,
    List<(int x, int y)> chosen,
  ) {
    var bestCell = list.first;
    var bestMinD2 = 0;
    for (final (x, y) in list) {
      if (chosen.contains((x, y))) continue;
      var minD2 = kUnsetSquaredDistanceInt31;
      for (final (sx, sy) in chosen) {
        final d2 = (x - sx) * (x - sx) + (y - sy) * (y - sy);
        if (d2 < minD2) minD2 = d2;
      }
      if (minD2 > bestMinD2) {
        bestMinD2 = minD2;
        bestCell = (x, y);
      }
    }
    return bestCell;
  }
}
