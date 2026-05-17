import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'orders_application_military_ship_skip_test_support.dart';

void main() {
  group('applyBuildAndWorkOrders military and ship skip branches', () {
    test('skips build when unitType unknown in RegimentEconomyCatalog', () {
      final game = Game(
        id: 'g',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: const RegionData(
            provinces: [
              Province(id: 'oldWorld|P1', regionId: 'oldWorld', ownerId: 'p1'),
            ],
            units: [],
          ),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(
            id: 'p1',
            displayName: 'P1',
            isHuman: true,
            stockpile: Stockpile(),
            workerPool: WorkerPool(peasants: 5),
            treasury: 1000,
          ),
        ],
      );
      final orders = Orders(
        buildUnitOrdersByPlayerId: {
          'p1': [
            BuildUnitOrder(
              unitType: 'unknown_regiment_xyz',
              isMilitary:
                  buildUnitCategoryForUnitType('unknown_regiment_xyz') ==
                  BuildUnitCategory.military,
              spawnProvinceId: 'oldWorld|P1',
            ),
          ],
        },
      );
      final next = applyBuildAndWorkOrders(game, orders);
      expect(next.worldState.oldWorld.units, isEmpty);
    });

    test('skips military build when zero peasants', () {
      final econ = RegimentEconomyCatalog.byId['peasant_levies']!;
      var stockpile = const Stockpile();
      for (final e in econ.buildInputs.entries) {
        stockpile = stockpile.applyDelta(e.key, e.value + 1);
      }
      final game = Game(
        id: 'g',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: const RegionData(
            provinces: [
              Province(id: 'oldWorld|P1', regionId: 'oldWorld', ownerId: 'p1'),
            ],
            units: [],
          ),
          newWorld: const RegionData(),
        ),
        players: [
          Player(
            id: 'p1',
            displayName: 'P1',
            isHuman: true,
            stockpile: stockpile,
            workerPool: const WorkerPool(peasants: 0),
            treasury: econ.buildTreasuryCost + 10,
          ),
        ],
      );
      final orders = Orders(
        buildUnitOrdersByPlayerId: {
          'p1': [
            BuildUnitOrder(
              unitType: 'peasant_levies',
              isMilitary:
                  buildUnitCategoryForUnitType('peasant_levies') ==
                  BuildUnitCategory.military,
              spawnProvinceId: 'oldWorld|P1',
            ),
          ],
        },
      );
      final next = applyBuildAndWorkOrders(game, orders);
      expect(next.worldState.oldWorld.units, isEmpty);
    });

    test('skips military build when tech not unlocked', () {
      final regimentWithTech = unlockingTechByRegimentId.keys.firstOrNull;
      if (regimentWithTech == null) return; // no regiment with tech in catalog
      final econ = RegimentEconomyCatalog.byId[regimentWithTech];
      if (econ == null) return;
      var stockpile = const Stockpile();
      for (final e in econ.buildInputs.entries) {
        stockpile = stockpile.applyDelta(e.key, e.value + 1);
      }
      final game = Game(
        id: 'g',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: const RegionData(
            provinces: [
              Province(id: 'oldWorld|P1', regionId: 'oldWorld', ownerId: 'p1'),
            ],
            units: [],
          ),
          newWorld: const RegionData(),
        ),
        players: [
          Player(
            id: 'p1',
            displayName: 'P1',
            isHuman: true,
            stockpile: stockpile,
            workerPool: const WorkerPool(peasants: 3),
            treasury: econ.buildTreasuryCost + 10,
            techUnlocked: {}, // none unlocked
          ),
        ],
      );
      final orders = Orders(
        buildUnitOrdersByPlayerId: {
          'p1': [
            BuildUnitOrder(
              unitType: regimentWithTech,
              isMilitary:
                  buildUnitCategoryForUnitType(regimentWithTech) ==
                  BuildUnitCategory.military,
              spawnProvinceId: 'oldWorld|P1',
            ),
          ],
        },
      );
      final next = applyBuildAndWorkOrders(game, orders);
      expect(next.worldState.oldWorld.units, isEmpty);
    });

    test('skips ship build when tech not unlocked', () {
      const shipTypeId = 'fluyte';
      final shipEcon = ShipEconomyCatalog.byId[shipTypeId];
      if (shipEcon == null || unlockingTechByShipId[shipTypeId] == null) return;
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
      var stockpile = const Stockpile();
      for (final e in shipEcon.buildInputs.entries) {
        stockpile = stockpile.applyDelta(e.key, e.value + 1);
      }
      final game = Game(
        id: 'g',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: const RegionData(
            provinces: [
              Province(id: 'oldWorld|P1', regionId: 'oldWorld', ownerId: 'p1'),
            ],
            units: [],
          ),
          newWorld: const RegionData(),
        ),
        players: [
          Player(
            id: 'p1',
            displayName: 'P1',
            isHuman: true,
            capitalProvinceId: 'oldWorld|P1',
            stockpile: stockpile,
            treasury: shipEcon.buildTreasuryCost + 10,
            techUnlocked: {}, // fluyte requires superior_hull_design
          ),
        ],
      );
      final orders = Orders(
        buildUnitOrdersByPlayerId: {
          'p1': [
            BuildUnitOrder(
              unitType: shipTypeId,
              isMilitary:
                  buildUnitCategoryForUnitType(shipTypeId) ==
                  BuildUnitCategory.military,
              spawnProvinceId: 'oldWorld|P1',
            ),
          ],
        },
      );
      final next = applyBuildAndWorkOrders(game, orders, topology: topology);
      expect(next.worldState.fleets, isEmpty);
    });

    test('ship build with topology null does not add fleet', () {
      final shipEcon = ShipEconomyCatalog.byId['fluyte']!;
      var stockpile = const Stockpile();
      for (final e in shipEcon.buildInputs.entries) {
        stockpile = stockpile.applyDelta(e.key, e.value + 1);
      }
      final player = Player(
        id: 'p1',
        displayName: 'P1',
        isHuman: true,
        capitalProvinceId: 'oldWorld|P1',
        stockpile: stockpile,
        workerPool: const WorkerPool(peasants: 1),
        treasury: shipEcon.buildTreasuryCost + 10,
        techUnlocked: {kTechIdSuperiorHullDesign: true},
      );
      final game = Game(
        id: 'g',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: const RegionData(
            provinces: [
              Province(id: 'oldWorld|P1', regionId: 'oldWorld', ownerId: 'p1'),
            ],
            units: [],
          ),
          newWorld: const RegionData(),
        ),
        players: [player],
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
      final next = applyBuildAndWorkOrders(game, orders); // no topology
      expectShipBuildSpentButNoFleet(
        next: next,
        baselinePlayer: player,
        baselineStockpile: stockpile,
        buildTreasuryCost: shipEcon.buildTreasuryCost,
        buildInputs: shipEcon.buildInputs,
      );
    });

    test('ship build with capitalProvinceId null does not add fleet', () {
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
        displayName: 'P1',
        isHuman: true,
        capitalProvinceId: null, // no capital
        stockpile: stockpile,
        workerPool: const WorkerPool(peasants: 1),
        treasury: shipEcon.buildTreasuryCost + 10,
        techUnlocked: {kTechIdSuperiorHullDesign: true},
      );
      final game = Game(
        id: 'g',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: const RegionData(
            provinces: [
              Province(id: 'oldWorld|P1', regionId: 'oldWorld', ownerId: 'p1'),
            ],
            units: [],
          ),
          newWorld: const RegionData(),
        ),
        players: [player],
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
      final next = applyBuildAndWorkOrders(game, orders, topology: topology);
      expectShipBuildSpentButNoFleet(
        next: next,
        baselinePlayer: player,
        baselineStockpile: stockpile,
        buildTreasuryCost: shipEcon.buildTreasuryCost,
        buildInputs: shipEcon.buildInputs,
      );
    });

    test('ship build with capital not adjacent to sea does not add ship', () {
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
        edges: [], // P1 not connected to sea
      );
      final shipEcon = ShipEconomyCatalog.byId['fluyte']!;
      var stockpile = const Stockpile();
      for (final e in shipEcon.buildInputs.entries) {
        stockpile = stockpile.applyDelta(e.key, e.value + 1);
      }
      final player = Player(
        id: 'p1',
        displayName: 'P1',
        isHuman: true,
        capitalProvinceId: 'oldWorld|P1',
        stockpile: stockpile,
        workerPool: const WorkerPool(peasants: 1),
        treasury: shipEcon.buildTreasuryCost + 10,
        techUnlocked: {kTechIdSuperiorHullDesign: true},
      );
      final game = Game(
        id: 'g',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: const RegionData(
            provinces: [
              Province(id: 'oldWorld|P1', regionId: 'oldWorld', ownerId: 'p1'),
            ],
            units: [],
          ),
          newWorld: const RegionData(),
        ),
        players: [player],
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
      final next = applyBuildAndWorkOrders(game, orders, topology: topology);
      expectShipBuildSpentButNoFleet(
        next: next,
        baselinePlayer: player,
        baselineStockpile: stockpile,
        buildTreasuryCost: shipEcon.buildTreasuryCost,
        buildInputs: shipEcon.buildInputs,
      );
    });
  });
}
