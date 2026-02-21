import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('OrderEngine', () {
    test('add order and validate', () {
      final engine = OrderEngine();
      final result = engine.addMoveOrder('p1', const MoveOrder(unitId: 'u1', destinationProvinceId: 'P2'));
      expect(result.status, OrderValidationStatus.accepted);
      expect(engine.orders.moveOrdersByPlayerId['p1']?.length, 1);
    });

    test('first invalid order plus subsequent rejected', () {
      const ow = 'oldWorld';
      final topology = MapTopology(
        nodes: [
          const TopologyNode(id: 'P1', regionId: ow, type: TopologyNodeType.province),
          const TopologyNode(id: 'P2', regionId: ow, type: TopologyNodeType.province),
        ],
        edges: [const TopologyEdge(id1: 'P1', id2: 'P2')],
      );
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: RegionData(
            provinces: [
              Province(id: '$ow|P1', regionId: ow, ownerId: 'p1'),
              Province(id: '$ow|P2', regionId: ow, ownerId: 'p1'),
            ],
            units: [
              Unit(id: 'u1', type: 'musketeers', ownerId: 'p1', provinceId: '$ow|P1'),
            ],
            ),
          newWorld: const RegionData(),
          playerVisibilityByTile: const {
            'p1': {
              'oldWorld|P1|0|0': 'fullyVisible',
              'oldWorld|P2|0|0': 'fullyVisible',
            },
          },
        ),
        players: [Player(id: 'p1', displayName: 'P1', isHuman: true)],
      );

      final engine = OrderEngine();
      engine.addMoveOrder('p1', const MoveOrder(unitId: 'u1', destinationProvinceId: 'oldWorld|P2'));
      engine.addMoveOrder('p1', const MoveOrder(unitId: 'u999', destinationProvinceId: 'oldWorld|P2'));
      engine.addMoveOrder('p1', const MoveOrder(unitId: 'u1', destinationProvinceId: 'oldWorld|P3'));

      final results = engine.validatePlayerOrdersWithContext(game, topology, 'p1');
      expect(results.length, 3);
      expect(results[0].status, OrderValidationStatus.accepted);
      expect(results[1].status, OrderValidationStatus.rejected);
      expect(results[2].status, OrderValidationStatus.rejected);
    });

    test('projected effects returns worker count', () {
      const ow = 'oldWorld';
      final topology = MapTopology(
        nodes: [
          const TopologyNode(id: 'P1', regionId: ow, type: TopologyNodeType.province),
        ],
        edges: [],
      );
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
        players: [Player(id: 'p1', displayName: 'P1', isHuman: true)],
      );

      final engine = OrderEngine();
      final effects = engine.projectedEffects(game, topology, 'p1');
      expect(effects.workerCount, isNotNull);
    });

    test('addMoveOrderWithContext uses world-state validation', () {
      const ow = 'oldWorld';
      final topology = MapTopology(
        nodes: [
          const TopologyNode(id: 'P1', regionId: ow, type: TopologyNodeType.province),
          const TopologyNode(id: 'P2', regionId: ow, type: TopologyNodeType.province),
        ],
        edges: [const TopologyEdge(id1: 'P1', id2: 'P2')],
      );
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: RegionData(
            provinces: [
              Province(id: '$ow|P1', regionId: ow, ownerId: 'p1'),
              Province(id: '$ow|P2', regionId: ow, ownerId: 'p1'),
            ],
            units: [
              Unit(id: 'u1', type: 'musketeers', ownerId: 'p1', provinceId: '$ow|P1'),
            ],
          ),
          newWorld: const RegionData(),
          playerVisibilityByTile: const {
            'p1': {
              'oldWorld|P1|0|0': 'fullyVisible',
              'oldWorld|P2|0|0': 'fullyVisible',
            },
          },
        ),
        players: [Player(id: 'p1', displayName: 'P1', isHuman: true)],
      );

      final engine = OrderEngine();
      final ok = engine.addMoveOrderWithContext(
        game,
        topology,
        'p1',
        const MoveOrder(unitId: 'u1', destinationProvinceId: 'oldWorld|P2'),
      );
      final bad = engine.addMoveOrderWithContext(
        game,
        topology,
        'p1',
        const MoveOrder(unitId: 'u999', destinationProvinceId: 'oldWorld|P2'),
      );

      expect(ok.status, OrderValidationStatus.accepted);
      expect(bad.status, OrderValidationStatus.rejected);
    });

    test('civilian cannot move into other GP territory', () {
      const ow = 'oldWorld';
      final topology = MapTopology(
        nodes: const [
          TopologyNode(id: 'P1', regionId: 'oldWorld', type: TopologyNodeType.province),
          TopologyNode(id: 'P2', regionId: 'oldWorld', type: TopologyNodeType.province),
        ],
        edges: const [TopologyEdge(id1: 'P1', id2: 'P2')],
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
            units: [
              Unit(id: 'u1', type: 'Builder', ownerId: 'p1', provinceId: '$ow|P1'),
            ],
          ),
          newWorld: const RegionData(),
          playerVisibilityByTile: const {
            'p1': {
              'oldWorld|P1|0|0': 'fullyVisible',
              'oldWorld|P2|0|0': 'fogged',
            },
          },
        ),
        players: const [
          Player(id: 'p1', displayName: 'P1', isHuman: true),
          Player(id: 'p2', displayName: 'P2', isHuman: true),
        ],
      );

      final engine = OrderEngine();
      engine.addMoveOrder('p1', const MoveOrder(unitId: 'u1', destinationProvinceId: 'oldWorld|P2'));

      final results = engine.validatePlayerOrdersWithContext(game, topology, 'p1');
      expect(results.single.status, OrderValidationStatus.rejected);
    });

    test('explorer may move into tribal province', () {
      const ow = 'oldWorld';
      final topology = MapTopology(
        nodes: const [
          TopologyNode(id: 'P1', regionId: 'oldWorld', type: TopologyNodeType.province),
          TopologyNode(id: 'P2', regionId: 'oldWorld', type: TopologyNodeType.province),
        ],
        edges: const [TopologyEdge(id1: 'P1', id2: 'P2')],
      );
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: RegionData(
            provinces: [
              Province(id: '$ow|P1', regionId: ow, ownerId: 'p1'),
              Province(id: '$ow|P2', regionId: ow, ownerId: 'tribe1'),
            ],
            units: [
              Unit(id: 'u1', type: 'Explorer', ownerId: 'p1', provinceId: '$ow|P1'),
            ],
          ),
          newWorld: const RegionData(),
          playerVisibilityByTile: const {
            'p1': {
              'oldWorld|P1|0|0': 'fullyVisible',
              'oldWorld|P2|0|0': 'revealed',
            },
          },
        ),
        players: const [
          Player(id: 'p1', displayName: 'P1', isHuman: true),
        ],
        tribes: const [
          Tribe(id: 'tribe1', displayName: 'Tribe 1'),
        ],
      );

      final engine = OrderEngine();
      engine.addMoveOrder('p1', const MoveOrder(unitId: 'u1', destinationProvinceId: 'oldWorld|P2'));

      final results = engine.validatePlayerOrdersWithContext(game, topology, 'p1');
      expect(results.single.status, OrderValidationStatus.accepted);
    });

    test('move order rejected when source province unknown', () {
      const ow = 'oldWorld';
      final topology = MapTopology(
        nodes: const [
          TopologyNode(id: 'P1', regionId: 'oldWorld', type: TopologyNodeType.province),
          TopologyNode(id: 'P2', regionId: 'oldWorld', type: TopologyNodeType.province),
        ],
        edges: const [TopologyEdge(id1: 'P1', id2: 'P2')],
      );
      // No visibility for p1: P1 and P2 are unknown.
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: RegionData(
            provinces: [
              Province(id: '$ow|P1', regionId: ow, ownerId: 'p1'),
              Province(id: '$ow|P2', regionId: ow, ownerId: 'p1'),
            ],
            units: [
              Unit(id: 'u1', type: 'Explorer', ownerId: 'p1', provinceId: '$ow|P1'),
            ],
          ),
          newWorld: const RegionData(),
        ),
        players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
      );

      final engine = OrderEngine();
      engine.addMoveOrder('p1', const MoveOrder(unitId: 'u1', destinationProvinceId: 'oldWorld|P2'));
      final results = engine.validatePlayerOrdersWithContext(game, topology, 'p1');
      expect(results.length, 1);
      expect(results[0].status, OrderValidationStatus.rejected);
      expect(results[0].reason, contains('visible'));
    });

    test('move order rejected when destination province unknown', () {
      const ow = 'oldWorld';
      final topology = MapTopology(
        nodes: const [
          TopologyNode(id: 'P1', regionId: 'oldWorld', type: TopologyNodeType.province),
          TopologyNode(id: 'P2', regionId: 'oldWorld', type: TopologyNodeType.province),
        ],
        edges: const [TopologyEdge(id1: 'P1', id2: 'P2')],
      );
      // Only P1 visible; P2 unknown.
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: RegionData(
            provinces: [
              Province(id: '$ow|P1', regionId: ow, ownerId: 'p1'),
              Province(id: '$ow|P2', regionId: ow, ownerId: 'p1'),
            ],
            units: [
              Unit(id: 'u1', type: 'Explorer', ownerId: 'p1', provinceId: '$ow|P1'),
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
      engine.addMoveOrder('p1', const MoveOrder(unitId: 'u1', destinationProvinceId: 'oldWorld|P2'));
      final results = engine.validatePlayerOrdersWithContext(game, topology, 'p1');
      expect(results.length, 1);
      expect(results[0].status, OrderValidationStatus.rejected);
      expect(results[0].reason, contains('visible'));
    });

    test('work order explore rejected when province unknown', () {
      const ow = 'oldWorld';
      final topology = MapTopology(
        nodes: const [
          TopologyNode(id: 'P1', regionId: 'oldWorld', type: TopologyNodeType.province),
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
            ],
            units: [
              Unit(id: 'u1', type: 'Explorer', ownerId: 'p1', provinceId: '$ow|P1', tileKey: 'oldWorld|P1|0|0'),
            ],
          ),
          newWorld: const RegionData(),
          // No visibility: P1 unknown for p1.
        ),
        players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
      );

      final engine = OrderEngine();
      engine.addWorkOrder('p1', const WorkOrder(unitId: 'u1', target: 'explore', targetTileKey: 'oldWorld|P1|0|0'));
      final results = engine.validatePlayerOrdersWithContext(game, topology, 'p1');
      expect(results.length, 1);
      expect(results[0].status, OrderValidationStatus.rejected);
      expect(results[0].reason, contains('visible'));
    });

    test('work order prospect rejected when province not fogged or better', () {
      const ow = 'oldWorld';
      final topology = MapTopology(
        nodes: const [
          TopologyNode(id: 'P1', regionId: 'oldWorld', type: TopologyNodeType.province),
        ],
        edges: const [],
      );
      // P1 only revealed (not fogged) — prospect requires fogged or fullyVisible.
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: RegionData(
            provinces: [
              Province(id: '$ow|P1', regionId: ow, ownerId: 'tribe1'),
            ],
            units: [
              Unit(id: 'u1', type: 'Explorer', ownerId: 'p1', provinceId: '$ow|P1', tileKey: 'oldWorld|P1|0|0'),
            ],
          ),
          newWorld: const RegionData(),
          playerVisibilityByTile: const {
            'p1': {'oldWorld|P1|0|0': 'revealed'},
          },
        ),
        players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
        tribes: const [Tribe(id: 'tribe1', displayName: 'Tribe 1')],
      );

      final engine = OrderEngine();
      engine.addWorkOrder('p1', const WorkOrder(unitId: 'u1', target: 'prospect', targetTileKey: 'oldWorld|P1|0|0'));
      final results = engine.validatePlayerOrdersWithContext(game, topology, 'p1');
      expect(results.length, 1);
      expect(results[0].status, OrderValidationStatus.rejected);
      expect(results[0].reason, contains('visible'));
    });

    test('move order rejected when destination not adjacent', () {
      const ow = 'oldWorld';
      final topology = MapTopology(
        nodes: const [
          TopologyNode(id: 'P1', regionId: 'oldWorld', type: TopologyNodeType.province),
          TopologyNode(id: 'P2', regionId: 'oldWorld', type: TopologyNodeType.province),
          TopologyNode(id: 'P3', regionId: 'oldWorld', type: TopologyNodeType.province),
        ],
        edges: [
          const TopologyEdge(id1: 'P1', id2: 'P2'),
          const TopologyEdge(id1: 'P2', id2: 'P3'),
        ],
      );
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: RegionData(
            provinces: [
              Province(id: '$ow|P1', regionId: ow, ownerId: 'p1'),
              Province(id: '$ow|P2', regionId: ow, ownerId: 'p1'),
              Province(id: '$ow|P3', regionId: ow, ownerId: 'p1'),
            ],
            units: [
              Unit(id: 'u1', type: 'musketeers', ownerId: 'p1', provinceId: '$ow|P1'),
            ],
            ),
          newWorld: const RegionData(),
          playerVisibilityByTile: const {
            'p1': {
              'oldWorld|P1|0|0': 'fullyVisible',
              'oldWorld|P2|0|0': 'fullyVisible',
              'oldWorld|P3|0|0': 'fullyVisible',
            },
          },
        ),
        players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
      );
      final engine = OrderEngine();
      engine.addMoveOrder('p1', MoveOrder(unitId: 'u1', destinationProvinceId: '$ow|P3'));
      final results = engine.validatePlayerOrdersWithContext(game, topology, 'p1');
      expect(results.single.status, OrderValidationStatus.rejected);
    });

    test('work order rejected for invalid target for unit type', () {
      const ow = 'oldWorld';
      final topology = MapTopology(
        nodes: const [
          TopologyNode(id: 'P1', regionId: 'oldWorld', type: TopologyNodeType.province),
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
              Unit(id: 'u1', type: 'Builder', ownerId: 'p1', provinceId: '$ow|P1', tileKey: 'oldWorld|P1|0|0'),
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
      engine.addWorkOrder('p1', WorkOrder(unitId: 'u1', target: 'unknown_target', targetTileKey: 'oldWorld|P1|0|0'));
      final results = engine.validatePlayerOrdersWithContext(game, topology, 'p1');
      expect(results.single.status, OrderValidationStatus.rejected);
      expect(results.single.reason, contains('Invalid work target'));
    });

    test('initial orders copy: getter returns equal but distinct lists', () {
      final initial = Orders(
        moveOrdersByPlayerId: {
          'p1': [const MoveOrder(unitId: 'u1', destinationProvinceId: 'oldWorld|P2')],
        },
      );
      final engine = OrderEngine(initialOrders: initial);
      final orders1 = engine.orders;
      final orders2 = engine.orders;
      expect(orders1.moveOrdersByPlayerId['p1']!.length, 1);
      expect(orders2.moveOrdersByPlayerId['p1']!.length, 1);
      expect(identical(orders1.moveOrdersByPlayerId, orders2.moveOrdersByPlayerId), isFalse);
      expect(identical(orders1.moveOrdersByPlayerId['p1'], orders2.moveOrdersByPlayerId['p1']), isFalse);
    });

    test('naval move order rejected when fleet not found', () {
      const ow = 'oldWorld';
      final topology = MapTopology(
        nodes: const [
          TopologyNode(id: 'P1', regionId: ow, type: TopologyNodeType.province),
          TopologyNode(id: 'sea1', regionId: ow, type: TopologyNodeType.seaZone),
          TopologyNode(id: 'sea2', regionId: ow, type: TopologyNodeType.seaZone),
        ],
        edges: const [
          TopologyEdge(id1: 'sea1', id2: 'sea2'),
        ],
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
      engine.addNavalMoveOrder('p1', NavalMoveOrder(fleetId: 'nonexistent_fleet', destinationSeaZoneId: 'sea2'));
      final results = engine.validatePlayerOrdersWithContext(game, topology, 'p1');
      expect(results.single.status, OrderValidationStatus.rejected);
      expect(results.single.reason, contains('Fleet not found'));
    });

    test('projectedEffects returns treasuryDelta when orders affect treasury', () {
      const ow = 'oldWorld';
      final topology = MapTopology(
        nodes: const [
          TopologyNode(id: 'P1', regionId: ow, type: TopologyNodeType.province),
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
      engine.addBuildOrder('p1', BuildUnitOrder(
        unitType: 'peasant_levies',
        isMilitary: buildUnitCategoryForUnitType('peasant_levies') == BuildUnitCategory.military,
        spawnProvinceId: '$ow|P1',
      ));
      final effects = engine.projectedEffects(game, topology, 'p1');
      expect(effects.workerCount, isNotNull);
      expect(effects.treasuryDelta, isNotNull);
    });

    group('validateBuild (civilian)', () {
      const ow = 'oldWorld';
      final topology = MapTopology(
        nodes: const [TopologyNode(id: 'P1', regionId: ow, type: TopologyNodeType.province)],
        edges: const [],
      );

      test('rejects unknown unit type', () {
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
              stockpile: const Stockpile(),
              workerPool: const WorkerPool(peasants: 0),
              treasury: 5000,
            ),
          ],
        );
        final engine = OrderEngine();
        engine.addBuildOrder('p1', BuildUnitOrder(
          unitType: 'UnknownTypeXyz',
          isMilitary: buildUnitCategoryForUnitType('UnknownTypeXyz') == BuildUnitCategory.military,
          spawnProvinceId: '$ow|P1',
        ));
        final results = engine.validatePlayerOrdersWithContext(game, topology, 'p1');
        expect(results.single.status, OrderValidationStatus.rejected);
      });

      test('rejects Builder when treasury too low', () {
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
              stockpile: Stockpile().applyDelta(CommodityCatalog.paper.id, 5),
              workerPool: const WorkerPool(peasants: 0),
              treasury: 999,
            ),
          ],
        );
        final engine = OrderEngine();
        engine.addBuildOrder('p1', BuildUnitOrder(
          unitType: 'Builder',
          isMilitary: buildUnitCategoryForUnitType('Builder') == BuildUnitCategory.military,
          spawnProvinceId: '$ow|P1',
        ));
        final results = engine.validatePlayerOrdersWithContext(game, topology, 'p1');
        expect(results.single.status, OrderValidationStatus.rejected);
      });

      test('rejects Builder when paper insufficient', () {
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
              stockpile: const Stockpile(),
              workerPool: const WorkerPool(peasants: 0),
              treasury: 2000,
            ),
          ],
        );
        final engine = OrderEngine();
        engine.addBuildOrder('p1', BuildUnitOrder(
          unitType: 'Builder',
          isMilitary: buildUnitCategoryForUnitType('Builder') == BuildUnitCategory.military,
          spawnProvinceId: '$ow|P1',
        ));
        final results = engine.validatePlayerOrdersWithContext(game, topology, 'p1');
        expect(results.single.status, OrderValidationStatus.rejected);
      });

      test('rejects Merchant when merchant_companies not unlocked', () {
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
              stockpile: Stockpile().applyDelta(CommodityCatalog.paper.id, 5),
              workerPool: const WorkerPool(peasants: 0),
              treasury: 3000,
              techUnlocked: {},
            ),
          ],
        );
        final engine = OrderEngine();
        engine.addBuildOrder('p1', BuildUnitOrder(
          unitType: 'Merchant',
          isMilitary: buildUnitCategoryForUnitType('Merchant') == BuildUnitCategory.military,
          spawnProvinceId: '$ow|P1',
        ));
        final results = engine.validatePlayerOrdersWithContext(game, topology, 'p1');
        expect(results.single.status, OrderValidationStatus.rejected);
      });

      test('accepts Builder when treasury and paper sufficient', () {
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
              stockpile: Stockpile().applyDelta(CommodityCatalog.paper.id, 5),
              workerPool: const WorkerPool(peasants: 0),
              treasury: 2000,
            ),
          ],
        );
        final engine = OrderEngine();
        engine.addBuildOrder('p1', BuildUnitOrder(
          unitType: 'Builder',
          isMilitary: buildUnitCategoryForUnitType('Builder') == BuildUnitCategory.military,
          spawnProvinceId: '$ow|P1',
        ));
        final results = engine.validatePlayerOrdersWithContext(game, topology, 'p1');
        expect(results.single.status, OrderValidationStatus.accepted);
      });

      test('accepts Merchant when tech and resources ok', () {
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
              stockpile: Stockpile().applyDelta(CommodityCatalog.paper.id, 5),
              workerPool: const WorkerPool(peasants: 0),
              treasury: 3000,
              techUnlocked: {'merchant_companies': true},
            ),
          ],
        );
        final engine = OrderEngine();
        engine.addBuildOrder('p1', BuildUnitOrder(
          unitType: 'Merchant',
          isMilitary: buildUnitCategoryForUnitType('Merchant') == BuildUnitCategory.military,
          spawnProvinceId: '$ow|P1',
        ));
        final results = engine.validatePlayerOrdersWithContext(game, topology, 'p1');
        expect(results.single.status, OrderValidationStatus.accepted);
      });
    });
  });
}
