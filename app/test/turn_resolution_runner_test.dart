// TurnResolutionRunner lifecycle (#2160).

import 'dart:io';

import 'package:colonizethis_app/core/services/turn_resolution_runner.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

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
