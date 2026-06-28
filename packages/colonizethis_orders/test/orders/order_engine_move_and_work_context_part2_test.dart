import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  group('OrderEngine', () {
    test(
      'work order prospect accepted when mineral-eligible and visibility ok',
      () {
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
            playerVisibilityByTile: const {
              'p1': {tileKey: 'fogged'},
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
        expect(results[0].status, OrderValidationStatus.accepted);
      },
    );

    test('work order prospect rejected on foreign GP tile for explorer', () {
      const ow = 'oldWorld';
      const targetTileKey = 'oldWorld|P2|0|0';
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
          resourceByTileKey: const {targetTileKey: 'iron'},
          playerVisibilityByTile: const {
            'p1': {'oldWorld|P1|0|0': 'fullyVisible', targetTileKey: 'fogged'},
          },
          tileKeysByRegionAndProvince: const {
            ow: {
              '$ow|P1': ['oldWorld|P1|0|0'],
              '$ow|P2': [targetTileKey],
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
          target: kWorkTargetProspect,
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

    test(
      'move order rejected when destination not adjacent and not own province',
      () {
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
            TopologyNode(
              id: 'P3',
              regionId: 'oldWorld',
              type: TopologyNodeType.province,
            ),
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
                  locationProvinceId: '$ow|P1',
                ),
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
          'p1',
          MoveOrder(unitId: 'u1', destinationTileKey: '$ow|P3|0|0'),
        );
        final results = engine.validatePlayerOrdersWithContext(
          game,
          topology,
          'p1',
        );
        expect(results.single.status, OrderValidationStatus.rejected);
      },
    );

    test(
      'civilian move order accepted when destination not adjacent but own province',
      () {
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
            TopologyNode(
              id: 'P3',
              regionId: 'oldWorld',
              type: TopologyNodeType.province,
            ),
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
                'oldWorld|P3|0|0': 'fullyVisible',
              },
            },
          ),
          players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
        );
        final engine = OrderEngine();
        engine.addMoveOrder(
          'p1',
          MoveOrder(unitId: 'u1', destinationTileKey: '$ow|P3|0|0'),
        );
        final results = engine.validatePlayerOrdersWithContext(
          game,
          topology,
          'p1',
        );
        expect(results.single.status, OrderValidationStatus.accepted);
      },
    );
  });
}
