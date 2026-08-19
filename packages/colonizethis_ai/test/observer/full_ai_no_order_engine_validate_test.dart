import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  suppressLogsForTests();

  group('Full AI + suggestion path (Refs #2237 AC2)', () {
    tearDown(() {
      setOrderEngineValidatePlayerOrdersWithContextTrackingForTests(false);
    });

    test('generateOrdersForPlayerFullAI does not call OrderEngine full-pass', () {
      setOrderEngineValidatePlayerOrdersWithContextTrackingForTests(true);

      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: const RegionData(provinces: [], units: []),
          newWorld: const RegionData(provinces: [], units: []),
        ),
        players: const [
          Player(
            id: 'gp1',
            displayName: 'England',
            isHuman: false,
            leaderKey: 'victoria',
          ),
        ],
        hiddenAgendaByGpId: const {'gp1': 'peacemaker'},
      );
      const topology = MapTopology(nodes: [], edges: []);

      generateOrdersForPlayerFullAI(game, topology, 'gp1');

      expect(
        orderEngineValidatePlayerOrdersWithContextInvocationCountForTests,
        0,
        reason:
            'AI order generation must stay on incremental suggestion validation, '
            'not OrderEngine.validatePlayerOrdersWithContext (Refs #2237 AC2).',
      );
    });
  });
}
