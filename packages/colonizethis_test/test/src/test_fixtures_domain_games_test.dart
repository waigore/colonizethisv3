import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/game_test_fixtures.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('TestFixtures domain games', () {
    test('combatGame places default regiments on adjacent provinces', () {
      final game = TestFixtures.combatGame();
      expect(game.players.length, 2);
      expect(game.worldState.oldWorld.units.length, 2);
      expect(game.worldState.oldWorld.provinces.length, 2);
      expect(game.worldState.oldWorld.units.first.ownerId, 'p1');
      expect(game.worldState.oldWorld.units.last.ownerId, 'p2');
    });

    test('combatGame accepts custom units', () {
      final custom = Unit(
        id: 'x1',
        type: 'cavalry',
        ownerId: 'a',
        locationProvinceId: 'oldWorld|a',
      );
      final game = TestFixtures.combatGame(
        player1Id: 'a',
        player2Id: 'b',
        localProvince1: 'a',
        localProvince2: 'b',
        unit1: custom,
      );
      expect(game.worldState.oldWorld.units.first, custom);
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
      expect(game.worldState.oldWorld.provinces.single.ownerId, 'gp1');
    });

    test('singlePlayerGame uses orders phase turn 1 by default', () {
      const p = Player(id: 'p1', displayName: 'A', isHuman: true);
      final g = TestFixtures.singlePlayerGame(p);
      expect(g.players, [p]);
      expect(g.worldState.turnState.phase, TurnPhase.orders);
      expect(g.worldState.turnState.turnNumber, 1);
    });

    test('twoPlayerGame preserves richesCashMultiplier', () {
      const p1 = Player(id: 'a', displayName: 'A', isHuman: true, treasury: 10);
      const p2 = Player(
        id: 'b',
        displayName: 'B',
        isHuman: false,
        treasury: 20,
      );
      final g = TestFixtures.twoPlayerGame(
        player1: p1,
        player2: p2,
        richesCashMultiplier: 2.0,
      );
      expect(g.richesCashMultiplier, 2.0);
      expect(g.players.length, 2);
    });

    test('singlePlayerWorkPreviewGame wires p1 province and units', () {
      final g = TestFixtures.singlePlayerWorkPreviewGame(
        playerStockpile: const Stockpile(),
        units: [
          Unit(
            id: 'u1',
            type: kUnitTypeBuilder,
            ownerId: 'p1',
            locationProvinceId: 'ow|p1',
            tileKey: 'ow|p1|0|0',
          ),
        ],
      );
      expect(g.players.single.id, 'p1');
      expect(g.worldState.oldWorld.provinces.single.ownerId, 'p1');
      expect(g.worldState.oldWorld.units.single.id, 'u1');
    });

    test('multiProvinceGame creates owned provinces across both regions', () {
      final game = TestFixtures.multiProvinceGame();
      expect(game.players.single.id, 'p1');
      expect(game.worldState.oldWorld.provinces.length, 2);
      expect(game.worldState.newWorld.provinces.single.id, 'newWorld|n1');
      expect(
        game.worldState.oldWorld.provinces.every((p) => p.ownerId == 'p1'),
        isTrue,
      );
    });

    test('navalGame wires ports and coastal tile ownership map', () {
      final game = TestFixtures.navalGame();
      expect(
        game.worldState.portsByProvinceSeaboard['oldWorld|harbor|north'],
        'oldWorld|harbor|0|0',
      );
      expect(
        game.worldState.tileKeysByRegionAndProvince['oldWorld']?['oldWorld|harbor'],
        ['oldWorld|harbor|0|0'],
      );
      expect(game.worldState.oldWorld.provinces.single.ownerId, 'p1');
    });

    test('economyGame provides stockpile and mapped resources', () {
      final game = TestFixtures.economyGame();
      expect(game.players.single.stockpile.quantityOf('food'), 3);
      expect(game.players.single.stockpile.quantityOf('silver'), 2);
      expect(game.worldState.resourceByTileKey['oldWorld|farm|0|0'], 'food');
      expect(game.worldState.oldWorld.provinces.single.ownerId, 'p1');
    });
  });
}
