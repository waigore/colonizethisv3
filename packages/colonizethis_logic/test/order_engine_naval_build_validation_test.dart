import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  group('OrderEngine', () {
    test('move order accepted for own province across regions', () {
      const ow = 'oldWorld';
      const nw = 'newWorld';
      final topology = MapTopology(
        nodes: const [
          TopologyNode(id: 'P1', regionId: ow, type: TopologyNodeType.province),
          TopologyNode(id: 'P2', regionId: nw, type: TopologyNodeType.province),
        ],
        edges: const [],
      );
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: RegionData(
            provinces: [Province(id: '$ow|P1', regionId: ow, ownerId: 'p1')],
            units: [
              Unit(
                id: 'u1',
                type: 'musketeers',
                ownerId: 'p1',
                locationProvinceId: '$ow|P1',
              ),
            ],
          ),
          newWorld: RegionData(
            provinces: [Province(id: '$nw|P2', regionId: nw, ownerId: 'p1')],
            units: [],
          ),
          playerVisibilityByTile: const {
            'p1': {
              'oldWorld|P1|0|0': 'fullyVisible',
              'newWorld|P2|0|0': 'fullyVisible',
            },
          },
        ),
        players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
      );

      final engine = OrderEngine();
      engine.addMoveOrder(
        'p1',
        const MoveOrder(unitId: 'u1', destinationProvinceId: '$nw|P2'),
      );
      final results = engine.validatePlayerOrdersWithContext(
        game,
        topology,
        'p1',
      );
      expect(results.single.status, OrderValidationStatus.accepted);
    });

    test(
      'move order rejected when destination is foreign province across regions',
      () {
        const ow = 'oldWorld';
        const nw = 'newWorld';
        final topology = MapTopology(
          nodes: const [
            TopologyNode(
              id: 'P1',
              regionId: ow,
              type: TopologyNodeType.province,
            ),
            TopologyNode(
              id: 'P2',
              regionId: nw,
              type: TopologyNodeType.province,
            ),
          ],
          edges: const [],
        );
        final game = Game(
          id: 'g1',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
            oldWorld: RegionData(
              provinces: [Province(id: '$ow|P1', regionId: ow, ownerId: 'p1')],
              units: [
                Unit(
                  id: 'u1',
                  type: 'musketeers',
                  ownerId: 'p1',
                  locationProvinceId: '$ow|P1',
                ),
              ],
            ),
            newWorld: RegionData(
              provinces: [Province(id: '$nw|P2', regionId: nw, ownerId: 'p2')],
              units: [],
            ),
            playerVisibilityByTile: const {
              'p1': {
                'oldWorld|P1|0|0': 'fullyVisible',
                'newWorld|P2|0|0': 'fullyVisible',
              },
            },
          ),
          players: const [
            Player(id: 'p1', displayName: 'P1', isHuman: true),
            Player(id: 'p2', displayName: 'P2', isHuman: true),
          ],
        );

        final engine = OrderEngine();
        engine.addMoveOrder(
          'p1',
          const MoveOrder(unitId: 'u1', destinationProvinceId: '$nw|P2'),
        );
        final results = engine.validatePlayerOrdersWithContext(
          game,
          topology,
          'p1',
        );
        expect(results.single.status, OrderValidationStatus.rejected);
      },
    );

    test('work order rejected for invalid target for unit type', () {
      const ow = 'oldWorld';
      final topology = MapTopology(
        nodes: const [
          TopologyNode(
            id: 'P1',
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
        ],
        edges: const [],
      );
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: RegionData(
            provinces: [Province(id: '$ow|P1', regionId: ow, ownerId: 'p1')],
            units: [
              Unit(
                id: 'u1',
                type: 'Builder',
                ownerId: 'p1',
                locationProvinceId: '$ow|P1',
                tileKey: 'oldWorld|P1|0|0',
              ),
            ],
          ),
          newWorld: const RegionData(),
          playerVisibilityByTile: const {
            'p1': {'oldWorld|P1|0|0': 'fullyVisible'},
          },
        ),
        players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
      );
      final engine = OrderEngine();
      engine.addWorkOrder(
        'p1',
        WorkOrder(
          unitId: 'u1',
          target: 'unknown_target',
          targetTileKey: 'oldWorld|P1|0|0',
        ),
      );
      final results = engine.validatePlayerOrdersWithContext(
        game,
        topology,
        'p1',
      );
      expect(results.single.status, OrderValidationStatus.rejected);
      expect(results.single.reason, contains('Invalid work target'));
    });

    test('initial orders copy: getter returns equal but distinct lists', () {
      final initial = Orders(
        moveOrdersByPlayerId: {
          'p1': [
            const MoveOrder(unitId: 'u1', destinationProvinceId: 'oldWorld|P2'),
          ],
        },
      );
      final engine = OrderEngine(initialOrders: initial);
      final orders1 = engine.orders;
      final orders2 = engine.orders;
      expect(orders1.moveOrdersByPlayerId['p1']!.length, 1);
      expect(orders2.moveOrdersByPlayerId['p1']!.length, 1);
      expect(
        identical(orders1.moveOrdersByPlayerId, orders2.moveOrdersByPlayerId),
        isFalse,
      );
      expect(
        identical(
          orders1.moveOrdersByPlayerId['p1'],
          orders2.moveOrdersByPlayerId['p1'],
        ),
        isFalse,
      );
    });

    test('naval move order rejected when fleet not found', () {
      const ow = 'oldWorld';
      final topology = MapTopology(
        nodes: const [
          TopologyNode(id: 'P1', regionId: ow, type: TopologyNodeType.province),
          TopologyNode(
            id: 'sea1',
            regionId: ow,
            type: TopologyNodeType.seaZone,
          ),
          TopologyNode(
            id: 'sea2',
            regionId: ow,
            type: TopologyNodeType.seaZone,
          ),
        ],
        edges: const [TopologyEdge(id1: 'sea1', id2: 'sea2')],
      );
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
          fleets: [],
        ),
        players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
      );
      final engine = OrderEngine();
      engine.addNavalMoveOrder(
        'p1',
        NavalMoveOrder(
          fleetId: 'nonexistent_fleet',
          destinationSeaZoneId: 'sea2',
        ),
      );
      final results = engine.validatePlayerOrdersWithContext(
        game,
        topology,
        'p1',
      );
      expect(results.single.status, OrderValidationStatus.rejected);
      expect(results.single.reason, contains('Fleet not found'));
    });

    test('blockade order rejected when not at war with province owner', () {
      const ow = 'oldWorld';
      final topology = MapTopology(
        nodes: const [
          TopologyNode(
            id: 'sea1',
            regionId: ow,
            type: TopologyNodeType.seaZone,
          ),
        ],
        edges: const [],
      );
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: RegionData(
            provinces: [
              Province(id: '$ow|P1', regionId: ow, ownerId: 'p1'),
              Province(id: '$ow|P2', regionId: ow, ownerId: 'p2'),
            ],
          ),
          newWorld: const RegionData(),
          fleets: [
            Fleet(
              id: 'f1',
              ownerId: 'p1',
              seaZoneId: 'sea1',
              regionId: ow,
              shipTypeIds: const ['carrack'],
            ),
          ],
        ),
        players: const [
          Player(id: 'p1', displayName: 'P1', isHuman: true),
          Player(id: 'p2', displayName: 'P2', isHuman: true),
        ],
        diplomacyRelations: [
          DiplomacyRelation(
            factionId1: 'p1',
            factionId2: 'p2',
            state: RelationState.atPeace,
          ),
        ],
      );
      final engine = OrderEngine();
      final result = engine.addNavalMissionOrderWithContext(
        game,
        topology,
        'p1',
        NavalMissionOrder(
          fleetId: 'f1',
          mission: FleetMission.blockade.name,
          targetProvinceId: '$ow|P2',
        ),
      );
      expect(result.status, OrderValidationStatus.rejected);
      expect(result.reason, contains('at war'));
    });

    test('blockade order accepted when at war with province owner', () {
      const ow = 'oldWorld';
      final topology = MapTopology(
        nodes: const [
          TopologyNode(
            id: 'sea1',
            regionId: ow,
            type: TopologyNodeType.seaZone,
          ),
        ],
        edges: const [],
      );
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: RegionData(
            provinces: [
              Province(id: '$ow|P1', regionId: ow, ownerId: 'p1'),
              Province(id: '$ow|P2', regionId: ow, ownerId: 'p2'),
            ],
          ),
          newWorld: const RegionData(),
          fleets: [
            Fleet(
              id: 'f1',
              ownerId: 'p1',
              seaZoneId: 'sea1',
              regionId: ow,
              shipTypeIds: const ['carrack'],
            ),
          ],
        ),
        players: const [
          Player(id: 'p1', displayName: 'P1', isHuman: true),
          Player(id: 'p2', displayName: 'P2', isHuman: true),
        ],
        diplomacyRelations: [
          DiplomacyRelation(
            factionId1: 'p1',
            factionId2: 'p2',
            state: RelationState.atWar,
          ),
        ],
      );
      final engine = OrderEngine();
      final result = engine.addNavalMissionOrderWithContext(
        game,
        topology,
        'p1',
        NavalMissionOrder(
          fleetId: 'f1',
          mission: FleetMission.blockade.name,
          targetProvinceId: '$ow|P2',
        ),
      );
      expect(result.status, OrderValidationStatus.accepted);
    });

    test(
      'projectedEffects returns treasuryDelta when orders affect treasury',
      () {
        const ow = 'oldWorld';
        final topology = MapTopology(
          nodes: const [
            TopologyNode(
              id: 'P1',
              regionId: ow,
              type: TopologyNodeType.province,
            ),
          ],
          edges: const [],
        );
        final econ = RegimentEconomyCatalog.byId['peasant_levies']!;
        var stockpile = const Stockpile();
        for (final e in econ.buildInputs.entries) {
          stockpile = stockpile.applyDelta(e.key, e.value + 1);
        }
        final game = Game(
          id: 'g1',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
            oldWorld: RegionData(
              provinces: [Province(id: '$ow|P1', regionId: ow, ownerId: 'p1')],
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
              treasury: econ.buildTreasuryCost + 100,
            ),
          ],
        );
        final engine = OrderEngine();
        engine.addBuildOrder(
          'p1',
          BuildUnitOrder(
            unitType: 'peasant_levies',
            isMilitary:
                buildUnitCategoryForUnitType('peasant_levies') ==
                BuildUnitCategory.military,
            spawnProvinceId: '$ow|P1',
          ),
        );
        final effects = engine.projectedEffects(game, topology, 'p1');
        expect(effects.workerCount, isNotNull);
        expect(effects.treasuryDelta, isNotNull);
      },
    );

    test('rejects naval build when peasants are zero', () {
      const ow = 'oldWorld';
      final topology = MapTopology(
        nodes: const [
          TopologyNode(
            id: 'P1',
            regionId: ow,
            type: TopologyNodeType.province,
          ),
        ],
        edges: const [],
      );
      final shipEcon = ShipEconomyCatalog.byId['carrack']!;
      var stockpile = const Stockpile();
      for (final e in shipEcon.buildInputs.entries) {
        stockpile = stockpile.applyDelta(e.key, e.value + 1);
      }
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: RegionData(
            provinces: [Province(id: '$ow|P1', regionId: ow, ownerId: 'p1')],
            units: [],
          ),
          newWorld: const RegionData(),
        ),
        players: [
          Player(
            id: 'p1',
            displayName: 'P1',
            isHuman: true,
            capitalProvinceId: '$ow|P1',
            stockpile: stockpile,
            workerPool: const WorkerPool(peasants: 0),
            treasury: shipEcon.buildTreasuryCost + 10,
          ),
        ],
      );
      final engine = OrderEngine();
      final result = engine.addBuildOrderWithContext(
        game,
        topology,
        'p1',
        BuildUnitOrder(
          unitType: 'carrack',
          isMilitary: false,
          spawnProvinceId: '$ow|P1',
        ),
      );
      expect(result.status, OrderValidationStatus.rejected);
      expect(result.reason, 'Insufficient resources');
    });
  });
}
