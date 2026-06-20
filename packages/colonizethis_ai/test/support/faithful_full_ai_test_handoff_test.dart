import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'faithful_full_ai_test_handoff.dart';

void main() {
  test('applyFaithfulFullAiTestHandoff clears isHuman and enables AI control '
      '(Refs #2924)', () {
    final game = Game(
      id: 'g1',
      players: [
        const Player(id: 'gp1', isHuman: true, displayName: 'GP1'),
        const Player(id: 'gp2', isHuman: false, displayName: 'GP2'),
      ],
      worldState: WorldState(
        turnState: const TurnState(turnNumber: 1, phase: TurnPhase.orders),
        oldWorld: const RegionData(),
        newWorld: const RegionData(),
      ),
      aiControlByGpId: const {'gp2': true},
    );

    final handedOff = applyFaithfulFullAiTestHandoff(game);

    for (final p in handedOff.players) {
      expect(p.isHuman, isFalse, reason: p.id);
      expect(handedOff.aiControlByGpId[p.id], isTrue, reason: p.id);
    }
  });
}
