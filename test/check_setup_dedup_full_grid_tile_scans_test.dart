import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_setup_dedup_full_grid_tile_scans.dart';

void main() {
  group('findSetupDedupFullGridTileScansViolations', () {
    const shared =
        'packages/colonizethis_setup/lib/src/setup/tile_cell_scan.dart';
    const other =
        'packages/colonizethis_setup/lib/src/setup/setup_road_wiring.dart';

    test('flags a nested height×width double-loop outside the shared module', () {
      const src = '''
void scan(TileMapResult map) {
  for (var y = 0; y < map.height; y++) {
    for (var x = 0; x < map.width; x++) {
      final cell = map.cell(x, y);
    }
  }
}
''';
      final violations = findSetupDedupFullGridTileScansViolations(
        sourcesByPath: const {other: src},
      );
      expect(violations, hasLength(1));
      expect(violations.single.message, contains('Nested full-grid'));
    });

    test('exempts tile_cell_scan.dart', () {
      const src = '''
void forEachTileCell(TileMapResult map, String regionId, visitor) {
  for (var y = 0; y < map.height; y++) {
    for (var x = 0; x < map.width; x++) {
      visitor(x, y);
    }
  }
}
''';
      final violations = findSetupDedupFullGridTileScansViolations(
        sourcesByPath: const {shared: src},
      );
      expect(violations, isEmpty);
    });

    test('does not flag edge scans without a nested width loop', () {
      const src = '''
void edge(TileMapResult tileMap, int h, int w) {
  for (var y = 0; y < h; y++) {
    final left = tileMap.cell(0, y);
    final right = tileMap.cell(w - 1, y);
  }
}
''';
      final violations = findSetupDedupFullGridTileScansViolations(
        sourcesByPath: {
          'packages/colonizethis_setup/lib/src/setup/warp_zone_generator.dart':
              src,
        },
      );
      expect(violations, isEmpty);
    });

    test('passes on the live setup source tree', () {
      final code = runCheckSetupDedupFullGridTileScans(
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
