import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/game_test_fixtures.dart';
import 'package:colonizethis_test/test.dart';

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

    test('worldStateAtOrdersPhase respects turnNumber and regions', () {
      const ow = RegionData(
        provinces: [
          Province(id: 'oldWorld|x', regionId: 'oldWorld', ownerId: 'o'),
        ],
      );
      final ws = TestFixtures.worldStateAtOrdersPhase(
        turnNumber: 7,
        oldWorld: ow,
      );
      expect(ws.turnState.phase, TurnPhase.orders);
      expect(ws.turnState.turnNumber, 7);
      expect(ws.oldWorld.provinces.single.id, 'oldWorld|x');
      expect(ws.newWorld.provinces, isEmpty);
    });

    test('worldStateAtOrdersPhase passes armies fleets and tile keys', () {
      const armies = [
        Army(
          id: 'a1',
          ownerId: 'p1',
          regionId: 'oldWorld',
          stationedProvinceId: 'oldWorld|p1',
          regimentUnitIds: ['r1'],
        ),
      ];
      final fleets = [
        Fleet(
          id: 'f1',
          ownerId: 'p1',
          regionId: 'oldWorld',
          seaZoneId: 'oldWorld|sea1',
        ),
      ];
      const tileKeys = {
        'oldWorld': {'oldWorld|p1': ['oldWorld|p1|0|0']},
      };
      final ws = TestFixtures.worldStateAtOrdersPhase(
        armies: armies,
        fleets: fleets,
        nextArmySeq: 3,
        tileKeysByRegionAndProvince: tileKeys,
      );
      expect(ws.armies, armies);
      expect(ws.fleets, fleets);
      expect(ws.nextArmySeq, 3);
      expect(ws.tileKeysByRegionAndProvince, tileKeys);
    });

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
