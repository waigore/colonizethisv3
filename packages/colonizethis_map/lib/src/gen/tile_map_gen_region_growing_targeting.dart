/// Macro/micro targeting for [TerrainRegionGrowPhases].
/// SPEC/program/tile-map-gen-algorithm.md Pass 6b.
library;

import 'dart:math';

import 'package:colonizethis_data/colonizethis_data.dart';

import 'terrain_dominance.dart';
import 'tile_map_gen_region_growing_queues.dart';
import 'tile_map_params.dart';

class TerrainRegionGrowTargeting {
  TerrainRegionGrowTargeting(this.params, this._queues);

  final TileMapParams params;
  final TerrainRegionGrowQueues _queues;

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
    final macroQueues = _queues.seedQueuesForPhase(
      terrainGrid,
      allowed,
      macroTargets,
      macroRemaining,
      cells,
      rnd,
    );
    _queues.growQueuesForPhase(
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
    final microQueues = _queues.seedQueuesForPhase(
      terrainGrid,
      allowed,
      residualTargets,
      microRemaining,
      cells.where((c) => terrainGrid[c.$2][c.$1] == null).toList(),
      rnd,
    );
    _queues.growQueuesForPhase(
      terrainGrid,
      grid,
      component,
      allowed,
      microRemaining,
      microQueues,
      rnd,
    );
  }
}
