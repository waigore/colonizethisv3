import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/flame/map_state/map_state.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  suppressLogsForTests();
  group('GameMapAreaStateLogicShell.allowsFullTurnResolution', () {
    final baseGame = Game(
      id: 'g1',
      worldState: WorldState(
        turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 5),
        oldWorld: const RegionData(),
        newWorld: const RegionData(),
      ),
      players: const [Player(id: 'p1', displayName: 'Spain', isHuman: true)],
    );

    test('true when no victory and calendar not halted', () {
      expect(GameMapAreaStateLogicShell.allowsFullTurnResolution(baseGame), isTrue);
    });

    test('false when calendar halted', () {
      final g = baseGame.copyWith(calendarCampaignHalted: true);
      expect(GameMapAreaStateLogicShell.allowsFullTurnResolution(g), isFalse);
    });

    test('false when military victory set', () {
      final g = baseGame.copyWith(
        victory: const VictoryState(
          winnerPlayerId: 'p1',
          type: VictoryType.military,
          turnNumber: 4,
        ),
      );
      expect(GameMapAreaStateLogicShell.allowsFullTurnResolution(g), isFalse);
    });
  });
}
