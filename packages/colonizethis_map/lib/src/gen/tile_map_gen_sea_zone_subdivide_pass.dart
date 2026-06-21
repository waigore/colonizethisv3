/// Pass 11: subdivide sea into bounded-size zones.
///
/// Extracted from the former `_TileMapGenJoinSea` subdivide fragment into a
/// standalone [MapGenPass] family (Refs #3588). Splits each connected sea
/// component so no zone exceeds `maxSeaZoneFraction * totalSea` tiles, using
/// farthest-point seeding + deterministic Voronoi assignment.
/// SPEC/program/tile-map-gen-algorithm.md § Pass 11.
library;

import 'grid_voronoi.dart';
import 'map_gen_pass_payloads.dart';
import 'map_gen_stage.dart';
import 'tile_map_distance_sentinels.dart';
import 'tile_map_grid_graph.dart';
import 'tile_map_params.dart';

/// Pass 11 sea-zone subdivision service.
class SeaZoneSubdividePass
    implements
        MapGenPass<SeaZoneSubdividePassPayload, SeaZoneSubdividePassResult> {
  SeaZoneSubdividePass(this.params, this._graph);

  @override
  final TileMapParams params;
  final TileMapGridGraph _graph;

  /// Uniform pass entry: subdivides sea zones when there is sea to split
  /// (Refs #3588). Returns the grid unchanged with a zero count otherwise.
  @override
  SeaZoneSubdividePassResult run(
    MapGenPassContext<SeaZoneSubdividePassPayload> ctx,
  ) {
    final payload = ctx.payload;
    if (payload.totalSea <= 0) {
      return (payload.grid, 0);
    }
    final (newGrid, numSeaZones) = subdivideSeaZonesWithCap(
      payload.grid,
      payload.seaZoneId,
      payload.totalSea,
    );
    ctx.log(
      'Pass 11: Sea zone subdivision ($numSeaZones sea zones, '
      'cap ${(params.maxSeaZoneFraction * 100).toInt()}% of sea)',
    );
    return (newGrid, numSeaZones);
  }

  /// Total number of [seaZoneId] cells in [grid].
  int countSeaCells(List<List<String>> grid, String seaZoneId) =>
      _graph.countSeaCells(grid, seaZoneId);

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
    final g = snapshotGrid(grid);
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
