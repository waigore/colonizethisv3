/// Macro/micro phase helpers for [TerrainRegionGrower].
/// SPEC/program/tile-map-gen-algorithm.md Pass 6b.
library;

import 'dart:math';

import 'package:colonizethis_data/colonizethis_data.dart';

import '../tile_map_directions.dart';
import 'terrain_dominance.dart';
import 'tile_map_land_sentinel.dart';
import 'tile_map_params.dart';

/// Macro/micro grow phases and queue seeding for region-growing assignment.
class TerrainRegionGrowPhases {
  TerrainRegionGrowPhases(this.params);

  final TileMapParams params;

  Map<TerrainType, int> buildComponentTargets(
    int totalRemaining,
    List<TerrainType> allowed,
    TerrainDistribution distribution,
  ) {
    final targets = <TerrainType, int>{};
    int sum = 0;
    for (final t in allowed) {
      final frac = distribution.nonMountainFractions[t] ?? 0.0;
      final n = (frac * totalRemaining).round();
      targets[t] = n;
      sum += n;
    }
    if (sum <= 0) {
      final int per = (totalRemaining / allowed.length).round();
      targets.clear();
      sum = 0;
      for (final t in allowed) {
        targets[t] = per;
        sum += per;
      }
    }
    final int delta = totalRemaining - sum;
    if (delta != 0) {
      final last = allowed.last;
      targets[last] = (targets[last] ?? 0) + delta;
    }
    return targets;
  }

  (Map<TerrainType, int>, Map<TerrainType, int>) runMacroPhase(
    List<List<TerrainType?>> terrainGrid,
    List<List<String>> grid,
    Set<(int x, int y)> component,
    List<(int x, int y)> cells,
    List<TerrainType> allowed,
    Map<TerrainType, int> targets,
    Random rnd,
  ) {
    final macroTargets = <TerrainType, int>{};
    final macroRemaining = <TerrainType, int>{};
    for (final t in allowed) {
      final target = targets[t] ?? 0;
      if (target <= 0) continue;
      final macro = max(
        1,
        (target * params.terrainMacroFraction).round().clamp(1, target),
      );
      macroTargets[t] = macro;
      macroRemaining[t] = macro;
    }
    final macroQueues = seedQueuesForPhase(
      terrainGrid,
      allowed,
      macroTargets,
      macroRemaining,
      cells,
      rnd,
    );
    growQueuesForPhase(
      terrainGrid,
      grid,
      component,
      allowed,
      macroRemaining,
      macroQueues,
      rnd,
    );
    return (macroTargets, macroRemaining);
  }

  void runMicroPhase(
    List<List<TerrainType?>> terrainGrid,
    List<List<String>> grid,
    Set<(int x, int y)> component,
    List<(int x, int y)> cells,
    List<TerrainType> allowed,
    Map<TerrainType, int> targets,
    Map<TerrainType, int> macroTargets,
    Map<TerrainType, int> macroRemaining,
    Random rnd,
  ) {
    final residualTargets = <TerrainType, int>{};
    for (final t in allowed) {
      final target = targets[t] ?? 0;
      if (target <= 0) continue;
      final macro = macroTargets[t] ?? 0;
      final usedMacro = macro - (macroRemaining[t] ?? 0);
      final residual = max(0, target - usedMacro);
      if (residual > 0) {
        residualTargets[t] = residual;
      }
    }
    if (residualTargets.isEmpty) return;
    final microRemaining = <TerrainType, int>{...residualTargets};
    final microQueues = seedQueuesForPhase(
      terrainGrid,
      allowed,
      residualTargets,
      microRemaining,
      cells.where((c) => terrainGrid[c.$2][c.$1] == null).toList(),
      rnd,
    );
    growQueuesForPhase(
      terrainGrid,
      grid,
      component,
      allowed,
      microRemaining,
      microQueues,
      rnd,
    );
  }

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
