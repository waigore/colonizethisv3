import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_map/src/tile_map_topology_helpers.dart';

import 'support/tile_map_gen_fixtures.dart';
import 'support/tile_map_generator_sea_lakes_support.dart';

void main() {
  group('TileMapGenerator sea and lakes', () {
    test(
      'no enclosed sea after fill-lakes: all sea connected to grid edge',
      () {
        final (result, _) = runTileMapGeneration(
          params: genParams(width: 30, height: 30, seed: 11),
          numProvinces: 1,
          numContinents: 1,
          regionId: 'r1',
        );
        expectNoEnclosedSeaAfterFillLakes(result);
      },
    );

    test(
      'generated map has at least one sea zone on grid boundary (warp zone placement)',
      () {
        // SPEC/game/map-topology.md § Warp zones: placement uses sea zones on the map edge.
        final (result, topology) = runTileMapGeneration(
          params: genParams(width: 24, height: 24, seed: 7),
          numProvinces: 2,
          numContinents: 1,
          regionId: 'r1',
        );
        final seaZoneIds = seaZoneIdsFromTopology(topology);
        if (seaZoneIds.isEmpty) return;
        final boundaryIds = <String>{};
        final w = result.width;
        final h = result.height;
        for (var x = 0; x < w; x++) {
          boundaryIds.add(result.cell(x, 0));
          boundaryIds.add(result.cell(x, h - 1));
        }
        for (var y = 0; y < h; y++) {
          boundaryIds.add(result.cell(0, y));
          boundaryIds.add(result.cell(w - 1, y));
        }
        final edgeSea = boundaryIds.where(seaZoneIds.contains).toSet();
        expect(
          edgeSea,
          isNotEmpty,
          reason:
              'At least one sea zone should touch grid boundary for warp zone generation',
        );
      },
    );

    test('Pass 11 subdivides sea: result has sea zone ids s1, s2, ...', () {
      final (result, topology) = runTileMapGeneration(
        params: genParams(width: 24, height: 24, seed: 7),
        numProvinces: 2,
        numContinents: 1,
        regionId: 'r1',
      );
      final seaNodes = seaZoneIdsFromTopology(topology);
      expect(seaNodes, isNotEmpty);
      for (final id in seaNodes) {
        expect(RegExp(r'^s\d+$').hasMatch(id), isTrue);
      }
      final gridSeaIds = <String>{};
      for (var y = 0; y < result.height; y++) {
        for (var x = 0; x < result.width; x++) {
          final id = result.cell(x, y);
          if (RegExp(r'^s\d+$').hasMatch(id)) gridSeaIds.add(id);
        }
      }
      expect(gridSeaIds, equals(seaNodes));
    });

    test(
      'Pass 11 sea zone size cap: subdivision produces many zones when sea is large',
      () {
        final (result, topology) = runTileMapGeneration(
          params: genParams(
            width: 40,
            height: 40,
            seed: 99,
            seaFraction: 0.65,
            maxSeaZoneFraction: 0.05,
          ),
          numProvinces: 4,
          numContinents: 1,
          regionId: 'r1',
        );
        var totalSea = 0;
        for (var y = 0; y < result.height; y++) {
          for (var x = 0; x < result.width; x++) {
            if (RegExp(r'^s\d+$').hasMatch(result.cell(x, y))) totalSea++;
          }
        }
        if (totalSea == 0) return;
        final seaZoneCount = seaZoneIdsFromTopology(topology).length;
        // With 5% cap, one ocean should be split into at least ~20 zones.
        expect(
          seaZoneCount,
          greaterThanOrEqualTo(15),
          reason:
              'Expected many sea zones when cap is 5% of $totalSea sea tiles',
        );
      },
    );

    test('Pass 11 log mentions sea zones and cap', () {
      final logLines = <String>[];
      runTileMapGeneration(
        params: genParams(width: 24, height: 24, seed: 7),
        numProvinces: 2,
        numContinents: 1,
        regionId: 'r1',
        onLog: (msg) => logLines.add(msg),
      );
      final pass11 = logLines.where((s) => s.contains('Pass 11')).toList();
      expect(pass11, isNotEmpty);
      expect(pass11.first, contains('Sea zone subdivision'));
      expect(pass11.first, contains('cap'));
    });

    test('Pass 4 log mentions lakes and moats', () {
      final logLines = <String>[];
      runTileMapGeneration(
        params: genParams(width: 10, height: 10, seed: 1),
        numProvinces: 1,
        numContinents: 1,
        regionId: 'r1',
        onLog: (msg) => logLines.add(msg),
        omitResourceRules: true,
      );
      expect(logLines.any((s) => s.contains('Pass 4')), isTrue);
      expect(
        logLines.any(
          (s) =>
              s.contains('Pass 4') &&
              s.contains('lakes') &&
              s.contains('moats'),
        ),
        isTrue,
      );
    });

    test('skipFillLakes true logs Fill lakes skipped', () {
      final logLines = <String>[];
      runTileMapGeneration(
        params: genParams(width: 10, height: 10, seed: 1, skipFillLakes: true),
        numProvinces: 1,
        numContinents: 1,
        regionId: 'r1',
        onLog: (msg) => logLines.add(msg),
        omitResourceRules: true,
      );
      expect(
        logLines.any((s) => s.contains('Fill lakes') && s.contains('skipped')),
        isTrue,
      );
    });

    test('borderNoise greater than zero applies border noise', () {
      final logLines = <String>[];
      final (result, _) = runTileMapGeneration(
        params: genParams(width: 20, height: 20, seed: 2, borderNoise: 0.5),
        numProvinces: 2,
        numContinents: 1,
        regionId: 'r1',
        resourceRules: ResourceRules.defaultRules,
        onLog: (msg) => logLines.add(msg),
      );
      expect(result.terrainGrid, isNotNull);
      expect(
        logLines.any((s) => s.contains('Border noise') || s.contains('Pass 5')),
        isTrue,
      );
    });
  });
}
