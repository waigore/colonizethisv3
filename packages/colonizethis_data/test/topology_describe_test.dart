import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:test/test.dart';

void main() {
  final topology = MapTopology(
    nodes: [
      const TopologyNode(id: 'p1', regionId: 'oldWorld', type: TopologyNodeType.province),
      const TopologyNode(id: 'p2', regionId: 'oldWorld', type: TopologyNodeType.province),
      const TopologyNode(id: 's1', regionId: 'oldWorld', type: TopologyNodeType.seaZone),
    ],
    edges: [
      const TopologyEdge(id1: 'p1', id2: 'p2'),
      const TopologyEdge(id1: 'p1', id2: 's1'),
    ],
  );

  group('describeTopologyGraph', () {
    test('returns string with nodes and edges', () {
      final s = describeTopologyGraph(topology);
      expect(s, contains('Nodes (3)'));
      expect(s, contains('P p1 (region: oldWorld)'));
      expect(s, contains('P p2 (region: oldWorld)'));
      expect(s, contains('S s1 (region: oldWorld)'));
      expect(s, contains('Edges (2)'));
      expect(s, contains('p1 <-> p2'));
      expect(s, contains('p1 <-> s1'));
    });
  });

  group('computeTileCountsPerRegion', () {
    test('counts tiles per region id', () {
      final result = TileMapResult(
        width: 3,
        height: 2,
        grid: [
          ['p1', 'p1', 'p2'],
          ['p1', 's1', 's1'],
        ],
      );
      final counts = computeTileCountsPerRegion(result);
      expect(counts['p1'], 3);
      expect(counts['p2'], 1);
      expect(counts['s1'], 2);
    });
  });

  group('formatMapSummary', () {
    test('formats tile count per node', () {
      final counts = {'p1': 10, 'p2': 5, 's1': 3};
      final s = formatMapSummary(topology, counts);
      expect(s, contains('Map summary'));
      expect(s, contains('p1'));
      expect(s, contains('10 tiles'));
      expect(s, contains('p2'));
      expect(s, contains('5 tiles'));
      expect(s, contains('s1'));
      expect(s, contains('3 tiles'));
    });
  });

  group('getProvinceListForInteractive', () {
    test('returns only province nodes with tile counts', () {
      final list = getProvinceListForInteractive(topology, {'p1': 4, 'p2': 2});
      expect(list.length, 2);
      expect(list.any((e) => e.id == 'p1' && e.regionId == 'oldWorld' && e.tileCount == 4), isTrue);
      expect(list.any((e) => e.id == 'p2' && e.regionId == 'oldWorld' && e.tileCount == 2), isTrue);
    });
    test('uses zero when tile counts not provided', () {
      final list = getProvinceListForInteractive(topology);
      expect(list.length, 2);
      expect(list.every((e) => e.tileCount == 0), isTrue);
    });
  });

  group('formatProvinceDetail', () {
    test('formats known province with owner', () {
      final s = formatProvinceDetail('p1', topology, tileCount: 12, ownerId: 'player1');
      expect(s, contains('Province: p1'));
      expect(s, contains('region: oldWorld'));
      expect(s, contains('owner: player1'));
      expect(s, contains('tiles: 12'));
      expect(s, contains('no improvement data'));
    });
    test('shows no owner when ownerId is null', () {
      final s = formatProvinceDetail('p2', topology, tileCount: 5);
      expect(s, contains('owner: no owner'));
    });
    test('returns not found for unknown province', () {
      final s = formatProvinceDetail('unknown', topology);
      expect(s, contains('Province not found: unknown'));
    });
  });
}
