import 'dart:math';

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_map/src/gen/map_gen_pass_payloads.dart';
import 'package:colonizethis_map/src/gen/map_gen_stage.dart';
import 'package:colonizethis_map/src/gen/tile_map_grid_graph.dart';
import 'package:colonizethis_test/test.dart';

import 'support/tile_map_gen_fixtures.dart';
import 'support/tile_map_gen_join_scenarios.dart';

/// Per-pass unit tests for the standalone JoinSea passes extracted from the
/// former `_TileMapGenJoinSea` family (Refs #3588). Each pass is exercised in
/// isolation, which the prior `part of` coupling prevented.
void main() {
  group('ContinentJoinPass', () {
    test('joinContinents bridges two land components of one continent', () {
      final params = genParams(width: 5, height: 1);
      final pass = continentJoinPassFor(params);
      final grid = <List<String>>[
        ['p1', joinTestSeaId, joinTestSeaId, joinTestSeaId, 'p1'],
      ];
      final (g, tg, rg, didJoin) = pass.joinContinents(
        grid,
        null,
        null,
        {'p1': 0},
        joinTestSeaId,
        null,
        const [(0, 0), (4, 0)],
        const [0, 0],
        null,
        Random(1),
      );

      expect(didJoin, isTrue, reason: 'two components must trigger a join');
      expect(g[0][1], 'p1');
      expect(g[0][2], 'p1');
      expect(g[0][3], 'p1');
      expect(tg, isNull);
      expect(rg, isNull);
      final landCells = <(int, int)>{};
      for (var x = 0; x < params.width; x++) {
        if (g[0][x] != joinTestSeaId) landCells.add((x, 0));
      }
      final components = TileMapGridGraph(
        params,
      ).connectedComponentsOfLand(landCells);
      expect(components.length, 1);
    });

    test('joinContinents leaves a single-component continent unchanged', () {
      final params = genParams(width: 3, height: 1);
      final pass = continentJoinPassFor(params);
      final grid = <List<String>>[
        ['p1', 'p1', joinTestSeaId],
      ];
      final (g, _, _, didJoin) = pass.joinContinents(
        grid,
        null,
        null,
        {'p1': 0},
        joinTestSeaId,
        null,
        const [(0, 0)],
        const [0],
        null,
        Random(1),
      );
      expect(didJoin, isFalse);
      expect(g, grid);
    });

    test('run returns inputs unchanged when joinContinents is disabled', () {
      final params = genParams(width: 5, height: 1, joinContinents: false);
      final pass = continentJoinPassFor(params);
      final grid = <List<String>>[
        ['p1', joinTestSeaId, joinTestSeaId, joinTestSeaId, 'p1'],
      ];
      final logged = <String>[];
      final result = pass.run(
        MapGenPassContext<ContinentJoinPassPayload>(
          params: params,
          payload: ContinentJoinPassPayload(
            grid: grid,
            terrainGrid: null,
            resourceGrid: null,
            provinceToContinent: const {'p1': 0},
            seaZoneId: joinTestSeaId,
            mapRegionId: null,
            landSeeds: const [(0, 0), (4, 0)],
            continentBySeedIndex: const [0, 0],
            resourceRules: null,
            rnd: Random(1),
          ),
          onLog: logged.add,
        ),
      );
      expect(result.didJoin, isFalse);
      expect(identical(result.grid, grid), isTrue);
      expect(logged, isEmpty);
    });

    test(
      'preserveSeaFraction restores coastal land to sea (count-bounded)',
      () {
        final params = genParams(width: 3, height: 3);
        final pass = continentJoinPassFor(params);
        final grid = <List<String>>[
          [joinTestSeaId, 'p1', joinTestSeaId],
          ['p1', 'p1', 'p1'],
          [joinTestSeaId, 'p1', joinTestSeaId],
        ];
        final ocean = <(int, int)>{(0, 0), (2, 0), (0, 2), (2, 2)};
        final restored = pass.preserveSeaFraction(
          grid,
          null,
          null,
          joinTestSeaId,
          ocean,
          2,
        );
        expect(restored, hasLength(2));
        for (final (x, y) in restored) {
          expect(grid[y][x], joinTestSeaId);
        }
      },
    );
  });

  group('SeaZoneSubdividePass', () {
    test('countSeaCells counts only sea-id cells', () {
      final params = genParams(width: 2, height: 2);
      final pass = seaZoneSubdividePassFor(params);
      final grid = <List<String>>[
        [joinTestSeaId, 'p1'],
        ['p1', joinTestSeaId],
      ];
      expect(pass.countSeaCells(grid, joinTestSeaId), 2);
    });

    test('subdivideSeaZonesWithCap splits one component into capped zones', () {
      final params = genParams(
        width: 10,
        height: 1,
        maxSeaZoneFraction: 0.3,
      );
      final pass = seaZoneSubdividePassFor(params);
      final grid = <List<String>>[List<String>.filled(10, joinTestSeaId)];
      final (newGrid, zones) = pass.subdivideSeaZonesWithCap(grid, joinTestSeaId, 10);
      expect(zones, 4);
      final assigned = newGrid[0].toSet();
      expect(assigned, {'s1', 's2', 's3', 's4'});
    });

    test(
      'subdivideSeaZonesWithCap keeps a small component as a single zone',
      () {
        final params = genParams(width: 3, height: 1);
        final pass = seaZoneSubdividePassFor(params);
        final grid = <List<String>>[
          [joinTestSeaId, joinTestSeaId, joinTestSeaId],
        ];
        final (newGrid, zones) = pass.subdivideSeaZonesWithCap(grid, joinTestSeaId, 3);
        expect(zones, 1);
        expect(newGrid[0], ['s1', 's1', 's1']);
      },
    );

    test('run is a no-op (no log) when there is no sea', () {
      final params = genParams(width: 2, height: 1);
      final pass = seaZoneSubdividePassFor(params);
      final grid = <List<String>>[
        ['p1', 'p1'],
      ];
      final logged = <String>[];
      final (newGrid, zones) = pass.run(
        MapGenPassContext<SeaZoneSubdividePassPayload>(
          params: params,
          payload: SeaZoneSubdividePassPayload(
            grid: grid,
            seaZoneId: joinTestSeaId,
            totalSea: 0,
          ),
          onLog: logged.add,
        ),
      );
      expect(zones, 0);
      expect(identical(newGrid, grid), isTrue);
      expect(logged, isEmpty);
    });
  });

  group('TerrainJitterPass', () {
    test(
      'jitter reassigns dominant edge cells toward supported neighbours',
      () {
        final params = genParams(
          width: 5,
          height: 5,
          jitterMinProvinceSize: 4,
          jitterHomogeneityThreshold: 0.5,
          jitterMaxFraction: 1.0,
          jitterProbability: 1.0,
          jitterNeighborSupportThreshold: 1,
        );
        final pass = terrainJitterPassFor(params);
        final grid = provinceOnlyGrid(5);
        final terrain = plainsTerrainGrid(5);
        terrain[2][2] = TerrainType.hills;
        final resources = emptyResourceGrid(5);

        final hillsBefore = countTerrainType(terrain, TerrainType.hills);
        pass.jitterTerrainByProvince(
          grid,
          terrain,
          resources,
          'oldWorld',
          Random(7),
        );
        final hillsAfter = countTerrainType(terrain, TerrainType.hills);
        expect(
          hillsAfter,
          greaterThan(hillsBefore),
          reason: 'plains edge cells adjacent to hills should flip to hills',
        );
      },
    );

    test('jitter leaves provinces below the min size untouched', () {
      final params = genParams(
        width: 5,
        height: 5,
        jitterMinProvinceSize: 1000,
      );
      final pass = terrainJitterPassFor(params);
      final grid = provinceOnlyGrid(5);
      final terrain = plainsTerrainGrid(5);
      terrain[2][2] = TerrainType.hills;
      final resources = emptyResourceGrid(5);
      final before = [
        for (final row in terrain) [...row],
      ];
      pass.run(
        MapGenPassContext<TerrainJitterPassPayload>(
          params: params,
          payload: TerrainJitterPassPayload(
            grid: grid,
            terrainGrid: terrain,
            resourceGrid: resources,
            regionId: 'oldWorld',
            rnd: Random(7),
          ),
        ),
      );
      expect(terrain, before);
    });
  });
}
