import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_setup_dedup_advanced_start_flood_fill.dart';

void main() {
  group('findSetupDedupAdvancedStartFloodFillViolations', () {
    const colonization =
        'packages/colonizethis_setup/lib/src/setup/'
        'advanced_start_bootstrap_colonization.dart';
    const topology =
        'packages/colonizethis_setup/lib/src/setup/advanced_start_nw_topology.dart';

    test('flags private enqueue helper in bootstrap colonization', () {
      const src = '''
void _enqueueUnvisitedNeighbors({required String current}) {}
''';
      final violations = findSetupDedupAdvancedStartFloodFillViolations(
        sourcesByPath: const {colonization: src},
      );
      expect(violations, isNotEmpty);
      expect(violations.first.message, contains('enqueue'));
    });

    test('flags hand-rolled visited/queue/head BFS in bootstrap', () {
      const src = '''
void flood() {
  final visited = <String>{};
  final queue = <String>[];
  var head = 0;
  while (head < queue.length) {
    final current = queue[head++];
    visited.add(current);
  }
}
''';
      final violations = findSetupDedupAdvancedStartFloodFillViolations(
        sourcesByPath: const {colonization: src},
      );
      expect(violations, isNotEmpty);
      expect(violations.any((v) => v.message.contains('Hand-rolled')), isTrue);
    });

    test('exempts the canonical topology module', () {
      const src = '''
List<String> advancedStartFloodFillProvinces() {
  final visited = <String>{};
  final queue = <String>[];
  var head = 0;
  return const [];
}
''';
      final violations = findSetupDedupAdvancedStartFloodFillViolations(
        sourcesByPath: const {topology: src},
      );
      expect(violations, isEmpty);
    });

    test('passes on the live setup source tree', () {
      final code = runCheckSetupDedupAdvancedStartFloodFill(
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
