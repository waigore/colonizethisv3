/// Pass 6b post-processing (issue #3573): hardwood-forest clustering swaps.

part of 'tile_map_generator.dart';

extension _TileMapGenTerrainResourceHardwood on _TileMapGenTerrainResource {
  /// Pass 6b post-processing (R7, issue #3573): nudge isolated hardwood-forest
  /// cells towards existing hardwood/scrub clusters using **reciprocal
  /// hardwood↔scrub swaps only**. Each swap exchanges an isolated hardwood cell
  /// with a scrub cell adjacent to other hardwood, leaving both per-terrain cell
  /// counts (and the R6 1:4 hardwood:scrub ratio) unchanged. Hardwood never
  /// swaps with plains, mountain, or any non-scrub terrain. The pass is bounded
  /// by a fixed iteration cap and degrades gracefully (some hardwood may remain
  /// isolated when no eligible scrub is available).
  /// SPEC/program/tile-map-gen-algorithm.md, SPEC/game/tile-map-and-generation.md.
  void _clusterHardwoodForest(
    List<List<TerrainType?>> terrainGrid,
    Set<(int x, int y)> component,
    Random rnd,
  ) {
    const directions = kTileMapDirections4;

    final hardwoodCount = _componentCellsOfTerrain(
      terrainGrid,
      component,
      TerrainType.hardwoodForest,
    ).length;
    // Need at least two hardwood cells for clustering to be meaningful.
    if (hardwoodCount < 2) return;

    bool hasNeighborOfTerrain(
      int x,
      int y,
      TerrainType terrain, {
      (int, int)? except,
    }) {
      for (final (dx, dy) in directions) {
        final nx = x + dx;
        final ny = y + dy;
        if (!component.contains((nx, ny))) continue;
        if (except != null && nx == except.$1 && ny == except.$2) continue;
        if (terrainGrid[ny][nx] == terrain) return true;
      }
      return false;
    }

    // Bounded by the hardwood cell count: each successful swap clusters one
    // previously isolated hardwood cell, so a fixed cap prevents infinite loops.
    final maxSwaps = hardwoodCount;
    for (var swap = 0; swap < maxSwaps; swap++) {
      final isolated = <(int x, int y)>[
        for (final (x, y) in component)
          if (terrainGrid[y][x] == TerrainType.hardwoodForest &&
              !hasNeighborOfTerrain(x, y, TerrainType.hardwoodForest))
            (x, y),
      ]..shuffle(rnd);
      if (isolated.isEmpty) return;

      var didSwap = false;
      for (final (hx, hy) in isolated) {
        final target = _findScrubSwapTargetForHardwood(
          terrainGrid,
          component,
          directions,
          hx,
          hy,
          rnd,
        );
        if (target == null) continue;
        // Reciprocal hardwood↔scrub swap: counts of both terrains are preserved.
        terrainGrid[hy][hx] = TerrainType.scrubForest;
        terrainGrid[target.$2][target.$1] = TerrainType.hardwoodForest;
        didSwap = true;
        break;
      }
      // Graceful degradation: no eligible scrub for any isolated hardwood cell.
      if (!didSwap) return;
    }
  }

  /// Picks a scrub-forest cell in [component] that is adjacent to a hardwood
  /// cell **other than** the isolated source cell ([hx], [hy]); swapping the
  /// source hardwood into that scrub location places it beside existing
  /// hardwood. Returns `null` when no such scrub cell exists.
  (int x, int y)? _findScrubSwapTargetForHardwood(
    List<List<TerrainType?>> terrainGrid,
    Set<(int x, int y)> component,
    List<(int dx, int dy)> directions,
    int hx,
    int hy,
    Random rnd,
  ) {
    final candidates = <(int x, int y)>[];
    for (final (x, y) in component) {
      if (terrainGrid[y][x] != TerrainType.scrubForest) continue;
      var adjacentToOtherHardwood = false;
      for (final (dx, dy) in directions) {
        final nx = x + dx;
        final ny = y + dy;
        if (!component.contains((nx, ny))) continue;
        if (nx == hx && ny == hy) continue;
        if (terrainGrid[ny][nx] == TerrainType.hardwoodForest) {
          adjacentToOtherHardwood = true;
          break;
        }
      }
      if (adjacentToOtherHardwood) candidates.add((x, y));
    }
    if (candidates.isEmpty) return null;
    return candidates[rnd.nextInt(candidates.length)];
  }
}
