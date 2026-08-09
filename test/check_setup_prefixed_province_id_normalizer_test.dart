import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_setup_prefixed_province_id_normalizer.dart';

void main() {
  group('findSetupPrefixedProvinceIdNormalizerViolations', () {
    const setupLibPath =
        'packages/colonizethis_setup/lib/src/setup/advanced_start.dart';
    const setupTestPath =
        'packages/colonizethis_setup/test/setup/advanced_start_test.dart';

    test('flags manual prefixed id ternary normalization', () {
      const src = '''
final id = ProvinceId.isPrefixed(province.id)
    ? province.id
    : ProvinceId.full(province.regionId, province.id);
''';
      final violations = findSetupPrefixedProvinceIdNormalizerViolations(
        sourcesByPath: const {setupLibPath: src},
      );
      expect(violations, hasLength(1));
      expect(violations.single.line, 1);
      expect(violations.single.message, contains('prefixedFrom'));
    });

    test('flags manual local id ternary normalization in tests', () {
      const src = '''
final localId = ProvinceId.isPrefixed(province.id)
    ? ProvinceId.localIdFrom(province.id)
    : province.id;
''';
      final violations = findSetupPrefixedProvinceIdNormalizerViolations(
        sourcesByPath: const {setupTestPath: src},
      );
      expect(violations, hasLength(1));
      expect(violations.single.message, contains('localFromMaybePrefixed'));
    });

    test('accepts canonical helpers and non-ternary checks', () {
      const src = '''
final id = ProvinceId.prefixedFrom(province.regionId, province.id);
final localId = ProvinceId.localFromMaybePrefixed(province.id);
if (ProvinceId.isPrefixed(id)) return id;
''';
      final violations = findSetupPrefixedProvinceIdNormalizerViolations(
        sourcesByPath: const {setupLibPath: src},
      );
      expect(violations, isEmpty);
    });

    test('ignores comment lines', () {
      const src = '''
// final id = ProvinceId.isPrefixed(province.id) ? province.id : ProvinceId.full(regionId, province.id);
/// Use ProvinceId.prefixedFrom instead of ProvinceId.isPrefixed(id) ? ...
''';
      final violations = findSetupPrefixedProvinceIdNormalizerViolations(
        sourcesByPath: const {setupLibPath: src},
      );
      expect(violations, isEmpty);
    });

    test('passes on the live setup source tree', () {
      final repoRoot = _repoRoot();
      final code = runCheckSetupPrefixedProvinceIdNormalizer(
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
