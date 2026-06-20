import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('Naval', () {
    late MapTopology topology;

    setUp(() {
      topology = MapTopology(
        nodes: const [
          TopologyNode(
            id: 'p1',
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
          TopologyNode(
            id: 'p2',
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
          TopologyNode(
            id: 'sea1',
            regionId: 'oldWorld',
            type: TopologyNodeType.seaZone,
          ),
          TopologyNode(
            id: 'sea2',
            regionId: 'oldWorld',
            type: TopologyNodeType.seaZone,
          ),
        ],
        edges: const [
          TopologyEdge(id1: 'p1', id2: 'sea1'),
          TopologyEdge(id1: 'p2', id2: 'sea1'),
          TopologyEdge(id1: 'sea1', id2: 'sea2'),
        ],
      );
    });

    group('isWarpZoneSeaZone', () {
      test('returns true when sea zone has cross-region S-S edge', () {
        const ow = 'oldWorld';
        const nw = 'newWorld';
        final combined = MapTopology(
          nodes: const [
            TopologyNode(
              id: '$ow|sea_a',
              regionId: ow,
              type: TopologyNodeType.seaZone,
            ),
            TopologyNode(
              id: '$ow|sea_b',
              regionId: ow,
              type: TopologyNodeType.seaZone,
            ),
            TopologyNode(
              id: '$nw|sea_c',
              regionId: nw,
              type: TopologyNodeType.seaZone,
            ),
          ],
          edges: const [
            TopologyEdge(id1: '$ow|sea_a', id2: '$ow|sea_b'),
            TopologyEdge(id1: '$ow|sea_b', id2: '$nw|sea_c'),
          ],
        );

        expect(isWarpZoneSeaZone(combined, '$ow|sea_b'), isTrue);
        expect(isWarpZoneSeaZone(combined, '$nw|sea_c'), isTrue);
      });

      test('returns false for same-region edges only', () {
        expect(isWarpZoneSeaZone(topology, 'sea1'), isFalse);
        expect(isWarpZoneSeaZone(topology, 'sea2'), isFalse);
      });
    });

    group('provinceIdsAdjacentToSeaZone region-scoped', () {
      test('when regionId passed, returns only provinces in that region', () {
        final multiRegion = MapTopology(
          nodes: const [
            TopologyNode(
              id: 'p1',
              regionId: 'oldWorld',
              type: TopologyNodeType.province,
            ),
            TopologyNode(
              id: 'sea1',
              regionId: 'oldWorld',
              type: TopologyNodeType.seaZone,
            ),
            TopologyNode(
              id: 'p1',
              regionId: 'newWorld',
              type: TopologyNodeType.province,
            ),
            TopologyNode(
              id: 'sea1',
              regionId: 'newWorld',
              type: TopologyNodeType.seaZone,
            ),
          ],
          edges: const [TopologyEdge(id1: 'p1', id2: 'sea1')],
        );
        expect(
          provinceIdsAdjacentToSeaZone(
            multiRegion,
            'sea1',
            regionId: 'oldWorld',
          ),
          equals({'p1'}),
        );
        expect(
          provinceIdsAdjacentToSeaZone(
            multiRegion,
            'sea1',
            regionId: 'newWorld',
          ),
          equals({'p1'}),
        );
        expect(
          provinceIdsAdjacentToSeaZone(
            multiRegion,
            'sea1',
            regionId: 'otherRegion',
          ),
          isEmpty,
        );
      });

      test('when sea zone not in topology, returns empty', () {
        expect(provinceIdsAdjacentToSeaZone(topology, 'nonexistent'), isEmpty);
      });
    });

    group('fleetsInPortAtProvince', () {
      test('returns fleets in port at province (inPortAtProvinceId)', () {
        final worldState = WorldState(
          turnState: TurnState(phase: TurnPhase.movement, turnNumber: 1),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
          portsByProvinceSeaboard: {'oldWorld|p1|sea1': 'oldWorld|p1|0|0'},
          fleets: [
            Fleet(
              id: 'f1',
              ownerId: 'gp1',
              seaZoneId: null,
              inPortAtProvinceId: 'oldWorld|p1',
              regionId: 'oldWorld',
              shipTypeIds: ['carrack', 'carrack'],
            ),
            Fleet(
              id: 'f2',
              ownerId: 'gp2',
              seaZoneId: 'sea2',
              inPortAtProvinceId: null,
              regionId: 'oldWorld',
              shipTypeIds: ['carrack'],
            ),
          ],
        );
        final inPort = fleetsInPortAtProvince(worldState, 'oldWorld|p1');
        expect(inPort.length, 1);
        expect(inPort.first.id, 'f1');
        expect(inPort.first.inPortAtProvinceId, 'oldWorld|p1');
      });

      test('returns empty when no fleet in port at province', () {
        final worldState = WorldState(
          turnState: TurnState(phase: TurnPhase.movement, turnNumber: 1),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
          portsByProvinceSeaboard: {'oldWorld|p2|sea1': 'oldWorld|p2|0|0'},
          fleets: const [],
        );
        expect(fleetsInPortAtProvince(worldState, 'oldWorld|p1'), isEmpty);
      });
    });
  });
}
