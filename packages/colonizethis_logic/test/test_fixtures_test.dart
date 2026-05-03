import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'test_fixtures.dart';

void main() {
  group('TestFixtures', () {
    test('emptyWorldState yields empty regions and turn state', () {
      final ws = TestFixtures.emptyWorldState(
        phase: TurnPhase.production,
        turnNumber: 7,
      );
      expect(ws.oldWorld.provinces, isEmpty);
      expect(ws.newWorld.provinces, isEmpty);
      expect(ws.turnState.phase, TurnPhase.production);
      expect(ws.turnState.turnNumber, 7);
    });

    test('minimalGame passes resourceByTileKey into world state', () {
      const res = {'oldWorld|p|0|0': 'grain'};
      final game = TestFixtures.minimalGame(resourceByTileKey: res);
      expect(game.worldState.resourceByTileKey, res);
    });

    test('minimalGame passes playerVisibilityByTile into world state', () {
      const vis = {
        'p1': {'oldWorld|x|0|0': 'fullyVisible'},
      };
      final game = TestFixtures.minimalGame(
        playerVisibilityByTile: vis,
      );
      expect(game.worldState.playerVisibilityByTile, vis);
    });

    test('minimalGame preserves richesCashMultiplier and players', () {
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
      expect(game.id, 'gid');
      expect(game.richesCashMultiplier, 2.0);
      expect(game.players.length, 2);
      expect(game.worldState.turnState.turnNumber, 3);
    });

    test('oldWorldGameWithUnit places unit on old world only', () {
      final unit = Unit(
        id: 'u1',
        type: kUnitTypeExplorer,
        ownerId: 'h1',
        locationProvinceId: 'oldWorld|p1',
        tileKey: 'oldWorld|p1|0|0',
      );
      final game = TestFixtures.oldWorldGameWithUnit(unit: unit);
      expect(game.worldState.oldWorld.units, [unit]);
      expect(game.worldState.newWorld.units, isEmpty);
      expect(game.worldState.oldWorld.provinces.length, 2);
    });

    test('gameWithSingleOwnedProvince wires owner and capital', () {
      final game = TestFixtures.gameWithSingleOwnedProvince(
        id: 'g1',
        treasury: 42,
      );
      expect(game.players.single.id, 'gp1');
      expect(game.players.single.capitalProvinceId, 'oldWorld|p1');
      expect(game.players.single.treasury, 42);
      expect(
        game.worldState.oldWorld.provinces.single.ownerId,
        'gp1',
      );
    });
  });
}
