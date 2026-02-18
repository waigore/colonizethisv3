import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:test/test.dart';

void main() {
  group('OrderEngine', () {
    test('add order and validate', () {
      final engine = OrderEngine();
      final result = engine.addMoveOrder('p1', const MoveOrder(unitId: 'u1', destinationProvinceId: 'P2'));
      expect(result.status, OrderValidationStatus.accepted);
      expect(engine.orders.moveOrdersByPlayerId['p1']?.length, 1);
    });

    test('first invalid order plus subsequent rejected', () {
      final topology = MapTopology(
        nodes: [
          const TopologyNode(id: 'P1', regionId: 'oldWorld', type: TopologyNodeType.province),
          const TopologyNode(id: 'P2', regionId: 'oldWorld', type: TopologyNodeType.province),
        ],
        edges: [const TopologyEdge(id1: 'P1', id2: 'P2')],
      );
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: RegionData(
            provinces: [
              Province(id: 'P1', regionId: 'oldWorld', ownerId: 'p1'),
              Province(id: 'P2', regionId: 'oldWorld', ownerId: 'p1'),
            ],
            units: [
              Unit(id: 'u1', type: 'musketeers', ownerId: 'p1', provinceId: 'P1'),
            ],
            ),
          newWorld: const RegionData(),
        ),
        players: [Player(id: 'p1', displayName: 'P1', isHuman: true)],
      );

      final engine = OrderEngine();
      engine.addMoveOrder('p1', const MoveOrder(unitId: 'u1', destinationProvinceId: 'P2'));
      engine.addMoveOrder('p1', const MoveOrder(unitId: 'u999', destinationProvinceId: 'P2'));
      engine.addMoveOrder('p1', const MoveOrder(unitId: 'u1', destinationProvinceId: 'P3'));

      final results = engine.validatePlayerOrdersWithContext(game, topology, 'p1');
      expect(results.length, 3);
      expect(results[0].status, OrderValidationStatus.accepted);
      expect(results[1].status, OrderValidationStatus.rejected);
      expect(results[2].status, OrderValidationStatus.rejected);
    });

    test('projected effects returns worker count', () {
      final topology = MapTopology(
        nodes: [
          const TopologyNode(id: 'P1', regionId: 'oldWorld', type: TopologyNodeType.province),
        ],
        edges: [],
      );
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: const RegionData(
            provinces: [Province(id: 'P1', regionId: 'oldWorld', ownerId: 'p1')],
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
      final topology = MapTopology(
        nodes: [
          const TopologyNode(id: 'P1', regionId: 'oldWorld', type: TopologyNodeType.province),
          const TopologyNode(id: 'P2', regionId: 'oldWorld', type: TopologyNodeType.province),
        ],
        edges: [const TopologyEdge(id1: 'P1', id2: 'P2')],
      );
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: RegionData(
            provinces: [
              Province(id: 'P1', regionId: 'oldWorld', ownerId: 'p1'),
              Province(id: 'P2', regionId: 'oldWorld', ownerId: 'p1'),
            ],
            units: [
              Unit(id: 'u1', type: 'musketeers', ownerId: 'p1', provinceId: 'P1'),
            ],
          ),
          newWorld: const RegionData(),
        ),
        players: [Player(id: 'p1', displayName: 'P1', isHuman: true)],
      );

      final engine = OrderEngine();
      final ok = engine.addMoveOrderWithContext(
        game,
        topology,
        'p1',
        const MoveOrder(unitId: 'u1', destinationProvinceId: 'P2'),
      );
      final bad = engine.addMoveOrderWithContext(
        game,
        topology,
        'p1',
        const MoveOrder(unitId: 'u999', destinationProvinceId: 'P2'),
      );

      expect(ok.status, OrderValidationStatus.accepted);
      expect(bad.status, OrderValidationStatus.rejected);
    });

    test('civilian cannot move into other GP territory', () {
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
            provinces: const [
              Province(id: 'P1', regionId: 'oldWorld', ownerId: 'p1'),
              Province(id: 'P2', regionId: 'oldWorld', ownerId: 'p2'),
            ],
            units: const [
              Unit(id: 'u1', type: 'Builder', ownerId: 'p1', provinceId: 'P1'),
            ],
          ),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(id: 'p1', displayName: 'P1', isHuman: true),
          Player(id: 'p2', displayName: 'P2', isHuman: true),
        ],
      );

      final engine = OrderEngine();
      engine.addMoveOrder('p1', const MoveOrder(unitId: 'u1', destinationProvinceId: 'P2'));

      final results = engine.validatePlayerOrdersWithContext(game, topology, 'p1');
      expect(results.single.status, OrderValidationStatus.rejected);
    });

    test('explorer may move into tribal province', () {
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
            provinces: const [
              Province(id: 'P1', regionId: 'oldWorld', ownerId: 'p1'),
              Province(id: 'P2', regionId: 'oldWorld', ownerId: 'tribe1'),
            ],
            units: const [
              Unit(id: 'u1', type: 'Explorer', ownerId: 'p1', provinceId: 'P1'),
            ],
          ),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(id: 'p1', displayName: 'P1', isHuman: true),
        ],
        tribes: const [
          Tribe(id: 'tribe1', displayName: 'Tribe 1'),
        ],
      );

      final engine = OrderEngine();
      engine.addMoveOrder('p1', const MoveOrder(unitId: 'u1', destinationProvinceId: 'P2'));

      final results = engine.validatePlayerOrdersWithContext(game, topology, 'p1');
      expect(results.single.status, OrderValidationStatus.accepted);
    });
  });
}
