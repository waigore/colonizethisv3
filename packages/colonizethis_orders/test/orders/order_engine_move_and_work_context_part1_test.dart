import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  group('OrderEngine', () {
    test('move order rejected when destination province unknown', () {
      const ow = 'oldWorld';
      final topology = MapTopology(
        nodes: const [
          TopologyNode(
            id: 'P1',
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
          TopologyNode(
            id: 'P2',
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
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
                type: kUnitTypeExplorer,
                ownerId: 'p1',
                locationProvinceId: '$ow|P1',
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
      engine.addMoveOrder(
        'p1',
        const MoveOrder(unitId: 'u1', destinationTileKey: 'oldWorld|P2|0|0'),
      );
      final results = engine.validatePlayerOrdersWithContext(
        game,
        topology,
        'p1',
      );
      expect(results.length, 1);
      expect(results[0].status, OrderValidationStatus.rejected);
      expect(results[0].reason, contains('visible'));
    });

    test('work order explore rejected when province unknown', () {
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
                type: kUnitTypeExplorer,
                ownerId: 'p1',
                locationProvinceId: '$ow|P1',
                tileKey: 'oldWorld|P1|0|0',
              ),
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
          target: kWorkTargetExplore,
          targetTileKey: 'oldWorld|P1|0|0',
        ),
      );
      final results = engine.validatePlayerOrdersWithContext(
        game,
        topology,
        'p1',
      );
      expect(results.length, 1);
      expect(results[0].status, OrderValidationStatus.rejected);
      expect(results[0].reason, contains('visible'));
    });

    test('work order explore rejected on foreign GP tile for explorer', () {
      const ow = 'oldWorld';
      const targetTileKey = 'oldWorld|P2|0|0';
      const p2OtherLand = 'oldWorld|P2|1|0';
      final topology = MapTopology(
        nodes: const [
          TopologyNode(
            id: 'P1',
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
          TopologyNode(
            id: 'P2',
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
            provinces: [
              Province(id: '$ow|P1', regionId: ow, ownerId: 'p1'),
              Province(id: '$ow|P2', regionId: ow, ownerId: 'p2'),
            ],
            units: [
              Unit(
                id: 'u1',
                type: kUnitTypeExplorer,
                ownerId: 'p1',
                locationProvinceId: '$ow|P1',
                tileKey: 'oldWorld|P1|0|0',
              ),
            ],
          ),
          newWorld: const RegionData(),
          playerVisibilityByTile: const {
            'p1': {
              'oldWorld|P1|0|0': 'fullyVisible',
              targetTileKey: 'fullyVisible',
              p2OtherLand: 'unknown',
            },
          },
          tileKeysByRegionAndProvince: const {
            ow: {
              '$ow|P1': ['oldWorld|P1|0|0'],
              '$ow|P2': [targetTileKey, p2OtherLand],
            },
          },
        ),
        players: const [
          Player(id: 'p1', displayName: 'P1', isHuman: true),
          Player(id: 'p2', displayName: 'P2', isHuman: true),
        ],
      );

      final engine = OrderEngine();
      engine.addWorkOrder(
        'p1',
        const WorkOrder(
          unitId: 'u1',
          target: kWorkTargetExplore,
          targetTileKey: targetTileKey,
        ),
      );
      final results = engine.validatePlayerOrdersWithContext(
        game,
        topology,
        'p1',
      );
      expect(results.length, 1);
      expect(results[0].status, OrderValidationStatus.rejected);
      expect(results[0].reason, contains('cannot occupy'));
    });

    test('work order prospect rejected when province not fogged or better', () {
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
      // P1 tiles unknown — prospect requires fogged or fullyVisible.
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
                type: kUnitTypeExplorer,
                ownerId: 'p1',
                locationProvinceId: '$ow|P1',
                tileKey: 'oldWorld|P1|0|0',
              ),
            ],
          ),
          newWorld: const RegionData(),
          playerVisibilityByTile: const {
            'p1': {'oldWorld|P1|0|0': 'unknown'},
          },
        ),
        players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
        tribes: const [Tribe(id: 'tribe1', displayName: 'Tribe 1')],
        // Refs #3753 R4: hold a Consulate so this test exercises the
        // visibility gate rather than the new consulate gate.
        overtureStates: const [
          OvertureState(
            gpId: 'p1',
            targetId: 'tribe1',
            stage: OvertureStage.tradeConsulate,
          ),
        ],
      );

      final engine = OrderEngine();
      engine.addWorkOrder(
        'p1',
        const WorkOrder(
          unitId: 'u1',
          target: kWorkTargetProspect,
          targetTileKey: 'oldWorld|P1|0|0',
        ),
      );
      final results = engine.validatePlayerOrdersWithContext(
        game,
        topology,
        'p1',
      );
      expect(results.length, 1);
      expect(results[0].status, OrderValidationStatus.rejected);
      expect(results[0].reason, contains('visible'));
    });

    test('work order prospect rejected when tile is not mineral-eligible', () {
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
      const tileKey = 'oldWorld|P1|0|0';
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
                type: kUnitTypeExplorer,
                ownerId: 'p1',
                locationProvinceId: '$ow|P1',
                tileKey: tileKey,
              ),
            ],
          ),
          newWorld: const RegionData(),
          resourceByTileKey: const {tileKey: 'grain'},
          playerVisibilityByTile: const {
            'p1': {tileKey: 'fogged'},
          },
        ),
        players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
        tribes: const [Tribe(id: 'tribe1', displayName: 'Tribe 1')],
        // Refs #3753 R4: hold a Consulate so this test exercises the
        // mineral-eligibility gate rather than the new consulate gate.
        overtureStates: const [
          OvertureState(
            gpId: 'p1',
            targetId: 'tribe1',
            stage: OvertureStage.tradeConsulate,
          ),
        ],
      );

      final engine = OrderEngine();
      engine.addWorkOrder(
        'p1',
        const WorkOrder(
          unitId: 'u1',
          target: kWorkTargetProspect,
          targetTileKey: tileKey,
        ),
      );
      final results = engine.validatePlayerOrdersWithContext(
        game,
        topology,
        'p1',
      );
      expect(results.length, 1);
      expect(results[0].status, OrderValidationStatus.rejected);
      expect(results[0].reason, contains('mineral-eligible'));
    });

    test('work order prospect rejected when tile already prospected', () {
      const ow = 'oldWorld';
      const tileKey = 'oldWorld|P1|0|0';
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
            provinces: [
              Province(id: '$ow|P1', regionId: ow, ownerId: 'tribe1'),
            ],
            units: [
              Unit(
                id: 'u1',
                type: kUnitTypeExplorer,
                ownerId: 'p1',
                locationProvinceId: '$ow|P1',
                tileKey: tileKey,
              ),
            ],
          ),
          newWorld: const RegionData(),
          resourceByTileKey: const {tileKey: 'iron'},
          playerProspectedTiles: const {
            'p1': {tileKey},
          },
          playerVisibilityByTile: const {
            'p1': {tileKey: 'fogged'},
          },
        ),
        players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
        tribes: const [Tribe(id: 'tribe1', displayName: 'Tribe 1')],
        // Refs #3753 R4: hold a Consulate so this test exercises the
        // already-prospected gate rather than the new consulate gate.
        overtureStates: const [
          OvertureState(
            gpId: 'p1',
            targetId: 'tribe1',
            stage: OvertureStage.tradeConsulate,
          ),
        ],
      );

      final engine = OrderEngine();
      engine.addWorkOrder(
        'p1',
        const WorkOrder(
          unitId: 'u1',
          target: kWorkTargetProspect,
          targetTileKey: tileKey,
        ),
      );
      final results = engine.validatePlayerOrdersWithContext(
        game,
        topology,
        'p1',
      );
      expect(results.length, 1);
      expect(results[0].status, OrderValidationStatus.rejected);
      expect(results[0].reason, contains('already prospected'));
    });
  });
}
