import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:logger/logger.dart';

import 'support/tile_map_gen_fixtures.dart';
import 'support/tile_map_generator_core_scenarios.dart';

void main() {
  group('TileMapGenerator core', () {
    test('generates grid with correct dimensions', () {
      final params = genParams(
        width: 20,
        height: 15,
        seed: 1,
      );
      final (result, topology) = runTileMapGeneration(
        params: params,
        numProvinces: 1,
        numContinents: 1,
        regionId: 'r1',
      );
      expect(result.width, 20);
      expect(result.height, 15);
      expect(result.grid.length, 15);
      for (final row in result.grid) {
        expect(row.length, 20);
        expect(
          row.every((id) => id == 'p1' || RegExp(r'^s\d+$').hasMatch(id)),
          isTrue,
        );
      }
      expect(topology.nodes.length, greaterThanOrEqualTo(2));
    });

    test(
      'TileMapGenerator.generate emits end info with continents and success',
      () {
        final capturedEvents = <LogEvent>[];
        void listener(LogEvent e) => capturedEvents.add(e);
        Logger.addLogListener(listener);
        Logger.level = Level.info;

        try {
          final params = genParams(
            width: 20,
            height: 15,
            seed: 1,
          );
          // map-generation-harness-exempt: constructor/DI probe
          final gen = TileMapGenerator(params: params);

          final (_, topology) = gen.generate(
            numProvinces: 3,
            numContinents: 2,
            regionId: 'r1',
          );

          final expectedProvinces = topology.nodes
              .where((n) => n.type == TopologyNodeType.province)
              .length;
          const expectedContinents = 2;

          final endMessages = capturedEvents
              .where((e) => e.message.contains('TileMapGenerator.generate end'))
              .map((e) => e.message)
              .toList();
          expect(endMessages.length, 1);

          final endLine = endMessages.single;
          expect(endLine, contains('regionId=r1'));
          expect(endLine, contains('provinces=$expectedProvinces'));
          expect(endLine, contains('continents=$expectedContinents'));
          expect(endLine, contains('success=true'));
        } finally {
          Logger.removeLogListener(listener);
          Logger.level = Level.info;
        }
      },
    );

    test('two adjacent regions touch in grid', () {
      final params = genParams(
        width: 30,
        height: 30,
        seed: 42,
        maxEnforceIterations: 5,
      );
      final (result, _) = runTileMapGeneration(
        params: params,
        numProvinces: 2,
        numContinents: 1,
        regionId: 'r1',
      );
      final pairs = result.adjacentRegionPairs();
      expect(pairs.contains('p1|p2'), isTrue);
    });

    test('numProvinces 0 throws', () {
      final gen = coreTestGenerator(width: 10, height: 10);
      expect(
        () => gen.generate(numProvinces: 0, numContinents: 1, regionId: 'r1'),
        throwsArgumentError,
      );
    });

    test('numContinents 0 throws', () {
      final gen = coreTestGenerator(width: 10, height: 10);
      expect(
        () => gen.generate(numProvinces: 1, numContinents: 0, regionId: 'r1'),
        throwsArgumentError,
      );
    });

    test(
      'two-phase sea fraction: land count matches (1 - seaFraction) * width * height',
      () {
        const w = 20;
        const h = 20;
        const seaFraction = 0.6;
        final params = genParams(
          width: w,
          height: h,
          seed: 12345,
          seaFraction: seaFraction,
        );
        final (result, _) = runTileMapGeneration(
          params: params,
          numProvinces: 1,
          numContinents: 1,
          regionId: 'r1',
        );
        final landCount = countLandCells(result, w, h);
        final expectedLand = ((1 - seaFraction) * w * h).round();
        expect(landCount, expectedLand);
      },
    );

    test('onLog receives a line per pass', () {
      final logLines = <String>[];
      runTileMapGeneration(
        params: genParams(width: 10, height: 10, seed: 1),
        numProvinces: 1,
        numContinents: 1,
        regionId: 'r1',
        onLog: logLines.add,
        omitResourceRules: true,
      );
      expectStandardPassLogLines(logLines);
    });

    test(
      'emits generation_params map log with derived grid and key toggles',
      () {
        final capturedEvents = <LogEvent>[];
        addLoggerCaptureTearDown(capturedEvents);

        final params = genParams(
          width: 12,
          height: 9,
          seed: 77,
          seaFraction: 0.55,
          joinContinents: true,
          skipFillLakes: true,
          seedBeforeAssignment: false,
        );
        runTileMapGeneration(
          params: params,
          numProvinces: 3,
          numContinents: 2,
          regionId: 'oldWorld',
          omitResourceRules: true,
        );

        final message = capturedEvents
            .map((e) => e.message.toString())
            .firstWhere((m) => m.contains('map: generation_params'));
        expect(message, contains('regionId=oldWorld'));
        expect(message, contains('numProvinces=3'));
        expect(message, contains('numContinents=2'));
        expect(message, contains('width=12'));
        expect(message, contains('height=9'));
        expect(message, contains('seed=77'));
        expect(message, contains('seaFraction=0.55'));
        expect(message, contains('joinContinents=true'));
        expect(message, contains('skipFillLakes=true'));
        expect(message, contains('seedBeforeAssignment=false'));
      },
    );

    test(
      'final grid has only province and sea zone ids (no land sentinel)',
      () {
        final (result, topology) = runTileMapGeneration(
          params: genParams(
            width: 24,
            height: 24,
            seed: 7,
          ),
          numProvinces: 2,
          numContinents: 1,
          regionId: 'r1',
        );
        expectAllCellsHaveValidTopologyIds(result, topology);
      },
    );

    test('inferred topology matches grid adjacencies', () {
      final (result, topology) = runTileMapGeneration(
        params: genParams(
          width: 30,
          height: 30,
          seed: 42,
        ),
        numProvinces: 2,
        numContinents: 1,
        regionId: 'r1',
      );
      final validation = validateTileMapTopology(topology, result);
      expect(validation.missing, isEmpty);
      expect(validation.extra, isEmpty);
      expect(validation.hasIssues, isFalse);
    });

    test(
      'seed 125148772 with default buffer and fill lakes has no p6-p33 land bridge',
      () {
        final topology = runLandBridgeRegressionGeneration();
        expect(
          topologyHasProvinceEdge(topology, 'p6', 'p33'),
          isFalse,
        );
      },
    );

    test(
      'joinContinents completes for small multi-continent grids (regression: no hang)',
      () {
        for (final seed in [0, 7, 42, 99, 777]) {
          runTileMapGeneration(
            params: genParams(
              width: 20,
              height: 18,
              seed: seed,
            ),
            numProvinces: 6,
            numContinents: 3,
            regionId: 'oldWorld',
          );
        }
      },
    );
  });
}
