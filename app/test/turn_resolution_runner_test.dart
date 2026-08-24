// TurnResolutionRunner lifecycle (#2160).

import 'package:colonizethis_app/core/services/turn_resolution/turn_resolution_runner.dart';
import 'package:colonizethis_app/features/game/flame/overlays/turn_resolution_progress_labels.dart';
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
