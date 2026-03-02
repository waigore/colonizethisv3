import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  group('neighborProvinceIdsInRegion and isValidLandMoveInRegion', () {
    test('duplicate local ids across regions: neighbors are region-scoped', () {
      final topology = MapTopology(
        nodes: const [
          TopologyNode(id: 'p1', regionId: 'oldWorld', type: TopologyNodeType.province),
          TopologyNode(id: 'p2', regionId: 'oldWorld', type: TopologyNodeType.province),
          TopologyNode(id: 'p1', regionId: 'newWorld', type: TopologyNodeType.province),
          TopologyNode(id: 'p2', regionId: 'newWorld', type: TopologyNodeType.province),
        ],
        edges: const [
          TopologyEdge(id1: 'p1', id2: 'p2'), // same local ids in both regions
        ],
      );
      expect(
        neighborProvinceIdsInRegion(topology, 'oldWorld', 'p1').toList(),
        ['p2'],
      );
      expect(
        neighborProvinceIdsInRegion(topology, 'newWorld', 'p1').toList(),
        ['p2'],
      );
      expect(isValidLandMoveInRegion(topology, 'oldWorld', 'p1', 'p2'), isTrue);
      expect(isValidLandMoveInRegion(topology, 'newWorld', 'p1', 'p2'), isTrue);
      expect(isValidLandMove(topology, 'p1', 'p2'), isFalse); // ambiguous: two nodes p1
    });
  });

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

    test('civilian unit move sets tileKey when tileKeysByRegionAndProvince provided', () {
      const regionId = 'oldWorld';
      final topology = MapTopology(
        nodes: const [
          TopologyNode(id: 'P1', regionId: regionId, type: TopologyNodeType.province),
          TopologyNode(id: 'P2', regionId: regionId, type: TopologyNodeType.province),
        ],
        edges: const [
          TopologyEdge(id1: 'P1', id2: 'P2'),
        ],
      );
      const destTileKey = 'oldWorld|P2|0|0';
      final destFullId = ProvinceId.full(regionId, 'P2');
      final region = RegionData(
        provinces: const [
          Province(id: 'P1', regionId: regionId, ownerId: 'p1'),
          Province(id: 'P2', regionId: regionId, ownerId: 'p1'),
        ],
        units: const [
          Unit(
            id: 'u1',
            type: 'Merchant',
            ownerId: 'p1',
            provinceId: 'oldWorld|P1',
            tileKey: 'oldWorld|P1|0|0',
          ),
        ],
      );
      final orders = {
        'p1': [
          const MoveOrder(unitId: 'u1', destinationProvinceId: 'P2'),
        ],
      };
      final updated = applyMoveOrdersToRegion(
        region,
        topology,
        orders,
        regionId: regionId,
        tileKeysByRegionAndProvince: {
          regionId: {destFullId: [destTileKey]},
        },
      );
      expect(updated.units.single.provinceId, destFullId);
      expect(updated.units.single.tileKey, destTileKey);
    });

    test('ignores move when destination prefixed id is in a different region', () {
      const regionId = 'oldWorld';
      final topology = MapTopology(
        nodes: const [
          TopologyNode(id: 'P1', regionId: regionId, type: TopologyNodeType.province),
          TopologyNode(id: 'P2', regionId: regionId, type: TopologyNodeType.province),
        ],
        edges: const [
          TopologyEdge(id1: 'P1', id2: 'P2'),
        ],
      );
      final region = RegionData(
        provinces: const [
          Province(id: 'P1', regionId: regionId, ownerId: 'p1'),
          Province(id: 'P2', regionId: regionId, ownerId: 'p1'),
        ],
        units: const [
          Unit(
            id: 'u1',
            type: 'Regiment',
            ownerId: 'p1',
            provinceId: 'oldWorld|P1',
          ),
        ],
      );
      final orders = {
        'p1': [
          const MoveOrder(unitId: 'u1', destinationProvinceId: 'newWorld|P2'),
        ],
      };
      final updated = applyMoveOrdersToRegion(
        region,
        topology,
        orders,
        regionId: regionId,
      );
      expect(updated.units.single.provinceId, 'oldWorld|P1');
    });

    test('uses prefixed province id and region-scoped tiles for multi-region civilian move', () {
      const ow = 'oldWorld';
      const nw = 'newWorld';
      final topology = MapTopology(
        nodes: const [
          TopologyNode(id: 'p1', regionId: ow, type: TopologyNodeType.province),
          TopologyNode(id: 'p2', regionId: ow, type: TopologyNodeType.province),
          TopologyNode(id: 'p1', regionId: nw, type: TopologyNodeType.province),
          TopologyNode(id: 'p2', regionId: nw, type: TopologyNodeType.province),
        ],
        edges: const [
          TopologyEdge(id1: 'p1', id2: 'p2'),
        ],
      );
      final owDestFullId = ProvinceId.full(ow, 'p2');
      final nwDestFullId = ProvinceId.full(nw, 'p2');
      const owDestTile = 'oldWorld|p2|0|0';
      const nwDestTile = 'newWorld|p2|0|0';
      final region = RegionData(
        provinces: const [
          Province(id: 'p1', regionId: ow, ownerId: 'p1'),
          Province(id: 'p2', regionId: ow, ownerId: 'p1'),
        ],
        units: const [
          Unit(
            id: 'u1',
            type: 'Merchant',
            ownerId: 'p1',
            provinceId: 'oldWorld|p1',
            tileKey: 'oldWorld|p1|0|0',
          ),
        ],
      );
      final orders = {
        'p1': [
          const MoveOrder(unitId: 'u1', destinationProvinceId: 'p2'),
        ],
      };
      final updated = applyMoveOrdersToRegion(
        region,
        topology,
        orders,
        regionId: ow,
        tileKeysByRegionAndProvince: {
          ow: {owDestFullId: [owDestTile]},
          nw: {nwDestFullId: [nwDestTile]},
        },
      );
      expect(updated.units.single.provinceId, owDestFullId);
      expect(updated.units.single.tileKey, owDestTile);
    });

    test('allows move to non-adjacent province when destination is own (isDestinationOwnedByPlayer)', () {
      const regionId = 'oldWorld';
      final topology = MapTopology(
        nodes: const [
          TopologyNode(id: 'P1', regionId: regionId, type: TopologyNodeType.province),
          TopologyNode(id: 'P2', regionId: regionId, type: TopologyNodeType.province),
          TopologyNode(id: 'P3', regionId: regionId, type: TopologyNodeType.province),
        ],
        edges: [
          const TopologyEdge(id1: 'P1', id2: 'P2'),
          const TopologyEdge(id1: 'P2', id2: 'P3'),
        ],
      );
      final destFullId = ProvinceId.full(regionId, 'P3');
      final region = RegionData(
        provinces: const [
          Province(id: 'P1', regionId: regionId, ownerId: 'p1'),
          Province(id: 'P2', regionId: regionId, ownerId: 'p1'),
          Province(id: 'P3', regionId: regionId, ownerId: 'p1'),
        ],
        units: const [
          Unit(
            id: 'u1',
            type: 'Regiment',
            ownerId: 'p1',
            provinceId: 'oldWorld|P1',
          ),
        ],
      );
      final orders = {
        'p1': [
          MoveOrder(unitId: 'u1', destinationProvinceId: destFullId),
        ],
      };
      bool isDestinationOwnedByPlayer(String playerId, String destFullProvinceId) =>
          playerId == 'p1' && destFullProvinceId == destFullId;
      final updated = applyMoveOrdersToRegion(
        region,
        topology,
        orders,
        regionId: regionId,
        isDestinationOwnedByPlayer: isDestinationOwnedByPlayer,
      );
      expect(updated.units.single.provinceId, destFullId);
    });
  });
}

