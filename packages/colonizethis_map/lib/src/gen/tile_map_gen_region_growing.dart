/// Pass 6b: region-growing assignment for non-mountain terrains.
///
/// Extracted from the `part of 'tile_map_generator.dart'` terrain fragment into
/// a standalone, independently importable strategy class injected into
/// [TileMapGenTerrainResource] (Refs #3588). Constructor-injected
/// [TileMapParams] and [TileMapGridGraph] replace the former shared-scope
/// access. The per-component post-processing passes (pattern refinement, noise
/// perturbation, hardwood clustering) are injected so the macro/micro grow
/// sequence stays cohesive while remaining individually testable. Pure
/// relocation; iteration order and RNG sequence are unchanged.
library;

import 'dart:math';

import 'package:colonizethis_data/colonizethis_data.dart';

import '../tile_map_directions.dart';
import 'terrain_dominance.dart';
import 'tile_map_gen_hardwood_cluster.dart';
import 'tile_map_gen_terrain_noise.dart';
import 'tile_map_gen_terrain_pattern_refine.dart';
import 'tile_map_grid_graph.dart';
import 'tile_map_land_sentinel.dart';
import 'tile_map_params.dart';

/// Pass 6b region-growing strategy with injected post-processing passes.
class TerrainRegionGrower {
  TerrainRegionGrower(
    this.params,
    this._graph, {
    TerrainPatternRefiner? patternRefiner,
    TerrainNoisePerturbation? noisePerturbation,
    HardwoodForestClusterer? hardwoodClusterer,
  }) : _patternRefiner =
           patternRefiner ?? TerrainPatternRefiner(params, _graph),
       _noisePerturbation =
           noisePerturbation ?? TerrainNoisePerturbation(params, _graph),
       _hardwoodClusterer =
           hardwoodClusterer ?? const HardwoodForestClusterer();

  final TileMapParams params;
  final TileMapGridGraph _graph;
  final TerrainPatternRefiner _patternRefiner;
  final TerrainNoisePerturbation _noisePerturbation;
  final HardwoodForestClusterer _hardwoodClusterer;

  /// Pass 6b: region-growing assignment for non-mountain terrains over the
  /// connected components of [remainingNonMountainLand].
  void assignNonMountainTerrains(
    List<List<TerrainType?>> terrainGrid,
    List<List<String>> grid,
    String mapRegionId,
    TerrainDistribution distribution,
    Random rnd, {
    required List<(int x, int y)> remainingNonMountainLand,
  }) {
    final allowed = allowedTerrainsForRegion(
      mapRegionId,
    ).where((t) => t != TerrainType.mountain).toList();
    if (allowed.isEmpty) return;

    final remainingLand = remainingNonMountainLand;
    if (remainingLand.isEmpty) return;
    final components = _graph.connectedComponentsOfLand(remainingLand.toSet());
    if (components.isEmpty) return;

    for (final component in components) {
      if (component.isEmpty) continue;
      _assignNonMountainInComponent(
        terrainGrid,
        grid,
        component,
        allowed,
        distribution,
        rnd,
      );
    }
  }

  void _assignNonMountainInComponent(
    List<List<TerrainType?>> terrainGrid,
    List<List<String>> grid,
    Set<(int x, int y)> component,
    List<TerrainType> allowed,
    TerrainDistribution distribution,
    Random rnd,
  ) {
    final cells = component.toList();
    final targets = _buildComponentTargets(cells.length, allowed, distribution);
    final macro = _runMacroPhase(
      terrainGrid,
      grid,
      component,
      cells,
      allowed,
      targets,
      rnd,
    );
    _runMicroPhase(
      terrainGrid,
      grid,
      component,
      cells,
      allowed,
      targets,
      macro.$1,
      macro.$2,
      rnd,
    );
    _cleanupUnassignedInComponent(terrainGrid, component, allowed, rnd);
    _patternRefiner.refineComponent(
      terrainGrid,
      grid,
      component,
      allowed,
      distribution,
      rnd,
    );
    _noisePerturbation.apply(
      terrainGrid,
      grid,
      component,
      allowed,
      distribution,
      rnd,
    );
    _hardwoodClusterer.cluster(terrainGrid, component, rnd);
  }

  Map<TerrainType, int> _buildComponentTargets(
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

  (Map<TerrainType, int>, Map<TerrainType, int>) _runMacroPhase(
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
    final macroQueues = _seedQueuesForPhase(
      terrainGrid,
      allowed,
      macroTargets,
      macroRemaining,
      cells,
      rnd,
    );
    _growQueuesForPhase(
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

  void _runMicroPhase(
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
    final microQueues = _seedQueuesForPhase(
      terrainGrid,
      allowed,
      residualTargets,
      microRemaining,
      cells.where((c) => terrainGrid[c.$2][c.$1] == null).toList(),
      rnd,
    );
    _growQueuesForPhase(
      terrainGrid,
      grid,
      component,
      allowed,
      microRemaining,
      microQueues,
      rnd,
    );
  }

  Map<TerrainType, List<(int x, int y)>> _seedQueuesForPhase(
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

  void _growQueuesForPhase(
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

  void _cleanupUnassignedInComponent(
    List<List<TerrainType?>> terrainGrid,
    Set<(int x, int y)> component,
    List<TerrainType> allowed,
    Random rnd,
  ) {
    for (final (x, y) in component) {
      if (terrainGrid[y][x] != null) continue;
      final counts = _neighborNonMountainCounts(terrainGrid, component, x, y);
      terrainGrid[y][x] = counts.isEmpty
          ? allowed[rnd.nextInt(allowed.length)]
          : mostFrequentTerrain(counts);
    }
  }

  Map<TerrainType, int> _neighborNonMountainCounts(
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
