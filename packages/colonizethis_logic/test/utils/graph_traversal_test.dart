import 'package:colonizethis_logic/src/utils/graph_traversal.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('connectedComponentsInSubset', () {
    test('single component', () {
      final adj = {
        'a': {'b'},
        'b': {'a', 'c'},
        'c': {'b'},
      };
      final comps = connectedComponentsInSubset({'a', 'b', 'c'}, adj);
      expect(comps.length, 1);
      expect(comps.single, {'a', 'b', 'c'});
    });

    test('two components', () {
      final adj = {
        'a': {'b'},
        'b': {'a'},
        'x': {'y'},
        'y': {'x'},
      };
      final comps = connectedComponentsInSubset({'a', 'b', 'x', 'y'}, adj);
      expect(comps.length, 2);
      expect(comps.any((c) => c.contains('a') && c.contains('b')), isTrue);
      expect(comps.any((c) => c.contains('x') && c.contains('y')), isTrue);
    });

    test('isolated vertex is its own component', () {
      final adj = <String, Set<String>>{
        'a': {'b'},
        'b': {'a'},
      };
      final comps = connectedComponentsInSubset({'a', 'b', 'z'}, adj);
      expect(comps.length, 2);
      expect(comps.any((c) => c.length == 1 && c.contains('z')), isTrue);
    });
  });

  group('landmassIdsFromProvinceAdjacency', () {
    test('labels two disjoint edges as two landmasses', () {
      final adj = {
        'p1': {'p2'},
        'p2': {'p1'},
        'q1': {'q2'},
        'q2': {'q1'},
      };
      final ids = landmassIdsFromProvinceAdjacency(adj);
      expect(ids['p1'], ids['p2']);
      expect(ids['q1'], ids['q2']);
      expect(ids['p1'], isNot(ids['q1']));
    });
  });

  group('breadthFirstReachableInSubgraph', () {
    test('expands along sea–sea edges within universe', () {
      final sea = <String>{'s1', 's2', 's3'};
      final adj = {
        's1': {'s2'},
        's2': {'s1', 's3'},
        's3': {'s2'},
      };
      final r = breadthFirstReachableInSubgraph(['s1'], adj, sea);
      expect(r, {'s1', 's2', 's3'});
    });

    test('does not leave universe', () {
      final universe = <String>{'a', 'b'};
      final adj = {
        'a': {'b', 'x'},
        'b': {'a'},
        'x': {'a'},
      };
      final r = breadthFirstReachableInSubgraph(['a'], adj, universe);
      expect(r, {'a', 'b'});
    });
  });
}
