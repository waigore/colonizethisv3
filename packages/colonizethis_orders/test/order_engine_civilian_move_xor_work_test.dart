import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_orders/src/orders/bundled_civilian_work_order.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('civilian MoveOrder xor WorkOrder', () {
    test('rejects work when same civilian already has a move order', () {
      const regionId = 'oldWorld';
      const p1 = '$regionId|P1';
      const p2 = '$regionId|P2';
      const tileA = '$p1|0|0';
      const tileB = '$p2|0|0';
      const tileB2 = '$p2|1|0';

      final game = Game(
        id: 'g',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: [
              Province(id: p1, regionId: regionId, ownerId: 'p1'),
              Province(id: p2, regionId: regionId, ownerId: 'p1'),
            ],
            units: [
              Unit(
                id: 'u1',
                type: kUnitTypeExplorer,
                ownerId: 'p1',
                locationProvinceId: p1,
                tileKey: tileA,
              ),
            ],
          ),
          newWorld: const RegionData(),
          tileKeysByRegionAndProvince: {
            regionId: {
              p1: [tileA],
              p2: [tileB, tileB2],
            },
          },
          playerVisibilityByTile: const {
            'p1': {
              tileA: 'fullyVisible',
              tileB: 'fullyVisible',
            },
          },
        ),
        players: [
          const Player(id: 'p1', displayName: 'P1', isHuman: true),
        ],
      );

      final topology = MapTopology(
        nodes: const [
          TopologyNode(
            id: 'P1',
            regionId: regionId,
            type: TopologyNodeType.province,
          ),
          TopologyNode(
            id: 'P2',
            regionId: regionId,
            type: TopologyNodeType.province,
          ),
        ],
        edges: const [
          TopologyEdge(id1: 'P1', id2: 'P2'),
        ],
      );

      final engine = OrderEngine();
      final moveRes = engine.addMoveOrderWithContext(
        game,
        topology,
        'p1',
        const MoveOrder(unitId: 'u1', destinationTileKey: tileB),
      );
      expect(moveRes.isAccepted, isTrue, reason: moveRes.reason);
      final workResult = engine.addWorkOrderWithContext(
        game,
        topology,
        'p1',
        WorkOrder(
          unitId: 'u1',
          target: kWorkTargetExplore,
          targetTileKey: '$regionId|P2|0|0',
        ),
      );
      expect(workResult.isAccepted, isFalse);
      expect(workResult.reason, kReasonCivilianMoveXorWorkOrder);
    });

    test('merged draft with move then work rejects work (move remains valid)', () {
      const regionId = 'oldWorld';
      const p1 = '$regionId|P1';
      const p2 = '$regionId|P2';
      const tileA = '$p1|0|0';
      const tileB = '$p2|0|0';
      const tileB2 = '$p2|1|0';

      final game = Game(
        id: 'g',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: [
              Province(id: p1, regionId: regionId, ownerId: 'p1'),
              Province(id: p2, regionId: regionId, ownerId: 'p1'),
            ],
            units: [
              Unit(
                id: 'u1',
                type: kUnitTypeExplorer,
                ownerId: 'p1',
                locationProvinceId: p1,
                tileKey: tileA,
              ),
            ],
          ),
          newWorld: const RegionData(),
          tileKeysByRegionAndProvince: {
            regionId: {
              p1: [tileA],
              p2: [tileB, tileB2],
            },
          },
          playerVisibilityByTile: const {
            'p1': {
              tileA: 'fullyVisible',
              tileB: 'fullyVisible',
            },
          },
        ),
        players: [
          const Player(id: 'p1', displayName: 'P1', isHuman: true),
        ],
      );

      final topology = MapTopology(
        nodes: const [
          TopologyNode(
            id: 'P1',
            regionId: regionId,
            type: TopologyNodeType.province,
          ),
          TopologyNode(
            id: 'P2',
            regionId: regionId,
            type: TopologyNodeType.province,
          ),
        ],
        edges: const [
          TopologyEdge(id1: 'P1', id2: 'P2'),
        ],
      );

      final engine = OrderEngine(
        initialOrders: Orders(
          moveOrdersByPlayerId: {
            'p1': [const MoveOrder(unitId: 'u1', destinationTileKey: tileB)],
          },
          workOrdersByPlayerId: {
            'p1': [
              WorkOrder(
                unitId: 'u1',
                target: kWorkTargetExplore,
                targetTileKey: '$regionId|P2|0|0',
              ),
            ],
          },
        ),
      );
      final results = engine.validatePlayerOrdersWithContext(
        game,
        topology,
        'p1',
      );
      expect(results.first.isAccepted, isTrue);
      expect(results.last.isAccepted, isFalse);
      expect(results.last.reason, kReasonCivilianMoveXorWorkOrder);
    });
  });
}
