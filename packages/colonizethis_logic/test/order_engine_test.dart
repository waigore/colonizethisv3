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
  });
}
