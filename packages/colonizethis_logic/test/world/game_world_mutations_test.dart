import 'package:colonizethis_logic/src/world/game_world_mutations.dart';
import 'package:colonizethis_test/test.dart';

import '../test_fixtures.dart';

void main() {
  group('GameWorldMutations', () {
    test('updateWorldState replaces worldState without nested game.copyWith chain', () {
      final game = TestFixtures.minimalGame();
      final next = game.updateWorldState(
        (ws) => ws.copyWith(nextArmySeq: ws.nextArmySeq + 1),
      );
      expect(next.worldState.nextArmySeq, game.worldState.nextArmySeq + 1);
      expect(next, isNot(same(game)));
    });

    test('updateTurnState replaces turnState on WorldState', () {
      final ws = TestFixtures.minimalGame().worldState;
      final next = ws.updateTurnState(
        (ts) => ts.copyWith(turnNumber: ts.turnNumber + 1),
      );
      expect(
        next.turnState.turnNumber,
        ws.turnState.turnNumber + 1,
      );
    });
  });
}
