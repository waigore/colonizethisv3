/// Queue seed/grow helpers for [TerrainRegionGrowPhases].
/// SPEC/program/tile-map-gen-algorithm.md Pass 6b.
library;

import 'dart:math';

import 'package:colonizethis_data/colonizethis_data.dart';

import '../tile_map_directions.dart';
import 'terrain_dominance.dart';
import 'tile_map_land_sentinel.dart';
import 'tile_map_params.dart';

class TerrainRegionGrowQueues {
  TerrainRegionGrowQueues(this.params);

  final TileMapParams params;

  Map<TerrainType, List<(int x, int y)>> seedQueuesForPhase(
    List<List<TerrainType?>> terrainGrid,
    List<TerrainType> allowed,
    Map<TerrainType, int> phaseTargets,
    Map<TerrainType, int> phaseRemaining,
    List<(int x, int y)> availableCells,
    Random rnd,
  ) {
    final queues = <TerrainType, List<(int x, int y)>>{};
    final available = List<(int x, int y)>.from(availableCells);
    for (final t in allowed) {
      final target = phaseTargets[t] ?? 0;
      if (target <= 0) continue;
      final seedCount = max(
        params.terrainSeedsMin,
        min(
          params.terrainSeedsMax,
          (params.terrainSeedsFactor * sqrt(target)).round(),
        ),
      );
      final q = <(int x, int y)>[];
      queues[t] = q;
      var placedSeeds = 0;
      while (placedSeeds < seedCount &&
          (phaseRemaining[t] ?? 0) > 0 &&
          available.isNotEmpty) {
        final idx = rnd.nextInt(available.length);
        final (sx, sy) = available.removeAt(idx);
        if (terrainGrid[sy][sx] != null) continue;
        terrainGrid[sy][sx] = t;
        q.add((sx, sy));
        phaseRemaining[t] = (phaseRemaining[t] ?? 0) - 1;
        placedSeeds++;
      }
    }
    return queues;
  }

  void growQueuesForPhase(
    List<List<TerrainType?>> terrainGrid,
    List<List<String>> grid,
    Set<(int x, int y)> component,
    List<TerrainType> allowed,
    Map<TerrainType, int> remainingByTerrain,
    Map<TerrainType, List<(int x, int y)>> queuesByTerrain,
    Random rnd,
  ) {
    const directions = kTileMapDirections4;
    while (true) {
      var totalRem = 0;
      var hasActive = false;
      for (final t in allowed) {
        final rem = remainingByTerrain[t] ?? 0;
        final q = queuesByTerrain[t];
        totalRem += rem;
        if (rem > 0 && q != null && q.isNotEmpty) {
          hasActive = true;
        }
      }
      if (!hasActive || totalRem <= 0) return;
      var roll = rnd.nextInt(totalRem) + 1;
      TerrainType? chosen;
      for (final t in allowed) {
        final rem = remainingByTerrain[t] ?? 0;
        if (rem <= 0) continue;
        roll -= rem;
        if (roll <= 0) {
          chosen = t;
          break;
        }
      }
      if (chosen == null) return;
      final queue = queuesByTerrain[chosen];
      if (queue == null || queue.isEmpty) continue;
      final (cx, cy) = queue.removeLast();
      final dirs = List<(int dx, int dy)>.from(directions)..shuffle(rnd);
      for (final (dx, dy) in dirs) {
        final nx = cx + dx;
        final ny = cy + dy;
        if (nx < 0 || nx >= params.width || ny < 0 || ny >= params.height) {
          continue;
        }
        if (!component.contains((nx, ny))) continue;
        if (grid[ny][nx] != kTileMapLandSentinel) continue;
        if (terrainGrid[ny][nx] != null) continue;
        terrainGrid[ny][nx] = chosen;
        remainingByTerrain[chosen] = (remainingByTerrain[chosen] ?? 0) - 1;
        queue.add((nx, ny));
        if ((remainingByTerrain[chosen] ?? 0) <= 0) break;
      }
    }
  }

  void cleanupUnassignedInComponent(
    List<List<TerrainType?>> terrainGrid,
    Set<(int x, int y)> component,
    List<TerrainType> allowed,
    Random rnd,
  ) {
    for (final (x, y) in component) {
      if (terrainGrid[y][x] != null) continue;
      final counts = neighborNonMountainCounts(terrainGrid, component, x, y);
      terrainGrid[y][x] = counts.isEmpty
          ? allowed[rnd.nextInt(allowed.length)]
          : mostFrequentTerrain(counts);
    }
  }

  Map<TerrainType, int> neighborNonMountainCounts(
    List<List<TerrainType?>> terrainGrid,
    Set<(int x, int y)> component,
    int x,
    int y,
  ) {
    const directions = kTileMapDirections4;
    final counts = <TerrainType, int>{};
    for (final (dx, dy) in directions) {
      final nx = x + dx;
      final ny = y + dy;
      if (nx < 0 || nx >= params.width || ny < 0 || ny >= params.height) {
        continue;
      }
      if (!component.contains((nx, ny))) continue;
      final terrain = terrainGrid[ny][nx];
      if (terrain == null || terrain == TerrainType.mountain) continue;
      counts[terrain] = (counts[terrain] ?? 0) + 1;
    }
    return counts;
  }
}
