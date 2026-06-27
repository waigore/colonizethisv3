import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_setup_dedup_grid_bfs_coord_keys.dart';

void main() {
  group('findSetupGridBfsCoordKeyViolations', () {
    const townsPath =
        'packages/colonizethis_setup/lib/src/setup/game_setup_helpers_towns.dart';

    test('flags inline cardinal-delta integer-pair list literals', () {
      const src = r'''
void f() {
  for (final delta in const [
    [1, 0],
    [-1, 0],
    [0, 1],
    [0, -1],
  ]) {
    use(delta);
  }
}
''';
      final violations = findSetupGridBfsCoordKeyViolations(
        relativePath: townsPath,
        source: src,
      );
      expect(violations.length, 4);
      expect(violations.first.message, contains('cardinal-delta'));
    });

    test('flags raw coord-key interpolation with coordinate-like operands', () {
      const src = r'''
String f(int nx, int ny) => '$nx|$ny';
String g(Object coords) => '${coords.x}|${coords.y}';
''';
      final violations = findSetupGridBfsCoordKeyViolations(
        relativePath: townsPath,
        source: src,
      );
      expect(violations.length, 2);
      expect(violations.first.message, contains('coord-key'));
    });

    test('does not flag id-join interpolations or gridCoordKey usage', () {
      const src = r'''
String port(String provinceId, String seaZoneId) => '$provinceId|$seaZoneId';
String prov(String regionId, String localProvinceId) =>
    '$regionId|$localProvinceId';
String key(int x, int y) => gridCoordKey(x, y);
''';
      final violations = findSetupGridBfsCoordKeyViolations(
        relativePath: townsPath,
        source: src,
      );
      expect(violations, isEmpty);
    });

    test('passes on the live setup lib tree (grid_bfs.dart exempt)', () {
      final code = runCheckSetupDedupGridBfsCoordKeys(
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
