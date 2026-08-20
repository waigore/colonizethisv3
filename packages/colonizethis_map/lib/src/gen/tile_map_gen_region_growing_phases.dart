/// Macro/micro phase helpers for [TerrainRegionGrower].
/// SPEC/program/tile-map-gen-algorithm.md Pass 6b.
library;

import 'dart:math';

import 'package:colonizethis_data/colonizethis_data.dart';

import 'tile_map_gen_region_growing_queues.dart';
import 'tile_map_gen_region_growing_targeting.dart';
import 'tile_map_params.dart';

/// Macro/micro grow phases and queue seeding for region-growing assignment.
class TerrainRegionGrowPhases {
  TerrainRegionGrowPhases(this.params) : _queues = TerrainRegionGrowQueues(params);

  final TileMapParams params;

  final TerrainRegionGrowQueues _queues;
  late final TerrainRegionGrowTargeting _targeting = TerrainRegionGrowTargeting(
    params,
    _queues,
  );

  Map<TerrainType, int> buildComponentTargets(
    int totalRemaining,
    List<TerrainType> allowed,
    TerrainDistribution distribution,
  ) =>
      _targeting.buildComponentTargets(
        totalRemaining,
        allowed,
        distribution,
      );

  (Map<TerrainType, int>, Map<TerrainType, int>) runMacroPhase(
    List<List<TerrainType?>> terrainGrid,
    List<List<String>> grid,
    Set<(int x, int y)> component,
    List<(int x, int y)> cells,
    List<TerrainType> allowed,
    Map<TerrainType, int> targets,
    Random rnd,
  ) =>
      _targeting.runMacroPhase(
        terrainGrid,
        grid,
        component,
        cells,
        allowed,
        targets,
        rnd,
      );

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
  ) =>
      _targeting.runMicroPhase(
        terrainGrid,
        grid,
        component,
        cells,
        allowed,
        targets,
        macroTargets,
        macroRemaining,
        rnd,
      );

  Map<TerrainType, List<(int x, int y)>> seedQueuesForPhase(
    List<List<TerrainType?>> terrainGrid,
    List<TerrainType> allowed,
    Map<TerrainType, int> phaseTargets,
    Map<TerrainType, int> phaseRemaining,
    List<(int x, int y)> availableCells,
    Random rnd,
  ) =>
      _queues.seedQueuesForPhase(
        terrainGrid,
        allowed,
        phaseTargets,
        phaseRemaining,
        availableCells,
        rnd,
      );

  void growQueuesForPhase(
    List<List<TerrainType?>> terrainGrid,
    List<List<String>> grid,
    Set<(int x, int y)> component,
    List<TerrainType> allowed,
    Map<TerrainType, int> remainingByTerrain,
    Map<TerrainType, List<(int x, int y)>> queuesByTerrain,
    Random rnd,
  ) =>
      _queues.growQueuesForPhase(
        terrainGrid,
        grid,
        component,
        allowed,
        remainingByTerrain,
        queuesByTerrain,
        rnd,
      );

  void cleanupUnassignedInComponent(
    List<List<TerrainType?>> terrainGrid,
    Set<(int x, int y)> component,
    List<TerrainType> allowed,
    Random rnd,
  ) =>
      _queues.cleanupUnassignedInComponent(
        terrainGrid,
        component,
        allowed,
        rnd,
      );

  Map<TerrainType, int> neighborNonMountainCounts(
    List<List<TerrainType?>> terrainGrid,
    Set<(int x, int y)> component,
    int x,
    int y,
  ) =>
      _queues.neighborNonMountainCounts(terrainGrid, component, x, y);
}
