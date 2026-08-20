import 'dart:math';

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_map/src/gen/map_gen_pass_payloads.dart';
import 'package:colonizethis_map/src/gen/map_gen_stage.dart';
import 'package:colonizethis_map/src/gen/tile_map_gen_mountain_ridges.dart';
import 'package:colonizethis_map/src/gen/tile_map_generator_terrain_assign.dart';
import 'package:colonizethis_map/src/gen/tile_map_grid_graph.dart';
import 'package:colonizethis_map/src/gen/tile_map_land_sentinel.dart';
import 'package:colonizethis_test/test.dart';

import 'tile_map_gen_fixtures.dart';

/// Shared helpers for `tile_map_gen_terrain_resource_test.dart`. Refs #4561.

List<List<String>> allLandGrid(int width, int height) => [
  for (var y = 0; y < height; y++)
    [for (var x = 0; x < width; x++) kTileMapLandSentinel],
];

TileMapGenTerrainResource terrainResourcePassFor(TileMapParams params) =>
    TileMapGenTerrainResource(params, TileMapGridGraph(params));

void expectMountainRidgePlacerLeavesNoLand() {
  final placer = MountainRidgePlacer(
    genParams(width: 4, height: 4),
  );
  final terrainGrid = <List<TerrainType?>>[
    for (var y = 0; y < 4; y++) [for (var x = 0; x < 4; x++) null],
  ];
  final remaining = placer.assignMountainRidges(
    terrainGrid,
    allLandGrid(4, 4),
    const [],
    terrainDistributionForRegion('oldWorld'),
    Random(1),
  );
  expect(remaining, isEmpty);
}

void expectMountainRidgePlacerPlacesMountains() {
  final params = genParams(width: 12, height: 12, seed: 42);
  final placer = MountainRidgePlacer(params);
  final grid = allLandGrid(12, 12);
  final terrainGrid = <List<TerrainType?>>[
    for (var y = 0; y < 12; y++) [for (var x = 0; x < 12; x++) null],
  ];
  final landCells = <(int, int)>[
    for (var y = 0; y < 12; y++)
      for (var x = 0; x < 12; x++) (x, y),
  ];

  final remaining = placer.assignMountainRidges(
    terrainGrid,
    grid,
    landCells,
    terrainDistributionForRegion('oldWorld'),
    Random(params.seed),
  );

  var mountains = 0;
  for (final row in terrainGrid) {
    for (final cell in row) {
      if (cell == TerrainType.mountain) mountains++;
    }
  }
  expect(mountains, greaterThan(0));
  for (final (x, y) in remaining) {
    expect(terrainGrid[y][x], isNot(TerrainType.mountain));
  }
}

void expectTerrainResourceRunSkipsWithoutRules() {
  final params = genParams(width: 4, height: 4);
  final pass = terrainResourcePassFor(params);
  final lines = <String>[];
  final result = pass.run(
    MapGenPassContext<TerrainPassPayload>(
      params: params,
      payload: TerrainPassPayload(
        grid: [
          for (var y = 0; y < 4; y++)
            [for (var x = 0; x < 4; x++) kTileMapLandSentinel],
        ],
        regionId: 'oldWorld',
        resourceRules: null,
        rnd: Random(1),
      ),
      onLog: lines.add,
    ),
  );
  expect(result.$1, isNull);
  expect(result.$2, isNull);
  expect(lines.any((l) => l.contains('skipped')), isTrue);
}

void expectTerrainResourceAssignsEveryLandCell() {
  final params = genParams(width: 10, height: 10, seed: 42);
  final pass = terrainResourcePassFor(params);
  final grid = allLandGrid(10, 10);
  final (terrainGrid, _) = pass.assignTerrainAndResources(
    grid,
    'oldWorld',
    ResourceRules.defaultRules,
    Random(params.seed),
  );
  for (var y = 0; y < 10; y++) {
    for (var x = 0; x < 10; x++) {
      expect(terrainGrid[y][x], isNotNull, reason: 'cell ($x,$y) terrain');
    }
  }
}

void expectTerrainResourceDeterministicForSeed() {
  final params = genParams(width: 10, height: 10, seed: 42);
  List<List<TerrainType?>> run() {
    final grid = allLandGrid(10, 10);
    final (terrainGrid, _) = terrainResourcePassFor(params)
        .assignTerrainAndResources(
          grid,
          'oldWorld',
          ResourceRules.defaultRules,
          Random(params.seed),
        );
    return terrainGrid;
  }

  final a = run();
  final b = run();
  for (var y = 0; y < 10; y++) {
    for (var x = 0; x < 10; x++) {
      expect(a[y][x], b[y][x]);
    }
  }
}

void expectTerrainResourceNoLandGridEmpty() {
  final params = genParams(width: 4, height: 4, seed: 42);
  final pass = terrainResourcePassFor(params);
  final grid = <List<String>>[
    for (var y = 0; y < 4; y++) [for (var x = 0; x < 4; x++) 's1'],
  ];
  final (terrainGrid, resourceGrid) = pass.assignTerrainAndResources(
    grid,
    'oldWorld',
    ResourceRules.defaultRules,
    Random(params.seed),
  );
  for (final row in terrainGrid) {
    expect(row.every((c) => c == null), isTrue);
  }
  for (final row in resourceGrid) {
    expect(row.every((c) => c == null), isTrue);
  }
}
