import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_setup_dedup_topology_adjacency.dart';

void main() {
  group('findSetupDedupTopologyAdjacencyViolations', () {
    const sharedModulePath =
        'packages/colonizethis_setup/lib/src/setup/setup_topology_adjacency.dart';
    const townsPath =
        'packages/colonizethis_setup/lib/src/setup/game_setup_helpers_towns.dart';
    const portRoadPath =
        'packages/colonizethis_setup/lib/src/setup/capital_choice_port_road_geometry.dart';

    test('flags re-inlined private topology-adjacency clones', () {
      const src = r'''
Set<String> _provinceNodeIds(MapTopology t) => {};
Set<String> _seaZonesAdjacentToProvince(MapTopology t, String p) => {};
bool _anyCardinalNeighborCell(int x, int y, Object m, Object t) => false;
''';
      final violations = findSetupDedupTopologyAdjacencyViolations(
        sourcesByPath: const {portRoadPath: src},
      );
      expect(violations.length, 3);
    });

    test('flags the towns _provinceSeaZones clone', () {
      const src = r'''
Set<String> _provinceSeaZones({required String provinceId}) => {};
''';
      final violations = findSetupDedupTopologyAdjacencyViolations(
        sourcesByPath: const {townsPath: src},
      );
      expect(violations, hasLength(1));
      expect(violations.single.message, contains('_provinceSeaZones'));
    });

    test('accepts delegation to world + shared helpers', () {
      const src = r'''
final ids = provinceNodeIds(topology);
final zones = seaZonesAdjacentToProvince(topology, localId);
final touches = tileAdjacentToSeaZone(x, y, map, topology, seaZoneId);
final near = anyCardinalNeighborCell(x, y, map, (c) => c == seaZoneId);
''';
      final violations = findSetupDedupTopologyAdjacencyViolations(
        sourcesByPath: const {townsPath: src},
      );
      expect(violations, isEmpty);
    });

    test('exempts the shared module that owns the canonical helpers', () {
      const src = r'''
bool anyCardinalNeighborCell(int x, int y, Object m, Object t) => false;
bool tileAdjacentToSeaZone(int x, int y, Object m, Object t, String s) => false;
''';
      final violations = findSetupDedupTopologyAdjacencyViolations(
        sourcesByPath: const {sharedModulePath: src},
      );
      expect(violations, isEmpty);
    });

    test('ignores patterns appearing only in comment lines', () {
      const src = r'''
// historical: _provinceNodeIds and _seaZonesAdjacentToProvince were clones.
/// _anyCardinalNeighborCell moved to the shared module before #3740.
''';
      final violations = findSetupDedupTopologyAdjacencyViolations(
        sourcesByPath: const {townsPath: src},
      );
      expect(violations, isEmpty);
    });

    test('passes on the live setup source tree', () {
      final code = runCheckSetupDedupTopologyAdjacency(
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
