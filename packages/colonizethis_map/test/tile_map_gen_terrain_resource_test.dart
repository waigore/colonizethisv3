import 'dart:math';

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_map/src/gen/terrain_blob_ops.dart';
import 'package:colonizethis_map/src/tile_map_directions.dart';
import 'package:colonizethis_map/src/gen/tile_map_gen_hardwood_cluster.dart';
import 'package:colonizethis_test/test.dart';

import 'support/tile_map_gen_fixtures.dart';
import 'support/tile_map_gen_terrain_resource_scenarios.dart';

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

        expect(
          countTerrain(terrainGrid, TerrainType.hardwoodForest),
          beforeHardwood,
        );
        expect(countTerrain(terrainGrid, TerrainType.scrubForest), beforeScrub);

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
    test('returns empty when there is no land (negative)', () {
      expectMountainRidgePlacerLeavesNoLand();
    });

    test('places mountains and returns mountain-free remaining land (positive)', () {
      expectMountainRidgePlacerPlacesMountains();
    });
  });

  group('TileMapGenTerrainResource (standalone)', () {
    test('run returns (null, null) and logs skip when resourceRules is null', () {
      expectTerrainResourceRunSkipsWithoutRules();
    });

    test('assignTerrainAndResources assigns terrain to every land cell', () {
      expectTerrainResourceAssignsEveryLandCell();
    });

    test('assignTerrainAndResources is deterministic for a fixed seed', () {
      expectTerrainResourceDeterministicForSeed();
    });

    test('assignTerrainAndResources on a no-land grid yields empty terrain', () {
      expectTerrainResourceNoLandGridEmpty();
    });
  });
}
