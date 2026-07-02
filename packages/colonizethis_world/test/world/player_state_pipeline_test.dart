import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'package:colonizethis_test/game_test_fixtures.dart';

void main() {
  group('GameMapPlayers', () {
    test(
      'mapPlayers updates each player and preserves order and other game fields',
      () {
        const p1 = Player(
          id: 'a',
          displayName: 'A',
          isHuman: true,
          treasury: 10,
        );
        const p2 = Player(
          id: 'b',
          displayName: 'B',
          isHuman: false,
          treasury: 20,
        );
        final game = TestFixtures.minimalGame(
          id: 'gid',
          players: const [p1, p2],
          turnNumber: 3,
          richesCashMultiplier: 2.0,
        );

        final next = game.mapPlayers(
          (p) => p.copyWith(treasury: p.treasury + 1),
        );

        expect(next.id, game.id);
        expect(next.richesCashMultiplier, game.richesCashMultiplier);
        expect(next.worldState.turnState.turnNumber, 3);
        expect(next.players.map((e) => e.id).toList(), ['a', 'b']);
        expect(next.players[0].treasury, 11);
        expect(next.players[1].treasury, 21);
        expect(game.players[0].treasury, 10);
      },
    );

    test('mapPlayers identity yields equal game', () {
      const p = Player(id: 'x', displayName: 'X', isHuman: true);
      final game = TestFixtures.minimalGame(id: 'g', players: const [p]);
      final next = game.mapPlayers((q) => q);
      expect(next.players, game.players);
    });
  });
}
