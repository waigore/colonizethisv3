import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_turn/src/turn/phases/riches_to_treasury_phase.dart';
import 'package:colonizethis_turn/src/turn/turn_resolver_config.dart';

import 'turn_phase_test_harness.dart';

void main() {
  group('turn_phase_test_harness', () {
    test('runTurnPhaseHandler returns game from TurnPhaseStepContinue', () {
      final game = Game(
        id: 'g1',
        players: [
          Player(
            id: 'gp1',
            displayName: 'GP',
            isHuman: true,
            treasury: 50,
            stockpile: const Stockpile().applyDelta('gold', 1),
          ),
        ],
        worldState: WorldState(
          turnState: TurnState(phase: TurnPhase.richesToTreasury, turnNumber: 3),
          oldWorld: RegionData(),
          newWorld: RegionData(),
        ),
      );
      const config = TurnResolverConfig(
        topology: MapTopology(nodes: [], edges: []),
        orders: Orders(),
      );

      final next = runTurnPhaseHandler(
        handler: richesToTreasuryTurnPhaseHandler,
        game: game,
        config: config,
      );

      expect(next.players.single.treasury, greaterThan(50));
    });
  });
}
