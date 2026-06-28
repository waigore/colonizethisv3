/// Pass 6–7: terrain ridges, region-growing, resources.
///
/// Extracted from the former `part of 'tile_map_generator.dart'`
/// `_TileMapGenTerrainResource` fragment into a standalone, independently
/// importable [TileMapGenTerrainResource] (Refs #3588). Constructor-injected
/// [TileMapGridGraph] plus strategy services ([MountainRidgePlacer],
/// [TerrainRegionGrower]) replace the former shared-library-scope access; the
/// top-level `_landSentinel` reference is replaced by the public
/// [kTileMapLandSentinel]. Pure relocation; iteration order and RNG sequence are
/// unchanged (determinism preserved).
library;

import 'dart:math';

import 'package:colonizethis_data/colonizethis_data.dart';

import '../tile_map_grid.dart';
import 'map_gen_pass_payloads.dart';
import 'map_gen_stage.dart';
import 'tile_map_gen_mountain_ridges.dart';
import 'tile_map_gen_region_growing.dart';
import 'tile_map_grid_graph.dart';
import 'tile_map_land_sentinel.dart';
import 'tile_map_params.dart';
import 'tile_map_resource_cap_state.dart';
import 'tile_map_resource_placement.dart';

/// Pass 6–7 terrain/resource assignment service. Implements [MapGenPass] so
/// [TileMapGenerator] drives it through the uniform [run] entry. Mountain-ridge
/// placement and non-mountain region growing (plus its pattern-refinement,
/// noise-perturbation, and hardwood-clustering post-passes) are delegated to
/// injected strategy services so each is independently testable.
class TileMapGenTerrainResource
    implements MapGenPass<TerrainPassPayload, TerrainPassResult> {
  TileMapGenTerrainResource(
    TileMapParams params,
    TileMapGridGraph graph, {
    MountainRidgePlacer? mountainPlacer,
    TerrainRegionGrower? regionGrower,
  }) : params = params,
       _mountainPlacer = mountainPlacer ?? MountainRidgePlacer(params),
       _regionGrower = regionGrower ?? TerrainRegionGrower(params, graph);

  @override
  final TileMapParams params;
  final MountainRidgePlacer _mountainPlacer;
  final TerrainRegionGrower _regionGrower;

  /// Uniform pass entry: Pass 6–7 terrain/resource assignment. Returns
  /// `(null, null)` when [TerrainPassPayload.resourceRules] is null (skip),
  /// matching the prior inline orchestration (Refs #3574, slice 4).
  @override
  TerrainPassResult run(MapGenPassContext<TerrainPassPayload> ctx) {
    final payload = ctx.payload;
    final rules = payload.resourceRules;
    if (rules == null) {
      ctx.log('Pass 6–7: Terrain/resources skipped (no rules or no provinces)');
      return (null, null);
    }
    final t = assignTerrainAndResources(
      payload.grid,
      payload.regionId,
      rules,
      payload.rnd,
    );
    var terrainCount = 0;
    var resourceCount = 0;
    TileMapGrid.forEachIndex(params.height, params.width, (y, x) {
      if (t.$1[y][x] != null) terrainCount++;
      if (t.$2[y][x] != null) resourceCount++;
    });
    ctx.log('Pass 6: Terrain assigned ($terrainCount land cells)');
    ctx.log('Pass 7: Resources placed ($resourceCount cells)');
    return t;
  }

  (List<List<TerrainType?>>, List<List<Resource?>>) assignTerrainAndResources(
    List<List<String>> grid,
    String mapRegionId,
    ResourceRules rules,
    Random rnd,
  ) {
    final terrainGrid = TileMapGrid.filled<TerrainType?>(
      params.height,
      params.width,
      null,
    );
    final resourceGrid = TileMapGrid.filled<Resource?>(
      params.height,
      params.width,
      null,
    );

    // Collect land cells (sentinel) for terrain assignment.
    final landCells = <(int x, int y)>[];
    TileMapGrid.forEachCell(grid, (y, x, value) {
      if (value == kTileMapLandSentinel) {
        landCells.add((x, y));
      }
    });
    if (landCells.isEmpty) {
      // No land; nothing to assign.
      return (terrainGrid, resourceGrid);
    }

    final distribution = terrainDistributionForRegion(mapRegionId);

    // Pass 6a: mountain ridges (random-walk ranges).
    final remainingNonMountainLand = _mountainPlacer.assignMountainRidges(
      terrainGrid,
      grid,
      landCells,
      distribution,
      rnd,
    );

    // Pass 6b: region-growing for non-mountain terrains.
    _regionGrower.assignNonMountainTerrains(
      terrainGrid,
      grid,
      mapRegionId,
      distribution,
      rnd,
      remainingNonMountainLand: remainingNonMountainLand,
    );

    // Pass 7: resources, using final terrainGrid and existing rules.
    final capState = (mapRegionId == 'oldWorld' || mapRegionId == 'newWorld')
        ? MultiRegionCapState(
            params.multiRegionResourceCapFraction,
            rules,
            mapRegionId,
          )
        : null;

    TileMapGrid.forEachIndex(params.height, params.width, (y, x) {
      _maybePlaceResourceAtLandCell(
        grid,
        terrainGrid,
        resourceGrid,
        mapRegionId,
        rules,
        capState,
        rnd,
        x,
        y,
      );
    });

    return (terrainGrid, resourceGrid);
  }

  void _maybePlaceResourceAtLandCell(
    List<List<String>> grid,
    List<List<TerrainType?>> terrainGrid,
    List<List<Resource?>> resourceGrid,
    String mapRegionId,
    ResourceRules rules,
    MultiRegionCapState? capState,
    Random rnd,
    int x,
    int y,
  ) {
    if (grid[y][x] != kTileMapLandSentinel) return;
    final terrain = terrainGrid[y][x];
    if (terrain == null) return;
    tryPlaceWeightedResourceAtCell(
      resourceGrid: resourceGrid,
      x: x,
      y: y,
      terrain: terrain,
      mapRegionId: mapRegionId,
      rules: rules,
      rnd: rnd,
      capState: capState,
    );
  }
}
