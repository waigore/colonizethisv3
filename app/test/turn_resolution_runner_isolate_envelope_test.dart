// Isolate success-envelope pins for TurnResolutionRunner (Refs #2277).

import 'dart:io';

import 'package:colonizethis_app/core/services/turn_resolution/turn_resolution_runner.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'turn_resolution_runner_test_support.dart';

void main() {
  suppressLogsForTests();

  group('TurnResolutionRunner', () {
    late Game game;
    late MapTopology topology;
    late Map<String, TileMapResult> tileMapByRegion;

    setUp(() {
      const ow = 'oldWorld';
      game = Game(
        id: 'runner_test_game',
        worldState: const WorldState(
          turnState: TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(),
          newWorld: RegionData(),
        ),
        players: const [
          Player(
            id: 'gp_human',
            displayName: 'Human',
            isHuman: true,
            treasury: 0,
          ),
        ],
      );
      topology = const MapTopology(nodes: [], edges: []);
      final tileMap = TileMapResult(
        width: 1,
        height: 1,
        grid: [
          ['$ow|M1'],
        ],
      );
      tileMapByRegion = {'oldWorld': tileMap, 'newWorld': tileMap};
    });

    test(
      'turnTraceEnabled exports merged trace from worker (no phases on SendPort) (Refs #2277)',
      () async {
        final tempDir = Directory.systemTemp.createTempSync(
          'runner_turn_trace_',
        );
        addTearDown(() {
          if (tempDir.existsSync()) {
            tempDir.deleteSync(recursive: true);
          }
        });
        final runner = TurnResolutionRunner();
        final session = runner.startResolution(
          game: game,
          orders: const Orders(),
          topology: topology,
          tileMapByRegion: tileMapByRegion,
          turnTraceEnabled: true,
          turnTraceRootDirectory: tempDir.path,
        );
        final terminal = await session.done;
        expect(terminal, isA<TurnResolutionTerminalComplete>());
        final c = terminal as TurnResolutionTerminalComplete;
        expect(c.turnTracePhases, isNull,
            reason: 'large phase snapshots must not cross SendPort (#2277)',
        );
        expect(c.aiTraceSections, isNull);
        expect(c.turnTraceStartedAtUtc, isNotNull);
        expect(c.turnTraceExportPath, isNotNull);
        final file = File(c.turnTraceExportPath!);
        expect(file.existsSync(), isTrue);
        final text = file.readAsStringSync();
        expect(text, contains('schemaVersion'));
        expect(text, contains('app_turn_worker'));
      },
      timeout: const Timeout(Duration(seconds: 60)),
    );

    test(
      'isolate success map omits turnTracePhases and aiTraceSections when tracing (Refs #2277)',
      () async {
        final tempDir = Directory.systemTemp.createTempSync(
          'runner_env_keys_',
        );
        addTearDown(() {
          if (tempDir.existsSync()) {
            tempDir.deleteSync(recursive: true);
          }
        });
        Map<Object?, Object?>? envelope;
        final runner = TurnResolutionRunner(
          inspectSuccessIsolateEnvelope: (m) {
            envelope = m;
          },
        );
        final session = runner.startResolution(
          game: game,
          orders: const Orders(),
          topology: topology,
          tileMapByRegion: tileMapByRegion,
          turnTraceEnabled: true,
          turnTraceRootDirectory: tempDir.path,
        );
        await session.done;
        expect(envelope, isNotNull);
        final map = envelope!;
        expect(
          map.containsKey('turnTracePhases'),
          isFalse,
          reason: '#2277: never ship embedded phase blobs on SendPort',
        );
        expect(
          map.containsKey('aiTraceSections'),
          isFalse,
          reason: '#2277: AI trace blobs must not shuttle on SendPort',
        );
        expect(map['kind'], 'success');
      },
      timeout: const Timeout(Duration(seconds: 60)),
    );

    test(
      'isolate success UTF-8 JSON stays small with tracing (Refs #2277)',
      () async {
        final tempDir = Directory.systemTemp.createTempSync(
          'runner_env_size_',
        );
        addTearDown(() {
          if (tempDir.existsSync()) {
            tempDir.deleteSync(recursive: true);
          }
        });
        Map<Object?, Object?>? envelope;
        final runner = TurnResolutionRunner(
          inspectSuccessIsolateEnvelope: (m) {
            envelope = m;
          },
        );
        final session = runner.startResolution(
          game: game,
          orders: const Orders(),
          topology: topology,
          tileMapByRegion: tileMapByRegion,
          turnTraceEnabled: true,
          turnTraceRootDirectory: tempDir.path,
        );
        await session.done;
        expect(envelope, isNotNull);
        final goodBytes = mapUtf8JsonLength(envelope!);
        expect(
          goodBytes,
          lessThan(kMaxIsolateSuccessEnvelopeUtf8Bytes),
          reason:
              'SendPort payloads must remain modest; oversized blobs freeze UI (#2277)',
        );
      },
      timeout: const Timeout(Duration(seconds: 60)),
    );

    test(
      'hypothetical embedded phase traces dwarf lean isolate envelope (Refs #2277)',
      () async {
        final tempDir = Directory.systemTemp.createTempSync(
          'runner_blob_cmp_',
        );
        addTearDown(() {
          if (tempDir.existsSync()) {
            tempDir.deleteSync(recursive: true);
          }
        });
        Map<Object?, Object?>? envelope;
        final runner = TurnResolutionRunner(
          inspectSuccessIsolateEnvelope: (m) {
            envelope = m;
          },
        );
        final session = runner.startResolution(
          game: game,
          orders: const Orders(),
          topology: topology,
          tileMapByRegion: tileMapByRegion,
          turnTraceEnabled: true,
          turnTraceRootDirectory: tempDir.path,
        );
        await session.done;
        expect(envelope, isNotNull);
        final good = envelope!;
        final gameJson =
            Map<String, Object?>.from(good['result']! as Map<Object?, Object?>)['game']!
                as Map<String, Object?>;
        final bad = Map<Object?, Object?>.from(good)
          ..['turnTracePhases'] = [
            for (var i = 0; i < kTurnResolutionPhaseCountForBlobRegression; i++)
              <String, Object?>{
                'phaseId': 'phase$i',
                'beforeState': gameJson,
                'afterState': gameJson,
                'orderEvents': <Object?>[],
              },
          ]
          ..['aiTraceSections'] = <Object?>[];
        final goodBytes = mapUtf8JsonLength(good);
        final badBytes = mapUtf8JsonLength(bad);
        expect(
          goodBytes,
          greaterThan(256),
          reason: 'fixture should serialize to non-trivial result payload',
        );
        expect(
          badBytes,
          greaterThan(goodBytes * 15),
          reason:
              'prior design replicated full game JSON per phase on SendPort; '
              'lean envelope regression guard (#2277)',
        );
      },
      timeout: const Timeout(Duration(seconds: 60)),
    );

  });
}
