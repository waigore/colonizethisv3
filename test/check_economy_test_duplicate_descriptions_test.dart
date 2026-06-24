import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_economy_test_duplicate_descriptions.dart';

void main() {
  group('findEconomyTestDuplicateDescriptions', () {
    const fileA = 'packages/colonizethis_economy/test/a_test.dart';
    const fileB = 'packages/colonizethis_economy/test/b_test.dart';

    test('flags a description shared across two files', () {
      const srcA = r'''
void main() {
  test('relation 75 yields 60.0 treasury credit', () {});
}
''';
      const srcB = r'''
void main() {
  test('relation 75 yields 60.0 treasury credit', () {});
}
''';
      final violations = findEconomyTestDuplicateDescriptions(
        sourcesByPath: const {fileA: srcA, fileB: srcB},
      );
      expect(violations, hasLength(1));
      expect(violations.single.description, contains('relation 75'));
      expect(violations.single.paths, equals([fileA, fileB]));
    });

    test('also flags testWidgets descriptions shared across files', () {
      const srcA = r'''
void main() {
  testWidgets('panel renders timber bid', (tester) async {});
}
''';
      const srcB = r'''
void main() {
  testWidgets('panel renders timber bid', (tester) async {});
}
''';
      final violations = findEconomyTestDuplicateDescriptions(
        sourcesByPath: const {fileA: srcA, fileB: srcB},
      );
      expect(violations, hasLength(1));
      expect(violations.single.description, 'panel renders timber bid');
    });

    test('allows the same description repeated within a single file', () {
      const src = r'''
void main() {
  group('one', () {
    test('grain used before meat', () {});
  });
  group('two', () {
    test('grain used before meat', () {});
  });
}
''';
      final violations = findEconomyTestDuplicateDescriptions(
        sourcesByPath: const {fileA: src},
      );
      expect(violations, isEmpty);
    });

    test('allows distinct descriptions across files', () {
      const srcA = r'''
void main() {
  test('relation 75 yields 60.0 treasury credit', () {});
}
''';
      const srcB = r'''
void main() {
  test('relation 100 yields 40 percent share', () {});
}
''';
      final violations = findEconomyTestDuplicateDescriptions(
        sourcesByPath: const {fileA: srcA, fileB: srcB},
      );
      expect(violations, isEmpty);
    });

    test('ignores a matching description that lives in a comment', () {
      const srcA = r'''
void main() {
  test('navy fed before workers', () {});
}
''';
      const srcB = r'''
void main() {
  // test('navy fed before workers', () {}); // moved to phases test
  /// test('navy fed before workers', () {});
  test('navy fed before workers at the phase level', () {});
}
''';
      final violations = findEconomyTestDuplicateDescriptions(
        sourcesByPath: const {fileA: srcA, fileB: srcB},
      );
      expect(violations, isEmpty);
    });

    test('ignores adjacent-string (multi-line) descriptions', () {
      // Concatenated descriptions are not single-literal first arguments, so
      // they are intentionally skipped rather than partially matched.
      const srcA = r'''
void main() {
  test('partial FRR fill: residual offer quantity becomes available '
      'for other GPs', () {});
}
''';
      const srcB = r'''
void main() {
  test('partial FRR fill: residual offer quantity becomes available '
      'for other GPs', () {});
}
''';
      final violations = findEconomyTestDuplicateDescriptions(
        sourcesByPath: const {fileA: srcA, fileB: srcB},
      );
      expect(violations, isEmpty);
    });

    test('passes on the live economy test tree', () {
      final repoRoot = _repoRoot();
      final code = runCheckEconomyTestDuplicateDescriptions(
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
