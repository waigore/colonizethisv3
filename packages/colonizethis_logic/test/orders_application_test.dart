import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('applyBuildAndWorkOrders (military training costs)', () {
    Game _baseGame({required int peasants, required int treasury}) {
      const playerId = 'p1';
      final player = Player(
        id: playerId,
        displayName: 'Player 1',
        isHuman: true,
        stockpile: const Stockpile(),
        workerPool: WorkerPool(peasants: peasants),
        treasury: treasury,
      );
      final world = WorldState(
        turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
        oldWorld: const RegionData(
          provinces: [
            Province(
              id: 'P1',
              regionId: 'oldWorld',
              ownerId: playerId,
            ),
          ],
          units: [],
        ),
        newWorld: const RegionData(),
      );
      return Game(id: 'g', worldState: world, players: [player]);
    }

    Orders _ordersFor(String unitType) {
      return Orders(
        buildUnitOrdersByPlayerId: {
          'p1': [
            BuildUnitOrder(
              unitType: unitType,
              isMilitary: true,
              spawnProvinceId: 'oldWorld|P1',
            ),
          ],
        },
      );
    }

    test('rejects build when treasury is insufficient', () {
      final econ = RegimentEconomyCatalog.byId['peasant_levies']!;
      final game = _baseGame(
        peasants: 5,
        treasury: econ.buildTreasuryCost - 1,
      );
      final orders = _ordersFor('peasant_levies');

      final next = applyBuildAndWorkOrders(game, orders);

      // No unit spawned and treasury unchanged.
      expect(next.worldState.oldWorld.units, isEmpty);
      expect(next.players.single.treasury, game.players.single.treasury);
      expect(next.players.single.workerPool.peasants,
          game.players.single.workerPool.peasants);
    });

    test('rejects build when materials are insufficient', () {
      final econ = RegimentEconomyCatalog.byId['peasant_levies']!;
      // Enough treasury, but empty stockpile (no fabric).
      final game = _baseGame(
        peasants: 5,
        treasury: econ.buildTreasuryCost + 10,
      );
      final orders = _ordersFor('peasant_levies');

      final next = applyBuildAndWorkOrders(game, orders);
      expect(next.worldState.oldWorld.units, isEmpty);
      expect(next.players.single.workerPool.peasants,
          game.players.single.workerPool.peasants);
    });

    test('applies treasury, stockpile and worker costs when valid', () {
      final econ = RegimentEconomyCatalog.byId['peasant_levies']!;
      var stockpile = const Stockpile();
      for (final entry in econ.buildInputs.entries) {
        stockpile =
            stockpile.applyDelta(entry.key, entry.value + 1); // small surplus
      }

      final player = Player(
        id: 'p1',
        displayName: 'Player 1',
        isHuman: true,
        stockpile: stockpile,
        workerPool: const WorkerPool(peasants: 3),
        treasury: econ.buildTreasuryCost + 5,
      );
      final world = WorldState(
        turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
        oldWorld: const RegionData(
          provinces: [
            Province(
              id: 'P1',
              regionId: 'oldWorld',
              ownerId: 'p1',
            ),
          ],
          units: [],
        ),
        newWorld: const RegionData(),
      );
      final game = Game(id: 'g', worldState: world, players: [player]);
      final orders = _ordersFor('peasant_levies');

      final next = applyBuildAndWorkOrders(game, orders);
      final nextPlayer = next.players.single;

      // Exactly one new unit of requested type was created.
      expect(next.worldState.oldWorld.units.length, 1);
      expect(next.worldState.oldWorld.units.single.type, 'peasant_levies');

      // Treasury reduced by training cost.
      expect(nextPlayer.treasury, player.treasury - econ.buildTreasuryCost);

      // One peasant consumed.
      expect(nextPlayer.workerPool.peasants, player.workerPool.peasants - 1);

      // Materials reduced by required inputs.
      for (final entry in econ.buildInputs.entries) {
        final before = player.stockpile.quantityOf(entry.key);
        final after = nextPlayer.stockpile.quantityOf(entry.key);
        expect(after, before - entry.value);
      }
    });

    test('returns game unchanged when no build or work orders', () {
      final game = _baseGame(peasants: 2, treasury: 100);
      final next = applyBuildAndWorkOrders(game, const Orders());
      expect(next.worldState.oldWorld.units.length, game.worldState.oldWorld.units.length);
      expect(next.players.single.treasury, game.players.single.treasury);
      expect(next.players.single.workerPool.peasants, game.players.single.workerPool.peasants);
    });

    test('ship build adds ship to fleet when topology and capital with sea', () {
      final topology = MapTopology(
        nodes: const [
          TopologyNode(id: 'P1', regionId: 'oldWorld', type: TopologyNodeType.province),
          TopologyNode(id: 'sea1', regionId: 'oldWorld', type: TopologyNodeType.seaZone),
        ],
        edges: const [TopologyEdge(id1: 'P1', id2: 'sea1')],
      );
      final player = Player(
        id: 'p1',
        displayName: 'Spain',
        isHuman: true,
        capitalProvinceId: 'oldWorld|P1',
        stockpile: const Stockpile(),
        workerPool: const WorkerPool(peasants: 0),
        treasury: 100,
      );
      final world = WorldState(
        turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
        oldWorld: const RegionData(
          provinces: [Province(id: 'P1', regionId: 'oldWorld', ownerId: 'p1')],
          units: [],
        ),
        newWorld: const RegionData(),
      );
      final game = Game(id: 'g', worldState: world, players: [player]);
      final shipEcon = ShipEconomyCatalog.byId['fluyte']!;
      var stockpile = const Stockpile();
      for (final e in shipEcon.buildInputs.entries) {
        stockpile = stockpile.applyDelta(e.key, e.value + 1);
      }
      final gameWithStock = game.copyWith(
        players: [player.copyWith(
          stockpile: stockpile,
          treasury: shipEcon.buildTreasuryCost + 10,
        )],
      );
      final orders = Orders(
        buildUnitOrdersByPlayerId: {
          'p1': [
            BuildUnitOrder(
              unitType: 'fluyte',
              isMilitary: false,
              spawnProvinceId: 'oldWorld|P1',
            ),
          ],
        },
      );
      final next = applyBuildAndWorkOrders(gameWithStock, orders, topology: topology);
      expect(next.worldState.fleets, isNotEmpty);
      expect(next.worldState.fleets.any((f) => f.ownerId == 'p1' && f.shipTypeIds.contains('fluyte')), isTrue);
    });
  });
}