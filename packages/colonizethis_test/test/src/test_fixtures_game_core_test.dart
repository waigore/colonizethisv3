import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/game_test_fixtures.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('TestFixtures game core', () {
    test('minimalGame passes spyRevealTurnsByPlayer and nextArmySeq', () {
      const spy = {
        'p1': {'oldWorld|p1': 2},
      };
      final game = TestFixtures.minimalGame(
        spyRevealTurnsByPlayer: spy,
        nextArmySeq: 4,
      );
      expect(game.worldState.spyRevealTurnsByPlayer, spy);
      expect(game.worldState.nextArmySeq, 4);
    });

    test('minimalGame passes resourceByTileKey into world state', () {
      const res = {'oldWorld|p|0|0': 'grain'};
      final game = TestFixtures.minimalGame(resourceByTileKey: res);
      expect(game.worldState.resourceByTileKey, res);
    });

    test('minimalGame passes purchasedTilesByTileKey into world state', () {
      const purchased = {'oldWorld|p2|0|0': 'gp1'};
      final game = TestFixtures.minimalGame(purchasedTilesByTileKey: purchased);
      expect(game.worldState.purchasedTilesByTileKey, purchased);
    });

    test('minimalGame passes ports and prospected tiles into world state', () {
      const ports = {'oldWorld|p1|sea1': 'oldWorld|p1|0|0'};
      const prospected = {
        'p1': {'oldWorld|p1|0|0'},
      };
      final game = TestFixtures.minimalGame(
        portsByProvinceSeaboard: ports,
        playerProspectedTiles: prospected,
      );
      expect(game.worldState.portsByProvinceSeaboard, ports);
      expect(game.worldState.playerProspectedTiles, prospected);
    });

    test('minimalGame passes playerVisibilityByTile into world state', () {
      const vis = {
        'p1': {'oldWorld|x|0|0': 'fullyVisible'},
      };
      final game = TestFixtures.minimalGame(playerVisibilityByTile: vis);
      expect(game.worldState.playerVisibilityByTile, vis);
    });

    test('minimalGame preserves richesCashMultiplier and players', () {
      const p1 = Player(id: 'a', displayName: 'A', isHuman: true, treasury: 10);
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

    test('minimalGame threads optional Game and WorldState fields', () {
      const generals = [
        General(id: 'g1', ownerId: 'p1'),
      ];
      const subsidies = [
        SubsidyState(
          payerId: 'p1',
          targetId: 'minor1',
          percent: 10,
        ),
      ];
      final game = TestFixtures.minimalGame(
        generals: generals,
        subsidyStates: subsidies,
        seaZoneDisplayNameById: const {'oldWorld|s': 'Bay'},
        nextShipInstanceSeq: 4,
      );
      expect(game.generals, generals);
      expect(game.subsidyStates, subsidies);
      expect(game.worldState.seaZoneDisplayNameById['oldWorld|s'], 'Bay');
      expect(game.worldState.nextShipInstanceSeq, 4);
    });
  });
}
