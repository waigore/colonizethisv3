import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';

void main() {
  group('Naval', () {
    late MapTopology topology;

    setUp(() {
      topology = MapTopology(
        nodes: const [
          TopologyNode(id: 'p1', regionId: 'oldWorld', type: TopologyNodeType.province),
          TopologyNode(id: 'p2', regionId: 'oldWorld', type: TopologyNodeType.province),
          TopologyNode(id: 'sea1', regionId: 'oldWorld', type: TopologyNodeType.seaZone),
          TopologyNode(id: 'sea2', regionId: 'oldWorld', type: TopologyNodeType.seaZone),
        ],
        edges: const [
          TopologyEdge(id1: 'p1', id2: 'sea1'),
          TopologyEdge(id1: 'p2', id2: 'sea1'),
          TopologyEdge(id1: 'sea1', id2: 'sea2'),
        ],
      );
    });

    group('isAdjacentSeaZone', () {
      test('returns true when sea zones are connected by edge', () {
        expect(isAdjacentSeaZone(topology, 'sea1', 'sea2'), isTrue);
        expect(isAdjacentSeaZone(topology, 'sea2', 'sea1'), isTrue);
      });

      test('returns true when province is adjacent to sea zone', () {
        expect(isAdjacentSeaZone(topology, 'p1', 'sea1'), isTrue);
        expect(isAdjacentSeaZone(topology, 'sea1', 'p1'), isTrue);
      });

      test('returns false for same zone', () {
        expect(isAdjacentSeaZone(topology, 'sea1', 'sea1'), isFalse);
      });

      test('returns false when no edge between zones', () {
        expect(isAdjacentSeaZone(topology, 'p1', 'sea2'), isFalse);
        expect(isAdjacentSeaZone(topology, 'p2', 'sea2'), isFalse);
      });
    });

    group('seaZoneIdForProvince', () {
      test('returns adjacent sea zone for coastal province', () {
        expect(seaZoneIdForProvince(topology, 'p1'), 'sea1');
        expect(seaZoneIdForProvince(topology, 'p2'), 'sea1');
      });

      test('when regionId is provided, lookup is region-scoped (world-model-identity)', () {
        final multiRegion = MapTopology(
          nodes: const [
            TopologyNode(id: 'p1', regionId: 'oldWorld', type: TopologyNodeType.province),
            TopologyNode(id: 'sea1', regionId: 'oldWorld', type: TopologyNodeType.seaZone),
            TopologyNode(id: 'p1', regionId: 'newWorld', type: TopologyNodeType.province),
            TopologyNode(id: 'sea2', regionId: 'newWorld', type: TopologyNodeType.seaZone),
          ],
          edges: const [
            TopologyEdge(id1: 'p1', id2: 'sea1'),
            TopologyEdge(id1: 'p1', id2: 'sea2'),
          ],
        );
        expect(seaZoneIdForProvince(multiRegion, 'p1', regionId: 'oldWorld'), 'sea1');
        expect(seaZoneIdForProvince(multiRegion, 'p1', regionId: 'newWorld'), 'sea2');
        expect(seaZoneIdForProvince(multiRegion, 'p1'), isNotNull);
      });

      test('returns null for province with no sea edge', () {
        final inland = MapTopology(
          nodes: const [
            TopologyNode(id: 'p1', regionId: 'oldWorld', type: TopologyNodeType.province),
            TopologyNode(id: 'p2', regionId: 'oldWorld', type: TopologyNodeType.province),
          ],
          edges: const [TopologyEdge(id1: 'p1', id2: 'p2')],
        );
        expect(seaZoneIdForProvince(inland, 'p1'), isNull);
      });
    });

    group('provinceIdsAdjacentToSeaZone', () {
      test('returns coastal provinces for sea zone', () {
        final ids = provinceIdsAdjacentToSeaZone(topology, 'sea1');
        expect(ids, containsAll(['p1', 'p2']));
        expect(ids.length, 2);
      });

      test('returns empty for sea zone with no province adjacent', () {
        final coastal = provinceIdsAdjacentToSeaZone(topology, 'sea2');
        expect(coastal, isEmpty);
      });
    });

    group('regionIdForSeaZone', () {
      test('returns regionId from topology node', () {
        expect(regionIdForSeaZone(topology, 'sea1'), 'oldWorld');
        expect(regionIdForSeaZone(topology, 'sea2'), 'oldWorld');
      });

      test('returns null when sea zone not found (no default region)', () {
        expect(regionIdForSeaZone(topology, 'nonexistent'), isNull);
      });
    });

    group('provinceIdsAdjacentToSeaZone region-scoped', () {
      test('when regionId passed, returns only provinces in that region', () {
        final multiRegion = MapTopology(
          nodes: const [
            TopologyNode(id: 'p1', regionId: 'oldWorld', type: TopologyNodeType.province),
            TopologyNode(id: 'sea1', regionId: 'oldWorld', type: TopologyNodeType.seaZone),
            TopologyNode(id: 'p1', regionId: 'newWorld', type: TopologyNodeType.province),
            TopologyNode(id: 'sea1', regionId: 'newWorld', type: TopologyNodeType.seaZone),
          ],
          edges: const [
            TopologyEdge(id1: 'p1', id2: 'sea1'),
          ],
        );
        expect(
          provinceIdsAdjacentToSeaZone(multiRegion, 'sea1', regionId: 'oldWorld'),
          equals({'p1'}),
        );
        expect(
          provinceIdsAdjacentToSeaZone(multiRegion, 'sea1', regionId: 'newWorld'),
          equals({'p1'}),
        );
        expect(
          provinceIdsAdjacentToSeaZone(multiRegion, 'sea1', regionId: 'otherRegion'),
          isEmpty,
        );
      });

      test('when sea zone not in topology, returns empty', () {
        expect(
          provinceIdsAdjacentToSeaZone(topology, 'nonexistent'),
          isEmpty,
        );
      });
    });
  });
}
