import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_setup_naming_lookup.dart';

void main() {
  group('findSetupNamingLookupViolations', () {
    const canonicalPath =
        'packages/colonizethis_setup/lib/src/setup/setup_naming_lookup.dart';
    const namingPath =
        'packages/colonizethis_setup/lib/src/setup/game_setup_helpers_naming.dart';

    test('flags empty MinorNationNaming sentinel', () {
      const src = '''
orElse: () => const MinorNationNaming(id: '', displayName: ''),
''';
      final violations = findSetupNamingLookupViolations(
        sourcesByPath: const {namingPath: src},
      );
      expect(violations, hasLength(1));
      expect(violations.single.message, contains('resolvedMinorNaming'));
    });

    test('flags empty TribeNaming sentinel', () {
      const src = '''
orElse: () => const TribeNaming(id: '', displayName: '', provinceNamePool: []),
''';
      final violations = findSetupNamingLookupViolations(
        sourcesByPath: const {namingPath: src},
      );
      expect(violations, hasLength(1));
      expect(violations.single.message, contains('resolvedTribeNaming'));
    });

    test('accepts shared helper call sites', () {
      const src = '''
final namingMinor = resolvedMinorNaming(naming, minor.id);
final namingTribe = resolvedTribeNaming(naming, tribe.id);
''';
      final violations = findSetupNamingLookupViolations(
        sourcesByPath: const {namingPath: src},
      );
      expect(violations, isEmpty);
    });

    test('exempts the canonical naming lookup module', () {
      const src = '''
orElse: () => const MinorNationNaming(id: '', displayName: ''),
orElse: () => const TribeNaming(id: '', displayName: '', provinceNamePool: []),
''';
      final violations = findSetupNamingLookupViolations(
        sourcesByPath: const {canonicalPath: src},
      );
      expect(violations, isEmpty);
    });

    test('ignores comment lines', () {
      const src = '''
// const MinorNationNaming(id: '', displayName: ''),
/// Avoid TribeNaming(id: '', displayName: '', provinceNamePool: []).
''';
      final violations = findSetupNamingLookupViolations(
        sourcesByPath: const {namingPath: src},
      );
      expect(violations, isEmpty);
    });

    test('passes on the live setup source tree', () {
      final repoRoot = _repoRoot();
      final code = runCheckSetupNamingLookup(
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
