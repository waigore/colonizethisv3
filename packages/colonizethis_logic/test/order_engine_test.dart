import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  group('OrderEngine', () {
    test('add order and validate', () {
      final engine = OrderEngine();
      final result = engine.addMoveOrder(
          'p1', const MoveOrder(unitId: 'u1', destinationProvinceId: 'oldWorld|P2'));
      expect(result.status, OrderValidationStatus.accepted);
      expect(engine.orders.moveOrdersByPlayerId['p1']?.length, 1);
    });

    test('removeMoveOrder removes order at index', () {
      final engine = OrderEngine();
      engine.addMoveOrder(
          'p1', const MoveOrder(unitId: 'u1', destinationProvinceId: 'oldWorld|P2'));
      engine.addMoveOrder(
          'p1', const MoveOrder(unitId: 'u2', destinationProvinceId: 'oldWorld|P3'));
      expect(engine.orders.moveOrdersByPlayerId['p1']!.length, 2);
      engine.removeMoveOrder('p1', 0);
      expect(engine.orders.moveOrdersByPlayerId['p1']!.length, 1);
      expect(engine.orders.moveOrdersByPlayerId['p1']!.first.unitId, 'u2');
    });

    test('removeBuildOrder removes order at index', () {
      final engine = OrderEngine();
      engine.addBuildOrder(
          'p1',
          BuildUnitOrder(
            unitType: 'peasant_levies',
            isMilitary: true,
            spawnProvinceId: 'oldWorld|P1',
          ));
      expect(engine.orders.buildUnitOrdersByPlayerId['p1']!.length, 1);
      engine.removeBuildOrder('p1', 0);
      expect(engine.orders.buildUnitOrdersByPlayerId['p1'], isEmpty);
    });

    test('addWorkOrderWithContext returns rejected when order invalid', () {
      const ow = 'oldWorld';
      final topology = MapTopology(
        nodes: const [
          TopologyNode(id: 'P1', regionId: ow, type: TopologyNodeType.province)
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
                  provinceId: '$ow|P1',
                  tileKey: 'oldWorld|P1|0|0'),
            ],
          ),
          newWorld: const RegionData(),
        ),
        players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
      );
      final engine = OrderEngine();
      final result = engine.addWorkOrderWithContext(
        game,
        topology,
        'p1',
        const WorkOrder(
            unitId: 'u1',
            target: 'unknown_target',
            targetTileKey: 'oldWorld|P1|0|0'),
      );
      expect(result.status, OrderValidationStatus.rejected);
    });

    test('first invalid order plus subsequent rejected', () {
      const ow = 'oldWorld';
      final topology = MapTopology(
        nodes: [
          const TopologyNode(
              id: 'P1', regionId: ow, type: TopologyNodeType.province),
          const TopologyNode(
              id: 'P2', regionId: ow, type: TopologyNodeType.province),
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
              Unit(
                  id: 'u1',
                  type: 'musketeers',
                  ownerId: 'p1',
                  provinceId: '$ow|P1'),
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
      engine.addMoveOrder('p1',
          const MoveOrder(unitId: 'u1', destinationProvinceId: 'oldWorld|P2'));
      engine.addMoveOrder(
          'p1',
          const MoveOrder(
              unitId: 'u999', destinationProvinceId: 'oldWorld|P2'));
      engine.addMoveOrder('p1',
          const MoveOrder(unitId: 'u1', destinationProvinceId: 'oldWorld|P3'));

      final results =
          engine.validatePlayerOrdersWithContext(game, topology, 'p1');
      expect(results.length, 3);
      expect(results[0].status, OrderValidationStatus.accepted);
      expect(results[1].status, OrderValidationStatus.rejected);
      expect(results[2].status, OrderValidationStatus.rejected);
    });

    test('projected effects returns worker count', () {
      const ow = 'oldWorld';
      final topology = MapTopology(
        nodes: [
          const TopologyNode(
              id: 'P1', regionId: ow, type: TopologyNodeType.province),
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

    test('projectedEffects returns unitLocations when engine has move order',
        () {
      const ow = 'oldWorld';
      final topology = MapTopology(
        nodes: [
          const TopologyNode(
              id: 'P1', regionId: ow, type: TopologyNodeType.province),
          const TopologyNode(
              id: 'P2', regionId: ow, type: TopologyNodeType.province),
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
              Unit(
                  id: 'u1',
                  type: 'musketeers',
                  ownerId: 'p1',
                  provinceId: '$ow|P1'),
            ],
          ),
          newWorld: const RegionData(),
        ),
        players: [Player(id: 'p1', displayName: 'P1', isHuman: true)],
      );
      final engine = OrderEngine();
      engine.addMoveOrder(
          'p1', const MoveOrder(unitId: 'u1', destinationProvinceId: '$ow|P2'));
      final effects = engine.projectedEffects(game, topology, 'p1');
      expect(effects.unitLocations, isNotNull);
      expect(effects.unitLocations!['u1'], '$ow|P2');
    });

    test('projectedEffects does not mutate passed-in game', () {
      const ow = 'oldWorld';
      final topology = MapTopology(
        nodes: [
          const TopologyNode(
              id: 'P1', regionId: ow, type: TopologyNodeType.province),
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
      final turnBefore = game.worldState.turnState.turnNumber;
      final engine = OrderEngine();
      engine.projectedEffects(game, topology, 'p1');
      expect(game.worldState.turnState.turnNumber, turnBefore);
    });

    test('addMoveOrderWithContext uses world-state validation', () {
      const ow = 'oldWorld';
      final topology = MapTopology(
        nodes: [
          const TopologyNode(
              id: 'P1', regionId: ow, type: TopologyNodeType.province),
          const TopologyNode(
              id: 'P2', regionId: ow, type: TopologyNodeType.province),
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
              Unit(
                  id: 'u1',
                  type: 'musketeers',
                  ownerId: 'p1',
                  provinceId: '$ow|P1'),
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
          TopologyNode(
              id: 'P1', regionId: 'oldWorld', type: TopologyNodeType.province),
          TopologyNode(
              id: 'P2', regionId: 'oldWorld', type: TopologyNodeType.province),
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
              Unit(
                  id: 'u1',
                  type: 'Builder',
                  ownerId: 'p1',
                  provinceId: '$ow|P1'),
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
      engine.addMoveOrder('p1',
          const MoveOrder(unitId: 'u1', destinationProvinceId: 'oldWorld|P2'));

      final results =
          engine.validatePlayerOrdersWithContext(game, topology, 'p1');
      expect(results.single.status, OrderValidationStatus.rejected);
    });

    // Issue #943: Cannot attack GP province without declaring war first
    test('military cannot move into other GP province without war', () {
      const ow = 'oldWorld';
      final topology = MapTopology(
        nodes: const [
          TopologyNode(
              id: 'P1', regionId: 'oldWorld', type: TopologyNodeType.province),
          TopologyNode(
              id: 'P2', regionId: 'oldWorld', type: TopologyNodeType.province),
        ],
        edges: const [TopologyEdge(id1: 'P1', id2: 'P2')],
      );
      // Create game with two GPs at peace
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
              Unit(
                  id: 'u1',
                  type: 'pikemen',
                  ownerId: 'p1',
                  provinceId: '$ow|P1'),
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
          Player(id: 'p2', displayName: 'P2', isHuman: true),
        ],
        // At peace - no diplomacy relations
        diplomacyRelations: const [],
      );

      final engine = OrderEngine();
      engine.addMoveOrder('p1',
          const MoveOrder(unitId: 'u1', destinationProvinceId: 'oldWorld|P2'));

      final results =
          engine.validatePlayerOrdersWithContext(game, topology, 'p1');
      expect(results.single.status, OrderValidationStatus.rejected);
      expect(results.single.reason, contains('declare war'));
    });

    test('explorer may move into tribal province', () {
      const ow = 'oldWorld';
      final topology = MapTopology(
        nodes: const [
          TopologyNode(
              id: 'P1', regionId: 'oldWorld', type: TopologyNodeType.province),
          TopologyNode(
              id: 'P2', regionId: 'oldWorld', type: TopologyNodeType.province),
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
              Unit(
                  id: 'u1',
                  type: 'Explorer',
                  ownerId: 'p1',
                  provinceId: '$ow|P1'),
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
      engine.addMoveOrder('p1',
          const MoveOrder(unitId: 'u1', destinationProvinceId: 'oldWorld|P2'));

      final results =
          engine.validatePlayerOrdersWithContext(game, topology, 'p1');
      expect(results.single.status, OrderValidationStatus.accepted);
    });

    test('move order rejected when source province unknown', () {
      const ow = 'oldWorld';
      final topology = MapTopology(
        nodes: const [
          TopologyNode(
              id: 'P1', regionId: 'oldWorld', type: TopologyNodeType.province),
          TopologyNode(
              id: 'P2', regionId: 'oldWorld', type: TopologyNodeType.province),
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
              Unit(
                  id: 'u1',
                  type: 'Explorer',
                  ownerId: 'p1',
                  provinceId: '$ow|P1'),
            ],
          ),
          newWorld: const RegionData(),
        ),
        players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
      );

      final engine = OrderEngine();
      engine.addMoveOrder('p1',
          const MoveOrder(unitId: 'u1', destinationProvinceId: 'oldWorld|P2'));
      final results =
          engine.validatePlayerOrdersWithContext(game, topology, 'p1');
      expect(results.length, 1);
      expect(results[0].status, OrderValidationStatus.rejected);
      expect(results[0].reason, contains('visible'));
    });

    test('move order rejected when destination province unknown', () {
      const ow = 'oldWorld';
      final topology = MapTopology(
        nodes: const [
          TopologyNode(
              id: 'P1', regionId: 'oldWorld', type: TopologyNodeType.province),
          TopologyNode(
              id: 'P2', regionId: 'oldWorld', type: TopologyNodeType.province),
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
              Unit(
                  id: 'u1',
                  type: 'Explorer',
                  ownerId: 'p1',
                  provinceId: '$ow|P1'),
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
      engine.addMoveOrder('p1',
          const MoveOrder(unitId: 'u1', destinationProvinceId: 'oldWorld|P2'));
      final results =
          engine.validatePlayerOrdersWithContext(game, topology, 'p1');
      expect(results.length, 1);
      expect(results[0].status, OrderValidationStatus.rejected);
      expect(results[0].reason, contains('visible'));
    });

    test('work order explore rejected when province unknown', () {
      const ow = 'oldWorld';
      final topology = MapTopology(
        nodes: const [
          TopologyNode(
              id: 'P1', regionId: 'oldWorld', type: TopologyNodeType.province),
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
              Unit(
                  id: 'u1',
                  type: 'Explorer',
                  ownerId: 'p1',
                  provinceId: '$ow|P1',
                  tileKey: 'oldWorld|P1|0|0'),
            ],
          ),
          newWorld: const RegionData(),
          // No visibility: P1 unknown for p1.
        ),
        players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
      );

      final engine = OrderEngine();
      engine.addWorkOrder(
          'p1',
          const WorkOrder(
              unitId: 'u1',
              target: 'explore',
              targetTileKey: 'oldWorld|P1|0|0'));
      final results =
          engine.validatePlayerOrdersWithContext(game, topology, 'p1');
      expect(results.length, 1);
      expect(results[0].status, OrderValidationStatus.rejected);
      expect(results[0].reason, contains('visible'));
    });

    test('work order prospect rejected when province not fogged or better', () {
      const ow = 'oldWorld';
      final topology = MapTopology(
        nodes: const [
          TopologyNode(
              id: 'P1', regionId: 'oldWorld', type: TopologyNodeType.province),
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
              Unit(
                  id: 'u1',
                  type: 'Explorer',
                  ownerId: 'p1',
                  provinceId: '$ow|P1',
                  tileKey: 'oldWorld|P1|0|0'),
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
      engine.addWorkOrder(
          'p1',
          const WorkOrder(
              unitId: 'u1',
              target: 'prospect',
              targetTileKey: 'oldWorld|P1|0|0'));
      final results =
          engine.validatePlayerOrdersWithContext(game, topology, 'p1');
      expect(results.length, 1);
      expect(results[0].status, OrderValidationStatus.rejected);
      expect(results[0].reason, contains('visible'));
    });

    test('move order rejected when destination not adjacent and not own province', () {
      const ow = 'oldWorld';
      final topology = MapTopology(
        nodes: const [
          TopologyNode(
              id: 'P1', regionId: 'oldWorld', type: TopologyNodeType.province),
          TopologyNode(
              id: 'P2', regionId: 'oldWorld', type: TopologyNodeType.province),
          TopologyNode(
              id: 'P3', regionId: 'oldWorld', type: TopologyNodeType.province),
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
              Province(id: '$ow|P3', regionId: ow, ownerId: 'p2'),
            ],
            units: [
              Unit(
                  id: 'u1',
                  type: 'musketeers',
                  ownerId: 'p1',
                  provinceId: '$ow|P1'),
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
        players: const [
          Player(id: 'p1', displayName: 'P1', isHuman: true),
          Player(id: 'p2', displayName: 'P2', isHuman: true),
        ],
      );
      final engine = OrderEngine();
      engine.addMoveOrder(
          'p1', MoveOrder(unitId: 'u1', destinationProvinceId: '$ow|P3'));
      final results =
          engine.validatePlayerOrdersWithContext(game, topology, 'p1');
      expect(results.single.status, OrderValidationStatus.rejected);
    });

    test('move order accepted when destination not adjacent but own province', () {
      const ow = 'oldWorld';
      final topology = MapTopology(
        nodes: const [
          TopologyNode(
              id: 'P1', regionId: 'oldWorld', type: TopologyNodeType.province),
          TopologyNode(
              id: 'P2', regionId: 'oldWorld', type: TopologyNodeType.province),
          TopologyNode(
              id: 'P3', regionId: 'oldWorld', type: TopologyNodeType.province),
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
              Unit(
                  id: 'u1',
                  type: 'musketeers',
                  ownerId: 'p1',
                  provinceId: '$ow|P1'),
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
      engine.addMoveOrder(
          'p1', MoveOrder(unitId: 'u1', destinationProvinceId: '$ow|P3'));
      final results =
          engine.validatePlayerOrdersWithContext(game, topology, 'p1');
      expect(results.single.status, OrderValidationStatus.accepted);
    });

    test('move order accepted for own province across regions', () {
      const ow = 'oldWorld';
      const nw = 'newWorld';
      final topology = MapTopology(
        nodes: const [
          TopologyNode(
              id: 'P1', regionId: ow, type: TopologyNodeType.province),
          TopologyNode(
              id: 'P2', regionId: nw, type: TopologyNodeType.province),
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
              Unit(
                  id: 'u1',
                  type: 'musketeers',
                  ownerId: 'p1',
                  provinceId: '$ow|P1'),
            ],
          ),
          newWorld: RegionData(
            provinces: [
              Province(id: '$nw|P2', regionId: nw, ownerId: 'p1'),
            ],
            units: const [],
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
      final results =
          engine.validatePlayerOrdersWithContext(game, topology, 'p1');
      expect(results.single.status, OrderValidationStatus.accepted);
    });

    test('move order rejected when destination is foreign province across regions', () {
      const ow = 'oldWorld';
      const nw = 'newWorld';
      final topology = MapTopology(
        nodes: const [
          TopologyNode(
              id: 'P1', regionId: ow, type: TopologyNodeType.province),
          TopologyNode(
              id: 'P2', regionId: nw, type: TopologyNodeType.province),
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
              Unit(
                  id: 'u1',
                  type: 'musketeers',
                  ownerId: 'p1',
                  provinceId: '$ow|P1'),
            ],
          ),
          newWorld: RegionData(
            provinces: [
              Province(id: '$nw|P2', regionId: nw, ownerId: 'p2'),
            ],
            units: const [],
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
      final results =
          engine.validatePlayerOrdersWithContext(game, topology, 'p1');
      expect(results.single.status, OrderValidationStatus.rejected);
    });

    test('work order rejected for invalid target for unit type', () {
      const ow = 'oldWorld';
      final topology = MapTopology(
        nodes: const [
          TopologyNode(
              id: 'P1', regionId: 'oldWorld', type: TopologyNodeType.province),
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
                  provinceId: '$ow|P1',
                  tileKey: 'oldWorld|P1|0|0'),
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
              targetTileKey: 'oldWorld|P1|0|0'));
      final results =
          engine.validatePlayerOrdersWithContext(game, topology, 'p1');
      expect(results.single.status, OrderValidationStatus.rejected);
      expect(results.single.reason, contains('Invalid work target'));
    });

    test('initial orders copy: getter returns equal but distinct lists', () {
      final initial = Orders(
        moveOrdersByPlayerId: {
          'p1': [
            const MoveOrder(unitId: 'u1', destinationProvinceId: 'oldWorld|P2')
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
          isFalse);
      expect(
          identical(orders1.moveOrdersByPlayerId['p1'],
              orders2.moveOrdersByPlayerId['p1']),
          isFalse);
    });

    test('naval move order rejected when fleet not found', () {
      const ow = 'oldWorld';
      final topology = MapTopology(
        nodes: const [
          TopologyNode(id: 'P1', regionId: ow, type: TopologyNodeType.province),
          TopologyNode(
              id: 'sea1', regionId: ow, type: TopologyNodeType.seaZone),
          TopologyNode(
              id: 'sea2', regionId: ow, type: TopologyNodeType.seaZone),
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
      engine.addNavalMoveOrder(
          'p1',
          NavalMoveOrder(
              fleetId: 'nonexistent_fleet', destinationSeaZoneId: 'sea2'));
      final results =
          engine.validatePlayerOrdersWithContext(game, topology, 'p1');
      expect(results.single.status, OrderValidationStatus.rejected);
      expect(results.single.reason, contains('Fleet not found'));
    });

    test('blockade order rejected when not at war with province owner', () {
      const ow = 'oldWorld';
      final topology = MapTopology(
        nodes: const [
          TopologyNode(
              id: 'sea1', regionId: ow, type: TopologyNodeType.seaZone),
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
              id: 'sea1', regionId: ow, type: TopologyNodeType.seaZone),
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

    test('projectedEffects returns treasuryDelta when orders affect treasury',
        () {
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
      engine.addBuildOrder(
          'p1',
          BuildUnitOrder(
            unitType: 'peasant_levies',
            isMilitary: buildUnitCategoryForUnitType('peasant_levies') ==
                BuildUnitCategory.military,
            spawnProvinceId: '$ow|P1',
          ));
      final effects = engine.projectedEffects(game, topology, 'p1');
      expect(effects.workerCount, isNotNull);
      expect(effects.treasuryDelta, isNotNull);
    });

    group('validateBuild (civilian)', () {
      const ow = 'oldWorld';
      final topology = MapTopology(
        nodes: const [
          TopologyNode(id: 'P1', regionId: ow, type: TopologyNodeType.province)
        ],
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
        engine.addBuildOrder(
            'p1',
            BuildUnitOrder(
              unitType: 'UnknownTypeXyz',
              isMilitary: buildUnitCategoryForUnitType('UnknownTypeXyz') ==
                  BuildUnitCategory.military,
              spawnProvinceId: '$ow|P1',
            ));
        final results =
            engine.validatePlayerOrdersWithContext(game, topology, 'p1');
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
        engine.addBuildOrder(
            'p1',
            BuildUnitOrder(
              unitType: 'Builder',
              isMilitary: buildUnitCategoryForUnitType('Builder') ==
                  BuildUnitCategory.military,
              spawnProvinceId: '$ow|P1',
            ));
        final results =
            engine.validatePlayerOrdersWithContext(game, topology, 'p1');
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
        engine.addBuildOrder(
            'p1',
            BuildUnitOrder(
              unitType: 'Builder',
              isMilitary: buildUnitCategoryForUnitType('Builder') ==
                  BuildUnitCategory.military,
              spawnProvinceId: '$ow|P1',
            ));
        final results =
            engine.validatePlayerOrdersWithContext(game, topology, 'p1');
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
        engine.addBuildOrder(
            'p1',
            BuildUnitOrder(
              unitType: 'Merchant',
              isMilitary: buildUnitCategoryForUnitType('Merchant') ==
                  BuildUnitCategory.military,
              spawnProvinceId: '$ow|P1',
            ));
        final results =
            engine.validatePlayerOrdersWithContext(game, topology, 'p1');
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
        engine.addBuildOrder(
            'p1',
            BuildUnitOrder(
              unitType: 'Builder',
              isMilitary: buildUnitCategoryForUnitType('Builder') ==
                  BuildUnitCategory.military,
              spawnProvinceId: '$ow|P1',
            ));
        final results =
            engine.validatePlayerOrdersWithContext(game, topology, 'p1');
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
        engine.addBuildOrder(
            'p1',
            BuildUnitOrder(
              unitType: 'Merchant',
              isMilitary: buildUnitCategoryForUnitType('Merchant') ==
                  BuildUnitCategory.military,
              spawnProvinceId: '$ow|P1',
            ));
        final results =
            engine.validatePlayerOrdersWithContext(game, topology, 'p1');
        expect(results.single.status, OrderValidationStatus.accepted);
      });
    });

    group('validateWork (purchase_land)', () {
      const ow = 'oldWorld';
      const minorProvinceId = '$ow|M1';
      const tileKey = '$ow|M1|0|0';
      final topology = MapTopology(
        nodes: const [
          TopologyNode(id: 'P1', regionId: ow, type: TopologyNodeType.province),
          TopologyNode(id: 'M1', regionId: ow, type: TopologyNodeType.province),
        ],
        edges: const [TopologyEdge(id1: 'P1', id2: 'M1')],
      );

      Game _baseGame({
        required int treasury,
        List<OvertureState>? overtureStates,
        List<DiplomacyRelation>? diplomacyRelations,
        Map<String, String>? resourceByTileKey,
        Map<String, Set<String>>? playerProspectedTiles,
      }) {
        return Game(
          id: 'g1',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
            oldWorld: RegionData(
              provinces: [
                Province(id: '$ow|P1', regionId: ow, ownerId: 'p1'),
                Province(id: minorProvinceId, regionId: ow, ownerId: 'minor1'),
              ],
              units: [
                Unit(
                    id: 'merchant1',
                    type: 'Merchant',
                    ownerId: 'p1',
                    provinceId: minorProvinceId,
                    tileKey: tileKey),
              ],
            ),
            newWorld: const RegionData(),
            resourceByTileKey: resourceByTileKey ?? {tileKey: 'grain'},
            playerVisibilityByTile: const {
              'p1': {tileKey: 'fullyVisible'},
            },
            tileKeysByRegionAndProvince: {
              ow: {
                minorProvinceId: [tileKey],
                '$ow|P1': ['$ow|P1|0|0']
              }
            },
            playerProspectedTiles: playerProspectedTiles ?? const {},
          ),
          players: [
            Player(
              id: 'p1',
              displayName: 'P1',
              isHuman: true,
              capitalProvinceId: '$ow|P1',
              stockpile: const Stockpile(),
              treasury: treasury,
              techUnlocked: {'merchant_companies': true},
            ),
          ],
          minorNations: const [
            MinorNation(id: 'minor1', displayName: 'Minor 1')
          ],
          overtureStates: overtureStates ?? [],
          diplomacyRelations: diplomacyRelations ?? [],
        );
      }

      test('rejects purchase_land when no embassy with Minor', () {
        final game = _baseGame(treasury: 500);
        final engine = OrderEngine();
        engine.addWorkOrder(
            'p1',
            const WorkOrder(
                unitId: 'merchant1',
                target: 'purchase_land',
                targetTileKey: tileKey));
        final results =
            engine.validatePlayerOrdersWithContext(game, topology, 'p1');
        expect(results.single.status, OrderValidationStatus.rejected);
        expect(results.single.reason, contains('embassy'));
      });

      test('rejects purchase_land when at war with faction', () {
        final game = _baseGame(
          treasury: 500,
          overtureStates: [
            const OvertureState(
                gpId: 'p1',
                targetId: 'minor1',
                stage: OvertureStage.embassy,
                sinceTurn: 0)
          ],
          diplomacyRelations: [
            const DiplomacyRelation(
                factionId1: 'p1',
                factionId2: 'minor1',
                state: RelationState.atWar)
          ],
        );
        final engine = OrderEngine();
        engine.addWorkOrder(
            'p1',
            const WorkOrder(
                unitId: 'merchant1',
                target: 'purchase_land',
                targetTileKey: tileKey));
        final results =
            engine.validatePlayerOrdersWithContext(game, topology, 'p1');
        expect(results.single.status, OrderValidationStatus.rejected);
        expect(results.single.reason, contains('war'));
      });

      test('rejects purchase_land when insufficient treasury', () {
        const cost = 15 * 10; // grain default base 10
        final game = _baseGame(
          treasury: cost - 1,
          overtureStates: [
            const OvertureState(
                gpId: 'p1',
                targetId: 'minor1',
                stage: OvertureStage.embassy,
                sinceTurn: 0)
          ],
        );
        final engine = OrderEngine();
        engine.addWorkOrder(
            'p1',
            const WorkOrder(
                unitId: 'merchant1',
                target: 'purchase_land',
                targetTileKey: tileKey));
        final results =
            engine.validatePlayerOrdersWithContext(game, topology, 'p1');
        expect(results.single.status, OrderValidationStatus.rejected);
        expect(results.single.reason, contains('Insufficient treasury'));
      });

      test('rejects purchase_land when tile has no resource', () {
        final game = _baseGame(
          treasury: 500,
          overtureStates: [
            const OvertureState(
                gpId: 'p1',
                targetId: 'minor1',
                stage: OvertureStage.embassy,
                sinceTurn: 0)
          ],
          resourceByTileKey: {},
        );
        final engine = OrderEngine();
        engine.addWorkOrder(
            'p1',
            const WorkOrder(
                unitId: 'merchant1',
                target: 'purchase_land',
                targetTileKey: tileKey));
        final results =
            engine.validatePlayerOrdersWithContext(game, topology, 'p1');
        expect(results.single.status, OrderValidationStatus.rejected);
        expect(results.single.reason, contains('no resource'));
      });

      test('rejects purchase_land when mineral tile not prospected', () {
        final game = _baseGame(
          treasury: 500,
          overtureStates: [
            const OvertureState(
                gpId: 'p1',
                targetId: 'minor1',
                stage: OvertureStage.embassy,
                sinceTurn: 0)
          ],
          resourceByTileKey: {tileKey: 'iron'},
          playerProspectedTiles: {}, // p1 has not prospected this tile
        );
        final engine = OrderEngine();
        engine.addWorkOrder(
            'p1',
            const WorkOrder(
                unitId: 'merchant1',
                target: 'purchase_land',
                targetTileKey: tileKey));
        final results =
            engine.validatePlayerOrdersWithContext(game, topology, 'p1');
        expect(results.single.status, OrderValidationStatus.rejected);
        expect(results.single.reason, contains('prospected'));
      });

      test(
          'accepts purchase_land with embassy, at peace, sufficient treasury, tile with resource',
          () {
        final game = _baseGame(
          treasury: 500,
          overtureStates: [
            const OvertureState(
                gpId: 'p1',
                targetId: 'minor1',
                stage: OvertureStage.embassy,
                sinceTurn: 0)
          ],
        );
        final engine = OrderEngine();
        engine.addWorkOrder(
            'p1',
            const WorkOrder(
                unitId: 'merchant1',
                target: 'purchase_land',
                targetTileKey: tileKey));
        final results =
            engine.validatePlayerOrdersWithContext(game, topology, 'p1');
        expect(results.single.status, OrderValidationStatus.accepted);
      });

      test(
          'rejects second Builder/Engineer/Merchant work order on same tile for same player (per-tile exclusivity)',
          () {
        const ow = 'oldWorld';
        const provinceId = '$ow|P1';
        const tileKey = '$ow|P1|0|0';
        final topology = MapTopology(
          nodes: const [
            TopologyNode(
                id: 'P1', regionId: ow, type: TopologyNodeType.province),
          ],
          edges: const [],
        );

        final game = Game(
          id: 'g1',
          worldState: WorldState(
            turnState:
                const TurnState(phase: TurnPhase.orders, turnNumber: 0),
            oldWorld: RegionData(
              provinces: const [
                Province(id: provinceId, regionId: ow, ownerId: 'p1'),
              ],
              units: const [
                Unit(
                  id: 'builder1',
                  type: 'Builder',
                  ownerId: 'p1',
                  provinceId: provinceId,
                  tileKey: tileKey,
                ),
                Unit(
                  id: 'engineer1',
                  type: 'Engineer',
                  ownerId: 'p1',
                  provinceId: provinceId,
                  tileKey: tileKey,
                ),
              ],
            ),
            newWorld: const RegionData(),
            resourceByTileKey: const {tileKey: 'grain'},
            // Tile is fully visible so visibility is not the rejecting reason.
            playerVisibilityByTile: const {
              'p1': {tileKey: 'fullyVisible'},
            },
            tileKeysByRegionAndProvince: const {
              ow: {provinceId: [tileKey]}
            },
          ),
          players: [
            Player(
              id: 'p1',
              displayName: 'P1',
              isHuman: true,
              capitalProvinceId: provinceId,
              // Provide enough materials so material-cost validation passes and
              // the first work order can be accepted.
              stockpile: Stockpile()
                  .applyDelta(CommodityCatalog.lumber.id, 10)
                  .applyDelta(CommodityCatalog.castIron.id, 10),
            ),
          ],
        );

        final engine = OrderEngine();
        engine
          ..addWorkOrder(
            'p1',
            const WorkOrder(
              unitId: 'builder1',
              target: 'build_improvement',
              targetTileKey: tileKey,
            ),
          )
          ..addWorkOrder(
            'p1',
            const WorkOrder(
              unitId: 'engineer1',
              target: 'build_road',
              targetTileKey: tileKey,
            ),
          );

        final results =
            engine.validatePlayerOrdersWithContext(game, topology, 'p1');

        expect(results.length, 2);
        expect(results[0].status, OrderValidationStatus.accepted);
        expect(results[1].status, OrderValidationStatus.rejected);
        expect(results[1].reason,
            contains('Tile already has development or purchase work'));
      });

      test('accepts purchase_land for mineral when prospected', () {
        final game = _baseGame(
          treasury: 500,
          overtureStates: [
            const OvertureState(
                gpId: 'p1',
                targetId: 'minor1',
                stage: OvertureStage.embassy,
                sinceTurn: 0)
          ],
          resourceByTileKey: {tileKey: 'iron'},
          playerProspectedTiles: {
            'p1': {tileKey}
          },
        );
        final engine = OrderEngine();
        engine.addWorkOrder(
            'p1',
            const WorkOrder(
                unitId: 'merchant1',
                target: 'purchase_land',
                targetTileKey: tileKey));
        final results =
            engine.validatePlayerOrdersWithContext(game, topology, 'p1');
        expect(results.single.status, OrderValidationStatus.accepted);
      });
    });

    group('validateWork (build_improvement)', () {
      const ow = 'oldWorld';
      const provinceId = '$ow|P1';
      const tileKey = '$provinceId|0|0';

      final topology = MapTopology(
        nodes: const [
          TopologyNode(id: 'P1', regionId: ow, type: TopologyNodeType.province),
        ],
        edges: const [],
      );

      Game _baseGame({
        Map<String, String>? resourceByTileKey,
        TileMapState tileState = const TileMapState(),
        Map<String, bool>? techUnlocked,
        Stockpile? stockpile,
      }) {
        return Game(
          id: 'g1',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
            oldWorld: RegionData(
              provinces: [
                Province(id: provinceId, regionId: ow, ownerId: 'p1'),
              ],
              units: [
                Unit(
                    id: 'builder1',
                    type: 'Builder',
                    ownerId: 'p1',
                    provinceId: provinceId,
                    tileKey: tileKey),
              ],
            ),
            newWorld: const RegionData(),
            resourceByTileKey: resourceByTileKey ?? {tileKey: 'grain'},
            tileState: tileState,
            tileKeysByRegionAndProvince: {
              ow: {provinceId: [tileKey]},
            },
            playerVisibilityByTile: const {
              'p1': {tileKey: 'fullyVisible'},
            },
          ),
          players: [
            Player(
              id: 'p1',
              displayName: 'P1',
              isHuman: true,
              capitalProvinceId: provinceId,
              stockpile: stockpile ??
                  Stockpile().applyDelta(CommodityCatalog.lumber.id, 2).applyDelta(
                      CommodityCatalog.castIron.id, 2),
              techUnlocked: techUnlocked ?? const {'gathering_3': true},
            ),
          ],
        );
      }

      test('rejects build_improvement when tile has no resource', () {
        final game = _baseGame(resourceByTileKey: {});
        final engine = OrderEngine();
        engine.addWorkOrder(
            'p1',
            const WorkOrder(
                unitId: 'builder1',
                target: 'build_improvement',
                targetTileKey: tileKey));
        final results =
            engine.validatePlayerOrdersWithContext(game, topology, 'p1');
        expect(results.single.status, OrderValidationStatus.rejected);
        expect(results.single.reason, contains('no resource'));
      });

      test('rejects build_improvement when improvement level already 4', () {
        final game = _baseGame(
          tileState: const TileMapState(
              improvementByTile: {'oldWorld|P1|0|0': 4}),
          stockpile: Stockpile()
              .applyDelta(CommodityCatalog.lumber.id, 20)
              .applyDelta(CommodityCatalog.castIron.id, 20),
        );
        final engine = OrderEngine();
        engine.addWorkOrder(
            'p1',
            const WorkOrder(
                unitId: 'builder1',
                target: 'build_improvement',
                targetTileKey: tileKey));
        final results =
            engine.validatePlayerOrdersWithContext(game, topology, 'p1');
        expect(results.single.status, OrderValidationStatus.rejected);
        expect(results.single.reason, contains('maximum'));
      });

      test('rejects build_improvement when tech cap would be exceeded', () {
        // gathering_1 gives cap 2; tile at level 2 → next would be 3 > 2
        final game = _baseGame(
          techUnlocked: const {'gathering_1': true},
          tileState: const TileMapState(
              improvementByTile: {'oldWorld|P1|0|0': 2}),
          stockpile: Stockpile()
              .applyDelta(CommodityCatalog.lumber.id, 10)
              .applyDelta(CommodityCatalog.castIron.id, 10),
        );
        final engine = OrderEngine();
        engine.addWorkOrder(
            'p1',
            const WorkOrder(
                unitId: 'builder1',
                target: 'build_improvement',
                targetTileKey: tileKey));
        final results =
            engine.validatePlayerOrdersWithContext(game, topology, 'p1');
        expect(results.single.status, OrderValidationStatus.rejected);
        expect(results.single.reason, contains('Insufficient tech'));
        expect(results.single.reason, contains('cap 2'));
      });

      test('accepts build_improvement when tile has resource, level < 4, tech cap allows', () {
        final game = _baseGame(
          resourceByTileKey: {tileKey: 'grain'},
          tileState: const TileMapState(),
          techUnlocked: const {'gathering_3': true},
        );
        final engine = OrderEngine();
        engine.addWorkOrder(
            'p1',
            const WorkOrder(
                unitId: 'builder1',
                target: 'build_improvement',
                targetTileKey: tileKey));
        final results =
            engine.validatePlayerOrdersWithContext(game, topology, 'p1');
        expect(results.single.status, OrderValidationStatus.accepted);
      });
    });

    group('validateWork (build_fort tech)', () {
      const ow = 'oldWorld';
      const provinceId = '$ow|P1';
      const tileKey = '$provinceId|0|0';

      final topology = MapTopology(
        nodes: const [
          TopologyNode(id: 'P1', regionId: ow, type: TopologyNodeType.province),
        ],
        edges: const [],
      );

      test('rejects build_fort to level 2 without Mine Engineering', () {
        final game = Game(
          id: 'g1',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
            oldWorld: RegionData(
              provinces: [
                Province(
                    id: provinceId, regionId: ow, ownerId: 'p1', fortLevel: 1),
              ],
              units: [
                Unit(
                    id: 'eng1',
                    type: 'Engineer',
                    ownerId: 'p1',
                    provinceId: provinceId,
                    tileKey: tileKey),
              ],
            ),
            newWorld: const RegionData(),
            tileKeysByRegionAndProvince: {ow: {provinceId: [tileKey]}},
            playerVisibilityByTile: const {'p1': {tileKey: 'fullyVisible'}},
          ),
          players: [
            Player(
              id: 'p1',
              displayName: 'P1',
              isHuman: true,
              capitalProvinceId: provinceId,
              stockpile: Stockpile()
                  .applyDelta(CommodityCatalog.lumber.id, 4)
                  .applyDelta(CommodityCatalog.bronze.id, 4),
              techUnlocked: {},
            ),
          ],
        );
        final engine = OrderEngine();
        engine.addWorkOrder(
            'p1',
            const WorkOrder(
                unitId: 'eng1',
                target: 'build_fort',
                targetTileKey: tileKey));
        final results =
            engine.validatePlayerOrdersWithContext(game, topology, 'p1');
        expect(results.single.status, OrderValidationStatus.rejected);
        expect(results.single.reason, contains('Mine Engineering'));
      });

      test('rejects build_fort to level 3 without Modern Forts', () {
        final game = Game(
          id: 'g1',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
            oldWorld: RegionData(
              provinces: [
                Province(
                    id: provinceId, regionId: ow, ownerId: 'p1', fortLevel: 2),
              ],
              units: [
                Unit(
                    id: 'eng1',
                    type: 'Engineer',
                    ownerId: 'p1',
                    provinceId: provinceId,
                    tileKey: tileKey),
              ],
            ),
            newWorld: const RegionData(),
            tileKeysByRegionAndProvince: {ow: {provinceId: [tileKey]}},
            playerVisibilityByTile: const {'p1': {tileKey: 'fullyVisible'}},
          ),
          players: [
            Player(
              id: 'p1',
              displayName: 'P1',
              isHuman: true,
              capitalProvinceId: provinceId,
              stockpile: Stockpile()
                  .applyDelta(CommodityCatalog.steel.id, 5)
                  .applyDelta(CommodityCatalog.lumber.id, 5),
              techUnlocked: const {'mine_engineering': true},
            ),
          ],
        );
        final engine = OrderEngine();
        engine.addWorkOrder(
            'p1',
            const WorkOrder(
                unitId: 'eng1',
                target: 'build_fort',
                targetTileKey: tileKey));
        final results =
            engine.validatePlayerOrdersWithContext(game, topology, 'p1');
        expect(results.single.status, OrderValidationStatus.rejected);
        expect(results.single.reason, contains('Modern Forts'));
      });
    });

    group('validateDiplomatic', () {
      final emptyTopology = MapTopology(nodes: const [], edges: const []);

      Game _gpMinorBaseGame({
        RelationState relationState = RelationState.atPeace,
        int relationScore = 50,
        OvertureStage overtureStage = OvertureStage.none,
        int treasury = 5000,
      }) {
        return Game(
          id: 'g1',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
            oldWorld: const RegionData(),
            newWorld: const RegionData(),
          ),
          players: [
            Player(
              id: 'gp1',
              displayName: 'GP1',
              isHuman: true,
              treasury: treasury,
            ),
          ],
          minorNations: const [
            MinorNation(id: 'minor1', displayName: 'Minor 1'),
          ],
          diplomacyRelations: [
            DiplomacyRelation(
              factionId1: 'gp1',
              factionId2: 'minor1',
              state: relationState,
              score: relationScore,
            ),
          ],
          overtureStates: [
            OvertureState(
              gpId: 'gp1',
              targetId: 'minor1',
              stage: overtureStage,
              sinceTurn: 0,
            ),
          ],
        );
      }

      test('declareWar rejected when already at war', () {
        final game = _gpMinorBaseGame(relationState: RelationState.atWar);
        final engine = OrderEngine();
        final result = engine.addDiplomaticOrderWithContext(
          game,
          emptyTopology,
          'gp1',
          const DiplomaticOrder(
            type: DiplomaticOrderType.declareWar,
            targetFactionId: 'minor1',
          ),
        );
        expect(result.status, OrderValidationStatus.rejected);
        expect(result.reason, contains('Already at war'));
      });

      test('offerPeace rejected when not at war', () {
        final game = _gpMinorBaseGame(relationState: RelationState.atPeace);
        final engine = OrderEngine();
        final result = engine.addDiplomaticOrderWithContext(
          game,
          emptyTopology,
          'gp1',
          const DiplomaticOrder(
            type: DiplomaticOrderType.offerPeace,
            targetFactionId: 'minor1',
          ),
        );
        expect(result.status, OrderValidationStatus.rejected);
        expect(result.reason, contains('not at war'));
      });

      test('establishOverture rejected when target is at war with GP', () {
        final game = _gpMinorBaseGame(
          relationState: RelationState.atWar,
          overtureStage: OvertureStage.none,
          treasury: overtureConsulateCost + 100,
        );
        final engine = OrderEngine();
        final result = engine.addDiplomaticOrderWithContext(
          game,
          emptyTopology,
          'gp1',
          const DiplomaticOrder(
            type: DiplomaticOrderType.establishOverture,
            targetFactionId: 'minor1',
            overtureStage: OvertureStage.tradeConsulate,
          ),
        );
        expect(result.status, OrderValidationStatus.rejected);
        expect(result.reason, contains('at war'));
      });

      test('establishOverture consulate rejected when treasury too low', () {
        final game = _gpMinorBaseGame(
          relationState: RelationState.atPeace,
          overtureStage: OvertureStage.none,
          treasury: overtureConsulateCost - 1,
        );
        final engine = OrderEngine();
        final result = engine.addDiplomaticOrderWithContext(
          game,
          emptyTopology,
          'gp1',
          const DiplomaticOrder(
            type: DiplomaticOrderType.establishOverture,
            targetFactionId: 'minor1',
            overtureStage: OvertureStage.tradeConsulate,
          ),
        );
        expect(result.status, OrderValidationStatus.rejected);
        expect(result.reason, contains('Insufficient treasury'));
      });

      test('establishOverture embassy requires existing consulate', () {
        final game = _gpMinorBaseGame(
          relationState: RelationState.atPeace,
          overtureStage: OvertureStage.none,
          treasury: overtureEmbassyCost + 1000,
        );
        final engine = OrderEngine();
        final result = engine.addDiplomaticOrderWithContext(
          game,
          emptyTopology,
          'gp1',
          const DiplomaticOrder(
            type: DiplomaticOrderType.establishOverture,
            targetFactionId: 'minor1',
            overtureStage: OvertureStage.embassy,
          ),
        );
        expect(result.status, OrderValidationStatus.rejected);
        expect(result.reason, contains('requires existing Trade Consulate'));
      });

      test('grantAid requires embassy and sufficient treasury', () {
        final game = _gpMinorBaseGame(
          relationState: RelationState.atPeace,
          overtureStage: OvertureStage.tradeConsulate,
          treasury: 50,
        );
        // No embassy yet: should be rejected.
        final noEmbassy = OrderEngine().addDiplomaticOrderWithContext(
          game,
          emptyTopology,
          'gp1',
          const DiplomaticOrder(
            type: DiplomaticOrderType.grantAid,
            targetFactionId: 'minor1',
            amount: 10,
          ),
        );
        expect(noEmbassy.status, OrderValidationStatus.rejected);
        expect(noEmbassy.reason, contains('Embassy required'));

        // With embassy but insufficient treasury.
        final gameWithEmbassy = _gpMinorBaseGame(
          relationState: RelationState.atPeace,
          overtureStage: OvertureStage.embassy,
          treasury: 5,
        );
        final insufficient = OrderEngine().addDiplomaticOrderWithContext(
          gameWithEmbassy,
          emptyTopology,
          'gp1',
          const DiplomaticOrder(
            type: DiplomaticOrderType.grantAid,
            targetFactionId: 'minor1',
            amount: 10,
          ),
        );
        expect(insufficient.status, OrderValidationStatus.rejected);
        expect(insufficient.reason, contains('Insufficient treasury'));
      });

      test('setSubsidy requires consulate or embassy and sufficient treasury',
          () {
        final gameNoOverture = _gpMinorBaseGame(
          relationState: RelationState.atPeace,
          overtureStage: OvertureStage.none,
          treasury: 100,
        );
        final noConsulate = OrderEngine().addDiplomaticOrderWithContext(
          gameNoOverture,
          emptyTopology,
          'gp1',
          const DiplomaticOrder(
            type: DiplomaticOrderType.setSubsidy,
            targetFactionId: 'minor1',
            amount: 50,
          ),
        );
        expect(noConsulate.status, OrderValidationStatus.rejected);
        expect(noConsulate.reason, contains('Consulate or Embassy required'));

        final gameLowTreasury = _gpMinorBaseGame(
          relationState: RelationState.atPeace,
          overtureStage: OvertureStage.tradeConsulate,
          treasury: 10,
        );
        final insufficient = OrderEngine().addDiplomaticOrderWithContext(
          gameLowTreasury,
          emptyTopology,
          'gp1',
          const DiplomaticOrder(
            type: DiplomaticOrderType.setSubsidy,
            targetFactionId: 'minor1',
            amount: 50,
          ),
        );
        expect(insufficient.status, OrderValidationStatus.rejected);
        expect(insufficient.reason, contains('Insufficient treasury'));
      });
    });
  });
}
