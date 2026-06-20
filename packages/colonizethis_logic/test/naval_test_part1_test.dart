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

    group('indexTopologyNodesByRegion', () {
      test('groups nodes by regionId and id', () {
        final idx = indexTopologyNodesByRegion(topology);
        expect(idx.keys, contains('oldWorld'));
        expect(
          idx['oldWorld']!.keys,
          containsAll(['p1', 'p2', 'sea1', 'sea2']),
        );
        expect(idx['oldWorld']!['p1']!.type, TopologyNodeType.province);
      });

      test(
        'returns the same Map instance on repeat calls for the same topology (Refs #2316 P2 #15)',
        () {
          final first = indexTopologyNodesByRegion(topology);
          final second = indexTopologyNodesByRegion(topology);
          expect(identical(first, second), isTrue);
        },
      );

      test('separate topology instances do not share cached node maps', () {
        final other = MapTopology(
          nodes: const [
            TopologyNode(
              id: 'pX',
              regionId: 'newWorld',
              type: TopologyNodeType.province,
            ),
          ],
          edges: const [],
        );
        expect(
          identical(
            indexTopologyNodesByRegion(topology),
            indexTopologyNodesByRegion(other),
          ),
          isFalse,
        );
      });
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

    group('isAdjacentSeaSeaZone', () {
      test('true only for S–S edges between sea-zone nodes', () {
        expect(isAdjacentSeaSeaZone(topology, 'sea1', 'sea2'), isTrue);
        expect(isAdjacentSeaSeaZone(topology, 'sea1', 'p1'), isFalse);
        expect(isAdjacentSeaSeaZone(topology, 'p1', 'sea1'), isFalse);
      });
    });

    group('navalMoveTopologyPicksForFleet', () {
      test('at sea: sea list is S–S only; dock list from S–P', () {
        final fleet = Fleet(
          id: 'f1',
          ownerId: 'p1',
          regionId: 'oldWorld',
          seaZoneId: 'sea1',
          shipTypeIds: const ['carrack'],
        );
        final picks = navalMoveTopologyPicksForFleet(
          topology: topology,
          fleet: fleet,
        );
        expect(picks.adjacentSeaZoneIds, ['sea2']);
        expect(picks.adjacentProvinceIdsForDock.toSet(), {'p1', 'p2'});
      });

      test('in port: undock list is P–S only (all seas touching port)', () {
        final top = MapTopology(
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
              id: 'sea2',
              regionId: 'oldWorld',
              type: TopologyNodeType.seaZone,
            ),
          ],
          edges: const [
            TopologyEdge(id1: 'p1', id2: 'sea1'),
            TopologyEdge(id1: 'p1', id2: 'sea2'),
          ],
        );
        final fleet = Fleet(
          id: 'f1',
          ownerId: 'p1',
          regionId: 'oldWorld',
          inPortAtProvinceId: 'p1',
          shipTypeIds: const ['carrack'],
        );
        final picks = navalMoveTopologyPicksForFleet(
          topology: top,
          fleet: fleet,
        );
        expect(picks.adjacentSeaZoneIds.toSet(), {'sea1', 'sea2'});
        expect(picks.adjacentProvinceIdsForDock, isEmpty);
      });
    });
  });
}
