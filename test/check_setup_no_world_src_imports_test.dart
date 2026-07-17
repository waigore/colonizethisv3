import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_setup_no_world_src_imports.dart';

void main() {
  group('findSetupWorldSrcImportViolations', () {
    const setupLibPath =
        'packages/colonizethis_setup/lib/src/setup/capital_choice.dart';
    const setupTestPath =
        'packages/colonizethis_setup/test/validation_exceptions_test.dart';

    test('flags a world src import in lib', () {
      const src = '''
import 'package:colonizethis_world/src/world/capital_reassignment.dart';
''';
      final violations = findSetupWorldSrcImportViolations(
        sourcesByPath: const {setupLibPath: src},
      );
      expect(violations, hasLength(1));
      expect(violations.single.line, 1);
      expect(
        violations.single.directive,
        contains('colonizethis_world/src/world/capital_reassignment.dart'),
      );
    });

    test('flags a world src export in lib', () {
      const src = '''
export 'package:colonizethis_world/src/world/town_capital_tile_strip.dart'
    show collectTownAndCapitalTileKeys;
''';
      final violations = findSetupWorldSrcImportViolations(
        sourcesByPath: const {setupLibPath: src},
      );
      expect(violations, hasLength(1));
      expect(violations.single.directive, startsWith('export '));
    });

    test('flags a world src import in test', () {
      const src = '''
import 'package:colonizethis_world/src/utils/graph_traversal.dart'
    show connectedComponentsInSubset;
''';
      final violations = findSetupWorldSrcImportViolations(
        sourcesByPath: const {setupTestPath: src},
      );
      expect(violations, hasLength(1));
    });

    test('accepts barrel imports and own-package src imports', () {
      const src = '''
import 'package:colonizethis_world/colonizethis_world.dart';
import 'package:colonizethis_setup/src/setup/setup_exceptions.dart';
export 'package:colonizethis_world/colonizethis_world.dart'
    show connectedComponentsInSubset;
''';
      final violations = findSetupWorldSrcImportViolations(
        sourcesByPath: const {setupLibPath: src},
      );
      expect(violations, isEmpty);
    });

    test('ignores comment lines', () {
      const src = '''
// import 'package:colonizethis_world/src/utils/graph_traversal.dart';
/// export 'package:colonizethis_world/src/world/capital_reassignment.dart'
''';
      final violations = findSetupWorldSrcImportViolations(
        sourcesByPath: const {setupLibPath: src},
      );
      expect(violations, isEmpty);
    });

    test('sorts violations across files', () {
      const badImport = '''
import 'package:colonizethis_world/src/world/naval.dart';
''';
      final violations = findSetupWorldSrcImportViolations(
        sourcesByPath: const {
          setupTestPath: badImport,
          setupLibPath: badImport,
        },
      );
      expect(violations, hasLength(2));
      expect(violations.first.path, setupLibPath);
      expect(violations.last.path, setupTestPath);
    });

    test('passes on the live setup source tree', () {
      final repoRoot = _repoRoot();
      final code = runCheckSetupNoWorldSrcImports(
        repoRoot,
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
