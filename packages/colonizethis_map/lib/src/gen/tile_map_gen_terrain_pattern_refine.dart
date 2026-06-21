/// Pass 6b pattern refinement: carve small pockets of other terrains into the
/// interior of large single-terrain blobs.
///
/// Extracted from the `part of 'tile_map_generator.dart'` terrain fragment into
/// a standalone, independently importable strategy class injected into
/// [TileMapGenTerrainResource] (Refs #3588). Constructor-injected
/// [TileMapParams] and [TileMapGridGraph] replace the former shared-scope
/// access; pure relocation otherwise.
library;

import 'dart:math';

import 'package:colonizethis_data/colonizethis_data.dart';

import '../tile_map_directions.dart';
import 'terrain_blob_ops.dart';
import 'tile_map_grid_graph.dart';
import 'tile_map_land_sentinel.dart';
import 'tile_map_params.dart';

/// Pass 6b pattern-refinement strategy.
class TerrainPatternRefiner {
  const TerrainPatternRefiner(this.params, this._graph);

  final TileMapParams params;
  final TileMapGridGraph _graph;

  /// Optional Pass 6b pattern refinement: for a given connected land component
  /// (continent), find large blobs of a single non-mountain terrain and carve
  /// small pockets of other non-mountain terrains into their interior while
  /// keeping blob shapes recognizable and overall fractions stable.
  void refineComponent(
    List<List<TerrainType?>> terrainGrid,
    List<List<String>> grid,
    Set<(int x, int y)> component,
    List<TerrainType> allowedNonMountain,
    TerrainDistribution distribution,
    Random rnd,
  ) {
    if (component.isEmpty || allowedNonMountain.isEmpty) return;

    const directions = kTileMapDirections4;

    for (final terrain in allowedNonMountain) {
      final cells = componentCellsOfTerrain(terrainGrid, component, terrain);
      if (cells.isEmpty) continue;
      final blobs = _graph.connectedComponentsOfLand(cells);
      if (blobs.isEmpty) continue;

      for (final blob in blobs) {
        _refineOneTerrainBlobPatterns(
          terrainGrid,
          grid,
          blob,
          terrain,
          allowedNonMountain,
          distribution,
          directions,
          rnd,
        );
      }
    }
  }

  void _refineOneTerrainBlobPatterns(
    List<List<TerrainType?>> terrainGrid,
    List<List<String>> grid,
    Set<(int x, int y)> blob,
    TerrainType terrain,
    List<TerrainType> allowedNonMountain,
    TerrainDistribution distribution,
    List<(int dx, int dy)> directions,
    Random rnd,
  ) {
    final size = blob.length;
    if (size < params.patternMinBlobSize) return;

    final maxChangesForBlob = (params.patternMaxFractionPerBlob * size)
        .floor()
        .clamp(0, size);
    if (maxChangesForBlob <= 0) return;

    final interior = blobInteriorCells(
      blob,
      params.width,
      params.height,
      directions,
    );
    if (interior.isEmpty) return;

    final seedCount = max(
      1,
      min(
        params.patternMaxSeedsPerBlob,
        (params.patternSeedFactor * sqrt(size)).round(),
      ),
    ).clamp(1, maxChangesForBlob);

    final interiorShuffled = List<(int x, int y)>.from(interior)..shuffle(rnd);
    final seeds = _patternSeedsFromInterior(
      interiorShuffled,
      seedCount,
      allowedNonMountain,
      terrain,
      distribution,
      rnd,
    );
    if (seeds.isEmpty) return;

    var remainingBlobBudget = maxChangesForBlob;
    for (final (sx, sy, target) in seeds) {
      if (remainingBlobBudget <= 0) break;
      final spent = _expandPatternSeedInBlob(
        terrainGrid,
        grid,
        blob,
        terrain,
        sx,
        sy,
        target,
        directions,
        remainingBlobBudget,
      );
      remainingBlobBudget -= spent;
    }
  }

  List<(int x, int y, TerrainType target)> _patternSeedsFromInterior(
    List<(int x, int y)> interiorShuffled,
    int seedCount,
    List<TerrainType> allowedNonMountain,
    TerrainType blobTerrain,
    TerrainDistribution distribution,
    Random rnd,
  ) {
    final seeds = <(int x, int y, TerrainType target)>[];
    var interiorIndex = 0;
    for (
      var i = 0;
      i < seedCount && interiorIndex < interiorShuffled.length;
      i++
    ) {
      final (sx, sy) = interiorShuffled[interiorIndex++];
      final options = allowedNonMountain
          .where((t) => t != blobTerrain)
          .toList();
      if (options.isEmpty) break;
      final chosen = weightedPickTerrainFromOptions(
        options,
        distribution,
        rnd,
      );
      seeds.add((sx, sy, chosen));
    }
    return seeds;
  }

  /// Returns how many blob tiles were converted (spent from blob budget).
  int _expandPatternSeedInBlob(
    List<List<TerrainType?>> terrainGrid,
    List<List<String>> grid,
    Set<(int x, int y)> blob,
    TerrainType blobTerrain,
    int sx,
    int sy,
    TerrainType target,
    List<(int dx, int dy)> directions,
    int maxBlobBudget,
  ) {
    if (maxBlobBudget <= 0) return 0;
    var spent = 0;
    var changesForSeed = 0;
    final queue = <(int x, int y, int dist)>[(sx, sy, 0)];
    final visited = <(int, int)>{(sx, sy)};

    while (queue.isNotEmpty &&
        changesForSeed < params.patternMaxChangesPerSeed &&
        spent < maxBlobBudget) {
      final (cx, cy, dist) = queue.removeAt(0);
      if (dist > params.patternMaxRadius) continue;

      if (grid[cy][cx] == kTileMapLandSentinel &&
          blob.contains((cx, cy)) &&
          terrainGrid[cy][cx] == blobTerrain) {
        terrainGrid[cy][cx] = target;
        changesForSeed++;
        spent++;
      }

      if (dist == params.patternMaxRadius) continue;

      for (final (dx, dy) in directions) {
        final nx = cx + dx;
        final ny = cy + dy;
        if (nx < 0 || nx >= params.width || ny < 0 || ny >= params.height) {
          continue;
        }
        final key = (nx, ny);
        if (!blob.contains(key) || visited.contains(key)) continue;
        visited.add(key);
        queue.add((nx, ny, dist + 1));
      }
    }
    return spent;
  }
}
