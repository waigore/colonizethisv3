import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  group('applyBuildAndWorkOrders (military training costs)', () {
    Game baseGame({required int peasants, required int treasury}) {
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
              id: 'oldWorld|P1',
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

    Orders ordersFor(String unitType, {String? spawnProvinceId}) {
      final spawn = spawnProvinceId ?? 'oldWorld|P1';
      return Orders(
        buildUnitOrdersByPlayerId: {
          'p1': [
            BuildUnitOrder(
              unitType: unitType,
              isMilitary:
                  buildUnitCategoryForUnitType(unitType) ==
                  BuildUnitCategory.military,
              spawnProvinceId: spawn,
            ),
          ],
        },
      );
    }

    test('rejects build when treasury is insufficient', () {
      final econ = RegimentEconomyCatalog.byId['peasant_levies']!;
      final game = baseGame(peasants: 5, treasury: econ.buildTreasuryCost - 1);
      final orders = ordersFor('peasant_levies');

      final next = applyBuildAndWorkOrders(game, orders);

      // No unit spawned and treasury unchanged.
      expect(next.worldState.oldWorld.units, isEmpty);
      expect(next.players.single.treasury, game.players.single.treasury);
      expect(
        next.players.single.workerPool.peasants,
        game.players.single.workerPool.peasants,
      );
    });

    test('rejects build when materials are insufficient', () {
      final econ = RegimentEconomyCatalog.byId['peasant_levies']!;
      // Enough treasury, but empty stockpile (no fabric).
      final game = baseGame(
        peasants: 5,
        treasury: econ.buildTreasuryCost + 10,
      );
      final orders = ordersFor('peasant_levies');

      final next = applyBuildAndWorkOrders(game, orders);
      expect(next.worldState.oldWorld.units, isEmpty);
      expect(
        next.players.single.workerPool.peasants,
        game.players.single.workerPool.peasants,
      );
    });

    test('applies treasury, stockpile and worker costs when valid', () {
      final econ = RegimentEconomyCatalog.byId['peasant_levies']!;
      var stockpile = const Stockpile();
      for (final entry in econ.buildInputs.entries) {
        stockpile = stockpile.applyDelta(
          entry.key,
          entry.value + 1,
        ); // small surplus
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
            Province(id: 'oldWorld|P1', regionId: 'oldWorld', ownerId: 'p1'),
          ],
          units: [],
        ),
        newWorld: const RegionData(),
      );
      final game = Game(id: 'g', worldState: world, players: [player]);
      final orders = ordersFor('peasant_levies');

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
      final game = baseGame(peasants: 2, treasury: 100);
      final next = applyBuildAndWorkOrders(game, const Orders());
      expect(
        next.worldState.oldWorld.units.length,
        game.worldState.oldWorld.units.length,
      );
      expect(next.players.single.treasury, game.players.single.treasury);
      expect(
        next.players.single.workerPool.peasants,
        game.players.single.workerPool.peasants,
      );
    });

    test(
      'ship build adds ship to fleet when topology and capital with sea',
      () {
        final topology = MapTopology(
          nodes: const [
            TopologyNode(
              id: 'P1',
              regionId: 'oldWorld',
              type: TopologyNodeType.province,
            ),
            TopologyNode(
              id: 'sea1',
              regionId: 'oldWorld',
              type: TopologyNodeType.seaZone,
            ),
          ],
          edges: const [TopologyEdge(id1: 'P1', id2: 'sea1')],
        );
        final player = Player(
          id: 'p1',
          displayName: 'Spain',
          isHuman: true,
          capitalProvinceId: 'oldWorld|P1',
          stockpile: const Stockpile(),
          workerPool: const WorkerPool(peasants: 2),
          treasury: 100,
          techUnlocked: {kTechIdSuperiorHullDesign: true},
        );
        final world = WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: const RegionData(
            provinces: [
              Province(id: 'P1', regionId: 'oldWorld', ownerId: 'p1'),
            ],
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
          players: [
            player.copyWith(
              stockpile: stockpile,
              treasury: shipEcon.buildTreasuryCost + 10,
            ),
          ],
        );
        final orders = Orders(
          buildUnitOrdersByPlayerId: {
            'p1': [
              BuildUnitOrder(
                unitType: 'fluyte',
                isMilitary:
                    buildUnitCategoryForUnitType('fluyte') ==
                    BuildUnitCategory.military,
                spawnProvinceId: 'oldWorld|P1',
              ),
            ],
          },
        );
        final next = applyBuildAndWorkOrders(
          gameWithStock,
          orders,
          topology: topology,
        );
        expect(next.worldState.fleets, isNotEmpty);
        expect(
          next.worldState.fleets.any(
            (f) => f.ownerId == 'p1' && f.shipTypeIds.contains('fluyte'),
          ),
          isTrue,
        );
        expect(next.players.single.workerPool.peasants, 1);
      },
    );

    test('rejects naval build when peasants are zero', () {
      final topology = MapTopology(
        nodes: const [
          TopologyNode(
            id: 'P1',
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
          TopologyNode(
            id: 'sea1',
            regionId: 'oldWorld',
            type: TopologyNodeType.seaZone,
          ),
        ],
        edges: const [TopologyEdge(id1: 'P1', id2: 'sea1')],
      );
      final shipEcon = ShipEconomyCatalog.byId['fluyte']!;
      var stockpile = const Stockpile();
      for (final e in shipEcon.buildInputs.entries) {
        stockpile = stockpile.applyDelta(e.key, e.value + 1);
      }
      final player = Player(
        id: 'p1',
        displayName: 'Spain',
        isHuman: true,
        capitalProvinceId: 'oldWorld|P1',
        stockpile: stockpile,
        workerPool: const WorkerPool(peasants: 0),
        treasury: shipEcon.buildTreasuryCost + 10,
        techUnlocked: {kTechIdSuperiorHullDesign: true},
      );
      final world = WorldState(
        turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
        oldWorld: const RegionData(
          provinces: [
            Province(id: 'P1', regionId: 'oldWorld', ownerId: 'p1'),
          ],
          units: [],
        ),
        newWorld: const RegionData(),
      );
      final game = Game(id: 'g', worldState: world, players: [player]);
      final orders = Orders(
        buildUnitOrdersByPlayerId: {
          'p1': [
            BuildUnitOrder(
              unitType: 'fluyte',
              isMilitary:
                  buildUnitCategoryForUnitType('fluyte') ==
                  BuildUnitCategory.military,
              spawnProvinceId: 'oldWorld|P1',
            ),
          ],
        },
      );
      final next = applyBuildAndWorkOrders(game, orders, topology: topology);
      expect(next.worldState.fleets, isEmpty);
      expect(next.players.single.workerPool.peasants, 0);
      expect(next.players.single.treasury, player.treasury);
    });

    test('second naval build adds ship to existing home fleet', () {
      const ow = 'oldWorld';
      final topology = MapTopology(
        nodes: const [
          TopologyNode(id: 'P1', regionId: ow, type: TopologyNodeType.province),
          TopologyNode(
            id: 'Sea1',
            regionId: ow,
            type: TopologyNodeType.seaZone,
          ),
        ],
        edges: const [TopologyEdge(id1: 'P1', id2: 'Sea1')],
      );
      final shipEcon = ShipEconomyCatalog.byId['fluyte']!;
      var stockpile = const Stockpile();
      for (final e in shipEcon.buildInputs.entries) {
        stockpile = stockpile.applyDelta(e.key, e.value * 2 + 1);
      }
      final player = Player(
        id: 'p1',
        displayName: 'P1',
        isHuman: true,
        capitalProvinceId: '$ow|P1',
        stockpile: stockpile,
        workerPool: const WorkerPool(peasants: 2),
        treasury: shipEcon.buildTreasuryCost * 2 + 10,
        techUnlocked: {kTechIdSuperiorHullDesign: true},
      );
      final world = WorldState(
        turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
        oldWorld: RegionData(
          provinces: [Province(id: '$ow|P1', regionId: ow, ownerId: 'p1')],
          units: [],
        ),
        newWorld: const RegionData(),
        fleets: [
          Fleet(
            id: 'fleet_p1',
            ownerId: 'p1',
            seaZoneId: 'Sea1',
            regionId: ow,
            shipTypeIds: ['fluyte'],
          ),
        ],
      );
      final game = Game(id: 'g', worldState: world, players: [player]);
      final orders = Orders(
        buildUnitOrdersByPlayerId: {
          'p1': [
            BuildUnitOrder(
              unitType: 'fluyte',
              isMilitary:
                  buildUnitCategoryForUnitType('fluyte') ==
                  BuildUnitCategory.military,
              spawnProvinceId: '$ow|P1',
            ),
          ],
        },
      );
      final next = applyBuildAndWorkOrders(game, orders, topology: topology);
      final p1Fleet = next.worldState.fleets
          .where((f) => f.ownerId == 'p1')
          .single;
      expect(p1Fleet.shipTypeIds.length, 2);
      expect(p1Fleet.shipTypeIds, contains('fluyte'));
      expect(next.players.single.workerPool.peasants, 1);
    });
  });
}
