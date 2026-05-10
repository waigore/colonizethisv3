// TurnResolutionRunner lifecycle (#2160).

import 'dart:convert';
import 'dart:io';

import 'package:colonizethis_app/core/services/turn_resolution_runner.dart';
import 'package:colonizethis_app/features/game/flame/turn_resolution_progress_labels.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

/// Full turn pipeline phase count (historical SendPort regression embedded one
/// full game JSON per phase as before+after). Kept in sync with
/// `colonizethis_logic/src/turn/turn_resolution_sequence.dart`.
const int _kTurnResolutionPhaseCountForBlobRegression = 14;

/// If we ever ship full per-phase snapshots on the isolate again, the UTF-8 JSON
/// blows up long before this (Refs #2277).
const int _kMaxIsolateSuccessEnvelopeUtf8Bytes = 786432;

Object? _deepToJsonEncodable(Object? value) {
  if (value == null || value is bool || value is num || value is String) {
    return value;
  }
  if (value is Map<Object?, Object?>) {
    final out = <String, Object?>{};
    for (final MapEntry<Object?, Object?> entry in value.entries) {
      out[entry.key.toString()] = _deepToJsonEncodable(entry.value);
    }
    return out;
  }
  if (value is List<Object?>) {
    return value.map(_deepToJsonEncodable).toList(growable: false);
  }
  return value.toString();
}

int _mapUtf8JsonLength(Map<Object?, Object?> raw) {
  return utf8.encode(jsonEncode(_deepToJsonEncodable(raw))).length;
}

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
      'second startResolution throws while first session is active',
      () async {
        final runner = TurnResolutionRunner();
        final session = runner.startResolution(
          game: game,
          orders: const Orders(),
          topology: topology,
          tileMapByRegion: tileMapByRegion,
        );
        expect(runner.isActive, isTrue);
        expect(
          () => runner.startResolution(
            game: game,
            orders: const Orders(),
            topology: topology,
            tileMapByRegion: tileMapByRegion,
          ),
          throwsA(isA<StateError>()),
        );
        await session.done;
        expect(runner.isActive, isFalse);
      },
      timeout: const Timeout(Duration(seconds: 60)),
    );

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
        final goodBytes = _mapUtf8JsonLength(envelope!);
        expect(
          goodBytes,
          lessThan(_kMaxIsolateSuccessEnvelopeUtf8Bytes),
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
            for (var i = 0; i < _kTurnResolutionPhaseCountForBlobRegression; i++)
              <String, Object?>{
                'phaseId': 'phase$i',
                'beforeState': gameJson,
                'afterState': gameJson,
                'orderEvents': <Object?>[],
              },
          ]
          ..['aiTraceSections'] = <Object?>[];
        final goodBytes = _mapUtf8JsonLength(good);
        final badBytes = _mapUtf8JsonLength(bad);
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

    test(
      'endOfTurn (Finalizing) finishes, session completes, next turn starts (Refs #2277)',
      () async {
        final startTurn = game.worldState.turnState.turnNumber;
        final runner = TurnResolutionRunner();
        final session = runner.startResolution(
          game: game,
          orders: const Orders(),
          topology: topology,
          tileMapByRegion: tileMapByRegion,
        );
        final progressEvents = <TurnResolutionProgressEvent>[];
        final sub = session.progress.listen(progressEvents.add);
        late final TurnResolutionTerminalEvent terminal;
        try {
          terminal = await session.done;
        } finally {
          await sub.cancel();
        }

        expect(terminal, isA<TurnResolutionTerminalComplete>());
        final wrapper = terminal as TurnResolutionTerminalComplete;
        expect(
          wrapper.result,
          isA<TurnResolutionComplete>(),
          reason:
              'Worker must return a completed turn (not stuck finalizing) (#2277)',
        );
        final resolved = wrapper.result as TurnResolutionComplete;

        expect(
          turnResolutionProgressPhaseLabel('endOfTurn'),
          'Finalizing turn...',
          reason: 'UI label contract for resolver final phase (#2277)',
        );
        expect(
          progressEvents.any(
            (e) => e.phase == 'endOfTurn' && e.marker == 'end',
          ),
          isTrue,
          reason:
              'Resolver must emit endOfTurn:end before success (no hang on '
              'Finalizing) (#2277)',
        );

        expect(
          resolved.game.worldState.turnState.turnNumber,
          startTurn + 1,
          reason: 'Turn counter advances after full pipeline (#2277)',
        );
        expect(
          resolved.game.worldState.turnState.phase,
          TurnPhase.orders,
          reason: 'Next turn begins in orders phase (#2277)',
        );
      },
      timeout: const Timeout(Duration(seconds: 60)),
    );

    test(
      'back-to-back resolutions complete and release runner (Refs #2277)',
      () async {
        final runner = TurnResolutionRunner();
        final first = runner.startResolution(
          game: game,
          orders: const Orders(),
          topology: topology,
          tileMapByRegion: tileMapByRegion,
        );
        await first.done;
        expect(runner.isActive, isFalse);
        final second = runner.startResolution(
          game: game,
          orders: const Orders(),
          topology: topology,
          tileMapByRegion: tileMapByRegion,
        );
        await second.done;
        expect(runner.isActive, isFalse);
      },
      timeout: const Timeout(Duration(seconds: 120)),
    );
  });
}
