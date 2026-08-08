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

import 'terrain_dominance.dart';
import 'tile_map_gen_hardwood_cluster.dart';
import 'tile_map_gen_region_growing_phases.dart';
import 'tile_map_gen_terrain_noise.dart';
import 'tile_map_gen_terrain_pattern_refine.dart';
import 'tile_map_grid_graph.dart';
import 'tile_map_params.dart';

/// Pass 6b region-growing strategy with injected post-processing passes.
class TerrainRegionGrower {
  TerrainRegionGrower(
    this.params,
    this._graph, {
    TerrainPatternRefiner? patternRefiner,
    TerrainNoisePerturbation? noisePerturbation,
    HardwoodForestClusterer? hardwoodClusterer,
    TerrainRegionGrowPhases? phases,
  }) : _patternRefiner =
           patternRefiner ?? TerrainPatternRefiner(params, _graph),
       _noisePerturbation =
           noisePerturbation ?? TerrainNoisePerturbation(params, _graph),
       _hardwoodClusterer =
           hardwoodClusterer ?? const HardwoodForestClusterer(),
       _phases = phases ?? TerrainRegionGrowPhases(params);

  final TileMapParams params;
  final TileMapGridGraph _graph;
  final TerrainPatternRefiner _patternRefiner;
  final TerrainNoisePerturbation _noisePerturbation;
  final HardwoodForestClusterer _hardwoodClusterer;
  final TerrainRegionGrowPhases _phases;

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
    final targets = _phases.buildComponentTargets(
      cells.length,
      allowed,
      distribution,
    );
    final macro = _phases.runMacroPhase(
      terrainGrid,
      grid,
      component,
      cells,
      allowed,
      targets,
      rnd,
    );
    _phases.runMicroPhase(
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
    _phases.cleanupUnassignedInComponent(terrainGrid, component, allowed, rnd);
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
}
