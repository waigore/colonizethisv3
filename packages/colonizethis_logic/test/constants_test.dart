import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  group('kRegion constants', () {
    test('kRegionOldWorld is oldWorld', () {
      expect(kRegionOldWorld, 'oldWorld');
    });

    test('kRegionNewWorld is newWorld', () {
      expect(kRegionNewWorld, 'newWorld');
    });
  });

  group('GamePlayerLookup.playerById', () {
    final game = Game(
      id: 'g1',
      worldState: WorldState(
        turnState: TurnState(phase: TurnPhase.orders, turnNumber: 1),
        oldWorld: const RegionData(),
        newWorld: const RegionData(),
      ),
      players: const [
        Player(id: 'gp1', displayName: 'France', isHuman: true),
        Player(id: 'gp2', displayName: 'England', isHuman: false),
        Player(id: 'gp3', displayName: 'Spain', isHuman: false),
      ],
    );

    test('returns player when id matches', () {
      final p = game.playerById('gp2');
      expect(p, isNotNull);
      expect(p!.id, 'gp2');
      expect(p.displayName, 'England');
    });

    test('returns null when id not found', () {
      expect(game.playerById('nonexistent'), isNull);
    });

    test('returns first player', () {
      expect(game.playerById('gp1')?.displayName, 'France');
    });

    test('returns last player', () {
      expect(game.playerById('gp3')?.displayName, 'Spain');
    });

    test('handles empty player list', () {
      final emptyGame = Game(
        id: 'g2',
        worldState: WorldState(
          turnState: TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
        ),
        players: const [],
      );
      expect(emptyGame.playerById('gp1'), isNull);
    });
  });
}
