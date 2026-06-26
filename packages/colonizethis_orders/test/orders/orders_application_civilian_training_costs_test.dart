import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  group('applyBuildAndWorkOrders (civilian training costs)', () {
    Game civilianGame({
      required int treasury,
      required int paper,
      Map<String, bool>? techUnlocked,
    }) {
      const playerId = 'p1';
      var stockpile = const Stockpile();
      if (paper > 0) {
        stockpile = stockpile.applyDelta(CommodityCatalog.paper.id, paper);
      }
      final player = Player(
        id: playerId,
        displayName: 'Player 1',
        isHuman: true,
        capitalProvinceId: 'oldWorld|P1',
        capitalTile: const CapitalTile(
          regionId: 'oldWorld',
          provinceId: 'P1',
          x: 0,
          y: 0,
        ),
        stockpile: stockpile,
        workerPool: const WorkerPool(peasants: 0),
        treasury: treasury,
        techUnlocked: techUnlocked,
      );
      final world = WorldState(
        turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
        oldWorld: const RegionData(
          provinces: [
            Province(id: 'oldWorld|P1', regionId: 'oldWorld', ownerId: playerId),
          ],
          units: [],
        ),
        newWorld: const RegionData(),
      );
      return Game(id: 'g', worldState: world, players: [player]);
    }

    test('rejects civilian build when treasury insufficient', () {
      final game = civilianGame(treasury: 999, paper: 2);
      final orders = Orders(
        buildUnitOrdersByPlayerId: {
          'p1': [
            BuildUnitOrder(
              unitType: kUnitTypeBuilder,
              isMilitary:
                  buildUnitCategoryForUnitType(kUnitTypeBuilder) ==
                  BuildUnitCategory.military,
              spawnProvinceId: 'oldWorld|P1',
            ),
          ],
        },
      );
      final next = applyBuildAndWorkOrders(game, orders);
      expect(next.worldState.oldWorld.units, isEmpty);
      expect(next.players.single.treasury, game.players.single.treasury);
      expect(
        next.players.single.stockpile.quantityOf(CommodityCatalog.paper.id),
        game.players.single.stockpile.quantityOf(CommodityCatalog.paper.id),
      );
    });

    test('rejects civilian build when paper insufficient', () {
      final game = civilianGame(treasury: 1000, paper: 0);
      final orders = Orders(
        buildUnitOrdersByPlayerId: {
          'p1': [
            BuildUnitOrder(
              unitType: kUnitTypeBuilder,
              isMilitary:
                  buildUnitCategoryForUnitType(kUnitTypeBuilder) ==
                  BuildUnitCategory.military,
              spawnProvinceId: 'oldWorld|P1',
            ),
          ],
        },
      );
      final next = applyBuildAndWorkOrders(game, orders);
      expect(next.worldState.oldWorld.units, isEmpty);
      expect(next.players.single.treasury, game.players.single.treasury);
    });

    test('applies treasury and paper cost when civilian build valid', () {
      const cash = 1000;
      const paperQty = 2;
      final game = civilianGame(treasury: cash + 100, paper: paperQty + 1);
      final orders = Orders(
        buildUnitOrdersByPlayerId: {
          'p1': [
            BuildUnitOrder(
              unitType: kUnitTypeBuilder,
              isMilitary:
                  buildUnitCategoryForUnitType(kUnitTypeBuilder) ==
                  BuildUnitCategory.military,
              spawnProvinceId: 'oldWorld|P1',
            ),
          ],
        },
      );
      final next = applyBuildAndWorkOrders(game, orders);
      expect(next.worldState.oldWorld.units.length, 1);
      expect(next.worldState.oldWorld.units.single.type, kUnitTypeBuilder);
      expect(next.players.single.treasury, game.players.single.treasury - cash);
      expect(
        next.players.single.stockpile.quantityOf(CommodityCatalog.paper.id),
        game.players.single.stockpile.quantityOf(CommodityCatalog.paper.id) -
            paperQty,
      );
    });

    test('Merchant requires merchant_companies tech', () {
      const cash = 2000;
      const paperQty = 4;
      final gameNoTech = civilianGame(
        treasury: cash + 100,
        paper: paperQty + 1,
        techUnlocked: {},
      );
      final orders = Orders(
        buildUnitOrdersByPlayerId: {
          'p1': [
            BuildUnitOrder(
              unitType: kUnitTypeMerchant,
              isMilitary:
                  buildUnitCategoryForUnitType(kUnitTypeMerchant) ==
                  BuildUnitCategory.military,
              spawnProvinceId: 'oldWorld|P1',
            ),
          ],
        },
      );
      final nextNoTech = applyBuildAndWorkOrders(gameNoTech, orders);
      expect(nextNoTech.worldState.oldWorld.units, isEmpty);
      expect(
        nextNoTech.players.single.treasury,
        gameNoTech.players.single.treasury,
      );

      final gameWithTech = civilianGame(
        treasury: cash + 100,
        paper: paperQty + 1,
        techUnlocked: {kTechIdMerchantCompanies: true},
      );
      final nextWithTech = applyBuildAndWorkOrders(gameWithTech, orders);
      expect(nextWithTech.worldState.oldWorld.units.length, 1);
      expect(nextWithTech.worldState.oldWorld.units.single.type, kUnitTypeMerchant);
      expect(
        nextWithTech.players.single.treasury,
        gameWithTech.players.single.treasury - cash,
      );
      expect(
        nextWithTech.players.single.stockpile.quantityOf(
          CommodityCatalog.paper.id,
        ),
        gameWithTech.players.single.stockpile.quantityOf(
              CommodityCatalog.paper.id,
            ) -
            paperQty,
      );
    });
  });
}
