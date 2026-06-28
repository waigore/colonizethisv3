import 'dart:math';

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_map/src/gen/map_gen_pass_payloads.dart';
import 'package:colonizethis_map/src/gen/map_gen_stage.dart';
import 'package:colonizethis_map/src/gen/terrain_blob_ops.dart';
import 'package:colonizethis_map/src/tile_map_directions.dart';
import 'package:colonizethis_map/src/gen/tile_map_gen_hardwood_cluster.dart';
import 'package:colonizethis_map/src/gen/tile_map_gen_mountain_ridges.dart';
import 'package:colonizethis_map/src/gen/tile_map_generator_terrain_assign.dart';
import 'package:colonizethis_map/src/gen/tile_map_grid_graph.dart';
import 'package:colonizethis_map/src/gen/tile_map_land_sentinel.dart';
import 'package:colonizethis_test/test.dart';

import 'support/tile_map_gen_fixtures.dart';

// Direct unit tests for the standalone terrain-resource family extracted from
// the former `part of 'tile_map_generator.dart'` fragment (Refs #3588). Each
// class is constructed directly — no `TileMapGenerator` orchestration — to
// confirm the passes are individually testable.
void main() {
  suppressLogsForTests();

  group('terrain_blob_ops (shared, dedup helpers)', () {
    test('componentCellsOfTerrain returns only cells of the requested terrain', () {
      final terrainGrid = <List<TerrainType?>>[
        [TerrainType.plains, TerrainType.hills],
        [TerrainType.plains, TerrainType.plains],
      ];
      final component = {(0, 0), (1, 0), (0, 1), (1, 1)};
      final plains = componentCellsOfTerrain(
        terrainGrid,
        component,
        TerrainType.plains,
      );
      expect(plains, {(0, 0), (0, 1), (1, 1)});
      expect(
        componentCellsOfTerrain(terrainGrid, component, TerrainType.swamp),
        isEmpty,
      );
    });

    test('blobInteriorCells excludes edge and out-of-bounds-adjacent cells', () {
      // 3x3 blob; only the center (1,1) has all four 4-neighbours inside.
      final blob = <(int, int)>{
        for (var y = 0; y < 3; y++)
          for (var x = 0; x < 3; x++) (x, y),
      };
      final interior = blobInteriorCells(blob, 3, 3, kTileMapDirections4);
      expect(interior, [(1, 1)]);
    });

    test('weightedPickTerrainFromOptions always returns a provided option', () {
      const distribution = TerrainDistribution(
        mountainFraction: 0.0,
        nonMountainFractions: {TerrainType.plains: 1.0},
      );
      final rnd = Random(1);
      for (var i = 0; i < 20; i++) {
        final pick = weightedPickTerrainFromOptions(
          [TerrainType.plains],
          distribution,
          rnd,
        );
        expect(pick, TerrainType.plains);
      }
    });
  });

  group('HardwoodForestClusterer (standalone)', () {
    const clusterer = HardwoodForestClusterer();

    int countTerrain(List<List<TerrainType?>> g, TerrainType t) {
      var n = 0;
      for (final row in g) {
        for (final cell in row) {
          if (cell == t) n++;
        }
      }
      return n;
    }

    test('leaves a component with a single hardwood cell unchanged (negative)', () {
      final terrainGrid = <List<TerrainType?>>[
        [TerrainType.hardwoodForest, TerrainType.plains],
        [TerrainType.plains, TerrainType.plains],
      ];
      final component = {(0, 0), (1, 0), (0, 1), (1, 1)};
      clusterer.cluster(terrainGrid, component, Random(3));
      expect(terrainGrid[0][0], TerrainType.hardwoodForest);
      expect(countTerrain(terrainGrid, TerrainType.hardwoodForest), 1);
    });

    test(
      'clusters isolated hardwood via reciprocal scrub swap, preserving counts',
      () {
        // Row 0: H S H  (two isolated hardwoods flanking a scrub).
        final terrainGrid = <List<TerrainType?>>[
          [
            TerrainType.hardwoodForest,
            TerrainType.scrubForest,
            TerrainType.hardwoodForest,
          ],
          [TerrainType.plains, TerrainType.plains, TerrainType.plains],
        ];
        final component = {
          for (var y = 0; y < 2; y++)
            for (var x = 0; x < 3; x++) (x, y),
        };

        final beforeHardwood = countTerrain(
          terrainGrid,
          TerrainType.hardwoodForest,
        );
        final beforeScrub = countTerrain(terrainGrid, TerrainType.scrubForest);

        clusterer.cluster(terrainGrid, component, Random(7));

        // Reciprocal swaps preserve both terrain counts exactly.
        expect(
          countTerrain(terrainGrid, TerrainType.hardwoodForest),
          beforeHardwood,
        );
        expect(countTerrain(terrainGrid, TerrainType.scrubForest), beforeScrub);

        // After clustering at least one hardwood cell is adjacent to another
        // hardwood cell (it is no longer isolated).
        var anyAdjacentHardwoodPair = false;
        for (final (x, y) in component) {
          if (terrainGrid[y][x] != TerrainType.hardwoodForest) continue;
          for (final (dx, dy) in kTileMapDirections4) {
            final nx = x + dx;
            final ny = y + dy;
            if (!component.contains((nx, ny))) continue;
            if (terrainGrid[ny][nx] == TerrainType.hardwoodForest) {
              anyAdjacentHardwoodPair = true;
            }
          }
        }
        expect(anyAdjacentHardwoodPair, isTrue);
      },
    );
  });

  group('MountainRidgePlacer (standalone)', () {
    List<List<String>> allLandGrid(int width, int height) => [
      for (var y = 0; y < height; y++)
        [for (var x = 0; x < width; x++) kTileMapLandSentinel],
    ];

    test('returns empty when there is no land (negative)', () {
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
    });

    test('places mountains and returns mountain-free remaining land (positive)', () {
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
      // Returned cells are exactly the non-mountain land cells.
      for (final (x, y) in remaining) {
        expect(terrainGrid[y][x], isNot(TerrainType.mountain));
      }
    });
  });

  group('TileMapGenTerrainResource (standalone)', () {
    TileMapGenTerrainResource build(TileMapParams params) =>
        TileMapGenTerrainResource(params, TileMapGridGraph(params));

    test('run returns (null, null) and logs skip when resourceRules is null', () {
      final params = genParams(width: 4, height: 4);
      final pass = build(params);
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
    });

    test('assignTerrainAndResources assigns terrain to every land cell', () {
      final params = genParams(width: 10, height: 10, seed: 42);
      final pass = build(params);
      final grid = <List<String>>[
        for (var y = 0; y < 10; y++)
          [for (var x = 0; x < 10; x++) kTileMapLandSentinel],
      ];
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
    });

    test('assignTerrainAndResources is deterministic for a fixed seed', () {
      final params = genParams(width: 10, height: 10, seed: 42);
      List<List<TerrainType?>> run() {
        final grid = <List<String>>[
          for (var y = 0; y < 10; y++)
            [for (var x = 0; x < 10; x++) kTileMapLandSentinel],
        ];
        final (terrainGrid, _) = build(params).assignTerrainAndResources(
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
    });

    test('assignTerrainAndResources on a no-land grid yields empty terrain', () {
      final params = genParams(width: 4, height: 4, seed: 42);
      final pass = build(params);
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
    });
  });
}
