import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  group('OrderEngine', () {
    test('add order and validate', () {
      final engine = OrderEngine();
      final result = engine.addMoveOrder(
        'p1',
        const MoveOrder(unitId: 'u1', destinationTileKey: 'oldWorld|P2|0|0'),
      );
      expect(result.status, OrderValidationStatus.accepted);
      expect(engine.orders.moveOrdersByPlayerId['p1']?.length, 1);
    });

    test('removeMoveOrder removes order at index', () {
      final engine = OrderEngine();
      engine.addMoveOrder(
        'p1',
        const MoveOrder(unitId: 'u1', destinationTileKey: 'oldWorld|P2|0|0'),
      );
      engine.addMoveOrder(
        'p1',
        const MoveOrder(unitId: 'u2', destinationTileKey: 'oldWorld|P3|0|0'),
      );
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
        ),
      );
      expect(engine.orders.buildUnitOrdersByPlayerId['p1']!.length, 1);
      engine.removeBuildOrder('p1', 0);
      expect(engine.orders.buildUnitOrdersByPlayerId['p1'], isEmpty);
    });

    test('addWorkOrderWithContext returns rejected when order invalid', () {
      const ow = 'oldWorld';
      final topology = MapTopology(
        nodes: const [
          TopologyNode(id: 'P1', regionId: ow, type: TopologyNodeType.province),
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
                type: kUnitTypeBuilder,
                ownerId: 'p1',
                locationProvinceId: '$ow|P1',
                tileKey: 'oldWorld|P1|0|0',
              ),
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
          targetTileKey: 'oldWorld|P1|0|0',
        ),
      );
      expect(result.status, OrderValidationStatus.rejected);
    });

    test('first invalid order plus subsequent rejected', () {
      const ow = 'oldWorld';
      final topology = MapTopology(
        nodes: [
          const TopologyNode(
            id: 'P1',
            regionId: ow,
            type: TopologyNodeType.province,
          ),
          const TopologyNode(
            id: 'P2',
            regionId: ow,
            type: TopologyNodeType.province,
          ),
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
                type: kUnitTypeBuilder,
                ownerId: 'p1',
                locationProvinceId: '$ow|P1',
              ),
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
      engine.addMoveOrder(
        'p1',
        const MoveOrder(unitId: 'u1', destinationTileKey: 'oldWorld|P2|0|0'),
      );
      engine.addMoveOrder(
        'p1',
        const MoveOrder(unitId: 'u999', destinationTileKey: 'oldWorld|P2|0|0'),
      );
      engine.addMoveOrder(
        'p1',
        const MoveOrder(unitId: 'u1', destinationTileKey: 'oldWorld|P3|0|0'),
      );

      final results = engine.validatePlayerOrdersWithContext(
        game,
        topology,
        'p1',
      );
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
            id: 'P1',
            regionId: ow,
            type: TopologyNodeType.province,
          ),
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

    test(
      'projectedEffects returns unitLocations when engine has move order',
      () {
        const ow = 'oldWorld';
        final topology = MapTopology(
          nodes: [
            const TopologyNode(
              id: 'P1',
              regionId: ow,
              type: TopologyNodeType.province,
            ),
            const TopologyNode(
              id: 'P2',
              regionId: ow,
              type: TopologyNodeType.province,
            ),
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
                  type: kUnitTypeMerchant,
                  ownerId: 'p1',
                  locationProvinceId: '$ow|P1',
                  tileKey: '$ow|P1|0|0',
                ),
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
        engine.addMoveOrder(
          'p1',
          const MoveOrder(unitId: 'u1', destinationTileKey: '$ow|P2|0|0'),
        );
        final effects = engine.projectedEffects(game, topology, 'p1');
        expect(effects.unitLocations, isNotNull);
        expect(effects.unitLocations!['u1'], '$ow|P2');
      },
    );

    test('projectedEffects does not mutate passed-in game', () {
      const ow = 'oldWorld';
      final topology = MapTopology(
        nodes: [
          const TopologyNode(
            id: 'P1',
            regionId: ow,
            type: TopologyNodeType.province,
          ),
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
            id: 'P1',
            regionId: ow,
            type: TopologyNodeType.province,
          ),
          const TopologyNode(
            id: 'P2',
            regionId: ow,
            type: TopologyNodeType.province,
          ),
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
                type: kUnitTypeBuilder,
                ownerId: 'p1',
                locationProvinceId: '$ow|P1',
              ),
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
        const MoveOrder(unitId: 'u1', destinationTileKey: 'oldWorld|P2|0|0'),
      );
      final bad = engine.addMoveOrderWithContext(
        game,
        topology,
        'p1',
        const MoveOrder(unitId: 'u999', destinationTileKey: 'oldWorld|P2|0|0'),
      );

      expect(ok.status, OrderValidationStatus.accepted);
      expect(bad.status, OrderValidationStatus.rejected);
    });
  });
}
