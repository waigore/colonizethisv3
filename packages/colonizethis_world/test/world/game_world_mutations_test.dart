import 'package:colonizethis_world/src/world/game_world_mutations.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import '../test_fixtures.dart';

void main() {
  group('GameWorldMutations', () {
    test(
      'updateWorldState replaces worldState without nested game.copyWith chain',
      () {
        final game = TestFixtures.minimalGame();
        final next = game.updateWorldState(
          (ws) => ws.copyWith(nextArmySeq: ws.nextArmySeq + 1),
        );
        expect(next.worldState.nextArmySeq, game.worldState.nextArmySeq + 1);
        expect(next, isNot(same(game)));
      },
    );

    test('updateTurnState replaces turnState on WorldState', () {
      final ws = TestFixtures.minimalGame().worldState;
      final next = ws.updateTurnState(
        (ts) => ts.copyWith(turnNumber: ts.turnNumber + 1),
      );
      expect(next.turnState.turnNumber, ws.turnState.turnNumber + 1);
    });

    group('withWorldState (Refs #2836 AC 6)', () {
      test('returns a copy whose worldState is the supplied instance', () {
        final game = TestFixtures.minimalGame();
        final replacement = game.worldState.copyWith(nextArmySeq: 42);
        final next = game.withWorldState(replacement);

        expect(next.worldState, same(replacement));
        expect(next.worldState.nextArmySeq, 42);
      });

      test('does not mutate the original game', () {
        final game = TestFixtures.minimalGame();
        final originalSeq = game.worldState.nextArmySeq;
        game.withWorldState(game.worldState.copyWith(nextArmySeq: 7));

        expect(game.worldState.nextArmySeq, originalSeq);
      });

      test('preserves unrelated top-level Game fields', () {
        final game = TestFixtures.minimalGame(richesCashMultiplier: 1.5);
        final next = game.withWorldState(
          game.worldState.copyWith(nextArmySeq: 11),
        );

        expect(next.id, game.id);
        expect(next.players, same(game.players));
        expect(next.richesCashMultiplier, 1.5);
      });
    });

    group('withArmies (Refs #2836 AC 6)', () {
      test('replaces armies list and preserves other worldState fields', () {
        final game = TestFixtures.minimalGame();
        final army = Army(
          id: 'army-1',
          ownerId: 'h1',
          regionId: 'oldWorld',
          stationedProvinceId: 'oldWorld|p1',
          regimentUnitIds: const ['u1'],
          isHomeArmy: false,
        );

        final next = game.withArmies([army]);

        expect(next.worldState.armies, [army]);
        expect(next.worldState.fleets, same(game.worldState.fleets));
        expect(next.worldState.turnState, same(game.worldState.turnState));
      });

      test('empty list resets armies without crashing', () {
        final game = TestFixtures.minimalGame();
        final next = game.withArmies(const []);

        expect(next.worldState.armies, isEmpty);
      });

      test('does not mutate the original game', () {
        final game = TestFixtures.minimalGame();
        final army = Army(
          id: 'army-1',
          ownerId: 'h1',
          regionId: 'oldWorld',
          stationedProvinceId: 'oldWorld|p1',
          regimentUnitIds: const [],
          isHomeArmy: true,
        );
        game.withArmies([army]);

        expect(game.worldState.armies, isEmpty);
      });
    });

    group('withFleets (Refs #2836 AC 6)', () {
      test('replaces fleets list and preserves other worldState fields', () {
        final game = TestFixtures.minimalGame();
        final fleet = Fleet(
          id: 'fleet-1',
          ownerId: 'h1',
          regionId: 'oldWorld',
          seaZoneId: 'oldWorld|sea1',
        );

        final next = game.withFleets([fleet]);

        expect(next.worldState.fleets, [fleet]);
        expect(next.worldState.armies, same(game.worldState.armies));
      });

      test('does not mutate the original game', () {
        final game = TestFixtures.minimalGame();
        final fleet = Fleet(
          id: 'fleet-1',
          ownerId: 'h1',
          regionId: 'oldWorld',
          seaZoneId: 'oldWorld|sea1',
        );
        game.withFleets([fleet]);

        expect(game.worldState.fleets, isEmpty);
      });
    });

    group('withPlayers (Refs #2836 AC 6)', () {
      test('replaces players list', () {
        final game = TestFixtures.minimalGame();
        const replacement = [
          Player(id: 'gp1', displayName: 'Alpha', isHuman: false),
          Player(id: 'gp2', displayName: 'Beta', isHuman: false),
        ];

        final next = game.withPlayers(replacement);

        expect(next.players, replacement);
      });

      test('preserves worldState and unrelated top-level Game fields', () {
        final game = TestFixtures.minimalGame(richesCashMultiplier: 2.0);
        final next = game.withPlayers(const [
          Player(id: 'h2', displayName: 'Other', isHuman: true),
        ]);

        expect(next.worldState, same(game.worldState));
        expect(next.richesCashMultiplier, 2.0);
      });

      test('empty list does not throw and yields empty players', () {
        final game = TestFixtures.minimalGame();
        final next = game.withPlayers(const []);

        expect(next.players, isEmpty);
      });
    });

    group('withTileState (Refs #2836 AC 6)', () {
      test('replaces tileState on worldState', () {
        final game = TestFixtures.minimalGame();
        final ts = const TileMapState().setImprovement('oldWorld|p1|0|0', 2);

        final next = game.withTileState(ts);

        expect(next.worldState.tileState, same(ts));
      });

      test('preserves other worldState fields', () {
        final game = TestFixtures.minimalGame();
        final ts = const TileMapState().setImprovement('oldWorld|p1|0|0', 1);
        final next = game.withTileState(ts);

        expect(next.worldState.armies, same(game.worldState.armies));
        expect(next.worldState.fleets, same(game.worldState.fleets));
        expect(next.worldState.turnState, same(game.worldState.turnState));
      });

      test('does not mutate the original game', () {
        final game = TestFixtures.minimalGame();
        final ts = const TileMapState().setImprovement('oldWorld|p1|0|0', 3);
        game.withTileState(ts);

        expect(game.worldState.tileState, isNot(same(ts)));
      });
    });
  });
}
