import 'dart:io';

import 'package:colonizethis_world/src/trace/turn_trace_contracts.dart';
import 'package:colonizethis_world/src/trace/turn_trace_file_exporter.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  late Directory tempRoot;

  setUp(() async {
    tempRoot = await Directory.systemTemp.createTemp(
      'turn_trace_file_exporter_test_',
    );
  });

  tearDown(() async {
    if (await tempRoot.exists()) {
      await tempRoot.delete(recursive: true);
    }
  });

  test(
    'exports to tmp/turn-traces/{gameId}/turn-{turnNumber}-{timestamp}.json',
    () async {
      final exporter = TurnTraceFileExporter(rootDirectory: tempRoot.path);
      final document = _document(
        gameId: 'game-42',
        turnNumber: 7,
        exportedAt: '2026-05-08T07:10:11.123Z',
      );

      final file = await exporter.export(document);

      final expectedDirectory = '${tempRoot.path}/turn-traces/game-42';
      expect(file.path.startsWith(expectedDirectory), isTrue);
      final fileName = file.uri.pathSegments.last;
      expect(fileName, 'turn-7-20260508T071011123Z.json');
      expect(await file.exists(), isTrue);
    },
  );

  test(
    'prunes oldest traces to keep only latest ten files per gameId',
    () async {
      final exporter = TurnTraceFileExporter(rootDirectory: tempRoot.path);

      for (var turn = 1; turn <= 12; turn++) {
        final timestamp = DateTime.utc(2026, 5, 8, 7, 0, turn);
        final document = _document(
          gameId: 'game-retain',
          turnNumber: turn,
          exportedAt: timestamp.toIso8601String(),
        );
        await exporter.export(document);
      }

      final directory = Directory('${tempRoot.path}/turn-traces/game-retain');
      final files =
          directory
              .listSync()
              .whereType<File>()
              .map((file) => file.uri.pathSegments.last)
              .toList()
            ..sort();
      expect(files.length, 10);
      expect(files.contains('turn-1-20260508T070001000Z.json'), isFalse);
      expect(files.contains('turn-2-20260508T070002000Z.json'), isFalse);
      expect(files.contains('turn-12-20260508T070012000Z.json'), isTrue);
    },
  );

  test(
    'empty traceDirectorySegment drops turn-traces parent directory',
    () async {
      final exporter = TurnTraceFileExporter(
        rootDirectory: tempRoot.path,
        traceDirectorySegment: '',
      );
      final document = _document(
        gameId: 'flat-path',
        turnNumber: 3,
        exportedAt: '2026-05-08T07:10:11.123Z',
      );
      final file = await exporter.export(document);
      expect(file.path.startsWith('${tempRoot.path}/flat-path/'), isTrue);
    },
  );

  test(
    'pruning skips snapshot and run-summary artifacts in the same folder',
    () async {
      final exporter = TurnTraceFileExporter(rootDirectory: tempRoot.path);
      final gameId = 'mixed-artifacts';
      final baseDir = Directory('${tempRoot.path}/turn-traces/$gameId');
      await baseDir.create(recursive: true);

      for (var turn = 1; turn <= 12; turn++) {
        final timestamp = DateTime.utc(2026, 5, 8, 8, 0, turn);
        final document = _document(
          gameId: gameId,
          turnNumber: turn + 100,
          exportedAt: timestamp.toIso8601String(),
        );
        await exporter.export(document);
      }
      await File(
        '${baseDir.path}/turn-000001.snapshot.json',
      ).writeAsString('{}');
      await File('${baseDir.path}/run-summary.json').writeAsString('{}');

      await exporter.export(
        _document(
          gameId: gameId,
          turnNumber: 999,
          exportedAt: DateTime.utc(2026, 5, 8, 9, 0, 0).toIso8601String(),
        ),
      );

      final files =
          baseDir
              .listSync()
              .whereType<File>()
              .map((file) => file.uri.pathSegments.last)
              .toList()
            ..sort();
      expect(files.contains('run-summary.json'), isTrue);
      expect(files.contains('turn-000001.snapshot.json'), isTrue);
      expect(
        files
            .where((n) => n.startsWith('turn-') && !n.contains('.snapshot'))
            .length,
        10,
      );
    },
  );
}

TurnTraceMergedDocument _document({
  required String gameId,
  required int turnNumber,
  required String exportedAt,
}) {
  return TurnTraceMergedDocument(
    schemaVersion: kTurnTraceSchemaVersionV1,
    meta: TurnTraceMeta(
      gameId: gameId,
      turnNumber: turnNumber,
      traceEnabled: true,
      source: 'ctdev',
      exportedAt: exportedAt,
    ),
    ai: const <TurnTraceAiSection>[
      TurnTraceAiSection(
        factionId: 'gp-france',
        state: <String, Object?>{
          'winningCandidate': <String, Object?>{'id': 'candidate-1'},
          'topAlternates': <Object?>[],
          'aggregates': <String, Object?>{},
        },
        thresholds: <String, Object?>{
          'constants': <String, Object?>{},
          'derived': <String, Object?>{},
          'effective': <String, Object?>{},
          'gates': <Object?>[],
        },
        outcome: <String, Object?>{
          'finalAggregatedOrders': <Object?>[],
          'domainOutputs': <String, Object?>{},
        },
      ),
    ],
    turnResolution: const TurnTraceResolutionSection(
      phases: <TurnTracePhaseTrace>[
        TurnTracePhaseTrace(
          phaseId: 'movement',
          beforeState: <String, Object?>{'units': 3},
          afterState: <String, Object?>{'units': 2},
          orderEvents: <TurnTraceOrderEvent>[
            TurnTraceOrderEvent(
              sequence: 0,
              orderId: 'order-1',
              eventType: 'order_applied',
            ),
          ],
        ),
      ],
    ),
  );
}
