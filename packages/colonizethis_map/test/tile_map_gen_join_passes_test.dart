import 'dart:math';

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_map/package_logger.dart';
import 'package:colonizethis_map/src/gen/map_gen_pass_payloads.dart';
import 'package:colonizethis_map/src/gen/map_gen_stage.dart';
import 'package:colonizethis_map/src/gen/tile_map_gen_continent_join_pass.dart';
import 'package:colonizethis_map/src/gen/tile_map_gen_sea_zone_subdivide_pass.dart';
import 'package:colonizethis_map/src/gen/tile_map_gen_terrain_jitter_pass.dart';
import 'package:colonizethis_map/src/gen/tile_map_grid_graph.dart';
import 'package:colonizethis_test/test.dart';

/// Per-pass unit tests for the standalone JoinSea passes extracted from the
/// former `_TileMapGenJoinSea` family (Refs #3588). Each pass is exercised in
/// isolation, which the prior `part of` coupling prevented.
void main() {
  group('ContinentJoinPass', () {
    const sea = 's1';

    ContinentJoinPass passFor(TileMapParams params) =>
        ContinentJoinPass(params, packageLogger(), TileMapGridGraph(params));

    test('joinContinents bridges two land components of one continent', () {
      final params = TileMapParams(width: 5, height: 1);
      final pass = passFor(params);
      final grid = <List<String>>[
        ['p1', sea, sea, sea, 'p1'],
      ];
      final (g, tg, rg, didJoin) = pass.joinContinents(
        grid,
        null,
        null,
        {'p1': 0},
        sea,
        null,
        const [(0, 0), (4, 0)],
        const [0, 0],
        null,
        Random(1),
      );

      expect(didJoin, isTrue, reason: 'two components must trigger a join');
      // The carved sea bridge cells become the adjacent province.
      expect(g[0][1], 'p1');
      expect(g[0][2], 'p1');
      expect(g[0][3], 'p1');
      expect(tg, isNull);
      expect(rg, isNull);
      // After joining, all land forms a single connected component.
      final landCells = <(int, int)>{};
      for (var x = 0; x < params.width; x++) {
        if (g[0][x] != sea) landCells.add((x, 0));
      }
      final components = TileMapGridGraph(
        params,
      ).connectedComponentsOfLand(landCells);
      expect(components.length, 1);
    });

    test('joinContinents leaves a single-component continent unchanged', () {
      final params = TileMapParams(width: 3, height: 1);
      final pass = passFor(params);
      final grid = <List<String>>[
        ['p1', 'p1', sea],
      ];
      final (g, _, _, didJoin) = pass.joinContinents(
        grid,
        null,
        null,
        {'p1': 0},
        sea,
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
      final params = TileMapParams(width: 5, height: 1, joinContinents: false);
      final pass = passFor(params);
      final grid = <List<String>>[
        ['p1', sea, sea, sea, 'p1'],
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
            seaZoneId: sea,
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
        final params = TileMapParams(width: 3, height: 3);
        final pass = passFor(params);
        final grid = <List<String>>[
          [sea, 'p1', sea],
          ['p1', 'p1', 'p1'],
          [sea, 'p1', sea],
        ];
        final ocean = <(int, int)>{(0, 0), (2, 0), (0, 2), (2, 2)};
        final restored = pass.preserveSeaFraction(
          grid,
          null,
          null,
          sea,
          ocean,
          2,
        );
        expect(restored, hasLength(2));
        for (final (x, y) in restored) {
          expect(grid[y][x], sea);
        }
      },
    );
  });

  group('SeaZoneSubdividePass', () {
    const sea = 's1';

    SeaZoneSubdividePass passFor(TileMapParams params) =>
        SeaZoneSubdividePass(params, TileMapGridGraph(params));

    test('countSeaCells counts only sea-id cells', () {
      final params = TileMapParams(width: 2, height: 2);
      final pass = passFor(params);
      final grid = <List<String>>[
        [sea, 'p1'],
        ['p1', sea],
      ];
      expect(pass.countSeaCells(grid, sea), 2);
    });

    test('subdivideSeaZonesWithCap splits one component into capped zones', () {
      final params = TileMapParams(
        width: 10,
        height: 1,
        maxSeaZoneFraction: 0.3,
      );
      final pass = passFor(params);
      final grid = <List<String>>[List<String>.filled(10, sea)];
      final (newGrid, zones) = pass.subdivideSeaZonesWithCap(grid, sea, 10);
      // cap = floor(0.3 * 10) = 3 → ceil(10 / 3) = 4 zones.
      expect(zones, 4);
      final assigned = newGrid[0].toSet();
      expect(assigned, {'s1', 's2', 's3', 's4'});
    });

    test(
      'subdivideSeaZonesWithCap keeps a small component as a single zone',
      () {
        final params = TileMapParams(width: 3, height: 1);
        final pass = passFor(params);
        final grid = <List<String>>[
          [sea, sea, sea],
        ];
        final (newGrid, zones) = pass.subdivideSeaZonesWithCap(grid, sea, 3);
        expect(zones, 1);
        expect(newGrid[0], ['s1', 's1', 's1']);
      },
    );

    test('run is a no-op (no log) when there is no sea', () {
      final params = TileMapParams(width: 2, height: 1);
      final pass = passFor(params);
      final grid = <List<String>>[
        ['p1', 'p1'],
      ];
      final logged = <String>[];
      final (newGrid, zones) = pass.run(
        MapGenPassContext<SeaZoneSubdividePassPayload>(
          params: params,
          payload: SeaZoneSubdividePassPayload(
            grid: grid,
            seaZoneId: sea,
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
    List<List<String>> provinceGrid(int size) => List<List<String>>.generate(
      size,
      (_) => List<String>.filled(size, 'p1'),
    );

    test(
      'jitter reassigns dominant edge cells toward supported neighbours',
      () {
        final params = TileMapParams(
          width: 5,
          height: 5,
          jitterMinProvinceSize: 4,
          jitterHomogeneityThreshold: 0.5,
          jitterMaxFraction: 1.0,
          jitterProbability: 1.0,
          jitterNeighborSupportThreshold: 1,
        );
        final pass = TerrainJitterPass(params);
        final grid = provinceGrid(5);
        final terrain = List<List<TerrainType?>>.generate(
          5,
          (_) => List<TerrainType?>.filled(5, TerrainType.plains),
        );
        // A single non-dominant neighbour terrain at the centre.
        terrain[2][2] = TerrainType.hills;
        final resources = List<List<Resource?>>.generate(
          5,
          (_) => List<Resource?>.filled(5, null),
        );

        var hillsBefore = 0;
        for (final row in terrain) {
          hillsBefore += row.where((t) => t == TerrainType.hills).length;
        }
        pass.jitterTerrainByProvince(
          grid,
          terrain,
          resources,
          'oldWorld',
          Random(7),
        );
        var hillsAfter = 0;
        for (final row in terrain) {
          hillsAfter += row.where((t) => t == TerrainType.hills).length;
        }
        expect(
          hillsAfter,
          greaterThan(hillsBefore),
          reason: 'plains edge cells adjacent to hills should flip to hills',
        );
      },
    );

    test('jitter leaves provinces below the min size untouched', () {
      final params = TileMapParams(
        width: 5,
        height: 5,
        jitterMinProvinceSize: 1000,
      );
      final pass = TerrainJitterPass(params);
      final grid = provinceGrid(5);
      final terrain = List<List<TerrainType?>>.generate(
        5,
        (_) => List<TerrainType?>.filled(5, TerrainType.plains),
      );
      terrain[2][2] = TerrainType.hills;
      final resources = List<List<Resource?>>.generate(
        5,
        (_) => List<Resource?>.filled(5, null),
      );
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
