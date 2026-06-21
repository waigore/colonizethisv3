import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:logger/logger.dart';

void main() {
  group('TileMapGenerator core', () {
    test('generates grid with correct dimensions', () {
      final params = TileMapParams(
        width: 20,
        height: 15,
        seed: 1,
        seaFraction: 0.6,
      );
      final (result, topology) = TileMapGenerator(
        params: params,
      ).generate(numProvinces: 1, numContinents: 1, regionId: 'r1');
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
          final params = TileMapParams(
            width: 20,
            height: 15,
            seed: 1,
            seaFraction: 0.6,
          );
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
      final params = TileMapParams(
        width: 30,
        height: 30,
        seed: 42,
        maxEnforceIterations: 5,
        seaFraction: 0.6,
      );
      final (result, _) = TileMapGenerator(
        params: params,
      ).generate(numProvinces: 2, numContinents: 1, regionId: 'r1');
      final pairs = result.adjacentRegionPairs();
      expect(pairs.contains('p1|p2'), isTrue);
    });

    test('numProvinces 0 throws', () {
      final gen = TileMapGenerator(
        params: TileMapParams(width: 10, height: 10),
      );
      expect(
        () => gen.generate(numProvinces: 0, numContinents: 1, regionId: 'r1'),
        throwsArgumentError,
      );
    });

    test('numContinents 0 throws', () {
      final gen = TileMapGenerator(
        params: TileMapParams(width: 10, height: 10),
      );
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
        final params = TileMapParams(
          width: w,
          height: h,
          seed: 12345,
          seaFraction: seaFraction,
        );
        final (result, _) = TileMapGenerator(
          params: params,
        ).generate(numProvinces: 1, numContinents: 1, regionId: 'r1');
        var landCount = 0;
        for (var y = 0; y < h; y++) {
          for (var x = 0; x < w; x++) {
            if (!RegExp(r'^s\d+$').hasMatch(result.cell(x, y))) landCount++;
          }
        }
        final expectedLand = ((1 - seaFraction) * w * h).round();
        expect(landCount, expectedLand);
      },
    );

    test('onLog receives a line per pass', () {
      final logLines = <String>[];
      TileMapGenerator(
        params: TileMapParams(width: 10, height: 10, seed: 1, seaFraction: 0.6),
      ).generate(
        numProvinces: 1,
        numContinents: 1,
        regionId: 'r1',
        onLog: (msg) => logLines.add(msg),
      );
      expect(logLines.any((s) => s.contains('Pass 1')), isTrue);
      expect(logLines.any((s) => s.contains('Pass 2')), isTrue);
      expect(logLines.any((s) => s.contains('Pass 3')), isTrue);
      expect(logLines.any((s) => s.contains('Pass 4')), isTrue);
      expect(logLines.any((s) => s.contains('Pass 5')), isTrue);
      expect(logLines.any((s) => s.contains('Pass 6')), isTrue);
      expect(logLines.any((s) => s.contains('Pass 8')), isTrue);
      expect(logLines.any((s) => s.contains('Pass 9')), isTrue);
      expect(logLines.any((s) => s.contains('Pass 11')), isTrue);
    });

    test(
      'emits generation_params map log with derived grid and key toggles',
      () {
        final capturedEvents = <LogEvent>[];
        void listener(LogEvent event) => capturedEvents.add(event);
        Logger.addLogListener(listener);
        addTearDown(() => Logger.removeLogListener(listener));

        final params = TileMapParams(
          width: 12,
          height: 9,
          seed: 77,
          seaFraction: 0.55,
          joinContinents: true,
          skipFillLakes: true,
          seedBeforeAssignment: false,
        );
        TileMapGenerator(
          params: params,
        ).generate(numProvinces: 3, numContinents: 2, regionId: 'oldWorld');

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
        final (result, topology) = TileMapGenerator(
          params: TileMapParams(
            width: 24,
            height: 24,
            seed: 7,
            seaFraction: 0.6,
          ),
        ).generate(numProvinces: 2, numContinents: 1, regionId: 'r1');
        final validIds = topology.nodes.map((n) => n.id).toSet();
        for (var y = 0; y < result.height; y++) {
          for (var x = 0; x < result.width; x++) {
            expect(
              validIds.contains(result.cell(x, y)),
              isTrue,
              reason: 'cell ($x,$y) has id ${result.cell(x, y)}',
            );
          }
        }
      },
    );

    test('inferred topology matches grid adjacencies', () {
      final (result, topology) = TileMapGenerator(
        params: TileMapParams(
          width: 30,
          height: 30,
          seed: 42,
          seaFraction: 0.6,
        ),
      ).generate(numProvinces: 2, numContinents: 1, regionId: 'r1');
      final validation = validateTileMapTopology(topology, result);
      expect(validation.missing, isEmpty);
      expect(validation.extra, isEmpty);
      expect(validation.hasIssues, isFalse);
    });

    test(
      'seed 125148772 with default buffer and fill lakes has no p6-p33 land bridge',
      () {
        final mapGenParams = MapGenerationParams(
          seed: 125148772,
          numContinents: 3,
          continentBufferTiles: 2,
          skipFillLakes: false,
        );
        final size = computeGridSizeFromParams(60, mapGenParams);
        final params = TileMapParams(
          width: size.width,
          height: size.height,
          seed: mapGenParams.seed,
          seaFraction: mapGenParams.seaFraction,
          continentBufferTiles: mapGenParams.continentBufferTiles,
          skipFillLakes: mapGenParams.skipFillLakes,
        );
        final (_, topology) = TileMapGenerator(
          params: params,
        ).generate(numProvinces: 60, numContinents: 3, regionId: 'oldWorld');
        final p6p33Key = 'p6|p33';
        final hasBridge = topology.edges.any((e) {
          final key = e.id1.compareTo(e.id2) < 0
              ? '${e.id1}|${e.id2}'
              : '${e.id2}|${e.id1}';
          return key == p6p33Key;
        });
        expect(hasBridge, isFalse);
      },
    );

    test(
      'joinContinents completes for small multi-continent grids (regression: no hang)',
      () {
        for (final seed in [0, 7, 42, 99, 777]) {
          final params = TileMapParams(
            width: 20,
            height: 18,
            seed: seed,
            seaFraction: 0.6,
          );
          TileMapGenerator(
            params: params,
          ).generate(numProvinces: 6, numContinents: 3, regionId: 'oldWorld');
        }
      },
    );
  });
}
