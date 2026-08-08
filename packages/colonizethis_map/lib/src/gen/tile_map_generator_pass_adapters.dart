/// Pass-adapter helpers for [TileMapGenerator.generate].
/// SPEC/program/tile-map-gen-algorithm.md.
library;

import 'dart:math';

import 'package:colonizethis_data/colonizethis_data.dart';

import 'map_gen_pass_payloads.dart';
import 'map_gen_stage.dart';
import 'tile_map_gen_continent_join_pass.dart';
import 'tile_map_gen_sea_zone_subdivide_pass.dart';
import 'tile_map_gen_terrain_jitter_pass.dart';
import 'tile_map_generator_land_seeds.dart';
import 'tile_map_generator_lakes_provinces.dart';
import 'tile_map_generator_terrain_assign.dart';
import 'tile_map_land_sentinel.dart';
import 'tile_map_params.dart';
import '../tile_map_grid.dart';

int countLandCells(List<List<String>> grid) {
  var landCount = 0;
  TileMapGrid.forEachCell(grid, (_, __, value) {
    if (value == kTileMapLandSentinel) landCount++;
  });
  return landCount;
}

(List<List<String>>, List<(int x, int y)>, List<(int x, int y)>, List<int>)
runSeedAndAssignLandPass({
  required TileMapParams params,
  required TileMapGenLandSeeds landSeedService,
  required List<List<String>> grid,
  required Map<String, int> provinceToContinent,
  required String seaZoneId,
  required Random rnd,
  void Function(String)? onLog,
}) {
  final result = landSeedService.run(
    MapGenPassContext<LandSeedPassPayload>(
      params: params,
      payload: LandSeedPassPayload(
        grid: grid,
        provinceToContinent: provinceToContinent,
        seaZoneId: seaZoneId,
        rnd: rnd,
        seedBeforeAssignment: params.seedBeforeAssignment,
      ),
      onLog: onLog,
    ),
  );
  return (
    result.grid,
    result.continentSeeds,
    result.landSeeds,
    result.continentBySeedIndex,
  );
}

List<List<String>> runLakesAndBorderNoisePass({
  required TileMapParams params,
  required TileMapGenLakesProvinces lakeAndProvinceService,
  required List<List<String>> grid,
  required String seaZoneId,
  required List<(int x, int y)> landSeeds,
  required List<int> continentBySeedIndex,
  required Random rnd,
  void Function(String)? onLog,
}) {
  return lakeAndProvinceService.run(
    MapGenPassContext<LakesPassPayload>(
      params: params,
      payload: LakesPassPayload(
        grid: grid,
        seaZoneId: seaZoneId,
        landSeeds: landSeeds,
        continentBySeedIndex: continentBySeedIndex,
        rnd: rnd,
      ),
      onLog: onLog,
    ),
  );
}

(List<List<TerrainType?>>?, List<List<Resource?>>?) runTerrainAndResourcesPass({
  required TileMapParams params,
  required TileMapGenTerrainResource terrainResourceService,
  required List<List<String>> grid,
  required String regionId,
  required ResourceRules? resourceRules,
  required Random rnd,
  void Function(String)? onLog,
}) {
  return terrainResourceService.run(
    MapGenPassContext<TerrainPassPayload>(
      params: params,
      payload: TerrainPassPayload(
        grid: grid,
        regionId: regionId,
        resourceRules: resourceRules,
        rnd: rnd,
      ),
      onLog: onLog,
    ),
  );
}

(List<List<String>>, List<List<TerrainType?>>?, List<List<Resource?>>?)
runJoinContinentsPass({
  required TileMapParams params,
  required ContinentJoinPass continentJoinService,
  required List<List<String>> grid,
  required List<List<TerrainType?>>? terrainGrid,
  required List<List<Resource?>>? resourceGrid,
  required Map<String, int> provinceToContinent,
  required String seaZoneId,
  required String regionId,
  required List<(int x, int y)> landSeeds,
  required List<int> continentBySeedIndex,
  required ResourceRules? resourceRules,
  required Random rnd,
  void Function(String)? onLog,
}) {
  final joinResult = continentJoinService.run(
    MapGenPassContext<ContinentJoinPassPayload>(
      params: params,
      payload: ContinentJoinPassPayload(
        grid: grid,
        terrainGrid: terrainGrid,
        resourceGrid: resourceGrid,
        provinceToContinent: provinceToContinent,
        seaZoneId: seaZoneId,
        mapRegionId: regionId,
        landSeeds: landSeeds,
        continentBySeedIndex: continentBySeedIndex,
        resourceRules: resourceRules,
        rnd: rnd,
      ),
      onLog: onLog,
    ),
  );
  return (joinResult.grid, joinResult.terrainGrid, joinResult.resourceGrid);
}

void runTerrainJitterPass({
  required TileMapParams params,
  required TerrainJitterPass terrainJitterService,
  required List<List<String>> grid,
  required List<List<TerrainType?>>? terrainGrid,
  required List<List<Resource?>>? resourceGrid,
  required String regionId,
  required Random rnd,
}) {
  if (terrainGrid == null || resourceGrid == null) return;
  terrainJitterService.run(
    MapGenPassContext<TerrainJitterPassPayload>(
      params: params,
      payload: TerrainJitterPassPayload(
        grid: grid,
        terrainGrid: terrainGrid,
        resourceGrid: resourceGrid,
        regionId: regionId,
        rnd: rnd,
      ),
    ),
  );
}

List<List<String>> runSubdivideSeaZonesPass({
  required TileMapParams params,
  required SeaZoneSubdividePass seaZoneSubdivideService,
  required List<List<String>> grid,
  required String seaZoneId,
  void Function(String)? onLog,
}) {
  final totalSea = seaZoneSubdivideService.countSeaCells(grid, seaZoneId);
  if (totalSea <= 0) return grid;
  final (newGrid, _) = seaZoneSubdivideService.run(
    MapGenPassContext<SeaZoneSubdividePassPayload>(
      params: params,
      payload: SeaZoneSubdividePassPayload(
        grid: grid,
        seaZoneId: seaZoneId,
        totalSea: totalSea,
      ),
      onLog: onLog,
    ),
  );
  return newGrid;
}
