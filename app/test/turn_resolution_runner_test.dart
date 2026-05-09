// TurnResolutionRunner lifecycle (#2160).

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
      'turnTraceEnabled attaches phase traces and timestamps to terminal',
      () async {
        final runner = TurnResolutionRunner();
        final session = runner.startResolution(
          game: game,
          orders: const Orders(),
          topology: topology,
          tileMapByRegion: tileMapByRegion,
          turnTraceEnabled: true,
        );
        final terminal = await session.done;
        expect(terminal, isA<TurnResolutionTerminalComplete>());
        final c = terminal as TurnResolutionTerminalComplete;
        expect(c.turnTracePhases, isNotNull);
        expect(c.turnTracePhases, isNotEmpty);
        expect(c.turnTraceStartedAtUtc, isNotNull);
        expect(c.aiTraceSections, isNotNull);
      },
      timeout: const Timeout(Duration(seconds: 60)),
    );
  });
}
