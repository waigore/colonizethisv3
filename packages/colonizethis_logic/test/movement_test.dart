import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:test/test.dart';

void main() {
  group('isValidLandMove', () {
    test('allows move to adjacent land province', () {
      final topology = MapTopology(
        nodes: const [
          TopologyNode(id: 'A', regionId: 'oldWorld', type: TopologyNodeType.province),
          TopologyNode(id: 'B', regionId: 'oldWorld', type: TopologyNodeType.province),
        ],
        edges: const [
          TopologyEdge(id1: 'A', id2: 'B'),
        ],
      );
      expect(isValidLandMove(topology, 'A', 'B'), isTrue);
    });

    test('rejects move to non-adjacent or sea', () {
      final topology = MapTopology(
        nodes: const [
          TopologyNode(id: 'A', regionId: 'oldWorld', type: TopologyNodeType.province),
          TopologyNode(id: 'Sea1', regionId: 'oldWorld', type: TopologyNodeType.seaZone),
        ],
        edges: const [
          TopologyEdge(id1: 'A', id2: 'Sea1'),
        ],
      );
      expect(isValidLandMove(topology, 'A', 'B'), isFalse);
      expect(isValidLandMove(topology, 'A', 'Sea1'), isFalse);
    });
  });

  group('applyMoveOrdersToRegion', () {
    test('applies valid move orders and ignores invalid ones', () {
      final topology = MapTopology(
        nodes: const [
          TopologyNode(id: 'P1', regionId: 'oldWorld', type: TopologyNodeType.province),
          TopologyNode(id: 'P2', regionId: 'oldWorld', type: TopologyNodeType.province),
        ],
        edges: const [
          TopologyEdge(id1: 'P1', id2: 'P2'),
        ],
      );

      final region = RegionData(
        provinces: const [
          Province(id: 'P1', regionId: 'oldWorld', ownerId: 'player1'),
          Province(id: 'P2', regionId: 'oldWorld', ownerId: 'player2'),
        ],
        units: const [
          Unit(
            id: 'u1',
            type: 'Regiment',
            ownerId: 'player1',
            provinceId: 'P1',
          ),
        ],
      );

      final orders = {
        'player1': [
          const MoveOrder(unitId: 'u1', destinationProvinceId: 'P2'),
        ],
      };

      final updated = applyMoveOrdersToRegion(region, topology, orders);
      expect(updated.units.single.provinceId, 'P2');
    });
  });
}

