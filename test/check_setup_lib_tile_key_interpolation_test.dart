import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_setup_lib_tile_key_interpolation.dart';

void main() {
  group('findSetupLibTileKeyInterpolationViolations', () {
    const setupPath =
        'packages/colonizethis_setup/lib/src/setup/initial_visibility.dart';

    test('flags raw region|local|x|y tile-key interpolation', () {
      const src = r'''
String build(String regionId, String localId, int x, int y) {
  return '$regionId|$localId|$x|$y';
}
''';
      final violations = findSetupLibTileKeyInterpolationViolations(
        relativePath: setupPath,
        source: src,
      );
      expect(violations, hasLength(1));
      expect(violations.single.message, contains('CapitalTile.tileKey'));
    });

    test('flags interpolation with braced segments', () {
      const src = r'''
String build(int x, int y) {
  return '${kRegionOldWorld}|${localId}|${x}|${y}';
}
''';
      final violations = findSetupLibTileKeyInterpolationViolations(
        relativePath: setupPath,
        source: src,
      );
      expect(violations, hasLength(1));
    });

    test('accepts the canonical CapitalTile.tileKey helper call', () {
      const src = r'''
final tileKey = CapitalTile.tileKey(regionId, localId, x, y);
''';
      final violations = findSetupLibTileKeyInterpolationViolations(
        relativePath: setupPath,
        source: src,
      );
      expect(violations, isEmpty);
    });

    test('does not flag two-segment coord keys', () {
      const src = r'''
String coord(int x, int y) => '$x|$y';
''';
      final violations = findSetupLibTileKeyInterpolationViolations(
        relativePath: setupPath,
        source: src,
      );
      expect(violations, isEmpty);
    });

    test('does not flag descriptive log strings with non-pipe literals', () {
      const src = r'''
final line = 'i=$i|sz=${lm.size}|sea=$sea|min=${lm.minProvinceId}';
''';
      final violations = findSetupLibTileKeyInterpolationViolations(
        relativePath: setupPath,
        source: src,
      );
      expect(violations, isEmpty);
    });

    test('passes on the live setup lib source tree', () {
      final repoRoot = _repoRoot();
      final code = runCheckSetupLibTileKeyInterpolation(
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
