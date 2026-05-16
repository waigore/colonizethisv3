import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:colonizethis_app/features/game/flame/game_map_area_state_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GameMapAreaStateLogic.allowsFullTurnResolution', () {
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
      expect(GameMapAreaStateLogic.allowsFullTurnResolution(baseGame), isTrue);
    });

    test('false when calendar halted', () {
      final g = baseGame.copyWith(calendarCampaignHalted: true);
      expect(GameMapAreaStateLogic.allowsFullTurnResolution(g), isFalse);
    });

    test('false when military victory set', () {
      final g = baseGame.copyWith(
        victory: const VictoryState(
          winnerPlayerId: 'p1',
          type: VictoryType.military,
          turnNumber: 4,
        ),
      );
      expect(GameMapAreaStateLogic.allowsFullTurnResolution(g), isFalse);
    });
  });
}
