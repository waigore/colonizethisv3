import 'package:test/test.dart';

import '../tool/check_map_grid_ops_central.dart';

void main() {
  group('findMapGridOpsCentralViolations', () {
    test('flags a removed copyTileMapGrid(...) call', () {
      const src = r'''
final next = copyTileMapGrid(grid);
''';
      final violations = findMapGridOpsCentralViolations(
        relativePath:
            'packages/colonizethis_map/lib/src/tile_map_generator_lakes_provinces.dart',
        source: src,
      );
      expect(violations, hasLength(1));
      expect(violations.single.message, contains('TileMapGrid.copy'));
    });

    test('flags an inline row-major deep copy', () {
      const src = r'''
final copy = grid.map((row) => row.toList()).toList();
''';
      final violations = findMapGridOpsCentralViolations(
        relativePath: 'packages/colonizethis_map/lib/src/foo.dart',
        source: src,
      );
      expect(violations, hasLength(1));
      expect(violations.single.message, contains('TileMapGrid.copy'));
    });

    test('accepts the canonical TileMapGrid.copy(...) delegation', () {
      const src = r'''
final next = TileMapGrid.copy(grid);
''';
      final violations = findMapGridOpsCentralViolations(
        relativePath:
            'packages/colonizethis_map/lib/src/tile_map_generator_lakes_provinces.dart',
        source: src,
      );
      expect(violations, isEmpty);
    });

    test('does not flag a comment mentioning copyTileMapGrid', () {
      const src = r'''
/// Replaces the old copyTileMapGrid(...) helper with TileMapGrid.copy(...).
final next = TileMapGrid.copy(grid);
''';
      final violations = findMapGridOpsCentralViolations(
        relativePath: 'packages/colonizethis_map/lib/src/foo.dart',
        source: src,
      );
      expect(violations, isEmpty);
    });

    test('does not flag an unrelated single-list toList copy', () {
      const src = r'''
final rows = grid.toList();
''';
      final violations = findMapGridOpsCentralViolations(
        relativePath: 'packages/colonizethis_map/lib/src/foo.dart',
        source: src,
      );
      expect(violations, isEmpty);
    });
  });
}
