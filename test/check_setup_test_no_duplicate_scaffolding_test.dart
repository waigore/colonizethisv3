import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_setup_test_no_duplicate_scaffolding.dart';

void main() {
  group('setupTestDuplicateScaffoldingViolationReason', () {
    const supportPath =
        'packages/colonizethis_setup/test/setup/init_game_orchestrator_test_support.dart';

    test('flags a re-inlined provinceNeighboursFromTopology clone', () {
      const src = r'''
Map<String, Set<String>> _provincePpNeighbours(MapTopology topology) {
  final provinces = {
    for (final n in topology.nodes)
      if (n.type == TopologyNodeType.province) n.id,
  };
  final neighbours = <String, Set<String>>{};
  for (final edge in topology.edges) {
    neighbours[edge.id1]!.add(edge.id2);
  }
  return neighbours;
}
''';
      final reason = setupTestDuplicateScaffoldingViolationReason(
        supportPath,
        src,
      );
      expect(reason, isNotNull);
      expect(reason, contains('provinceNeighboursFromTopology'));
    });

    test('flags a re-inlined connected-components clone', () {
      const src = r'''
List<Set<String>> _landComponents(Map<String, Set<String>> neighbours) {
  final visited = <String>{};
  final out = <Set<String>>[];
  for (final start in neighbours.keys) {
    if (visited.contains(start)) continue;
  }
  return out;
}
''';
      final reason = setupTestDuplicateScaffoldingViolationReason(
        supportPath,
        src,
      );
      expect(reason, isNotNull);
      expect(reason, contains('connectedComponentsInSubset'));
    });

    test('accepts reuse of the production helpers', () {
      const src = r'''
final nbr = provinceNeighboursFromTopology(topology);
final comps = connectedComponentsInSubset(nbr.keys.toSet(), nbr);
''';
      final reason = setupTestDuplicateScaffoldingViolationReason(
        supportPath,
        src,
      );
      expect(reason, isNull);
    });

    test('does not flag mere TopologyNodeType.province use without edges', () {
      const src = r'''
final provinceNodes = topology.nodes
    .where((n) => n.type == TopologyNodeType.province)
    .toList();
expect(provinceNodes, isNotEmpty);
''';
      final reason = setupTestDuplicateScaffoldingViolationReason(
        supportPath,
        src,
      );
      expect(reason, isNull);
    });

    test('returns null for out-of-scope (non-setup-test) paths', () {
      const src = r'''
for (final edge in topology.edges) {}
final t = TopologyNodeType.province;
final m = <String, Set<String>>{};
''';
      final reason = setupTestDuplicateScaffoldingViolationReason(
        'packages/colonizethis_ai/test/foo_test.dart',
        src,
      );
      expect(reason, isNull);
    });

    test('passes on the live setup test tree', () {
      final code = runCheckSetupTestNoDuplicateScaffolding(
        _repoRoot(),
        info: (_) {},
        err: (_) {},
      );
      expect(code, 0);
    });
  });
}

String _repoRoot() {
  var dir = Directory.current;
  while (true) {
    final manifest = File(
      p.join(dir.path, 'tool', 'ct_repo_lint_manifest.yaml'),
    );
    if (manifest.existsSync()) return dir.path;
    final parent = dir.parent;
    if (parent.path == dir.path) {
      return Directory.current.path;
    }
    dir = parent;
  }
}
